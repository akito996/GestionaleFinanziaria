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
- **Due varianti** (scelta dell'utente: opzione "Prestazione"), installabili insieme:
  - **ufficiale** (`io.github.akito996.gestionale_finanziaria`, "GestionaleFinanziaria"): quella con i dati veri;
  - **prova** (suffisso `.prova`, "GF Prova"): per provare le novità senza toccare i dati veri; la firma della versione mostra "· prova".
- **Firma definitiva**:
  - keystore generato dall'utente sul proprio PC (le password non passano da Claude);
  - caricato come secret di GitHub Actions (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`);
  - la CI crea `android/key.properties` e il keystore solo durante la build e li cancella alla fine. Senza secret (es. pull request da fork) firma con la chiave di debug e lascia un avviso.
  - Il certificato è leggibile da chiunque abbia l'APK: nel nome si mette solo "CN=GestionaleFinanziaria", nessun dato personale.
  - Se il keystore si perde non si possono più pubblicare aggiornamenti dell'app installata: va conservato in due posti sicuri, fuori dal repository.
- **"Salva con nome" su Android**: `file_selector` su Android non sa salvare. `salvaConNome` usa `file_picker` (licenza MIT), che apre la finestra di sistema "Salva in…" (Storage Access Framework: Download, Drive…), senza permessi di archiviazione. Su Windows resta `file_selector`.
- **PDF dei contratti**: su Android il file scelto non ha sempre un percorso, quindi si leggono i byte (`testoDaPdfDati`). PDFium per Android arriva dal native asset di `pdfium_dart`.
- **FLAG_SECURE** già attivo (`MainActivity`): niente screenshot né anteprima nelle app recenti.

## Conseguenze
- ✅ Ogni push produce un APK da provare e verifica l'app vera su Android.
- FLAG_SECURE resta attivo anche nella variante di prova (scelta dell'utente: per le segnalazioni usa la foto da un altro telefono).
- 🔜 Firma definitiva; sblocco biometrico (`local_auth`); dispositivi fidati; notifiche di sistema (avvisi delle scadenze e della maxi rata).
