# ADR-019 – Portafogli condivisi (conti cointestati)

- **Stato**: accettata. Consegna 0 (prova tecnica) in corso.
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
