package io.github.akito996.gestionale_finanziaria

import android.content.pm.PackageManager
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_STRONG
import androidx.biometric.BiometricManager.Authenticators.DEVICE_CREDENTIAL
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Sblocco con impronta, viso o PIN del telefono (ADR-016).
 *
 * Un segreto casuale apre l'archivio (nell'app). Qui viene cifrato con una
 * chiave AES dell'Android Keystore (nel chip di sicurezza StrongBox, se il
 * telefono ce l'ha) che si può usare solo subito dopo la verifica
 * dell'utente: senza impronta, viso "sicuro" o PIN il segreto resta cifrato.
 * Se si toglie il blocco schermo, Android annulla la chiave e l'app chiede di
 * nuovo la password.
 */
class SbloccoRapido(private val attivita: FragmentActivity) :
    MethodChannel.MethodCallHandler {
    companion object {
        private const val ALIAS = "gestionale.sblocco_rapido.v1"
        private const val LUNGHEZZA_IV = 12
        private const val TAG_BIT = 128
    }

    /** Da Android 11 anche il PIN (o segno, password) del telefono. */
    private val conPin = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R

    private val autenticatori =
        if (conPin) BIOMETRIC_STRONG or DEVICE_CREDENTIAL else BIOMETRIC_STRONG

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "disponibilita" -> result.success(
                mapOf("stato" to disponibilita(), "pin" to conPin),
            )
            "attiva" -> attiva(result)
            "leggi" -> leggi(call.argument<ByteArray>("dati"), result)
            "disattiva" -> {
                cancellaChiave()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun disponibilita(): String =
        when (BiometricManager.from(attivita).canAuthenticate(autenticatori)) {
            BiometricManager.BIOMETRIC_SUCCESS -> "pronta"
            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> "nessunMetodo"
            else -> "nonSupportata"
        }

    private fun attiva(result: MethodChannel.Result) {
        val cifrario = try {
            Cipher.getInstance("AES/GCM/NoPadding").apply {
                init(Cipher.ENCRYPT_MODE, nuovaChiave())
            }
        } catch (e: Exception) {
            result.error("errore", e.message, null)
            return
        }
        verifica(cifrario, "Attiva lo sblocco rapido", result) { c ->
            val segreto = ByteArray(32).also { SecureRandom().nextBytes(it) }
            mapOf("materiale" to segreto, "dati" to c.iv + c.doFinal(segreto))
        }
    }

    private fun leggi(dati: ByteArray?, result: MethodChannel.Result) {
        val chiave = try {
            KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
                .getKey(ALIAS, null) as? SecretKey
        } catch (e: Exception) {
            null
        }
        if (dati == null || dati.size <= LUNGHEZZA_IV || chiave == null) {
            result.error("invalidata", "Chiave dello sblocco rapido assente", null)
            return
        }
        val cifrario = try {
            Cipher.getInstance("AES/GCM/NoPadding").apply {
                init(
                    Cipher.DECRYPT_MODE,
                    chiave,
                    GCMParameterSpec(TAG_BIT, dati, 0, LUNGHEZZA_IV),
                )
            }
        } catch (e: KeyPermanentlyInvalidatedException) {
            // Blocco schermo tolto o (su molti telefoni) impronte cambiate.
            cancellaChiave()
            result.error("invalidata", e.message, null)
            return
        } catch (e: Exception) {
            result.error("errore", e.message, null)
            return
        }
        verifica(cifrario, "Sblocca l'archivio", result) { c ->
            mapOf(
                "materiale" to c.doFinal(dati, LUNGHEZZA_IV, dati.size - LUNGHEZZA_IV),
            )
        }
    }

    /** Chiede impronta, viso o PIN; con la verifica riuscita usa la chiave. */
    private fun verifica(
        cifrario: Cipher,
        titolo: String,
        result: MethodChannel.Result,
        usa: (Cipher) -> Any,
    ) {
        var risposto = false
        fun rispondi(risposta: () -> Unit) {
            if (!risposto) {
                risposto = true
                risposta()
            }
        }
        val richiesta = BiometricPrompt(
            attivita,
            ContextCompat.getMainExecutor(attivita),
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(
                    esito: BiometricPrompt.AuthenticationResult,
                ) = rispondi {
                    val c = esito.cryptoObject?.cipher
                    if (c == null) {
                        result.error("errore", "Verifica senza chiave", null)
                    } else {
                        try {
                            result.success(usa(c))
                        } catch (e: Exception) {
                            // Dati alterati o chiave non più valida.
                            result.error("invalidata", e.message, null)
                        }
                    }
                }

                override fun onAuthenticationError(
                    codice: Int,
                    messaggio: CharSequence,
                ) = rispondi {
                    val tipo = when (codice) {
                        BiometricPrompt.ERROR_USER_CANCELED,
                        BiometricPrompt.ERROR_NEGATIVE_BUTTON,
                        BiometricPrompt.ERROR_CANCELED,
                        -> "annullato"
                        BiometricPrompt.ERROR_LOCKOUT,
                        BiometricPrompt.ERROR_LOCKOUT_PERMANENT,
                        -> "bloccato"
                        else -> "errore"
                    }
                    result.error(tipo, messaggio.toString(), codice)
                }
            },
        )
        val info = BiometricPrompt.PromptInfo.Builder()
            .setTitle(titolo)
            .setSubtitle("WalleCy")
            .setAllowedAuthenticators(autenticatori)
            .setConfirmationRequired(false)
            .apply { if (!conPin) setNegativeButtonText("Usa la password") }
            .build()
        richiesta.authenticate(info, BiometricPrompt.CryptoObject(cifrario))
    }

    private fun nuovaChiave(): SecretKey {
        cancellaChiave()
        val generatore = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            "AndroidKeyStore",
        )
        val chip = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            attivita.packageManager.hasSystemFeature(
                PackageManager.FEATURE_STRONGBOX_KEYSTORE,
            )
        if (chip) {
            try {
                generatore.init(specifica(strongBox = true))
                return generatore.generateKey()
            } catch (e: Exception) {
                // StrongBox occupato o senza AES: si usa l'area sicura (TEE).
            }
        }
        generatore.init(specifica(strongBox = false))
        return generatore.generateKey()
    }

    private fun specifica(strongBox: Boolean): KeyGenParameterSpec =
        KeyGenParameterSpec.Builder(
            ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .setUserAuthenticationRequired(true)
            .setInvalidatedByBiometricEnrollment(true)
            .apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    setUserAuthenticationParameters(
                        0,
                        KeyProperties.AUTH_BIOMETRIC_STRONG or
                            KeyProperties.AUTH_DEVICE_CREDENTIAL,
                    )
                } else {
                    // Una verifica per ogni uso, solo impronta.
                    @Suppress("DEPRECATION")
                    setUserAuthenticationValidityDurationSeconds(-1)
                }
                if (strongBox && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    setIsStrongBoxBacked(true)
                }
            }
            .build()

    private fun cancellaChiave() {
        try {
            KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
                .deleteEntry(ALIAS)
        } catch (e: Exception) {
            // Nessuna chiave da cancellare.
        }
    }
}
