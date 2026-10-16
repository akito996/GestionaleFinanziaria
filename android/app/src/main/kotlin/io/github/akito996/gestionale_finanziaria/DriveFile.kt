package io.github.akito996.gestionale_finanziaria

import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.fragment.app.FragmentActivity
import com.google.android.gms.auth.api.identity.AuthorizationRequest
import com.google.android.gms.auth.api.identity.AuthorizationResult
import com.google.android.gms.auth.api.identity.Identity
import com.google.android.gms.common.api.Scope
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicInteger

/**
 * Selettore di Google Drive per i portafogli condivisi (ADR-019, prova).
 *
 * Con il permesso `drive.file` l'app vede solo i file che crea lei o che
 * l'utente sceglie qui: il membro sceglie una volta la cartella condivisa
 * dal proprietario.
 */
class DriveFile(private val attivita: FragmentActivity) :
    MethodChannel.MethodCallHandler {
    companion object {
        private const val DRIVE_FILE = "https://www.googleapis.com/auth/drive.file"
        private const val CARTELLA = "application/vnd.google-apps.folder"
        private val richieste = AtomicInteger()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scegli" -> scegli(result)
            else -> result.notImplemented()
        }
    }

    private fun scegli(result: MethodChannel.Result) {
        val richiesta = AuthorizationRequest.Builder()
            .setRequestedScopes(listOf(Scope(DRIVE_FILE)))
            .setOptOutIncludingGrantedScopes(true)
            .setPrompt(AuthorizationRequest.Prompt.CONSENT)
            .addResourceParameter(
                AuthorizationRequest.ResourceParameter.PICKER_OAUTH_TRIGGER,
                "true",
            )
            .addResourceParameter(
                AuthorizationRequest.ResourceParameter.PICKER_ALLOW_FOLDER_SELECTION,
                "true",
            )
            // Solo cartelle: il membro sceglie la cartella condivisa, non i
            // file al suo interno.
            .addResourceParameter(
                AuthorizationRequest.ResourceParameter.PICKER_MIMETYPES,
                CARTELLA,
            )
            .build()
        val client = Identity.getAuthorizationClient(attivita)
        client.authorize(richiesta)
            .addOnSuccessListener { esito ->
                if (esito.hasResolution()) {
                    avviaSelettore(esito, result)
                } else {
                    rispondi(esito, result)
                }
            }
            .addOnFailureListener { e -> result.error("errore", e.message, null) }
    }

    /** La finestra di Google (scelta della cartella) e poi la risposta. */
    private fun avviaSelettore(esito: AuthorizationResult, result: MethodChannel.Result) {
        val intento = esito.pendingIntent
        if (intento == null) {
            result.error("errore", "Selettore non disponibile", null)
            return
        }
        val chiave = "drive_file_${richieste.incrementAndGet()}"
        var avvio: androidx.activity.result.ActivityResultLauncher<IntentSenderRequest>? = null
        avvio = attivita.activityResultRegistry.register(
            chiave,
            ActivityResultContracts.StartIntentSenderForResult(),
        ) { risposta ->
            avvio?.unregister()
            val dati = risposta.data
            if (dati == null) {
                result.error("annullato", "Scelta annullata", null)
                return@register
            }
            try {
                val finale = Identity.getAuthorizationClient(attivita)
                    .getAuthorizationResultFromIntent(dati)
                rispondi(finale, result)
            } catch (e: Exception) {
                result.error("annullato", e.message, null)
            }
        }
        avvio.launch(IntentSenderRequest.Builder(intento.intentSender).build())
    }

    private fun rispondi(esito: AuthorizationResult, result: MethodChannel.Result) {
        val token = esito.accessToken
        if (token == null) {
            result.error("errore", "Nessun accesso concesso", null)
            return
        }
        val scelti = esito.tokenResponseParams?.getString("picked_file_ids") ?: ""
        result.success(mapOf("token" to token, "scelti" to scelti))
    }
}
