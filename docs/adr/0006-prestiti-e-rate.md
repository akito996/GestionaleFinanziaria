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

## Aggiornamento dell'11/10/2026 – maxi rata finale
- Colonna `prestiti.maxi_rata_minimo` (schema v8). La maxi rata è l'**ultima** delle N rate: le prime N−1 sono costanti, l'ultima chiude il debito.
- **Ammortamento**: rata = (capitale − maxi rata attualizzata) × i ÷ (1 − (1+i)^−(N−1)). Anche il TAN si ricava con la maxi rata quando il contratto non lo riporta.
- **Rate automatiche**: la pianificazione del prestito non ha più un importo fisso; il calcolo del prestito restituisce la maxi rata nel giorno dell'ultima scadenza.
- **Lettura del contratto**:
  - riconosce "maxi rata (finale)", "rata finale", "valore futuro garantito"/VFG e "rata residua";
  - "35 rate + maxi rata" diventa 36 rate;
  - scarta le date (es. "rata finale: 05/12/2030") e gli importi che appartengono a un'altra voce.

## Aggiornamento dell'11/10/2026 – documenti di trasparenza e piano di ammortamento
Prova con un documento reale dell'utente (documento di trasparenza di una finanziaria auto; non è nel repository, il test usa dati inventati con la stessa struttura).
- **Sigle puntate**: "T.A.N." e "T.A.E.G" (anche con il punto decimale, "5.41 %").
- **Piano di ammortamento**: righe "N data importo importo importo importo". La rata è l'importo che è somma di altri due (quota capitale + quota interessi), così l'ordine delle colonne può cambiare tra le finanziarie. Dal piano: numero di rate (ultima riga), prima rata (data della riga 1), rata (la più frequente), maxi rata (ultima rata più alta di una volta e mezza), capitale (quota capitale + residuo della riga 1, se manca l'etichetta).
- **Falsi positivi corretti**:
  - "12 mesi" nel testo sulla privacy non è più la durata (vale solo "durata … N mesi");
  - "Rata Data" (intestazione di tabella) non è più "rata da";
  - un numero senza centesimi né valuta non è un importo.
- **Finanziatore senza etichetta**: si usa una riga che contiene solo il nome della società (es. "… S.p.A.").
- **Spese di incasso per rata** ("Spese di gestione e/o incasso", colonna `prestiti.spese_rata_minimo`, schema v9). Scelta dell'utente: opzione "Qualità/Prezzo".
  - Il movimento registrato è rata + spese, come sull'estratto conto; il piano di ammortamento resta sulla sola rata.
  - "Ancora da pagare" comprende le spese delle rate future.
  - Le spese una tantum (es. imposta di bollo sulla prima rata) si correggono a mano sul singolo movimento.

## Aggiornamento del 12/10/2026 – totale rata, costo della vita, decisione sulla maxi rata
- **Totale della rata** nel modulo: rata + spese (e l'ultima: maxi rata + spese), aggiornato mentre si scrive.
- **Costo della vita**: le rate dei prestiti attivi (non archiviati) contano tra le spese fisse del mese in cui cadono, fino all'ultima rata (importo = rata o maxi rata + spese). La pagina mostra la sezione "Prestiti e rate"; i riepiloghi indicano "di cui rate".
- **Decisione sulla maxi rata** (colonne `decisione_maxi`, `maxi_rimandata_il`, schema v10):
  - da 6 mesi prima della scadenza l'app chiede: "Apro un altro prestito" (rifinanzio), "Pago tutto in un'unica soluzione", oppure "Ricordamelo più tardi";
  - la domanda compare all'apertura dell'app (e ogni 15 minuti se resta aperta) quando è il momento;
  - cadenza dopo un rimando: ogni 15 giorni (2 volte al mese); negli ultimi 2 mesi ogni settimana; nell'ultimo mese ogni 3 giorni (un intervallo non scavalca mai l'inizio della fascia successiva);
  - finché non si decide, una campanella con il numero di decisioni resta accanto al lucchetto in ogni sezione;
  - "Rifinanzio": la maxi rata non esce dal conto (non si registra e non conta nel costo della vita), alla scadenza risulta pagata; si apre il modulo di un nuovo prestito già impostato (capitale = maxi rata, prima rata il mese dopo);
  - "Pago tutto": nessun altro avviso, la maxi rata esce dal conto alla scadenza;
  - la scelta si può cambiare dal dettaglio del prestito ("Cambia").
- 🔜 Con la build Android: notifica di sistema oltre all'avviso nell'app.

## Conseguenze
- ✅ Nessun contratto lascia il dispositivo; funziona offline.
- ⚠️ Le scansioni (PDF immagine) non hanno testo: si compila a mano (OCR on-device previsto in Fase 3).
- ⚠️ `pdfium_dart` scarica il binario PDFium in fase di build senza verifica d'impronta: versione fissata; da rivalutare (verifica SHA-256 in CI).
- 🔜 Mutui a tasso variabile (rate diverse nel tempo), estinzione parziale, OCR.
