# ADR-016 – Sblocco rapido (impronta, viso, PIN, Windows Hello) e blocco automatico

- **Stato**: accettata (attua il punto "sblocco biometrico" dell'ADR-002)
- **Data**: 2026-10-15
- **Codice**:
  - `lib/core/sicurezza/`: `cassaforte.dart`, `sicurezza_dispositivo.dart`;
  - Android: `android/app/src/main/kotlin/.../SbloccoRapido.kt` (`MainActivity` è una `FlutterFragmentActivity`);
  - Windows: `windows/runner/sblocco_rapido.{h,cpp}` e canale in `flutter_window.cpp`;
  - `lib/features/sblocco/` (pagina di sblocco, proposta), `lib/features/impostazioni/`, `lib/features/comuni/blocco_automatico.dart`;
  - `Sessione.sbloccaRapido`, `Sessione.attivaSbloccoRapido`.

## Contesto
L'utente vuole aprire l'archivio con impronta, viso o PIN invece della password. Tra le tre scelte ha preso **Prestazione**:
- chiave legata alla verifica del dispositivo (non un semplice "sì/no" dell'impronta);
- anche Windows Hello sul PC;
- blocco automatico regolabile quando l'app resta in secondo piano.

Le alternative scartate:
- **Qualità/Prezzo**: come questa, ma solo su Android e senza blocco automatico.
- **Economica**: plugin `local_auth`. La verifica è un controllo che su un telefono con root si può aggirare, e la chiave non è legata alla verifica.

## Decisione
- **La password resta la chiave principale.** La Secret Key resta per il recupero. Lo sblocco rapido è una comodità di questo dispositivo, che si può spegnere o perdere senza perdere dati.
- **Come funziona**:
  - all'attivazione la "cassaforte" del dispositivo rilascia un segreto, solo dopo la verifica dell'utente;
  - dal segreto si ricava una chiave (BLAKE2b, poi KDF di libsodium con contesto `GFrapid1`);
  - questa chiave avvolge la chiave dei dati (DEK) con XChaCha20-Poly1305. L'AAD è `gf-sblocco-rapido|v1|<id archivio>`;
  - il risultato sta in `sicurezza.json` accanto al keyring: mai sincronizzato, nessun segreto in chiaro.
- **Android** (`SbloccoRapido.kt`):
  - chiave AES-256-GCM nell'Android Keystore, nel chip StrongBox se c'è, altrimenti nell'area sicura (TEE);
  - si usa solo subito dopo una verifica (`setUserAuthenticationRequired`, durata 0) con `BiometricPrompt` e `CryptoObject`;
  - da Android 11: impronta, viso di classe "forte" o PIN/segno del telefono. Prima di Android 11: solo impronta;
  - la chiave cifra un segreto casuale da 32 byte;
  - se si toglie il blocco schermo, Android annulla la chiave. Lo stesso succede su molti telefoni quando cambiano le impronte.
- **Windows** (`sblocco_rapido.cpp`, C++/WinRT):
  - `KeyCredentialManager` crea una chiave RSA di Windows Hello (nel TPM se c'è) e firma una "sfida" casuale salvata nel file;
  - la firma (RSA PKCS#1 v1.5, sempre uguale per la stessa sfida) è il segreto. È lo stesso schema usato da KeePassXC;
  - le chiamate lavorano su un thread a parte e rispondono dal thread della finestra. La finestra di Windows Hello si porta in primo piano.
- **Ogni 14 giorni** si chiede comunque la password, perché non venga dimenticata. Il conto si azzera a ogni sblocco con la password o con la Secret Key.
- **Quando lo sblocco rapido si spegne**:
  - nuovo archivio, o archivio scaricato da Drive (la DEK è diversa);
  - chiave annullata dal sistema: lo si spiega all'utente nella pagina di sblocco.
- **Proposta**: dopo la prima password si chiede una volta "Sblocco più veloce?" (Attiva / Non ora). Poi resta in **Impostazioni › Sicurezza**.
- **Blocco automatico** (Impostazioni › Sicurezza):
  - scelte: Subito, 1 minuto, 5 minuti (predefinito), 15 minuti, 1 ora, Mai;
  - il tempo si conta da quando l'app va in secondo piano (finestra ridotta a icona su Windows);
  - al ritorno, la verifica dello sblocco rapido parte da sola. Dopo il lucchetto toccato a mano, no;
  - non scatta mentre l'app è in secondo piano per scelta dell'utente: fotocamera, scelta file, salvataggio, consenso di Google, PIN di sistema (`senzaBloccoAutomatico`).
- **Nuova sezione Impostazioni** (sul telefono in "Altro"): Sicurezza, Sincronizzazione, Informazioni.

## Conseguenze
- Nessuna libreria Flutter nuova. Su Android si aggiunge `androidx.biometric:biometric:1.1.0` (AndroidX, Apache-2.0); su Windows `windowsapp.lib` (Windows SDK).
- La verifica vera (dito, viso, PIN) non si può fare in un test automatico. Come la si copre:
  - i test usano una cassaforte finta;
  - in CI si controlla che i canali nativi rispondano (annotazione "Sblocco rapido");
  - la prova sul dispositivo la fa l'utente.
- Firma APK: attivato anche lo schema v3, che permette in futuro di cambiare chiave di firma (rotazione).
- 🔜 Dispositivi fidati (QR da un dispositivo già aperto).
