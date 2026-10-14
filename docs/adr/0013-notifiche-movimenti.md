# ADR-013 – Notifiche, scadenze da confermare, sezione Movimenti

- **Stato**: accettata
- **Data**: 2026-10-14
- **Codice**: `lib/core/db/notifiche.dart`, `lib/core/db/pianificatore.dart`, `lib/features/notifiche/`, `lib/features/movimenti/movimenti_pagina.dart`, `lib/features/portafogli/avviso_obiettivi.dart`
- **Schema DB**: v12

## Contesto
Richieste dell'utente del 14/10/2026:
- avvisi in basso chiudibili con la "x";
- notifiche delle entrate e delle uscite programmate con i pulsanti Conferma, Riprogramma e Annulla;
- casella delle notifiche come icona "push" (nascondibile);
- sezione con tutte le notifiche: selezione multipla, "segna come letta", conferma in massa, filtri e scorciatoie "Da leggere" e "Da confermare";
- sezione con tutti i movimenti e i filtri, raggiungibile dalla Panoramica;
- obiettivi legati al portafoglio, con l'avviso di quanta parte dei soldi è per l'obiettivo.

Per il comportamento senza scelta l'utente ha preso l'opzione **Prestazione**: si sceglie per ogni voce. Le voci automatiche lasciano un avviso, che sparisce quando è letto.

## Decisione
- **`pianificazioni.richiede_conferma`**: se attivo, nel giorno previsto la scadenza non si registra da sola.
  - Predefinito: entrate con conferma, spese da sole.
  - Con la migrazione v12 le entrate previste già esistenti chiedono conferma.
  - Prestiti e carte restano automatici.
- **Tabella `occorrenze`**: la scelta su una singola scadenza (spostata, annullata, fatta).
  - L'id è `<pianificazione>:<giorno previsto>`, così due dispositivi aggiornano la stessa riga.
  - Il movimento tiene il giorno della regola (`data_prevista`, unico) e il giorno vero (`data`).
  - Una scadenza spostata conta nel mese della regola (l'importo si calcola sul giorno previsto).
- **Tabella `notifiche_lette`**: lo stato "letta" di ogni notifica, con id = chiave della notifica.
- **Tipi di notifica** (`NotificheServizio`), ricalcolati dalle scadenze degli ultimi 30 giorni:

  | Tipo | Quando compare | Quando sparisce |
  |---|---|---|
  | Da confermare | Dal giorno previsto | Finché non si decide |
  | Da decidere (maxi rata) | Come prima | Finché non si decide |
  | In arrivo | Uscite: 3 giorni prima. Entrate: il giorno stesso | Quando è letta |
  | Registrata da sola | Per 7 giorni | Quando è letta |
  | Promemoria (senza portafoglio) | Come "In arrivo" | Quando è "Fatto" o letto |

- **Annullare una conferma**: il movimento si elimina (cancellazione morbida) e si stacca dalla scadenza, che torna in attesa. Ogni azione restituisce un `Ripristino` per il pulsante "Annulla" dell'avviso.
- **Campanella** (`CampanellaNotifiche`) accanto al lucchetto in ogni sezione.
  - Il numero conta le notifiche da decidere e quelle non lette.
  - Il pannello si apre da destra sugli schermi larghi, come il centro notifiche di Windows, e dal basso sul telefono. Ha i propri avvisi, così "Annulla" resta visibile.
  - Sostituisce la campanella della maxi rata e la scheda "In arrivo" della Panoramica. Il codice `in_arrivo` salvato nelle preferenze viene ignorato.
- **Sezione Notifiche**: scorciatoie Tutte / Da leggere / Da confermare, Entrate e Uscite, ricerca e selezione multipla ("Segna come lette", "Conferma (n)").
- **Sezione Movimenti** (seconda voce di navigazione; sul telefono "Carte" passa in "Altro").
  - Filtri per periodo, tipo, categoria (con le sottocategorie) e portafoglio.
  - Ricerca nella descrizione, nella categoria, nei portafogli e nell'importo. "%" e "_" scritti dall'utente valgono come lettere.
  - Totali calcolati in SQL su tutti i risultati. Si caricano 300 movimenti alla volta ("Mostra altri").
- **Obiettivi**: `ObiettivoConStato.riservato` vale tutto il versato finché l'obiettivo non è raggiunto, poi l'importo dell'obiettivo. Il portafoglio mostra la parte riservata, i soldi liberi e un avviso se il saldo è più basso del riservato.
- **Avvisi in basso**: `SnackBarThemeData(showCloseIcon: true)` per tutta l'app.

## Conseguenze
- ✅ Saldo affidabile anche con entrate in ritardo; nessuna scadenza confermata due volte (indice unico).
- ✅ Scelte e letture pronte per la sincronizzazione (id deterministici, cancellazioni morbide).
- ⚠️ Le scadenze "da confermare" più vecchie di 30 giorni non vengono più proposte.
- 🔜 Notifiche di sistema su Android (con la build Android: canali, permesso POST_NOTIFICATIONS).
