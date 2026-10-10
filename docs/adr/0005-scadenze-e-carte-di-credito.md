# ADR-005 – Pagamenti programmati e carte di credito

- **Stato**: accettata
- **Data**: 2026-10-10
- **Codice**: `lib/core/ricorrenza.dart`, `lib/core/db/pianificatore.dart`, `lib/core/db/carte_credito.dart`

## Contesto
Bollette, rate e addebiti delle carte avvengono in date precise. L'utente vuole che l'app registri da sola il movimento nel giorno previsto e lo avvisi 3 giorni prima; per le carte di credito vuole vedere nel conto collegato quando e quanto verrà addebitato.

## Decisione
- **Ricorrenza** (puro Dart, testato): settimanale, mensile, bimestrale, trimestrale, semestrale, annuale; giorni mancanti (31, 29 febbraio) → ultimo giorno del mese; fine per data inclusa o dopo N volte.
- **Pagamenti programmati** (`pianificazioni`): tabella unica per tutte le origini (`costo_vita`, `carta`, `prestito`), con portafoglio di uscita, eventuale destinazione (trasferimento), tipo, categoria, descrizione, importo fisso o calcolato dall'origine.
- **Registrazione automatica**: all'apertura dell'app e ogni 15 minuti si creano i movimenti delle scadenze arrivate (recuperando i giorni in cui l'app era chiusa). Il movimento porta `pianificazione_id` + `data_prevista` con indice **unico**: mai due volte; un movimento generato e poi cancellato dall'utente non viene ricreato.
- **Senza portafoglio** il pagamento è solo un promemoria.
- **Avvisi**: scheda "In arrivo" (7 giorni nella Panoramica, 30 nel portafoglio), evidenziata nei 3 giorni prima. Su Windows l'avviso è nell'app; le notifiche di sistema arriveranno con la build Android.
- **Carte di credito**: la carta è un portafoglio di tipo "Carta di credito" (saldo negativo = debito). Ogni mese, nel giorno di addebito, un pagamento programmato trasferisce dal conto collegato alla carta il debito maturato fino alla **chiusura** (fine del mese precedente o giorno scelto). Avviso sempre visibile nel conto collegato e nella carta; plafond facoltativo.

## Conseguenze
- ✅ Un solo motore per costo della vita, carte e (prossimamente) prestiti.
- ✅ Gli importi degli addebiti seguono le modifiche (variazioni del mese, nuovi predefiniti, spese della carta).
- ⚠️ Per ora un'unica valuta per carta (quella del conto collegato).
- 🔜 Notifiche di sistema su Android; scelta dei giorni di avviso per singola scadenza.
