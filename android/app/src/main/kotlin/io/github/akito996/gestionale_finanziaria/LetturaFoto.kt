package io.github.akito996.gestionale_finanziaria

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Rect
import android.media.ExifInterface
import android.os.Handler
import android.os.Looper
import com.googlecode.tesseract.android.TessBaseAPI
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * Lettura del testo dalle foto (scontrini, contratti) con Tesseract, tutta sul
 * telefono: la foto non esce mai dal dispositivo.
 *
 * Metodi del canale `gestionale/lettura_foto`:
 * - `leggi(percorso)`: tutta la foto, righe con posizione e affidabilità;
 * - `zona(percorso, sinistra, sopra, destra, sotto, riga)`: rilegge una zona
 *   ingrandita (lo "zoom" sui dati) e ne restituisce anche l'immagine;
 * - `chiudi()`: libera memoria e motore.
 */
class LetturaFoto(private val contesto: Context) : MethodChannel.MethodCallHandler {
    // Tesseract non è thread-safe: un solo thread in background, sempre lo stesso.
    private val esecutore = Executors.newSingleThreadExecutor()
    private val principale = Handler(Looper.getMainLooper())
    private var tesseract: TessBaseAPI? = null
    private var percorsoCaricato: String? = null
    private var foto: Bitmap? = null

    override fun onMethodCall(chiamata: MethodCall, risultato: MethodChannel.Result) {
        esecutore.execute {
            try {
                val valore: Any? = when (chiamata.method) {
                    "leggi" -> leggi(chiamata.argument<String>("percorso")!!)
                    "zona" -> zona(
                        chiamata.argument<String>("percorso")!!,
                        Rect(
                            chiamata.argument<Int>("sinistra")!!,
                            chiamata.argument<Int>("sopra")!!,
                            chiamata.argument<Int>("destra")!!,
                            chiamata.argument<Int>("sotto")!!,
                        ),
                        chiamata.argument<Boolean>("riga") ?: true,
                    )
                    "chiudi" -> {
                        chiudi()
                        null
                    }
                    else -> {
                        principale.post { risultato.notImplemented() }
                        return@execute
                    }
                }
                principale.post { risultato.success(valore) }
            } catch (e: Throwable) {
                principale.post { risultato.error("lettura_foto", e.message, null) }
            }
        }
    }

    /** Tutta la foto: righe di testo con il riquadro (in pixel della foto). */
    private fun leggi(percorso: String): Map<String, Any> {
        val immagine = carica(percorso)
        val api = motore()
        api.pageSegMode = TessBaseAPI.PageSegMode.PSM_AUTO
        api.setImage(inGrigio(immagine))
        api.getUTF8Text() // esegue il riconoscimento
        val righe = mutableListOf<Map<String, Any>>()
        val iteratore = api.resultIterator
        if (iteratore != null) {
            val livello = TessBaseAPI.PageIteratorLevel.RIL_TEXTLINE
            iteratore.begin()
            do {
                val testo = iteratore.getUTF8Text(livello)?.trim().orEmpty()
                val riquadro = iteratore.getBoundingRect(livello)
                if (testo.isNotEmpty()) {
                    righe.add(
                        mapOf(
                            "testo" to testo,
                            "affidabilita" to iteratore.confidence(livello).toDouble(),
                            "sinistra" to riquadro.left,
                            "sopra" to riquadro.top,
                            "destra" to riquadro.right,
                            "sotto" to riquadro.bottom,
                        ),
                    )
                }
            } while (iteratore.next(livello))
            iteratore.delete()
        }
        api.clear()
        return mapOf(
            "larghezza" to immagine.width,
            "altezza" to immagine.height,
            "righe" to righe,
        )
    }

    /**
     * Lo "zoom": ritaglia la zona, la ingrandisce finché il testo è alto
     * almeno ~48 pixel e la rilegge. [riga] = una sola riga di testo.
     */
    private fun zona(percorso: String, zona: Rect, riga: Boolean): Map<String, Any> {
        val immagine = carica(percorso)
        val ritaglio = Rect(
            zona.left.coerceIn(0, immagine.width - 1),
            zona.top.coerceIn(0, immagine.height - 1),
            zona.right.coerceIn(1, immagine.width),
            zona.bottom.coerceIn(1, immagine.height),
        )
        require(ritaglio.width() > 2 && ritaglio.height() > 2) { "Zona troppo piccola" }
        val pezzo = Bitmap.createBitmap(
            immagine,
            ritaglio.left,
            ritaglio.top,
            ritaglio.width(),
            ritaglio.height(),
        )
        val altezzaRiga = if (riga) ritaglio.height() else ritaglio.height() / 4
        val scala = (48.0 / max(altezzaRiga, 1)).coerceIn(1.5, 4.0)
        val ingrandito = Bitmap.createScaledBitmap(
            pezzo,
            (pezzo.width * scala).roundToInt(),
            (pezzo.height * scala).roundToInt(),
            true,
        )
        val grigio = inGrigio(ingrandito)
        val api = motore()
        api.pageSegMode =
            if (riga) TessBaseAPI.PageSegMode.PSM_SINGLE_LINE else TessBaseAPI.PageSegMode.PSM_SINGLE_BLOCK
        api.setImage(grigio)
        val testo = api.getUTF8Text()?.trim().orEmpty()
        val affidabilita = api.meanConfidence().toDouble()
        api.clear()
        val png = ByteArrayOutputStream().use { uscita ->
            pezzo.compress(Bitmap.CompressFormat.PNG, 100, uscita)
            uscita.toByteArray()
        }
        return mapOf("testo" to testo, "affidabilita" to affidabilita, "immagine" to png)
    }

    /** La foto dritta (EXIF) e al massimo 2400 pixel per lato, tenuta in memoria. */
    private fun carica(percorso: String): Bitmap {
        foto?.let { if (percorso == percorsoCaricato) return it }
        foto?.recycle()
        val misure = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(percorso, misure)
        var riduzione = 1
        while (max(misure.outWidth, misure.outHeight) / riduzione > 2400) {
            riduzione *= 2
        }
        val opzioni = BitmapFactory.Options().apply { inSampleSize = riduzione }
        val letta = BitmapFactory.decodeFile(percorso, opzioni)
            ?: throw IllegalArgumentException("Foto non leggibile")
        val gradi = when (
            ExifInterface(percorso).getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL,
            )
        ) {
            ExifInterface.ORIENTATION_ROTATE_90 -> 90f
            ExifInterface.ORIENTATION_ROTATE_180 -> 180f
            ExifInterface.ORIENTATION_ROTATE_270 -> 270f
            else -> 0f
        }
        val dritta = if (gradi == 0f) {
            letta
        } else {
            Bitmap.createBitmap(
                letta, 0, 0, letta.width, letta.height,
                Matrix().apply { postRotate(gradi) }, true,
            ).also { letta.recycle() }
        }
        foto = dritta
        percorsoCaricato = percorso
        return dritta
    }

    /** Scala di grigi: Tesseract legge meglio il testo senza i colori della carta. */
    private fun inGrigio(sorgente: Bitmap): Bitmap {
        val uscita = Bitmap.createBitmap(sorgente.width, sorgente.height, Bitmap.Config.ARGB_8888)
        val pennello = Paint().apply {
            colorFilter = ColorMatrixColorFilter(ColorMatrix().apply { setSaturation(0f) })
        }
        Canvas(uscita).drawBitmap(sorgente, 0f, 0f, pennello)
        return uscita
    }

    /** Motore Tesseract con il modello italiano (copiato dall'APK al primo uso). */
    private fun motore(): TessBaseAPI {
        tesseract?.let { return it }
        val cartella = File(contesto.filesDir, "tesseract")
        val modello = File(cartella, "tessdata/ita.traineddata")
        // Si ricopia a ogni installazione o aggiornamento dell'app.
        val segno = File(cartella, "installato")
        val installazione = contesto.packageManager
            .getPackageInfo(contesto.packageName, 0).lastUpdateTime.toString()
        if (!modello.exists() || !segno.exists() || segno.readText() != installazione) {
            modello.parentFile!!.mkdirs()
            val temporaneo = File(modello.parentFile, "ita.traineddata.tmp")
            contesto.assets.open("tessdata/ita.traineddata").use { entrata ->
                temporaneo.outputStream().use { entrata.copyTo(it) }
            }
            modello.delete()
            check(temporaneo.renameTo(modello)) { "Modello di lettura non installato" }
            segno.writeText(installazione)
        }
        val api = TessBaseAPI()
        check(api.init(cartella.absolutePath, "ita")) { "Motore di lettura non disponibile" }
        tesseract = api
        return api
    }

    private fun chiudi() {
        foto?.recycle()
        foto = null
        percorsoCaricato = null
        tesseract?.recycle()
        tesseract = null
    }
}
