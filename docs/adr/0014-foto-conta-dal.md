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
