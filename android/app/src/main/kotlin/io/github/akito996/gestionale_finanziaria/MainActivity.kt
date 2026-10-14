package io.github.akito996.gestionale_finanziaria

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Lettura delle foto (scontrini, contratti) sul telefono, con Tesseract.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "gestionale/lettura_foto",
        ).setMethodCallHandler(LetturaFoto(applicationContext))
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
