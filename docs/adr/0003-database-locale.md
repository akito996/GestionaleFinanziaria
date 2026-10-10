# ADR-003 – Database locale cifrato e modello dati

- **Stato**: accettata
- **Data**: 2026-10-10
- **Codice**: `lib/core/db/`, test in `test/core/db/`

## Contesto
L'app è local-first: tutti i dati stanno in un database sul dispositivo, che deve essere cifrato. Il vecchio pacchetto `sqlcipher_flutter_libs` è dismesso (febbraio 2026); oggi `package:sqlite3` (3.x) fornisce build precompilate di SQLite, SQLite3 Multiple Ciphers e SQLCipher, verificate con impronta SHA-256.

## Decisione
- **Motore**: **SQLCipher** (AES-256 + HMAC-SHA512 per pagina) via `package:sqlite3` (`hooks.user_defines.sqlite3.source: sqlcipher` in `pubspec.yaml`) e **drift** per tabelle tipizzate e migrazioni.
  Alternativa scartata: SQLite3 Multiple Ciphers (ChaCha20-Poly1305, senza OpenSSL), resta un'opzione futura.
- **Chiave**: chiave "raw" a 256 bit derivata dalla DEK con `crypto_kdf` (contesto `GFdb0001`), passata con `PRAGMA key = "x'…'"`. Mai salvata: si ricava a ogni sblocco.
- **Controlli all'apertura**: se `PRAGMA cipher_version` è vuoto (SQLCipher non caricato) l'archivio **non** si apre, per non creare mai un file in chiaro; con la chiave sbagliata → `DatiNonValidiException`.
- **Modello dati** (Qualità/Prezzo dell'handoff): tabelle fisse per i concetti base + tipi come dati.

| Tabella | Contenuto |
| --- | --- |
| `definizioni_tipo` | tipi di portafoglio, movimento, finanziamento, raccolta fondi; `schema_campi` (JSON Schema) per i campi personalizzati; tipi di sistema non eliminabili |
| `portafogli` | nome, tipo, valuta, saldo iniziale, campi personalizzati |
| `categorie` | albero illimitato (`padre_id`) |
| `movimenti` | tipo, portafoglio (e destinazione per i trasferimenti), categoria, importo, valuta, data, campi personalizzati |
| `etichette`, `movimenti_etichette` | tag multilivello |
| `impostazioni` | valori locali del dispositivo (non sincronizzati) |

- **Regole comuni** per la sincronizzazione futura (ADR-001): id UUID v4 generati sul dispositivo, colonna `aggiornato_il` (orologio logico HLC), cancellazione morbida (`eliminato`).
- **Soldi sempre in interi** (unità minime, es. centesimi), mai numeri decimali.
- Il codice generato da drift (`*.g.dart`) è versionato; la pipeline verifica che sia aggiornato.

## Conseguenze
- ✅ Nuovi tipi e campi senza aggiornare app né database.
- ⚠️ SQLCipher porta OpenSSL su Windows e Android: app più grande, aggiornamenti di sicurezza da seguire (Dependabot su `sqlite3`).
- ⚠️ Licenze: SQLCipher (BSD) e OpenSSL (Apache 2.0) vanno citate nelle note di terze parti alla prima release.
- 🔜 Validazione dei campi personalizzati con JSON Schema, orologio HLC, migrazioni testate a ogni cambio di schema.
