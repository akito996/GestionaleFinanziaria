# GestionaleFinanziaria

App **open source** di finanza personale per **Windows** e **Android**, pensata per la **privacy**.

> Stato: **in sviluppo** (Fase 0 – fondamenta). Non ancora utilizzabile.

## Perché è diversa
- **I tuoi dati restano tuoi**: il database vive sul tuo dispositivo e l'app funziona anche offline.
- **Cifratura end-to-end**: la sincronizzazione passa dal *tuo* Google Drive (cartella nascosta dell'app), ma Google riceve solo file cifrati. Nessun server nostro, nessuna chiave in chiaro fuori dai tuoi dispositivi.
- **Tutto personalizzabile e illimitato**: portafogli, categorie e sottocategorie, tipi di movimento, finanziamenti, raccolte fondi, tag, campi personalizzati.
- **Assistente vocale su Android** (Gemini sul telefono); su Windows inserimento manuale rapido da tastiera.

## Sicurezza
- Password principale → Argon2id; dati cifrati con XChaCha20-Poly1305; database locale SQLCipher.
- Recovery Key di 24 parole per recuperare i dati se perdi la password o il dispositivo.
- Segnalazione vulnerabilità: vedi [SECURITY.md](SECURITY.md).
- Decisioni di architettura: [docs/adr](docs/adr).

## Licenza
[GNU AGPL v3.0](LICENSE): puoi usare, studiare, modificare e ridistribuire l'app, ma chi la modifica e la distribuisce (anche come servizio online) deve pubblicare il codice con la stessa licenza.
