# ADR-002 – Modulo crittografico (chiavi, cifratura, Secret Key)

- **Stato**: accettata
- **Data**: 2026-10-10
- **Codice**: `lib/core/crypto/`, test in `test/core/crypto/`

## Contesto
I dati devono essere illeggibili fuori dai dispositivi dell'utente (E2EE, ADR-001), recuperabili se si perde la password, e il formato deve poter cambiare algoritmo in futuro (crypto-agility, orizzonte 10 anni).

## Decisione
- **Libreria**: libsodium tramite il pacchetto Dart `sodium` (variante *sumo*, necessaria per Argon2). Il codice nativo viene compilato dai sorgenti ufficiali inclusi nel pacchetto: nessun binario scaricato a parte.
- **Chiave dei dati (DEK)**: 256 bit casuali, una per archivio. Cifra tutti i dati.
- **Password principale → KEK** con **Argon2id** (predefinito 64 MiB, 3 passaggi; minimo accettato 19 MiB, 2 passaggi, come da OWASP). Un keyring con parametri sotto il minimo è rifiutato (anti-downgrade).
- **Secret Key** (sostituisce le 24 parole BIP-39 della prima versione, decisione utente del 10/10/2026: più semplice da salvare e da usare): 256 bit casuali + 16 bit di controllo (SHA-256), in testo `GF1-XXXXX-…` Base32 Crockford (niente caratteri ambigui, O/I/L letti come 0/1/1; `GF1` = versione del formato). L'utente la salva come **file** o la **copia**; per il recupero sceglie il file o incolla il testo. Dall'entropia si deriva la chiave di avvolgimento con `crypto_kdf` (contesto `GFrecov1`).
- **ID archivio** (`GF-XXXX-XXXX`, 40 bit casuali, non segreto): identifica l'archivio nel file della Secret Key e nei messaggi; fa parte dei dati autenticati del keyring.
- **Keyring** (`keyring.bin`): JSON con versione, ID archivio, parametri Argon2, DEK avvolta dalla KEK e DEK avvolta dalla Secret Key. Nessun segreto in chiaro. I parametri Argon2 fanno parte dei dati autenticati: modificarli impedisce l'apertura.
- **Cifratura dei dati**: **XChaCha20-Poly1305-IETF**, nonce casuale da 24 byte. Blob v1 = `[versione 1 byte][nonce 24][cifrato + tag 16]`; il byte di versione è autenticato.
- **AAD** = tipo di dato | utente | dispositivo | sequenza, con lunghezze esplicite (nessuna ambiguità). Un blob spostato di dispositivo, di sequenza o di tipo non si decifra (anti-manomissione e anti-replay).
- **Errori** tipizzati con messaggi per l'utente: password errata, Secret Key non valida (incompleta, errore di battitura, di un altro archivio), dati non validi, versione non supportata, parametri non sicuri.

## Conseguenze
- ✅ Cambio password senza ricifrare i dati (si riavvolge solo la DEK); nuova Secret Key senza toccare la password.
- ✅ Nuovi algoritmi (es. post-quantum) aggiungibili con un nuovo numero di versione, leggendo ancora i dati vecchi.
- ⚠️ Argon2id è volutamente lento: nell'interfaccia va eseguito fuori dal thread grafico (`Sodium.runIsolated`).
- ⚠️ Persi password, Secret Key e tutti i dispositivi → dati irrecuperabili (per progetto; da spiegare nell'onboarding).
- 🔜 Taratura dei parametri Argon2 per dispositivo, normalizzazione Unicode della password; sblocco biometrico (Android Keystore / Windows Hello: ✅ ADR-016) e dispositivi fidati (nuovo dispositivo con password + Secret Key o QR da un dispositivo fidato).
