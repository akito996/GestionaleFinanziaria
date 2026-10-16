# ADR-019 – Portafogli condivisi (conti cointestati)

- **Stato**: accettata. Consegna 0 (prova tecnica) **riuscita** il 16/10/2026; consegna 1 progettata (file preparati dal proprietario).
- **Data**: 2026-10-16
- **Codice (consegna 0)**:
  - `lib/core/condivisi/` (`accesso_drive_file.dart`, `drive_condiviso.dart`);
  - `android/.../DriveFile.kt` (selettore di Drive);
  - `lib/features/condivisi/prova_condivisione_pagina.dart` (Impostazioni › Laboratorio).

## Contesto
L'utente vuole portafogli condivisi fra account diversi, per simulare i conti cointestati.

**Ruoli**:
- **proprietario**: tutto quello che può un membro, in più è il creatore, modifica ed elimina il portafoglio, invita i membri;
- **membro**: entra solo con l'invito.

**Cosa possono fare entrambi**:
- vedere il saldo e aggiungere spese ed entrate;
- impostare le entrate automatiche;
- passare dalla vista di tutti i movimenti a quella di un singolo membro;
- usare filtri e ricerca;
- ricevere una notifica quando un altro membro aggiunge una voce;
- vedere il badge "Condiviso" in Panoramica;
- esportare;
- sapere chi ha inserito ogni voce.

**Il vincolo**: la sincronizzazione attuale (ADR-015) usa la cartella nascosta `appDataFolder`, che appartiene a un solo account e non si può condividere.

## Opzioni
- **Qualità/Prezzo (scelta)**: cartella condivisa nel Drive del proprietario, cifrata end-to-end. Costo 0 €, nessun server. Aggiornamenti ogni 5 minuti; notifiche in app e, su Android, anche ad app chiusa (ogni circa 15–30 minuti).
- **Prestazione**: Firebase gratuito come "postino" cifrato. Quasi istantaneo, ma:
  - mette un server nel mezzo;
  - ha limiti giornalieri, oltre i quali si paga;
  - su Windows non ci sono notifiche push.
- **Economica**: file cifrati scambiati a mano. Manuale, senza notifiche.

## Decisioni dell'utente
- **Trasporto**: Qualità/Prezzo.
- **Totale in Panoramica**: conta la **quota** di ognuno (es. 50%). Il saldo intero si vede nel portafoglio.
- **Modifiche alle voci**: le fa l'**autore**, più il **proprietario** su tutte. Ogni cambiamento resta firmato.

## Progetto
- **Permesso `drive.file`**: non sensibile. L'app vede solo i file che crea lei o che l'utente sceglie.
  - Il proprietario crea la cartella del portafoglio e la condivide con l'email Google dei membri (`permissions`, ruolo "writer").
  - Il membro sceglie la cartella una volta con il **selettore di Google**:
    - Android: `AuthorizationRequest` con `PICKER_OAUTH_TRIGGER` e `PICKER_ALLOW_FOLDER_SELECTION`;
    - Windows: URL OAuth con `trigger_onepick` e `allow_folder_selection`, ritorno su localhost con PKCE.
  - Il token `drive.file` è separato da quello di `drive.appdata`: Google non permette di unirli nel selettore.
- **Cifratura**:
  - ogni portafoglio condiviso ha una **chiave sua**, consegnata con l'invito: codice monouso via QR o via messaggio;
  - ogni persona ha una coppia di chiavi (X25519 per ricevere, Ed25519 per firmare);
  - ogni pacchetto di modifiche è **firmato** dall'autore;
  - ruoli, inviti, uscite ed eliminazione valgono solo se firmati dal proprietario;
  - quando un membro viene tolto, la chiave cambia: non vede le novità, ma ciò che aveva già visto resta sul suo dispositivo.
- **Dati**:
  - ogni membro scrive solo i **propri** file di eventi nella cartella condivisa;
  - l'unione segue la stessa logica dell'ADR-015 (riga per riga, orologio logico);
  - ogni voce porta "inserita da" e "modificata da";
  - spese ed entrate automatiche usano id fissi, quindi niente doppioni se due membri le registrano.
- **Interfaccia**:
  - vista totale o per membro;
  - filtri e ricerca come in Movimenti, più "Inserito da";
  - badge "Condiviso";
  - esportazione per tutti;
  - nel totale personale conta la quota.
- **Notifiche**: dopo ogni sincronizzazione, una notifica per le voci nuove degli altri. Su Android anche in background (WorkManager); su Windows con l'app aperta.

## Richieste aggiunte il 16/10/2026
- **Condiviso già alla creazione**:
  - nel modulo "Nuovo portafoglio" c'è la scelta "Condiviso"; se attiva, si invitano i membri **via email**;
  - un portafoglio esistente si può condividere anche dopo, dal suo dettaglio.
- **Ripartizione**:
  - per un portafoglio condiviso si indica la **quota del totale** di ogni membro (es. 50% / 50%) e a chi è assegnata **ogni singola voce**;
  - vale sia alla creazione sia quando il portafoglio diventa condiviso dopo.
- **Membri in attesa**: finché un invitato non accetta, le sue quote e le sue voci compaiono come "**nome (da confermare)**".

## Prova del 16/10/2026 e piano B
- **Selettore Android**: con il filtro "solo cartelle", toccando la cartella la finestra la **apre** (mostrando «La cartella è vuota») invece di sceglierla. Ora la finestra mostra cartelle **e** file di testo, con scelta multipla: va bene scegliere la cartella o il file del proprietario che c'è dentro.
- **Dubbio da chiudere**: la documentazione di Google non dice se scegliere una cartella con `drive.file` dia accesso ai file **dentro**. Fonti non ufficiali dicono di no: l'app vedrebbe solo ciò che ha creato lei o che l'utente ha scelto, file per file.
- **Piano B** (provato nel Laboratorio, passi 2–4):
  - il membro sceglie il **file** del proprietario e lo legge;
  - se non può scrivere nella cartella condivisa, scrive il proprio file nella sua cartella «WalleCy» e lo condivide col proprietario;
  - nel file del proprietario lascia l'id del suo file (ha il permesso di scrittura);
  - il proprietario apre il file del membro con un tocco: la finestra di Google mostra **solo** quel file (`PICKER_FILE_IDS` / `file_ids`). È il passo naturale per "conferma il membro" (membri «da confermare»).
- **Ordine nel Drive**: tutte le cartelle di condivisione stanno dentro un'unica cartella **«WalleCy»** nella radice del Drive. Le cartelle già presenti si riusano (e si spostano dentro «WalleCy» se erano fuori); ogni persona ha un solo file, che si aggiorna invece di duplicarsi.
- **Invito**: Google manda all'invitato un'email con un messaggio dell'app che spiega cosa fare in WalleCy.

## Esito della prova a due account (16/10/2026, sera)
- Il membro sceglie il **file** del proprietario (la finestra di Android apre la cartella invece di sceglierla), lo **legge** ed elenca la cartella: vede solo i file scelti.
- Il membro **scrive** il proprio file nella cartella condivisa anche senza aver scelto la cartella, e **aggiorna** il file del proprietario.
- Il proprietario **non vede** il file creato dal membro, pur essendo nella sua cartella: `drive.file` vale **per persona** (file creati o scelti da quella persona con l'app).
- Con **un tocco** nella finestra di Google il proprietario apre il file del membro (passo 4).
- Il filtro `PICKER_FILE_IDS` sembra **ignorato** dalla finestra di Android (mostrava «Recenti» con entrambi i file): l'app controlla sempre la scelta e non conta sul filtro.

## Progetto scelto per la consegna 1: file preparati dal proprietario
Scelta dell'utente: **Qualità/Prezzo** (le altre: proprietario come "centro" che ridistribuisce; un file creato da ogni membro e confermato dal proprietario).
- La cartella del portafoglio sta dentro «WalleCy» del proprietario ed è condivisa (ruolo "writer") con i membri.
- Il proprietario crea **tutti** i file, già all'invito:
  - il **registro** del portafoglio (membri, ruoli, quote), firmato dal proprietario;
  - un file **per ogni membro**, creato prima che il membro entri.

  Il proprietario li vede sempre: nessun tocco di conferma da parte sua.
- Ogni file ha **un solo scrittore**: il proprietario il registro, ogni membro solo il proprio file, aggiornato sul posto (stesso id). Niente conflitti di scrittura.
- **Ingresso del membro**: sceglie una volta i file del portafoglio (cartella in «Condivisi con me», scelta multipla); l'app controlla di avere il registro e il proprio file.
- **Nuovo membro**: gli altri membri vedono «nuovo membro da confermare» e con un tocco aprono il suo file.
- **Contenuto dei file**: pacchetti cifrati con la chiave del portafoglio (XChaCha20-Poly1305) e firmati dall'autore (Ed25519); unione riga per riga come nell'ADR-015.

**Consegna 1, in quattro passi**:
- 1a. Fondamenta locali: chiavi della persona, tabelle dei portafogli condivisi e dei membri, voci con l'autore.
- 1b. Invito: "Condiviso" nel modulo del portafoglio, email, cartella e file preparati, consegna della chiave.
- 1c. Ingresso del membro: "Unisciti a un portafoglio condiviso", scelta dei file, il portafoglio compare.
- 1d. Sincronizzazione condivisa: scrittura e lettura dei file, firme, unione, "nuovo membro da confermare".

## Consegne
0. **Prova tecnica** (Laboratorio):
   - il proprietario crea una cartella, scrive un file e la condivide;
   - il membro la sceglie, ne legge i file e ci scrive;
   - il proprietario vede il file del membro.

   Serve a verificare con due account veri cosa permette `drive.file` sulle cartelle scelte (i file all'interno, la scrittura).
1. **Fondamenta**: chiavi delle persone, chiave del portafoglio, invito e accettazione, cartella e sincronizzazione condivisa, firme.
2. **Uso**: voci con autore, vista per membro, filtri, quota nel totale, badge, esportazione, automatiche.
3. **Notifiche e ruoli avanzati**: notifiche in background, rimozione con cambio di chiave, eliminazione, uscita volontaria.

## Prerequisiti (li fa l'utente in Google Cloud)
- Abilitare la **Google Picker API**.
- Aggiungere l'ambito `.../auth/drive.file` alla schermata di consenso (Accesso ai dati).
- Finché l'app è "In prova", aggiungere tra gli **utenti di test** anche l'account Google del membro.
