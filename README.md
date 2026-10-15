# WalleCy

App **open source** di finanza personale per **Windows** e **Android**, pensata per la **privacy**.

> Stato: **anteprima pubblica 0.9.0**. Scaricala dalle [Release](https://github.com/akito996/WalleCy/releases); la versione per il Microsoft Store è in arrivo.

## Cosa fa
- Portafogli, movimenti con filtri e categorie ad albero.
- Costo della vita ed entrate previste, con le scadenze registrate da sole.
- Carte di credito, prestiti e rate (anche da contratto PDF o da foto), obiettivi e collette.
- Report automatici e personalizzati, grafici, esportazione in PDF ed Excel.
- Lettura di scontrini dalla foto, sul telefono e senza internet.
- Sincronizzazione facoltativa tra PC, telefono e tablet.
- Sblocco con impronta, viso o PIN (Android) e Windows Hello (PC).

## Perché è diversa
- **I tuoi dati restano tuoi**: l'archivio vive sul tuo dispositivo e l'app funziona anche offline. Niente account, server, pubblicità o statistiche d'uso.
- **Cifratura end-to-end**: la sincronizzazione passa dal *tuo* Google Drive (cartella nascosta dell'app), ma Google riceve solo file cifrati.

## Sicurezza
- Password principale protetta con Argon2id; dati cifrati con XChaCha20-Poly1305; database locale SQLCipher.
- Secret Key (da salvare come file o testo) per recuperare i dati se dimentichi la password.
- Release verificabili: impronte SHA-256 e attestazione di provenienza (Sigstore) per ogni file.
- Segnalazione vulnerabilità: vedi [SECURITY.md](SECURITY.md).
- Decisioni di architettura: [docs/adr](docs/adr).
- Informativa privacy: [sito/privacy.html](sito/privacy.html).

## Licenza
Copyright © 2026 agjin.

[GNU AGPL v3.0](LICENSE): puoi usare, studiare, modificare e ridistribuire l'app. Chi la modifica e la distribuisce (anche come servizio online) deve pubblicare il codice con la stessa licenza.
