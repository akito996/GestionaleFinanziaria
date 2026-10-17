# ADR-012 – Peso dei file di installazione

- **Stato**: accettata
- **Data**: 2026-10-13
- **Codice**: `.github/workflows/verifica.yml`, `tool/dimensioni.py`, `lib/features/comuni/errori.dart`

## Contesto
L'utente chiede installazioni più leggere, purché senza bug e senza perdere qualità (scelta: opzione "Prestazione" con questa condizione).

Peso di partenza, misurato in CI (commit `4e8b3ba`):
- Windows: 18,9 MB da scaricare, 44,7 MB installata;
- APK Android (arm64): 33,4 MB. Le librerie native non sono compresse nell'APK, così Android non le copia una seconda volta e sul dispositivo occupano meno spazio.

Componenti principali (Windows):
- motore Flutter: 20,3 MB;
- PDFium: 6,8 MB;
- SQLCipher: 4,5 MB;
- libsodium: 0,5 MB;
- codice dell'app compilato.

## Decisione
- **Misura in ogni build** (`tool/dimensioni.py`): il peso da scaricare e quello installato, con i file e le librerie più pesanti, finiscono nel riepilogo dell'esecuzione e in un avviso.
- **Simboli di debug separati** (`--split-debug-info`): l'app è più leggera.
  - I simboli finiscono negli artifact `simboli-windows-*` e `simboli-android-*` (conservati 90 giorni), per decodificare gli errori con `flutter symbolize`.
  - Nei "Dettagli tecnici" degli errori ci sono la versione e il commit, per scegliere i simboli giusti.
  - Niente `--obfuscate`: il codice è comunque open source e l'offuscamento può rompere il codice che usa i nomi dei tipi.
- **APK per tipo di processore** (`--split-per-abi`): `arm64-v8a` (quasi tutti i telefoni e tablet) e `armeabi-v7a` (dispositivi a 32 bit). Un APK universale peserebbe circa il triplo.
- **Librerie Visual C++ accanto all'app Windows** (msvcp140, vcruntime140): l'app parte anche sui PC appena installati.
  - Circa +1 MB.
  - La licenza dei file "redist" di Visual Studio consente di distribuirli insieme all'app.
- **Scartato**:
  - **PDFium scaricato al primo uso.** La lettura dei PDF richiederebbe internet, mentre oggi l'app funziona tutta offline. Su Android, dalla versione 10, il caricamento di codice scaricato è limitato e rischia di non funzionare su alcuni dispositivi. Gli antivirus possono segnalare le librerie scaricate a parte. Non rispetta la condizione "senza bug e senza perdere qualità".
  - **Una sola libreria per i file** (`file_picker` al posto di `file_selector` anche su Windows): risparmio di circa 0,2 MB, contro il rischio di cambiare le finestre di salvataggio.

## Risultato (CI, commit `5a40a0c`)
| | Prima | Dopo |
|---|---|---|
| Windows, da scaricare | 18,9 MB | 18,6 MB (con le librerie Visual C++, ~1 MB) |
| Windows, installata | 44,7 MB | 43,9 MB (con le librerie Visual C++) |
| APK arm64-v8a | 33,4 MB | 31,8 MB |
| APK armeabi-v7a | – | 26,9 MB |

Simboli a parte: Windows 1,5 MB, Android 2,9 MB.

## Conseguenze
- ✅ Il peso è misurato a ogni build: un aumento inatteso si vede subito.
- ✅ Download e spazio occupato più bassi senza togliere funzioni.
- ⚠️ L'elenco delle chiamate negli errori delle build di release è in forma compatta: per leggerlo servono i simboli della stessa build.
- 🔜 MSI di release (con compressione) nella pipeline di rilascio.

## Aggiornamento del 17/10/2026: velocità, fluidità, batteria e peso
Richiesta dell'utente: ottimizzare velocità, fluidità, uso della batteria e peso dell'app.

**Già a posto** (verificato): l'archivio lavora in un isolate a parte (`NativeDatabase.createInBackground`); Argon2id e le operazioni sulle chiavi girano fuori dal thread grafico (`Isolate.run`, `runIsolated`); le build di release Android usano R8.

**Fatto (senza controindicazioni):**
- **Batteria**: con l'app in secondo piano i controlli periodici si fermano: scadenze ogni 15 minuti, sincronizzazione ogni 5, portafogli condivisi ogni minuto. Al ritorno ripartono, con un giro subito. Prima continuavano finché Android non congelava l'app.
- **Fluidità**:
  - nel dettaglio del portafoglio le righe dei movimenti (fino a 500) si costruiscono solo quando entrano in vista (`SliverList.builder`);
  - le ricerche sono preparate una volta sola: un cambio di saldo non rifà tutte le ricerche da capo;
  - nella sezione Movimenti si mostrano 100 movimenti alla volta invece di 300, con "Mostra altri".

**Peso, misurato il 17/10/2026:** Windows 19,2 MB da scaricare e 45,4 MB installata; APK arm64 48,3 MB, armeabi-v7a 41,4 MB. Dal 13/10 l'APK è cresciuto di circa 15 MB, soprattutto per la lettura delle foto (ADR-014): la libreria Tesseract e il modello italiano `tessdata_best`, che pesa da solo **8,9 MB** (`tessdata_fast`: 2,7 MB).

Le tre scelte per il peso; **l'utente ha scelto Prestazione** (17/10/2026, vedi ADR-014):

| Scelta | Cosa cambia | APK arm64 (stima) |
|---|---|---|
| **Qualità/Prezzo** (consigliata) | Il modello preciso si scarica solo al primo uso della lettura foto, verificato con SHA-256. Serve Internet una volta sola | circa 40 MB |
| **Prestazione** | Modello veloce incorporato: funziona subito, anche senza Internet. Quello preciso si scarica la prima volta e da lì si usa quello | circa 42 MB |
| **Economica** | Solo il modello veloce incorporato: sempre senza Internet, ma un po' meno preciso sugli scontrini difficili | circa 42 MB |
