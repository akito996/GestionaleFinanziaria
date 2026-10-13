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

## Conseguenze
- ✅ Il peso è misurato a ogni build: un aumento inatteso si vede subito.
- ✅ Download e spazio occupato più bassi senza togliere funzioni.
- ⚠️ L'elenco delle chiamate negli errori delle build di release è in forma compatta: per leggerlo servono i simboli della stessa build.
- 🔜 MSI di release (con compressione) nella pipeline di rilascio.
