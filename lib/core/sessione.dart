import 'package:flutter/foundation.dart';
import 'package:sodium/sodium_sumo.dart';

import 'crypto/keyring.dart';
import 'crypto/operazioni_chiavi.dart';
import 'crypto/secret_key.dart';
import 'db/archivio.dart';
import 'db/contabilita.dart';
import 'db/costo_vita.dart';
import 'db/deposito_locale.dart';

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
  });

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

  SecureKey? _dek;

  String? _idArchivio;

  /// ID pubblico dell'archivio aperto (es. `GF-7K3P-Q9XW`).
  String? get idArchivio => _idArchivio;

  /// Messaggio di conferma da mostrare una volta all'apertura (es. "Archivio sbloccato").
  String? avviso;

  /// Archivio nuovo in preparazione: salvato solo dopo la verifica della Secret Key.
  ArchivioCreato? _inPreparazione;

  Future<void> avvia() async {
    _cambia(
      await deposito.esisteKeyring()
          ? FaseSessione.bloccata
          : FaseSessione.primoAvvio,
    );
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
    await _apri(
      dek,
      Keyring.deserializza(keyring).idArchivio,
      'Archivio sbloccato',
    );
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
    await _apri(
      recuperato.dek,
      Keyring.deserializza(recuperato.keyring).idArchivio,
      'Nuova password impostata: archivio sbloccato',
    );
  }

  Future<void> blocca() async {
    _contabilita = null;
    _costoVita = null;
    await _archivio?.close();
    _archivio = null;
    _dek?.dispose();
    _dek = null;
    _idArchivio = null;
    avviso = null;
    _cambia(FaseSessione.bloccata);
  }

  @override
  void dispose() {
    annullaNuovoArchivio();
    _archivio?.close();
    _dek?.dispose();
    super.dispose();
  }

  Future<void> _apri(SecureKey dek, String idArchivio, String messaggio) async {
    final Archivio archivio;
    try {
      archivio = Archivio.apri(deposito.fileArchivio, sodium, dek);
    } catch (_) {
      dek.dispose();
      rethrow;
    }
    try {
      _contabilita = await Contabilita.apri(archivio);
      _costoVita = CostoVita(archivio, _contabilita!.orologio);
    } catch (_) {
      await archivio.close();
      dek.dispose();
      rethrow;
    }
    _archivio = archivio;
    _dek = dek;
    _idArchivio = idArchivio;
    avviso = messaggio;
    _cambia(FaseSessione.sbloccata);
  }

  void _cambia(FaseSessione fase) {
    _fase = fase;
    notifyListeners();
  }
}
