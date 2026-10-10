# ADR-007 – Obiettivi e collette

- **Stato**: accettata
- **Data**: 2026-10-10
- **Codice**: `lib/core/db/obiettivi.dart`, `lib/features/obiettivi/`

## Contesto
L'utente vuole una sezione "Raccolta fondi" che copra sia gli obiettivi di risparmio personali sia le raccolte di soldi con altre persone. Nome scelto: **Obiettivi e collette**.

## Decisione
- **Obiettivo** (`obiettivi`): nome, tipo `personale` o `colletta`, importo da raggiungere, scadenza facoltativa, portafoglio facoltativo (es. "Salvadanaio").
- **Partecipanti** (`partecipanti`, solo collette): quota personalizzata oppure **parti uguali** del resto (arrotondate per eccesso).
- **Versamenti** (`versamenti`): importo, data, partecipante; facoltativamente registrati anche come movimento: per un obiettivo personale con salvadanaio è un **trasferimento** verso il salvadanaio, altrimenti un'**entrata** nel portafoglio scelto. Annullare un versamento annulla anche il movimento (reversibile).
- **Indicatori**: avanzamento, quanto manca, **quanto mettere da parte al mese** fino alla scadenza, chi è in regola con la quota.
- **Riepilogo da condividere** (testo per la chat del gruppo), copiato solo su richiesta dell'utente.
- **Navigazione**: con 6 sezioni, sul telefono le prime 4 stanno in basso e le altre in "Altro".

## Correzione importante (stesso rilascio)
Le query di osservazione con lo **stesso testo SQL** vengono condivise da drift: tutti i servizi usavano `SELECT 1` con tabelle diverse, quindi alcuni elenchi non si aggiornavano (obiettivi) o si aggiornavano per coincidenza. Ora ogni servizio usa un testo univoco (`SELECT 1 AS osserva_<servizio>`), con un test di regressione.

## Conseguenze
- ✅ Un'unica sezione per risparmi personali e spese condivise.
- 🔜 Versamenti programmati ("metti da parte 100 € ogni mese") con il motore delle scadenze; condivisione della colletta con i dispositivi della famiglia (Fase 3).
