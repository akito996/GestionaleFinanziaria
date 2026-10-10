# ADR-004 – Costo della vita (spese fisse e variabili)

- **Stato**: accettata
- **Data**: 2026-10-10
- **Codice**: `lib/core/db/costo_vita.dart`, `lib/features/costo_vita/`, test in `test/core/db/costo_vita_test.dart`

## Contesto
L'utente vuole sapere quanto gli costa vivere ogni mese: spese **fisse** (affitto, bollette, abbonamenti) e **variabili** (spesa, carburante, svago), con un grafico nella dashboard. Gli importi cambiano nel tempo: a volte solo per un mese, a volte per sempre.

## Decisione
- **Voci** (`voci_costo`): nome, tipo `fissa`/`variabile`, categoria facoltativa.
- **Importo predefinito con decorrenza** (`importi_voce`): ogni modifica aggiunge una riga con `valido_dal`; l'utente sceglie **"da domani"** o **"dal mese prossimo"**. Una voce nuova vale dal 1° del mese in corso.
- **Variazione di un solo mese** (`variazioni_mese`): sostituisce l'importo di quel mese; si può annullare ("torna al predefinito").
- **Regola dei mesi**: mese passato → importo in vigore l'ultimo giorno del mese; mese in corso → importo in vigore **oggi** (quindi una modifica "da domani" si vede dal giorno dopo); mese futuro → importo del primo giorno.
- **Variabili, stima e importi reali**: le spese reali sono i movimenti di **uscita** del mese nella categoria della voce e in tutte le sue sottocategorie.
- **Grafico** (fl_chart): barre impilate per mese (fisse + variabili previste) con un punto "speso davvero" (fisse + variabili reali). Un solo asse in euro. Palette categoriale validata (blu, arancio, verde) con passi distinti per tema chiaro e scuro, legenda sempre visibile, valori al tocco, importi anche in forma di testo (elenco delle voci).
- Le voci tolte vengono **archiviate** (con Annulla), mai cancellate.
- **Categorie**: albero iniziale proposto (Casa › Bollette, Alimentari › Spesa, ...), modificabile senza limiti; migrazione dello schema v1 → v2 che conserva i dati.

## Conseguenze
- ✅ Lo storico dei mesi chiusi non cambia quando si aggiorna un importo.
- ✅ Configurazione rapida: suggerimenti a un tocco con categoria già collegata.
- ⚠️ Per ora una sola valuta (EUR) nella sezione.
- 🔜 Giorno di addebito delle fisse, promemoria, registrazione automatica del movimento della spesa fissa.
