# ADR-011 – Entrate previste e report

- **Stato**: accettata (in corso: report automatici e sezione Report)
- **Data**: 2026-10-13
- **Codice**: `lib/core/db/costo_vita.dart`, `lib/features/costo_vita/`, `lib/features/home/entrate_previste.dart`

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
