import 'package:flutter/foundation.dart';
import 'package:sodium/sodium_sumo.dart';

import 'crypto/operazioni_chiavi.dart';
import 'db/archivio.dart';
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

  SecureKey? _dek;

  /// Archivio nuovo in preparazione: salvato solo dopo la verifica della Recovery Key.
  ({Uint8List keyring, SecureKey dek})? _inPreparazione;

  Future<void> avvia() async {
    _cambia(
      await deposito.esisteKeyring()
          ? FaseSessione.bloccata
          : FaseSessione.primoAvvio,
    );
  }

  /// Primo passo del primo avvio: protegge la password e genera la Recovery Key.
  /// Restituisce le 24 parole da mostrare. Su disco non viene ancora scritto nulla.
  Future<List<String>> preparaNuovoArchivio(String password) async {
    annullaNuovoArchivio();
    final creato = await OperazioniChiavi.crea(
      sodium,
      password,
      costo: costoArgon2,
    );
    _inPreparazione = (keyring: creato.keyring, dek: creato.dek);
    return creato.parole;
  }

  void annullaNuovoArchivio() {
    _inPreparazione?.dek.dispose();
    _inPreparazione = null;
  }

  /// Recovery Key verificata: salva il keyring, crea il database e apre l'archivio.
  Future<void> confermaNuovoArchivio() async {
    final pronto = _inPreparazione;
    if (pronto == null) {
      throw StateError('Nessun archivio in preparazione.');
    }
    _inPreparazione = null;
    await deposito.metteDaParteArchivioOrfano();
    await deposito.scriviKeyring(pronto.keyring);
    _apri(pronto.dek);
  }

  /// Lancia `PasswordErrataException` se la password non è giusta.
  Future<void> sblocca(String password) async {
    final dek = await OperazioniChiavi.apriConPassword(
      sodium,
      await deposito.leggiKeyring(),
      password,
    );
    _apri(dek);
  }

  /// Password dimenticata: Recovery Key + nuova password.
  /// Lancia `RecoveryKeyNonValidaException` se le parole non sono giuste.
  Future<void> recupera(String paroleRecovery, String nuovaPassword) async {
    final recuperato = await OperazioniChiavi.recupera(
      sodium,
      await deposito.leggiKeyring(),
      paroleRecovery,
      nuovaPassword,
      costo: costoArgon2,
    );
    await deposito.scriviKeyring(recuperato.keyring);
    _apri(recuperato.dek);
  }

  Future<void> blocca() async {
    await _archivio?.close();
    _archivio = null;
    _dek?.dispose();
    _dek = null;
    _cambia(FaseSessione.bloccata);
  }

  @override
  void dispose() {
    annullaNuovoArchivio();
    _archivio?.close();
    _dek?.dispose();
    super.dispose();
  }

  void _apri(SecureKey dek) {
    try {
      _archivio = Archivio.apri(deposito.fileArchivio, sodium, dek);
    } catch (_) {
      dek.dispose();
      rethrow;
    }
    _dek = dek;
    _cambia(FaseSessione.sbloccata);
  }

  void _cambia(FaseSessione fase) {
    _fase = fase;
    notifyListeners();
  }
}
