import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sodium/sodium_sumo.dart';

import 'crypto/keyring.dart';
import 'crypto/operazioni_chiavi.dart';
import 'crypto/secret_key.dart';
import 'db/archivio.dart';
import 'db/carte_credito.dart';
import 'db/contabilita.dart';
import 'db/costo_vita.dart';
import 'db/deposito_locale.dart';
import 'db/notifiche.dart';
import 'db/obiettivi.dart';
import 'db/pianificatore.dart';
import 'db/prestiti.dart';
import 'db/statistiche.dart';
import 'db/orologio.dart';
import 'report/report_automatici.dart';
import 'report/report_personalizzati.dart';
import 'sicurezza/cassaforte.dart';
import 'sicurezza/sicurezza_dispositivo.dart';
import 'sync/accesso_google.dart';
import 'sync/drive.dart';
import 'sync/sincronizzatore.dart';
import 'sync/sincronizzazione.dart';
import 'sync/sync_backend.dart';

enum FaseSessione { caricamento, primoAvvio, bloccata, sbloccata }

/// Stato dell'app: primo avvio, archivio bloccato o sbloccato.
///
/// La chiave dei dati resta in memoria solo mentre l'archivio è sbloccato;
/// [blocca] la cancella e chiude il database.
class Sessione extends ChangeNotifier {
  Sessione({
    required this.sodium,
    required this.deposito,
    this.costoArgon2 = costoArgon2Predefinito,
    AccessoGoogle? accessoGoogle,
    CreaBackend? creaBackend,
    this._cassaforte,
  }) : _accessoIniettato = accessoGoogle,
       _creaBackend = creaBackend ?? DriveBackend.new;

  final AccessoGoogle? _accessoIniettato;
  final CreaBackend _creaBackend;
  final CassaforteDispositivo? _cassaforte;

  /// Sblocco rapido e blocco automatico di questo dispositivo (ADR-016):
  /// disponibile in ogni fase.
  late final SicurezzaDispositivo sicurezza = SicurezzaDispositivo(
    sodium: sodium,
    file: deposito.fileSicurezza,
    cassaforte: _cassaforte ?? CassaforteDiPiattaforma(),
  );

  /// Archivio bloccato all'avvio o dal blocco automatico: lo sblocco rapido
  /// parte da solo. Dopo il lucchetto toccato a mano, no.
  bool _proponiSbloccoRapido = false;

  /// Dopo la password: proporre di attivare lo sblocco rapido.
  bool _proponiAttivazione = false;

  /// Una volta sola: lo sblocco rapido deve partire da solo?
  bool prendiAvvioSbloccoRapido() {
    final proponi = _proponiSbloccoRapido;
    _proponiSbloccoRapido = false;
    return proponi;
  }

  /// Una volta sola: proporre di attivare lo sblocco rapido?
  bool prendiPropostaAttivazione() {
    final proponi = _proponiAttivazione && sicurezza.proponibile;
    _proponiAttivazione = false;
    return proponi;
  }

  /// Credenziali di Google (Windows): nell'archivio cifrato quando è aperto.
  late final _credenzialiGoogle = _CredenzialiNellArchivio(this);

  /// Accesso a Google Drive per la sincronizzazione (ADR-015).
  late final AccessoGoogle accessoGoogle =
      _accessoIniettato ?? AccessoGoogle.perPiattaforma(_credenzialiGoogle);

  Sincronizzazione? _sync;

  /// Sincronizzazione con Google Drive: disponibile solo nella fase
  /// [FaseSessione.sbloccata].
  Sincronizzazione get sync => _sync!;

  final SodiumSumo sodium;
  final DepositoLocale deposito;
  final CostoArgon2 costoArgon2;

  FaseSessione _fase = FaseSessione.caricamento;
  FaseSessione get fase => _fase;

  Archivio? _archivio;

  /// Disponibile solo nella fase [FaseSessione.sbloccata].
  Archivio get archivio => _archivio!;

  Contabilita? _contabilita;

  /// Portafogli e movimenti: disponibile solo nella fase [FaseSessione.sbloccata].
  Contabilita get contabilita => _contabilita!;

  CostoVita? _costoVita;

  /// Costo della vita: disponibile solo nella fase [FaseSessione.sbloccata].
  CostoVita get costoVita => _costoVita!;

  Pianificatore? _pianificatore;

  /// Pagamenti programmati: disponibile solo nella fase [FaseSessione.sbloccata].
  Pianificatore get pianificatore => _pianificatore!;

  CarteCreditoServizio? _carte;

  /// Carte di credito: disponibile solo nella fase [FaseSessione.sbloccata].
  CarteCreditoServizio get carte => _carte!;

  PrestitiServizio? _prestiti;

  /// Prestiti e rate: disponibile solo nella fase [FaseSessione.sbloccata].
  PrestitiServizio get prestiti => _prestiti!;

  NotificheServizio? _notifiche;

  /// Notifiche (scadenze e decisioni): disponibile solo nella fase
  /// [FaseSessione.sbloccata].
  NotificheServizio get notifiche => _notifiche!;

  ObiettiviServizio? _obiettivi;

  /// Obiettivi e collette: disponibile solo nella fase [FaseSessione.sbloccata].
  ObiettiviServizio get obiettivi => _obiettivi!;

  StatisticheServizio? _statistiche;

  /// Dati per grafici ed export: disponibile solo nella fase [FaseSessione.sbloccata].
  StatisticheServizio get statistiche => _statistiche!;

  ReportAutomatici? _report;

  /// Report mensili e annuali: disponibile solo nella fase [FaseSessione.sbloccata].
  ReportAutomatici get report => _report!;

  /// Report creati dall'utente (sezione Report).
  ReportPersonalizzati get reportPersonalizzati => ReportPersonalizzati(
    _archivio!,
    costoVita,
    statistiche,
    carte,
    prestiti,
    obiettivi,
  );

  SecureKey? _dek;

  String? _idArchivio;

  /// ID pubblico dell'archivio aperto (es. `GF-7K3P-Q9XW`).
  String? get idArchivio => _idArchivio;

  /// Messaggio di conferma da mostrare una volta all'apertura (es. "Archivio sbloccato").
  String? avviso;

  /// Archivio nuovo in preparazione: salvato solo dopo la verifica della Secret Key.
  ArchivioCreato? _inPreparazione;

  Future<void> avvia() async {
    // L'avvio non aspetta il dispositivo: per lo sblocco rapido basta il
    // file; cosa offre il dispositivo serve dopo (proposta, Impostazioni).
    try {
      sicurezza.leggi();
    } catch (e) {
      // Senza sblocco rapido si entra comunque con la password.
      debugPrint('Sicurezza del dispositivo non letta: $e');
    }
    unawaited(
      sicurezza.aggiornaDisponibilita().catchError(
        (Object e) => debugPrint('Sblocco rapido: dispositivo non letto: $e'),
      ),
    );
    final esiste = await deposito.esisteKeyring();
    _proponiSbloccoRapido = esiste;
    _cambia(esiste ? FaseSessione.bloccata : FaseSessione.primoAvvio);
  }

  /// Primo passo del primo avvio: protegge la password e genera ID e Secret Key
  /// da far salvare all'utente. Su disco non viene ancora scritto nulla.
  Future<({String idArchivio, String secretKey})> preparaNuovoArchivio(
    String password,
  ) async {
    annullaNuovoArchivio();
    final creato = await OperazioniChiavi.crea(
      sodium,
      password,
      costo: costoArgon2,
    );
    _inPreparazione = creato;
    return (idArchivio: creato.idArchivio, secretKey: creato.secretKey);
  }

  /// La Secret Key caricata o incollata è quella appena creata?
  /// Lancia `SecretKeyNonValidaException` se il testo non è una Secret Key.
  bool verificaSecretKey(String testo) {
    final pronto = _inPreparazione;
    if (pronto == null) {
      throw StateError('Nessun archivio in preparazione.');
    }
    final letta = SecretKey.daTesto(testo);
    try {
      return letta.testo == pronto.secretKey;
    } finally {
      letta.cancella();
    }
  }

  void annullaNuovoArchivio() {
    _inPreparazione?.dek.dispose();
    _inPreparazione = null;
  }

  /// Secret Key verificata: salva il keyring, crea il database e apre l'archivio.
  Future<void> confermaNuovoArchivio() async {
    final pronto = _inPreparazione;
    if (pronto == null) {
      throw StateError('Nessun archivio in preparazione.');
    }
    _inPreparazione = null;
    await deposito.metteDaParteArchivioOrfano();
    await deposito.scriviKeyring(pronto.keyring);
    await _dopoPassword(archivioNuovo: true);
    await _apri(pronto.dek, pronto.idArchivio, 'Archivio creato');
  }

  /// Lancia `PasswordErrataException` se la password non è giusta.
  Future<void> sblocca(String password) async {
    final keyring = await deposito.leggiKeyring();
    final dek = await OperazioniChiavi.apriConPassword(
      sodium,
      keyring,
      password,
    );
    await _dopoPassword();
    await _apri(
      dek,
      Keyring.deserializza(keyring).idArchivio,
      'Archivio sbloccato',
    );
  }

  /// Apre l'archivio con impronta, viso, PIN o Windows Hello. `false` se
  /// l'utente annulla. Lancia `ChiaveDispositivoAnnullata` (serve la
  /// password) o `VerificaBloccata`.
  Future<bool> sbloccaRapido() async {
    final id = Keyring.deserializza(await deposito.leggiKeyring()).idArchivio;
    final dek = await sicurezza.apriRapido(id);
    if (dek == null) {
      return false;
    }
    await _apri(dek, id, 'Archivio sbloccato');
    return true;
  }

  /// Attiva lo sblocco rapido per l'archivio aperto (chiede la verifica).
  /// Lancia `VerificaAnnullata` se l'utente rinuncia.
  Future<void> attivaSbloccoRapido() =>
      sicurezza.attivaRapido(_dek!, _idArchivio!);

  /// Password giusta: si azzera il conto dei 14 giorni. Con un archivio
  /// diverso (nuovo o scaricato) lo sblocco rapido di prima non vale più.
  Future<void> _dopoPassword({bool archivioNuovo = false}) async {
    try {
      if (archivioNuovo) {
        await sicurezza.disattivaRapido();
      }
      await sicurezza.passwordUsata();
    } catch (e) {
      debugPrint('Sicurezza del dispositivo non aggiornata: $e');
    }
    _proponiAttivazione = true;
  }

  /// Password dimenticata: Secret Key (testo o contenuto del file) + nuova password.
  /// Lancia `SecretKeyNonValidaException` se la Secret Key non è giusta.
  Future<void> recupera(String testoSecretKey, String nuovaPassword) async {
    final recuperato = await OperazioniChiavi.recupera(
      sodium,
      await deposito.leggiKeyring(),
      testoSecretKey,
      nuovaPassword,
      costo: costoArgon2,
    );
    await deposito.scriviKeyring(recuperato.keyring);
    await _dopoPassword();
    await _apri(
      recuperato.dek,
      Keyring.deserializza(recuperato.keyring).idArchivio,
      'Nuova password impostata: archivio sbloccato',
    );
  }

  /// [automatico]: blocco automatico (app rimasta in secondo piano): allo
  /// sblocco lo sblocco rapido parte da solo.
  Future<void> blocca({bool automatico = false}) async {
    final archivio = _archivio;
    final dek = _dek;
    _proponiSbloccoRapido = automatico;
    _proponiAttivazione = false;
    // Prima si tolgono le schermate dell'archivio, poi si chiude tutto:
    // nessuna schermata può leggere un archivio già chiuso.
    _idArchivio = null;
    avviso = null;
    _cambia(FaseSessione.bloccata);
    _contabilita = null;
    _costoVita = null;
    _pianificatore = null;
    _carte = null;
    _prestiti = null;
    _notifiche = null;
    _obiettivi = null;
    _statistiche = null;
    _report = null;
    _sync?.chiudi();
    _sync = null;
    _archivio = null;
    _dek = null;
    await archivio?.close();
    dek?.dispose();
  }

  @override
  void dispose() {
    annullaNuovoArchivio();
    _archivio?.close();
    _dek?.dispose();
    super.dispose();
  }

  // ------------------------------------------------- archivio da Google Drive

  /// Lo spazio su Google Drive, con il consenso dell'utente (`null` se
  /// annullato). Serve per collegare un dispositivo nuovo.
  Future<SyncBackend?> spazioRemoto() async {
    final client = await accessoGoogle.client(interattivo: true);
    return client == null ? null : _creaBackend(client);
  }

  /// Apre qui l'archivio che c'è su Drive, con la sua password. L'eventuale
  /// archivio di questo dispositivo viene messo da parte (non cancellato).
  /// Lancia `PasswordErrataException` se la password non è giusta.
  Future<void> apriArchivioRemoto(SyncBackend remoto, String password) async {
    final keyring = await _keyringRemoto(remoto);
    final dek = await OperazioniChiavi.apriConPassword(
      sodium,
      keyring,
      password,
    );
    await _usaRemoto(
      remoto,
      keyring,
      dek,
      'Archivio scaricato da Google Drive',
    );
  }

  /// Come [apriArchivioRemoto], con la Secret Key e una password nuova (che
  /// arriva anche agli altri dispositivi).
  Future<void> apriArchivioRemotoConSecretKey(
    SyncBackend remoto,
    String testoSecretKey,
    String nuovaPassword,
  ) async {
    final recuperato = await OperazioniChiavi.recupera(
      sodium,
      await _keyringRemoto(remoto),
      testoSecretKey,
      nuovaPassword,
      costo: costoArgon2,
    );
    await _usaRemoto(
      remoto,
      recuperato.keyring,
      recuperato.dek,
      'Archivio scaricato da Google Drive · nuova password impostata',
    );
  }

  Future<Uint8List> _keyringRemoto(SyncBackend remoto) async {
    final keyring = await Sincronizzatore.keyringRemoto(remoto);
    if (keyring == null) {
      throw const NessunArchivioRemoto();
    }
    return keyring;
  }

  Future<void> _usaRemoto(
    SyncBackend remoto,
    Uint8List keyring,
    SecureKey dek,
    String messaggio,
  ) async {
    // Il consenso di Google resta valido anche con l'archivio nuovo.
    final credenziali = await _credenzialiGoogle.leggi();
    if (_fase == FaseSessione.sbloccata) {
      await blocca();
    }
    await _credenzialiGoogle.scrivi(credenziali);
    await deposito.metteDaParteArchivio();
    await deposito.scriviKeyring(keyring);
    await _dopoPassword(archivioNuovo: true);
    final id = Keyring.deserializza(keyring).idArchivio;
    await _apri(
      dek,
      id,
      messaggio,
      prima: (archivio, orologio) async {
        // Accesa prima di scaricare: se si interrompe, riprende da sola.
        await archivio
            .into(archivio.impostazioni)
            .insertOnConflictUpdate(
              ImpostazioniCompanion.insert(
                chiave: 'sincronizzazione.attiva',
                valore: '1',
              ),
            );
        final sincronizzatore = Sincronizzatore(
          db: archivio,
          orologio: orologio,
          sodium: sodium,
          dek: dek,
          idArchivio: id,
          backend: remoto,
          leggiKeyring: deposito.leggiKeyring,
          scriviKeyring: deposito.scriviKeyring,
        );
        try {
          await sincronizzatore.scaricaTutto();
        } finally {
          sincronizzatore.chiudi();
        }
      },
    );
  }

  /// [prima]: lavoro sull'archivio appena aperto, prima di scadenze e report
  /// (es. scaricare i dati da Drive).
  Future<void> _apri(
    SecureKey dek,
    String idArchivio,
    String messaggio, {
    Future<void> Function(Archivio archivio, OrologioLogico orologio)? prima,
  }) async {
    final Archivio archivio;
    try {
      archivio = Archivio.apri(deposito.fileArchivio, sodium, dek);
    } catch (_) {
      dek.dispose();
      rethrow;
    }
    try {
      _contabilita = await Contabilita.apri(archivio);
      _pianificatore = Pianificatore(archivio, _contabilita!.orologio);
      _carte = CarteCreditoServizio(
        archivio,
        _contabilita!.orologio,
        _pianificatore!,
      );
      _prestiti = PrestitiServizio(
        archivio,
        _contabilita!.orologio,
        _pianificatore!,
      );
      _notifiche = NotificheServizio(
        archivio,
        _contabilita!.orologio,
        _pianificatore!,
        _prestiti!,
      );
      _obiettivi = ObiettiviServizio(archivio, _contabilita!.orologio);
      _statistiche = StatisticheServizio(archivio);
      _costoVita = CostoVita(archivio, _contabilita!.orologio, _pianificatore!);
      _report = ReportAutomatici(
        archivio,
        _contabilita!.orologio,
        _costoVita!,
        _statistiche!,
      );
      if (prima != null) {
        await prima(archivio, _contabilita!.orologio);
      }
    } catch (_) {
      await archivio.close();
      dek.dispose();
      rethrow;
    }
    _archivio = archivio;
    await _credenzialiGoogle.salvaInSospeso(archivio);
    final sync = Sincronizzazione(
      db: archivio,
      orologio: _contabilita!.orologio,
      sodium: sodium,
      dek: dek,
      idArchivio: idArchivio,
      accesso: accessoGoogle,
      leggiKeyring: deposito.leggiKeyring,
      scriviKeyring: deposito.scriviKeyring,
      creaBackend: _creaBackend,
    );
    _sync = sync;
    await sync.carica();
    // Scadenze arrivate mentre l'app era chiusa: si registrano subito.
    final registrati = await _pianificatore!.registraScadute();
    if (registrati > 0) {
      messaggio =
          '$messaggio · registrat${registrati == 1 ? 'o 1 pagamento programmato' : 'i $registrati pagamenti programmati'}';
    }
    // Report dei mesi e degli anni conclusi. Un errore qui non deve impedire
    // di aprire l'archivio: si riproverà alla prossima apertura.
    try {
      await _report!.aggiorna();
    } catch (e) {
      debugPrint('Report automatici non aggiornati: $e');
    }
    _dek = dek;
    _idArchivio = idArchivio;
    avviso = messaggio;
    _cambia(FaseSessione.sbloccata);
    // Le novità degli altri dispositivi, appena aperto (senza aspettare).
    unawaited(sync.sincronizza());
  }

  void _cambia(FaseSessione fase) {
    _fase = fase;
    notifyListeners();
  }
}

/// Su Google Drive non c'è ancora un archivio da scaricare.
class NessunArchivioRemoto implements Exception {
  const NessunArchivioRemoto();

  @override
  String toString() =>
      'Su Google Drive non c\'è ancora un archivio: crealo sull\'altro '
      'dispositivo e accendi lì la sincronizzazione.';
}

/// Le credenziali di Google (Windows) nell'archivio cifrato, solo su questo
/// dispositivo. Ad archivio chiuso restano in memoria e si salvano appena si
/// apre.
class _CredenzialiNellArchivio implements CredenzialiGoogle {
  _CredenzialiNellArchivio(this._sessione);

  static const _chiave = 'google.credenziali';

  final Sessione _sessione;
  String? _inSospeso;
  bool _daSalvare = false;

  @override
  Future<String?> leggi() async {
    final db = _sessione._archivio;
    if (db == null || _daSalvare) {
      return _inSospeso;
    }
    return (await (db.select(
      db.impostazioni,
    )..where((i) => i.chiave.equals(_chiave))).getSingleOrNull())?.valore;
  }

  @override
  Future<void> scrivi(String? json) async {
    final db = _sessione._archivio;
    if (db == null) {
      _inSospeso = json;
      _daSalvare = true;
      return;
    }
    await _salva(db, json);
  }

  Future<void> salvaInSospeso(Archivio db) async {
    if (_daSalvare) {
      _daSalvare = false;
      await _salva(db, _inSospeso);
      _inSospeso = null;
    }
  }

  static Future<void> _salva(Archivio db, String? json) => json == null
      ? (db.delete(
          db.impostazioni,
        )..where((i) => i.chiave.equals(_chiave))).go()
      : db
            .into(db.impostazioni)
            .insertOnConflictUpdate(
              ImpostazioniCompanion.insert(chiave: _chiave, valore: json),
            );
}
