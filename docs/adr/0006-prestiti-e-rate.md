# ADR-006 – Prestiti e rate, lettura del contratto sul dispositivo

- **Stato**: accettata
- **Data**: 2026-10-10
- **Codice**: `lib/core/prestiti/`, `lib/core/db/prestiti.dart`, `lib/features/prestiti/`

## Contesto
L'utente vuole inserire mutui, prestiti e acquisti a rate, anche facendo leggere all'app il contratto, e vedere le rate registrate da sole nel giorno previsto, nella categoria "Finanziamenti" o "Pagamento a rate".

## Decisione
- **Prestito** (`prestiti`): tipo (mutuo, prestito, a rate, tra privati), finanziatore, capitale, numero rate, rata, TAN/TAEG facoltativi, prima rata, frequenza, conto, categoria.
- **Rate**: pagamento programmato a importo fisso (ADR-005), `occorrenze` = numero rate. Registrazione automatica nel giorno previsto; senza conto è solo promemoria (le rate scadute si considerano pagate).
- **Piano di ammortamento alla francese** (rata costante): quota capitale, interessi e debito residuo per ogni rata; se manca il TAN lo si ricava dalla rata per bisezione. L'ultima rata chiude esattamente il debito.
- **Categoria "Finanziamenti"** con *Mutuo*, *Prestiti*, *Pagamenti a rate*, proposta in automatico in base al tipo (migrazione v5 per gli archivi esistenti).
- **Lettura del contratto, solo sul dispositivo**: testo estratto dal PDF con **PDFium** (`pdfrx_engine`, MIT, versione fissata) o incollato; un lettore a regole riconosce i moduli standard **SECCI** (credito ai consumatori) e **PIES** (mutui): capitale, numero e importo rate, TAN, TAEG, totale dovuto, prima rata, finanziatore. Il risultato è una **proposta** che l'utente controlla prima di salvare; nessun dato inventato.
- **Sicurezza**: al blocco dell'archivio si chiudono tutte le pagine aperte (dettagli, moduli), così nessun dato resta visibile sopra la schermata di sblocco.

## Conseguenze
- ✅ Nessun contratto lascia il dispositivo; funziona offline.
- ⚠️ Le scansioni (PDF immagine) non hanno testo: si compila a mano (OCR on-device previsto in Fase 3).
- ⚠️ `pdfium_dart` scarica il binario PDFium in fase di build senza verifica d'impronta: versione fissata; da rivalutare (verifica SHA-256 in CI).
- 🔜 Mutui a tasso variabile (rate diverse nel tempo), estinzione parziale, OCR.
