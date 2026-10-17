# ADR-014 – Lettura delle foto, "Conta dal", avvisi da 5 secondi

- **Stato**: accettata
- **Data**: 2026-10-14
- **Codice**:
  - `android/app/src/main/kotlin/.../LetturaFoto.kt`, `android/app/build.gradle.kts`;
  - `lib/core/foto/`, `lib/features/foto/foto.dart`;
  - `lib/core/db/pianificatore.dart` (`registraDal`), `lib/features/comuni/conta_dal.dart`, `lib/features/comuni/avvisi.dart`.
- **Schema DB**: v13

## Contesto
Richieste dell'utente del 14/10/2026:
- avvisi in basso che spariscono dopo 5 secondi;
- prestiti ed entrate già in corso quando li inserisci: contarli solo da quel momento (prima l'app registrava tutte le rate passate e abbassava il saldo);
- su Android, nuovo movimento dalla foto dello scontrino (data, negozio, importo) e nuovo prestito dalla foto del contratto, con lo "zoom" sui dati per leggerli meglio.

Scelte dell'utente:
- motore di lettura: **Tesseract open source** (opzione Economica), invece di ML Kit (Google, non open source) o ML Kit + Gemini Nano;
- prestiti e voci già inseriti: **"Conta dal" nel modulo** (opzione Qualità/Prezzo).

## Decisione
- **Avvisi in basso**: tutti passano da `avviso()`, che crea lo `SnackBar` con 5 secondi e `persist: false`. Con un'azione ("Annulla") Flutter altrimenti lo lascerebbe aperto. Resta la "x" (ADR-013).
- **"Conta dal"** (`pianificazioni.registra_dal`):
  - un pagamento programmato nuovo conta da oggi;
  - le scadenze prima non si registrano, non si notificano e non contano nel costo della vita (rate dei prestiti);
  - per il prestito le rate prima sono già pagate (contano per il debito residuo);
  - nei moduli il campo compare solo se la prima data è già passata.
  - Sui prestiti e sulle voci inseriti prima, impostarlo elimina i movimenti registrati prima di quella data (cancellazione morbida), con "Annulla" (`Pianificatore.contaDal` / `ripristinaMovimenti`). Nella migrazione v13 gli archivi esistenti restano com'erano (`null` = contano tutte).
- **Lettura delle foto** (solo Android, tutto sul telefono):
  - **Motore**: Tesseract 5.5.1 tramite Tesseract4Android 4.9.0 (Apache-2.0), con canale `gestionale/lettura_foto` (`LetturaFoto.kt`).
  - **Integrità**:
    - la libreria arriva da JitPack, che il repository usa solo per quel gruppo (`exclusiveContent`); l'AAR è verificato con SHA-256 a ogni build;
    - il modello `ita.traineddata` (tessdata_best 4.1.0, 8,9 MB, scelto per la precisione) viene scaricato in build con SHA-256 verificato e messo negli asset Android: nel repository non ci sono binari;
    - le regole ProGuard servono perché la libreria non ne porta.
  - **Due passaggi**: prima tutta la foto (righe con posizione), poi lo "zoom" sulle zone dei dati, ritagliate, ingrandite finché il testo è alto circa 48 pixel e rilette come una sola riga.
    - Scontrino: data, nome del negozio (in alto), riga "TOTALE COMPLESSIVO"/"TOTALE"; senza totale, l'importo più alto escluse righe come contante e resto.
    - Contratto: le righe con TAN, TAEG, importi, rate, durata e spese, poi il `LettoreContratto` esistente.
  - **Controllo dell'utente**: prima di usare i dati compaiono le zone ingrandite con i valori modificabili. La foto viene cancellata dopo la lettura.
  - **Tracciabilità**: test con un lettore finto (interpretazione e schermate) e test sull'app vera nell'emulatore Android, dove l'app disegna uno scontrino e lo rilegge con Tesseract; il risultato compare tra gli avvisi della CI.
- **CI**: in più un artifact `android-da-installare-*` con il solo `GestionaleFinanziaria-prova.apk` (telefoni e tablet a 64 bit).

## Conseguenze
- ✅ Saldo giusto per prestiti ed entrate già in corso.
- ✅ Lettura delle foto open source, offline e privata.
- ⚠️ L'APK cresce: circa +7,5 MB di libreria a 64 bit e +8,9 MB di modello.
- ⚠️ Tesseract è meno preciso di ML Kit su scontrini stropicciati o storti: per questo si confermano sempre i dati.
- 🔜 Allegare la foto al movimento (se richiesto) e la lettura su Windows.

## Aggiornamento del 17/10/2026: modelli e scontrini lunghi
Prova vera dell'utente: su uno scontrino con tante voci la lettura faticava a trovare il totale e non trovava la data.
- **Modelli** (ADR-012, scelta **Prestazione**):
  - nell'APK c'è il modello **veloce** (`tessdata_fast` 4.1.0, 2,7 MB, SHA-256 verificato in build), che funziona subito anche senza Internet;
  - il modello **preciso** (`tessdata_best` 4.1.0, 8,9 MB) si scarica la prima volta che si sceglie una foto, mentre la si scatta (`ModelloPreciso`). Si installa solo se l'impronta SHA-256 è quella attesa e da lì si usa sempre;
  - la prima lettura aspetta fino a 8 secondi uno scaricamento già partito. Se si legge con il modello veloce, la finestra di conferma lo dice;
  - chi aveva già il modello preciso dalle versioni precedenti lo riusa senza scaricarlo.
- **Zoom a piena risoluzione**: la zona si ritaglia dal file originale (`BitmapRegionDecoder`, con la rotazione EXIF), non dalla foto ridotta a 2400 pixel. Si porta a circa 64 pixel di altezza, anche rimpicciolendo. Se il formato non lo permette, si usa la foto ridotta.
- **Totale**:
  - l'importo si cerca anche sulla **stessa riga visiva** (i prezzi letti come colonna a parte) e sulla riga subito sotto;
  - la parola si riconosce anche letta male ("T0TALE", "TOTAIE", "IOTALE");
  - a pari punteggio vince la riga più in basso;
  - restano esclusi subtotale, IVA, contante, resto, punti, buoni;
  - se la parola non si legge, si ingrandiscono le righe con gli importi più alti nella parte bassa e vince quella in cui lo zoom legge "TOTALE".
- **Data**:
  - si correggono le cifre lette come lettere (`comeNumeri`: "2O26", "l4", "23,4O"), ma non quando il gruppo è attaccato ad altre lettere ("14-ott-26");
  - formati in più: mese in lettere ("14 OTT 2026") e anno-mese-giorno;
  - se non si trova, si ingrandiscono le righe con l'ora, con "DATA", "ORE" o "DOCUMENTO N.", o con tre numeri separati, partendo dal basso.
- In attesa compare "Cerco la data…" o "Cerco il totale…". Il consiglio nella scelta della foto dice: per gli scontrini lunghi basta inquadrare bene totale e data.
- Nuovo test nell'emulatore: scontrino lungo (30 voci) con i prezzi allineati a destra, letto da Tesseract vero.
