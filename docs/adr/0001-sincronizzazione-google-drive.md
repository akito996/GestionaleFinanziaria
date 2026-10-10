# ADR-001 – Sincronizzazione tramite Google Drive dell'utente (Scenario 6)

- **Stato**: accettata
- **Data**: 2026-10-10

## Contesto
L'app deve sincronizzare i dati tra Windows e Android **senza costi** e **senza server propri**, mantenendo i dati illeggibili a terzi. L'utente dispone già di spazio Google Drive.

## Decisione
- I dati si sincronizzano nella cartella nascosta **`appDataFolder`** del Google Drive dell'utente, con il solo ambito OAuth **`drive.appdata`** (non sensibile, minimo privilegio).
- Tutto ciò che arriva a Drive è **cifrato sul dispositivo** (E2EE): Google non può leggere né i dati né i nomi degli allegati.
- Struttura su Drive:

| File | Contenuto |
| --- | --- |
| `keyring.bin` | chiave dei dati cifrata con la password principale e con la Secret Key |
| `devices/<id>/events-<n>.bin` | pacchetti di modifiche cifrati, scritti solo dal dispositivo proprietario |
| `snapshots/snapshot-<data>.bin` | snapshot completo cifrato (compattazione) |
| `attachments/<casuale>.bin` | allegati cifrati con nomi casuali |
| `manifest.bin` | versione schema/algoritmi, elenco dispositivi |

- Le novità si rilevano con la **Drive Changes API**; i conflitti si risolvono con **orologi logici (HLC)**, last-writer-wins per singolo campo, storico nell'audit log.
- La sincronizzazione è dietro un'interfaccia astratta **`SyncBackend`**.

## Conseguenze
- ✅ Costo zero, nessun server da mantenere, dati nello spazio dell'utente.
- ⚠️ Sincronizzazione ogni 1-5 minuti, non istantanea.
- ⚠️ Condivisione con la famiglia rinviata (richiederà una cartella condivisa con ambito `drive.file`).
- 🔁 Grazie a `SyncBackend` si potrà passare allo **Scenario 7 – Ibrido** (Cloudflare Workers + D1 per la sincronizzazione, Drive per allegati e backup) senza riscrivere l'app.

## Alternative scartate
Solo locale; Cloudflare Workers + D1; Workers + R2 + Zero Trust; Firebase ("tutto Google"); Syncthing, server in casa, Oracle Free, cloud personale. Dettagli nella documentazione di progetto.
