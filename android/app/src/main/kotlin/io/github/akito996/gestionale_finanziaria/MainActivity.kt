package io.github.akito996.gestionale_finanziaria

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity: serve alla finestra di verifica di Android
// (impronta, viso o PIN) dello sblocco rapido.
class MainActivity : FlutterFragmentActivity() {
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
