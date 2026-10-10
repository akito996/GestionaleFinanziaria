# ADR-002 – Modulo crittografico (chiavi, cifratura, Recovery Key)

- **Stato**: accettata
- **Data**: 2026-10-10
- **Codice**: `lib/core/crypto/`, test in `test/core/crypto/`

## Contesto
I dati devono essere illeggibili fuori dai dispositivi dell'utente (E2EE, ADR-001), recuperabili se si perde la password, e il formato deve poter cambiare algoritmo in futuro (crypto-agility, orizzonte 10 anni).

## Decisione
- **Libreria**: libsodium tramite il pacchetto Dart `sodium` (variante *sumo*, necessaria per Argon2). Il codice nativo viene compilato dai sorgenti ufficiali inclusi nel pacchetto: nessun binario scaricato a parte.
- **Chiave dei dati (DEK)**: 256 bit casuali, una per archivio. Cifra tutti i dati.
- **Password principale → KEK** con **Argon2id** (predefinito 64 MiB, 3 passaggi; minimo accettato 19 MiB, 2 passaggi, come da OWASP). Un keyring con parametri sotto il minimo è rifiutato (anti-downgrade).
- **Recovery Key**: 24 parole **BIP-39 lista italiana** (256 bit + 8 bit di controllo). Dall'entropia si deriva la chiave di avvolgimento con `crypto_kdf` (contesto `GFrecov1`). Si accettano maiuscole, a capo e le sole prime 4 lettere di ogni parola.
- **Keyring** (`keyring.bin`): JSON con versione, parametri Argon2, DEK avvolta dalla KEK e DEK avvolta dalla Recovery Key. Nessun segreto in chiaro. I parametri Argon2 fanno parte dei dati autenticati: modificarli impedisce l'apertura.
- **Cifratura dei dati**: **XChaCha20-Poly1305-IETF**, nonce casuale da 24 byte. Blob v1 = `[versione 1 byte][nonce 24][cifrato + tag 16]`; il byte di versione è autenticato.
- **AAD** = tipo di dato | utente | dispositivo | sequenza, con lunghezze esplicite (nessuna ambiguità). Un blob spostato di dispositivo, di sequenza o di tipo non si decifra (anti-manomissione e anti-replay).
- **Errori** tipizzati con messaggi per l'utente: password errata, Recovery Key non valida (indica la parola sbagliata), dati non validi, versione non supportata, parametri non sicuri.

## Conseguenze
- ✅ Cambio password senza ricifrare i dati (si riavvolge solo la DEK); nuova Recovery Key senza toccare la password.
- ✅ Nuovi algoritmi (es. post-quantum) aggiungibili con un nuovo numero di versione, leggendo ancora i dati vecchi.
- ⚠️ Argon2id è volutamente lento: nell'interfaccia va eseguito fuori dal thread grafico (`Sodium.runIsolated`).
- ⚠️ Persi password, Recovery Key e tutti i dispositivi → dati irrecuperabili (per progetto; da spiegare nell'onboarding).
- 🔜 Taratura dei parametri Argon2 per dispositivo, sblocco rapido con Android Keystore / Windows Hello, normalizzazione Unicode della password.
