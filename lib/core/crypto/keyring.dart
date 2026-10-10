import 'dart:convert';
import 'dart:typed_data';

import 'package:sodium/sodium_sumo.dart';

import 'cifratura.dart';
import 'derivazione.dart';
import 'eccezioni.dart';
import 'recovery_key.dart';

/// Keyring (`keyring.bin` su Drive): la chiave dei dati (DEK) avvolta due volte,
/// con la password principale (Argon2id → KEK) e con la Recovery Key.
///
/// Non contiene segreti in chiaro: può stare nel cloud. Chi lo legge senza
/// password né Recovery Key non ottiene nulla.
class Keyring {
  const Keyring._({
    required this.argon2,
    required this._dekDaPassword,
    required this._dekDaRecovery,
  });

  factory Keyring.deserializza(Uint8List byte) {
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(byte));
    } on FormatException {
      throw const DatiNonValidiException();
    }
    if (json is! Map<String, Object?>) {
      throw const DatiNonValidiException();
    }
    final versione = json['v'];
    if (versione != versioneCorrente) {
      throw versione is int
          ? VersioneNonSupportataException(versione)
          : const DatiNonValidiException();
    }
    final argon2 = json['argon2'];
    final daPassword = json['dek_password'];
    final daRecovery = json['dek_recovery'];
    if (argon2 is! Map<String, Object?> ||
        daPassword is! String ||
        daRecovery is! String) {
      throw const DatiNonValidiException();
    }
    return Keyring._(
      argon2: ParametriArgon2.daJson(argon2),
      dekDaPassword: base64.decode(daPassword),
      dekDaRecovery: base64.decode(daRecovery),
    );
  }

  static const int versioneCorrente = 1;

  final ParametriArgon2 argon2;
  final Uint8List _dekDaPassword;
  final Uint8List _dekDaRecovery;

  /// Primo avvio: nuova DEK casuale e nuova Recovery Key da mostrare all'utente.
  static ({Keyring keyring, SecureKey dek, RecoveryKey recoveryKey}) crea(
    SodiumSumo sodium,
    String password, {
    ParametriArgon2? parametri,
  }) {
    final cifratore = Cifratore(sodium);
    final dek = cifratore.nuovaChiave();
    final recoveryKey = RecoveryKey.genera(sodium);
    final argon2 = parametri ?? ParametriArgon2.nuovi(sodium);
    final keyring = Keyring._(
      argon2: argon2,
      dekDaPassword: _avvolgiConPassword(sodium, dek, password, argon2),
      dekDaRecovery: _avvolgiConRecovery(sodium, dek, recoveryKey),
    );
    return (keyring: keyring, dek: dek, recoveryKey: recoveryKey);
  }

  SecureKey apriConPassword(SodiumSumo sodium, String password) {
    final kek = argon2.derivaChiave(sodium, password);
    try {
      return _svolgi(sodium, _dekDaPassword, kek, _aadPassword(argon2));
    } on DatiNonValidiException {
      throw const PasswordErrataException();
    } finally {
      kek.dispose();
    }
  }

  SecureKey apriConRecoveryKey(SodiumSumo sodium, RecoveryKey recoveryKey) {
    final chiave = recoveryKey.chiaveDiAvvolgimento(sodium);
    try {
      return _svolgi(sodium, _dekDaRecovery, chiave, _aadRecovery);
    } on DatiNonValidiException {
      throw const RecoveryKeyNonValidaException(
        'Questa Recovery Key non apre questo archivio.',
      );
    } finally {
      chiave.dispose();
    }
  }

  /// Cambio password: nuovo sale e nuovi parametri, la Recovery Key resta valida.
  Keyring conNuovaPassword(
    SodiumSumo sodium,
    SecureKey dek,
    String nuovaPassword, {
    ParametriArgon2? parametri,
  }) {
    final nuoviParametri = parametri ?? ParametriArgon2.nuovi(sodium);
    return Keyring._(
      argon2: nuoviParametri,
      dekDaPassword: _avvolgiConPassword(
        sodium,
        dek,
        nuovaPassword,
        nuoviParametri,
      ),
      dekDaRecovery: _dekDaRecovery,
    );
  }

  /// Nuova Recovery Key (es. quella vecchia è stata esposta): la precedente smette di funzionare.
  ({Keyring keyring, RecoveryKey recoveryKey}) conNuovaRecoveryKey(
    SodiumSumo sodium,
    SecureKey dek,
  ) {
    final recoveryKey = RecoveryKey.genera(sodium);
    return (
      keyring: Keyring._(
        argon2: argon2,
        dekDaPassword: _dekDaPassword,
        dekDaRecovery: _avvolgiConRecovery(sodium, dek, recoveryKey),
      ),
      recoveryKey: recoveryKey,
    );
  }

  Uint8List serializza() => utf8.encode(
    jsonEncode({
      'v': versioneCorrente,
      'argon2': argon2.toJson(),
      'dek_password': base64.encode(_dekDaPassword),
      'dek_recovery': base64.encode(_dekDaRecovery),
    }),
  );

  static Uint8List _avvolgiConPassword(
    SodiumSumo sodium,
    SecureKey dek,
    String password,
    ParametriArgon2 argon2,
  ) {
    final kek = argon2.derivaChiave(sodium, password);
    try {
      return _avvolgi(sodium, dek, kek, _aadPassword(argon2));
    } finally {
      kek.dispose();
    }
  }

  static Uint8List _avvolgiConRecovery(
    SodiumSumo sodium,
    SecureKey dek,
    RecoveryKey recoveryKey,
  ) {
    final chiave = recoveryKey.chiaveDiAvvolgimento(sodium);
    try {
      return _avvolgi(sodium, dek, chiave, _aadRecovery);
    } finally {
      chiave.dispose();
    }
  }

  static Uint8List _avvolgi(
    SodiumSumo sodium,
    SecureKey dek,
    SecureKey chiave,
    Uint8List aad,
  ) => dek.runUnlockedSync(
    (byte) => Cifratore(sodium).cifra(byte, chiave, aad: aad),
  );

  static SecureKey _svolgi(
    SodiumSumo sodium,
    Uint8List avvolta,
    SecureKey chiave,
    Uint8List aad,
  ) {
    final byte = Cifratore(sodium).decifra(avvolta, chiave, aad: aad);
    try {
      return SecureKey.fromList(sodium, byte);
    } finally {
      byte.fillRange(0, byte.length, 0);
    }
  }

  /// L'AAD include i parametri Argon2: chi li altera nel file fa fallire l'apertura.
  static Uint8List _aadPassword(ParametriArgon2 argon2) => utf8.encode(
    'gf-keyring|v$versioneCorrente|password|${jsonEncode(argon2.toJson())}',
  );

  static final Uint8List _aadRecovery = utf8.encode(
    'gf-keyring|v$versioneCorrente|recovery',
  );
}
