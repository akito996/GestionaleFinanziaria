# ADR-010 – Versione Android: build, test e prime scelte

- **Stato**: accettata (firma definitiva in sospeso)
- **Data**: 2026-10-12
- **Codice**: `.github/workflows/verifica.yml` (job `android`), `android/`, `lib/features/comuni/salva_file.dart`, `lib/core/prestiti/estrazione_pdf.dart`

## Contesto
Si comincia a provare l'app su Android. Sul PC la build Android non è possibile: il build hook di libsodium richiede `make`, che manca, e non c'è la Modalità sviluppatore. Come per Windows, la build si fa in GitHub Actions.

## Decisione
- **Build e test in CI** (job "Android (APK e test nell'emulatore)", su Ubuntu):
  - APK release per telefoni a 64 bit (`android-arm64`), scaricabile dagli artifact dell'esecuzione;
  - test sull'app vera (`integration_test`) in un emulatore Android 14 (API 34, x86_64, KVM), con `reactivecircus/android-emulator-runner` fissato per SHA (v2.38.0).
- **Firma**: per ora l'APK è firmato con la chiave di debug di Flutter, quindi **solo per prova**. Cambiando chiave bisogna disinstallare l'app e i dati sul telefono si perdono. La chiave definitiva (keystore come secret di GitHub) è una decisione dell'utente in sospeso.
- **"Salva con nome" su Android**: `file_selector` su Android non sa salvare. `salvaConNome` usa `file_picker` (licenza MIT), che apre la finestra di sistema "Salva in…" (Storage Access Framework: Download, Drive…), senza permessi di archiviazione. Su Windows resta `file_selector`.
- **PDF dei contratti**: su Android il file scelto non ha sempre un percorso, quindi si leggono i byte (`testoDaPdfDati`). PDFium per Android arriva dal native asset di `pdfium_dart`.
- **FLAG_SECURE** già attivo (`MainActivity`): niente screenshot né anteprima nelle app recenti.

## Conseguenze
- ✅ Ogni push produce un APK da provare e verifica l'app vera su Android.
- ⚠️ Con FLAG_SECURE l'utente non può fare screenshot dell'app da mandare come segnalazione: per le prove si può pensare a un interruttore solo nelle build di prova.
- 🔜 Firma definitiva; sblocco biometrico (`local_auth`); dispositivi fidati; notifiche di sistema (avvisi delle scadenze e della maxi rata).
