# ADR-008 – Grafici a scelta ed export PDF + Excel

- **Stato**: accettata
- **Data**: 2026-10-10
- **Codice**: `lib/features/grafici/`, `lib/core/db/statistiche.dart`, `lib/core/export/`, `lib/features/export/`

## Contesto
L'utente vuole scegliere il tipo di grafico (con il più semplice e chiaro come predefinito per ogni schermata) ed esportare i dati in modo dettagliato, anche con i grafici, scegliendo cosa esportare. Formato scelto: **PDF + Excel**.

## Decisione
- **Tipo di grafico a scelta** (`SchedaGrafico`): menu "Tipo di grafico"; il primo tipo è il consigliato per quei dati; la scelta è ricordata per schermata (impostazioni locali dell'archivio, cifrate).
  - Costo della vita → **barre impilate** (composizione nel tempo); alternative linee, tabella.
  - Spese del mese per categoria (Panoramica) → **barre orizzontali** ordinate; alternative ciambella (max 6 fette + "Altre"), tabella.
  - Andamento del saldo (portafoglio) → **linea**; alternativa tabella.
  - Palette categoriale validata (chiaro/scuro), un solo asse, legenda quando le serie sono più di una, tabella sempre disponibile.
- **Export** (Panoramica → "Esporta"): sezioni a scelta (portafogli, movimenti, spese per categoria, costo della vita, carte, prestiti, obiettivi), periodo (mese, 3 mesi, anno, date a scelta), formato (PDF, Excel o entrambi).
  - **PDF** con il pacchetto `pdf` (Apache 2.0): tabelle, barre delle categorie e grafico del costo della vita; carattere **Roboto** incorporato (Apache 2.0, preso dall'SDK Flutter) per euro e accenti.
  - **Excel (.xlsx)** generato in proprio (Office Open XML + zip con `archive`): un foglio per sezione, intestazione in grassetto e bloccata, importi come numeri in formato euro, piani completi delle rate. Il pacchetto `excel` è stato scartato perché incompatibile con `pdf` (versioni di `xml`); Syncfusion scartato perché non open source.
  - Avviso nella finestra: il file esportato **non è cifrato**.

## Conseguenze
- ✅ Report leggibile e dati completi per analisi esterne, senza servizi esterni.
- ⚠️ Nei file Excel non ci sono grafici nativi (sono nel PDF).
- 🔜 PDF protetto da password; altri grafici (entrate/uscite mensili, budget).
