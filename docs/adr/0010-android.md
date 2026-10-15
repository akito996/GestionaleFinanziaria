# ADR-010 – Versione Android: build, test e prime scelte

- **Stato**: accettata (firma definitiva in sospeso)
- **Data**: 2026-10-12
- **Codice**: `.github/workflows/verifica.yml` (job `android`), `android/`, `lib/features/comuni/salva_file.dart`, `lib/core/prestiti/estrazione_pdf.dart`

## Contesto
Si comincia a provare l'app su Android. Sul PC la build Android non è possibile: il build hook di libsodium richiede `make`, che manca, e non c'è la Modalità sviluppatore. Come per Windows, la build si fa in GitHub Actions.

## Decisione
- **Build e test in CI** (job "Android (APK e test nell'emulatore)", su Ubuntu):
  - APK release per telefoni e tablet a 64 bit (`android-arm64`), scaricabili dagli artifact dell'esecuzione;
  - test sull'app vera (`integration_test`) in emulatori Android 14 (API 34, x86_64, KVM), telefono e tablet, con `reactivecircus/android-emulator-runner` fissato per SHA (v2.38.0).
- **Due varianti** (scelta dell'utente: opzione "Prestazione"), installabili insieme:
  - **ufficiale** (`io.github.akito996.gestionale_finanziaria`, "GestionaleFinanziaria"): quella con i dati veri;
  - **prova** (suffisso `.prova`, "GF Prova"): per provare le novità senza toccare i dati veri; la firma della versione mostra "· prova".
- **Firma definitiva**:
  - keystore generato dall'utente sul proprio PC (le password non passano da Claude);
  - caricato come secret di GitHub Actions (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`);
  - la CI crea `android/key.properties` e il keystore solo durante la build e li cancella alla fine. Senza secret (es. pull request da fork) firma con la chiave di debug e lascia un avviso.
  - Il certificato è leggibile da chiunque abbia l'APK: nel nome si mette solo "CN=GestionaleFinanziaria", nessun dato personale.
  - Se il keystore si perde non si possono più pubblicare aggiornamenti dell'app installata: va conservato in due posti sicuri, fuori dal repository.
- **Telefono e tablet** (richiesta dell'utente: ottimizzare per entrambi). Punti di passaggio di Material 3, uguali su Windows (`lib/features/comuni/layout.dart`):
  - sotto 600 dp (telefono in verticale): barra in basso, 4 sezioni + "Altro";
  - da 600 dp (tablet in verticale, telefono in orizzontale): barra laterale, scorrevole quando l'altezza non basta;
  - da 840 dp (tablet in orizzontale, PC): Panoramica a due colonne; carte, prestiti e obiettivi in due colonne di schede;
  - pagine a una colonna larghe al massimo 960 dp, centrate (`marginiPagina`), e due colonne al massimo 1440 dp;
  - finestre alte (maxi rata, calendario) scorrevoli sugli schermi bassi.
- **Test dei layout**: `test/features/schermi_test.dart` percorre tutte le sezioni e le finestre principali su 5 schermi (telefono piccolo, telefono in orizzontale, tablet piccolo, tablet in verticale e in orizzontale): ogni sforamento fa fallire il test. In CI il test sull'app vera gira in due emulatori in parallelo: telefono (Pixel 6) e tablet (Pixel Tablet).
- **"Salva con nome" su Android**: `file_selector` su Android non sa salvare. `salvaConNome` usa `file_picker` (licenza MIT), che apre la finestra di sistema "Salva in…" (Storage Access Framework: Download, Drive…), senza permessi di archiviazione. Su Windows resta `file_selector`.
- **PDF dei contratti**: su Android il file scelto non ha sempre un percorso, quindi si leggono i byte (`testoDaPdfDati`). PDFium per Android arriva dal native asset di `pdfium_dart`.
- **FLAG_SECURE** già attivo (`MainActivity`): niente screenshot né anteprima nelle app recenti.

## Conseguenze
- ✅ Ogni push produce un APK da provare e verifica l'app vera su Android.
- FLAG_SECURE resta attivo anche nella variante di prova (scelta dell'utente: per le segnalazioni usa la foto da un altro telefono).
- ✅ Firma definitiva; sblocco con impronta, viso o PIN (ADR-016, Android Keystore, non `local_auth`).
- 🔜 Dispositivi fidati; notifiche di sistema (avvisi delle scadenze e della maxi rata).
