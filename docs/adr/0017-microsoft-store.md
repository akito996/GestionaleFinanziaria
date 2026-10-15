# ADR-017 – Windows: distribuzione dal Microsoft Store (MSIX)

- **Stato**: accettata (sostituisce, per Windows, "solo GitHub Releases / MSI")
- **Data**: 2026-10-15
- **Codice**:
  - `windows/msix/AppxManifest.xml` (modello del manifesto);
  - `tool/msix.ps1` (pacchetto con `makeappx` del Windows SDK);
  - passo "Pacchetto MSIX (Microsoft Store)" in `verifica.yml`;
  - `sito/` e `.github/workflows/sito.yml` (home e informativa privacy su GitHub Pages).

## Contesto
Il programma Windows non è firmato. Chi lo scarica vede "PC protetto da Windows" (SmartScreen). Sui PC con Smart App Control attivo il programma viene proprio bloccato, senza "Esegui comunque".

Regola del progetto: nessuna spesa. Restano fuori:
- i certificati OV/EV, a pagamento;
- Azure Artifact Signing, non disponibile ai privati dell'UE.

L'utente valuta inoltre di rendere l'app a pagamento in futuro.

## Opzioni
- **Qualità/Prezzo (scelta)**: Microsoft Store. Account sviluppatore gratuito anche per i privati dal 2025; Microsoft firma il pacchetto; aggiornamenti automatici.
  - Più avanti si può attivare un prezzo o un abbonamento: commissione del 15% col sistema di pagamento di Microsoft, 0% con un sistema proprio.
- **Prestazione**: Store più la firma gratuita di SignPath Foundation sui file di GitHub.
  - SignPath vale solo per progetti open source distribuiti gratis, senza versioni commerciali: con un futuro a pagamento quel lavoro andrebbe buttato.
- **Economica**: nessuna firma, solo istruzioni ("Ulteriori informazioni › Esegui comunque").

## Decisione
- **Pacchetto MSIX costruito in CI** a ogni commit (artifact `GestionaleFinanziaria-msix-*`):
  - non firmato, perché lo firma lo Store alla pubblicazione;
  - versione `maggiore.minore` del pubspec più il numero dell'esecuzione CI, con l'ultima parte a 0 (regola dello Store, numeri sempre crescenti);
  - app desktop classica (`runFullTrust`), permesso `internetClient` solo per la sincronizzazione.
- **Dati dello Store**: nome del pacchetto, editore ed editore visibile, presi da Partner Center.
  - Sono pubblici e stanno nelle variabili del repository `MSIX_IDENTITY_NAME`, `MSIX_PUBLISHER` e `MSIX_PUBLISHER_DISPLAY_NAME` (non sono secret).
  - Senza di loro la CI costruisce un pacchetto di prova e lo segnala.
- **Pagine pubbliche** su GitHub Pages: home e informativa privacy.
  - Servono allo Store e alla verifica dell'app presso Google, che toglie il nuovo accesso ogni 7 giorni.
  - Pubblicazione a mano finché Pages non è attivo.
- Lo zip su GitHub resta per chi lo preferisce, con l'avviso di SmartScreen.

## Conseguenze
- **Dati con il pacchetto dello Store**: Windows tiene i dati dell'app in una cartella sua e li cancella se si disinstalla l'app.
  - Per non perdere nulla: sincronizzazione accesa (Drive) e Secret Key conservata.
  - Prima di passare dallo zip allo Store: sincronizzare, installare dallo Store, scegliere "Ho già un archivio".
- **Windows Hello** funziona anche nel pacchetto, ma la chiave vale per il pacchetto: dopo il passaggio lo sblocco rapido si riattiva.
- **Lo fa l'utente**: registrazione su Partner Center (documento e selfie), prenotazione del nome, compilazione della scheda e invio. Claude non accede all'account.
- **Prima dell'invio** serve un'icona propria: oggi l'app usa il logo predefinito di Flutter, non adatto allo Store.
