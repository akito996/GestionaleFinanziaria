package io.github.akito996.gestionale_finanziaria

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity: serve alla finestra di verifica di Android
// (impronta, viso o PIN) dello sblocco rapido.
class MainActivity : FlutterFragmentActivity() {
    /** Link d'invito (wallecy://invito?...) non ancora letto dall'app. */
    private var invitoIniziale: String? = null
    private var canaleInviti: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Lettura delle foto (scontrini, contratti) sul telefono, con Tesseract.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "gestionale/lettura_foto",
        ).setMethodCallHandler(LetturaFoto(applicationContext))
        // Sblocco con impronta, viso o PIN del telefono.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "gestionale/sblocco_rapido",
        ).setMethodCallHandler(SbloccoRapido(this))
        // Selettore di Google Drive (portafogli condivisi, ADR-019).
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "gestionale/drive_file",
        ).setMethodCallHandler(DriveFile(this))
        // Link d'invito: quello che ha aperto l'app e quelli che arrivano dopo.
        invitoIniziale = invito(intent)
        canaleInviti = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "gestionale/invito",
        ).apply {
            setMethodCallHandler { chiamata, risultato ->
                if (chiamata.method == "iniziale") {
                    risultato.success(invitoIniziale)
                    invitoIniziale = null
                } else {
                    risultato.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        invito(intent)?.let { canaleInviti?.invokeMethod("arrivato", it) }
    }

    private fun invito(intent: Intent?): String? {
        val dati = intent?.data ?: return null
        return if (dati.scheme == "wallecy" && dati.host == "invito") {
            dati.toString()
        } else {
            null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // FLAG_SECURE: niente screenshot, registrazioni dello schermo e anteprime
        // nell'elenco delle app recenti (dati finanziari e Recovery Key).
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
    }
}
