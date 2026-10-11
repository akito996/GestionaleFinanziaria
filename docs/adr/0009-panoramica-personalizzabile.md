# ADR-009 – Panoramica personalizzabile, entrate/uscite, dati osservati per ascoltatore

- **Stato**: accettata
- **Data**: 2026-10-11
- **Codice**: `lib/features/home/`, `lib/core/db/osservazione.dart`, `lib/core/db/statistiche.dart`, `lib/features/comuni/campi.dart`, `lib/features/portafogli/raggruppa_portafogli.dart`

## Contesto
Richieste dell'utente:
- scegliere quali schede vedere nella Panoramica e in che ordine (saldo e portafogli sempre presenti);
- confrontare entrate e uscite tra mesi e anni, con l'andamento;
- raggruppare i portafogli in modo evidente;
- campo importo grande e centrato;
- date scelte sempre da un calendario in una finestra.

Bug segnalato: dopo aver stretto e riallargato la finestra, la scheda "Costo della vita" restava in caricamento.

## Decisione
- **Dati osservati per ascoltatore** (`Stream.ricalcola`): sostituisce `asyncMap` in tutti i servizi.
  - Causa del bug: con `asyncMap` chi si iscrive mentre un altro è ancora iscritto non riceve nulla fino al cambiamento successivo. Quando il layout cambia, il widget ricreato si iscrive prima che il vecchio si disiscriva.
  - Con `ricalcola` ogni iscrizione riparte dalla query di drift, che ripete subito l'ultimo risultato.
  - Regola per il codice futuro: non usare `asyncMap` sugli stream esposti dai servizi.
  - Test di regressione: unitario (`osservazione_test.dart`) e di interfaccia (finestra stretta e poi larga).
- **Panoramica personalizzabile** (`SchedaPanoramica`, `ConfigurazionePanoramica`):
  - schede disponibili: In arrivo, Costo della vita, Entrate e uscite, Spese del mese, Flusso del mese, Patrimonio, Ultimi movimenti;
  - finestra "Personalizza la Panoramica": spunta per mostrare o nascondere, trascina per l'ordine, "Ripristina";
  - salvataggio come testo nelle impostazioni dell'archivio (`costo_vita,-flusso,...`): le schede sconosciute si ignorano, quelle nuove di versioni future finiscono in fondo, visibili.
- **Entrate e uscite**:
  - mesi (ultimi 12) o anni (fino a 5, dal primo movimento);
  - grafici: colonne affiancate (consigliato), linee per l'andamento con la serie "Risparmio", tabella;
  - i trasferimenti tra i propri portafogli non contano;
  - riepilogo del periodo in corso con un **confronto alla pari**: stesso tratto del periodo precedente (1–11 ottobre contro 1–11 settembre; anno in corso contro lo stesso periodo dell'anno prima), non il mese intero contro un mese parziale.
- **Portafogli: "Mostra altro" / "Mostra meno"** (chiarimento dell'utente: "raggruppare" voleva dire questo, non cartelle con un nome):
  - i preferiti ⭐ sono sempre visibili, in cima; gli altri si aprono con "Mostra altro (N portafogli)";
  - senza preferiti, da chiuso si vedono i primi 3; la scelta aperto/chiuso è ricordata;
  - il "Preferito" si può impostare anche quando si crea un portafoglio.
  - I gruppi con nome (prima versione) sono stati tolti dall'interfaccia; la colonna `portafogli.gruppo` resta nello schema solo per compatibilità.
- **Campi comuni**:
  - `CampoImporto`: grande, centrato, con il simbolo della valuta;
  - `CampoData` e `scegliData`: calendario in una finestra con "Oggi" e "Ieri";
  - usati in movimenti, costo della vita, obiettivi, prestiti ed export (date "Dal"/"Al").

## Conseguenze
- ✅ Nessuna scheda bloccata quando cambia il layout (anche su Android ruotando lo schermo).
- ✅ Dashboard adattabile senza perdere le informazioni essenziali.
- ⚠️ Con più schede che osservano gli stessi dati, ogni scheda fa il proprio calcolo: costo trascurabile con i volumi di un archivio personale.
