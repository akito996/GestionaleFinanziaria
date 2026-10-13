# ADR-011 – Entrate previste e report

- **Stato**: accettata
- **Data**: 2026-10-13
- **Codice**: `lib/core/db/costo_vita.dart`, `lib/features/costo_vita/`, `lib/features/home/entrate_previste.dart`, `lib/core/report/`, `lib/features/report/`

## Contesto
L'utente vuole una sezione gemella del Costo della vita per le entrate mensili, con gli stessi comportamenti:
- importi predefiniti;
- variazione di un solo mese;
- cambio da domani o dal mese successivo.

Vuole inoltre:
- report mensili e annuali sull'andamento delle entrate previste e del costo della vita (dopo un anno restano solo gli annuali), scaricabili;
- una sezione Report per creare analisi di ogni strumento, con dettaglio giornaliero, settimanale, mensile o annuale.

## Decisione (fase 1: entrate previste)
- **Stesso motore del Costo della vita**: le voci hanno una `natura` (`spesa` o `entrata`, colonna `voci_costo.natura`, schema v11, le voci esistenti sono spese). Importi con decorrenza, variazioni del mese, data di accredito, suddivisione nei mesi, modifica ed eliminazione valgono per entrambe.
  - Per le entrate il "ricevuto davvero" sono i movimenti di **entrata** della categoria.
  - L'accredito automatico registra un movimento di tipo Entrata.
  - Le rate dei prestiti contano solo nel costo della vita.
- **Nome della sezione**: "Entrate previste" (nella barra di navigazione: "Entrate"). Testi in `TestiVoci`, uno per natura.
- **Navigazione**: Panoramica, Costo della vita, Entrate e Carte sono nella barra in basso del telefono; Prestiti, Obiettivi e Categorie in "Altro".
- **Panoramica**: nuova scheda "Entrate previste" con il **margine previsto** (entrate previste − costo della vita), con segno e icona.
- Schema v11: è già creata anche la tabella `report` per la fase 2.

## Decisione (fase 2: report automatici)
- **Documento report** (`DocumentoReport`): un solo formato per schermo, archivio e download.
  - Contiene titolo, sottotitolo e blocchi: cifre chiave, serie (andamento), tabelle con celle tipizzate (testo, importo, numero).
  - Si salva come JSON versionato nella tabella `report` (archivio cifrato, sincronizzabile).
  - Il report resta com'era anche se poi cambiano le voci.
- **Report mensile** (per ogni mese concluso):
  - cifre chiave: entrate previste ed effettive, costo della vita previsto, uscite effettive, margine previsto ed effettivo, con la variazione rispetto al mese prima;
  - andamento degli ultimi 12 mesi;
  - dettaglio per voce (con le rate dei prestiti).
- **Report annuale** (per ogni anno concluso): cifre dell'anno (con il confronto con l'anno prima), mese per mese, voci sommate su tutto l'anno.
- **Quando**: all'apertura dell'archivio e ogni 15 minuti se l'app resta aperta. Si creano i mensili degli ultimi 12 mesi conclusi (non oltre il primo mese con dati) e gli annuali degli anni conclusi. Un errore non impedisce di aprire l'archivio.
- **Conservazione**: i mensili più vecchi di 12 mesi si eliminano (eliminazione logica), ma solo se esiste già l'annuale del loro anno. Gli annuali restano sempre.
- **Download**: PDF (Roboto incorporato, cifre, grafico a colonne, tabelle, numeri di pagina) ed Excel (foglio "Sintesi" più un foglio per ogni grafico e tabella, importi come numeri). Avviso: il file scaricato non è cifrato.

## Decisione (fase 3: sezione Report)
- Nuova sezione "Report", nella barra laterale e su telefono in "Altro".
- **Crea un report**:
  - strumenti a scelta: entrate e uscite, spese per categoria, saldo dei portafogli, costo della vita, entrate previste, carte, prestiti, obiettivi;
  - dettaglio giornaliero, settimanale (da lunedì a domenica), mensile o annuale;
  - periodo (mese, 3 mesi, 12 mesi, anno o date a scelta).
- Il primo e l'ultimo intervallo sono tagliati sul periodo; oltre 400 intervalli l'app chiede un periodo più breve.
- **Costo della vita ed entrate previste per giorno o settimana**: il previsto mensile si distribuisce sui giorni del mese ed è confrontato con le uscite o le entrate effettive.
- **Report automatici**: elenco per anno (prima l'annuale, poi i mensili), da aprire e scaricare.

