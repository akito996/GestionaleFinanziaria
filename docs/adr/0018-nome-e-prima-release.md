# ADR-018 – Nome "WalleCy", autore e prima release pubblica

- **Stato**: accettata
- **Data**: 2026-10-15
- **Codice**:
  - `lib/core/identita.dart` (nome, autore, copyright, indirizzo del codice);
  - `DepositoLocale.copiaArchivioPrecedente`;
  - metadati in `windows/runner/Runner.rc`;
  - job `rilascio` in `verifica.yml`;
  - note di rilascio in `docs/rilasci/`.

## Contesto
L'app si chiamava provvisoriamente "GestionaleFinanziaria". Prima dello Store e della release l'utente ha deciso:
- **nome**: WalleCy;
- **firma, metadati e copyright** con il nome d'arte **agjin**: «© 2026 agjin». Scelta Qualità/Prezzo, tra nome d'arte, nome e cognome e "Gli autori di WalleCy";
- **prima release** 0.9.0, come anteprima pubblica (Qualità/Prezzo; scartate 1.0.0 e 0.1.0);
- **repository** rinominato in `WalleCy`, a cura dell'utente;
- **release su GitHub** con APK firmati, zip Windows, impronte SHA-256 e attestazione di provenienza (Qualità/Prezzo).

## Decisione
- **Nome visibile** ovunque (app, finestre, file esportati, Secret Key, Store, sito) da `Identita.nome`:
  - Android: "WalleCy" e "WalleCy Prova";
  - Windows: `WalleCy.exe`, titolo della finestra.
- **Firma e metadati**:
  - firma all'apertura: «WalleCy v0.9.0 · build · © 2026 agjin»;
  - pagina Informazioni e licenze delle librerie;
  - Windows: CompanyName `agjin`, ProductName `WalleCy`, LegalCopyright «Copyright © 2026 agjin - Licenza GNU AGPL-3.0»;
  - README.
- **Restano invariati** gli identificativi tecnici:
  - id Android `io.github.akito996.gestionale_finanziaria` (e `.prova`): cambiarlo significherebbe un'altra app e nuovi client OAuth;
  - certificato di firma (CN=GestionaleFinanziaria);
  - contesti crittografici e prefissi GF1-/GF- delle Secret Key, nome della chiave di Windows Hello, nomi dei canali nativi, nome del pacchetto Dart.
- **Cartella dei dati su Windows**:
  - dipende da editore e nome del programma, quindi passa da `%APPDATA%\io.github.akito996\GestionaleFinanziaria` a `%APPDATA%\agjin\WalleCy`;
  - al primo avvio l'archivio viene **copiato** dalla cartella vecchia, passando da una cartella temporanea; l'originale non si cancella;
  - Android non cambia.
- **Numero di build** = numero dell'esecuzione CI: sempre crescente (versionCode Android, versione del file Windows, MSIX).
- **Release**: un tag `vX.Y.Z` uguale alla versione del pubspec avvia la CI completa. Se tutto è verde, il job `rilascio`:
  - pubblica gli APK ufficiali (arm64, armv7), lo zip Windows, `SHA256SUMS.txt` e l'attestazione di provenienza (`actions/attest-build-provenance`, Sigstore);
  - usa le note in `docs/rilasci/vX.Y.Z.md`;
  - per le versioni 0.x crea una "pre-release".

  Il pacchetto MSIX non è nella release: si carica nello Store dall'artifact della CI.

## Conseguenze
- **Lo fa l'utente**:
  - rinominare il repository (i vecchi link vengono reindirizzati);
  - cambiare il nome dell'app nella schermata di consenso di Google (Google Cloud › Branding);
  - prenotare "WalleCy" in Partner Center.
- Le Secret Key già salvate (file "GestionaleFinanziaria-SecretKey-…") restano valide.
