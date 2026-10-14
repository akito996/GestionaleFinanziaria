# ADR-015 – Sincronizzazione con Google Drive: come funziona

- **Stato**: accettata (attua l'ADR-001)
- **Data**: 2026-10-14
- **Codice**:
  - `lib/core/sync/`: `sincronizzatore.dart`, `righe.dart`, `drive.dart`, `accesso_google.dart`, `sincronizzazione.dart`;
  - `lib/features/sync/`;
  - `Sessione.apriArchivioRemoto`.

## Contesto
L'utente vuole usare lo stesso archivio su PC Windows, telefono e tablet Android. L'ADR-001 ha deciso lo spazio: la cartella nascosta `appDataFolder` di Google Drive, ambito `drive.appdata`, tutto cifrato sul dispositivo.

Tra le tre scelte proposte l'utente ha preso **Qualità/Prezzo**: modifiche per dispositivo, unione riga per riga, controllo ogni 5 minuti. Ha confrontato i dati in più dell'opzione Prestazione, che unisce campo per campo e controlla ogni minuto.

## Decisione
- **File su Drive** (nomi piatti, etichette `appProperties` in chiaro solo con tipo, dispositivo, numero e archivio):
  - `keyring.bin`: il keyring già cifrato. Si apre solo con la password o con la Secret Key.
  - `eventi-<dispositivo>-<n>.bin`: le righe cambiate su quel dispositivo dopo l'ultimo invio. Ogni dispositivo scrive solo i propri file.
  - `istantanea-<tempo>-<dispositivo>.bin`: tutte le righe, più il "vettore" con l'ultimo pacchetto incluso per ogni dispositivo.
- **Cifratura**:
  - JSON compresso (gzip), poi XChaCha20-Poly1305;
  - la chiave è derivata da quella dei dati con il KDF di libsodium (`GFsync01`), così SQLCipher e sincronizzazione non condividono la stessa chiave;
  - l'AAD lega ogni file a tipo, archivio, dispositivo e numero: niente scambi né riusi;
  - ogni contenuto dichiara `formato`: con uno più nuovo l'app chiede di aggiornarsi.
- **Unione**:
  - riga per riga, vince l'orologio logico più recente (`aggiornato_il`, già presente in ogni tabella);
  - l'orologio "vede" quelli degli altri (`OrologioLogico.ricevi`) e riparte da lì dopo un riavvio;
  - cancellazioni morbide, quindi anche le eliminazioni viaggiano;
  - le colonne sconosciute a una versione dell'app si ignorano, quelle mancanti restano predefinite;
  - i riferimenti tra tabelle si controllano a fine transazione (`defer_foreign_keys`);
  - non viaggiano `report` (ognuno li ricalcola) e `impostazioni` (stato del dispositivo, credenziali). Un test controlla che ogni nuova tabella sincronizzabile sia nell'elenco.
- **Scadenze registrate da due dispositivi**:
  - i movimenti generati hanno un id fisso, `scadenza:<pianificazione>:<giorno>`, quindi PC e telefono scrivono la stessa riga;
  - per i vecchi id casuali con la stessa scadenza resta quello con l'id minore e l'altro si stacca.
- **Giro**:
  1. keyring: si carica se manca; se è cambiato altrove arriva qui (nuova password valida ovunque); se è cambiato qui va su Drive.
  2. Istantanea nuova (se c'è), poi i pacchetti degli altri non ancora applicati.
  3. Invio delle modifiche locali.
  4. Istantanea se mancante, oltre 30 pacchetti propri o più vecchia di 7 giorni. Dopo, ognuno cancella i propri pacchetti e le proprie istantanee vecchie.
- **Quando**: all'apertura, ogni 5 minuti, quando l'app va in secondo piano o torna, e con "Sincronizza ora".
- **Dispositivo nuovo**: al primo avvio, "Ho già un archivio su un altro dispositivo". Si accede a Google, si apre l'archivio di Drive con la password (o con la Secret Key e una password nuova), si svuotano i dati iniziali e si scarica tutto. La sincronizzazione si accende prima di scaricare, così se si interrompe riprende da sola.
- **Archivio diverso su Drive**: Windows, Android e la versione "prova" condividono la stessa cartella, perché appartengono allo stesso progetto Google. Se su Drive c'è un altro archivio, l'utente sceglie:
  - "Usa quello di Drive": l'archivio locale (database e keyring) viene rinominato `.sostituito-…`;
  - "Metti questo su Drive": i file remoti vengono rinominati `vecchio-…`.
  In nessun caso si cancella nulla.
- **Accesso**:
  - **Android**: Google Play services, sola autorizzazione `drive.appdata` (niente profilo). Client OAuth "Android" per pacchetto e impronta SHA-1, uno per la versione ufficiale e uno per la prova. L'impronta compare tra gli avvisi della CI.
  - **Windows**: browser con ritorno su `localhost` e PKCE (`googleapis_auth`). Il segreto del client desktop arriva dal secret di GitHub `GOOGLE_CLIENT_SECRET_WINDOWS` con `--dart-define`, mai dal repository; senza, la sincronizzazione su Windows risulta "non disponibile". Il token di rinnovo sta nell'archivio cifrato, solo su quel dispositivo.
  - Permesso Android `INTERNET`, prima assente nelle build di release.

## Conseguenze
- ✅ Stesso archivio su tutti i dispositivi, a costo zero, con dati illeggibili per Google.
- ✅ Nessuna perdita: conflitti risolti per riga, archivi diversi messi da parte, mai cancellati.
- ⚠️ Sulla stessa riga cambiata su due dispositivi tra due sincronizzazioni resta solo la modifica più recente (scelta Qualità/Prezzo).
- ⚠️ Finché l'app Google è in modalità "Test", il consenso scade ogni 7 giorni e la pagina chiede di riaccedere. Per toglierlo bisogna pubblicarla: servono le pagine home e privacy su GitHub Pages.
- 🔜 Unione campo per campo e controllo ogni minuto (opzione Prestazione): il `formato` versionato lo permette senza rifare i dati su Drive.
