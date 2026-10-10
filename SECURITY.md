# Sicurezza

## Versioni supportate
Il progetto è in sviluppo: non esistono ancora versioni rilasciate. Dalla prima release riceverà correzioni di sicurezza solo l'**ultima versione** pubblicata.

## Come segnalare una vulnerabilità
**Non aprire una issue pubblica.** Usa la segnalazione privata di GitHub:
**Security → Report a vulnerability** (https://github.com/akito996/GestionaleFinanziaria/security/advisories/new).

Indica, se possibile:
- versione e piattaforma (Windows / Android);
- passi per riprodurre il problema;
- impatto (es. dati leggibili, chiavi esposte, manomissione della sincronizzazione).

Riceverai una prima risposta entro **7 giorni**. La correzione viene pubblicata prima di rendere pubblici i dettagli.

## Modello di sicurezza (in breve)
- **Local-first**: i dati stanno sul dispositivo (database SQLCipher).
- **Zero-knowledge**: a Google Drive arrivano solo file cifrati (XChaCha20-Poly1305, dati autenticati con utente, dispositivo e sequenza).
- **Chiavi**: password principale → Argon2id → chiave che protegge la chiave dei dati; copia di emergenza protetta dalla Recovery Key.
- **Minimo privilegio**: l'app chiede a Google solo l'ambito `drive.appdata` (una cartella nascosta riservata all'app).
- **Nessun segreto nel repository**: chiavi di firma e credenziali stanno solo nei secret di GitHub Actions.

Fuori ambito: dispositivi già compromessi (malware, root/jailbreak) e perdita contemporanea di password, Recovery Key e di tutti i dispositivi (in quel caso i dati sono irrecuperabili per progetto).
