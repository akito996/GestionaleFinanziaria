import 'dart:convert';
import 'dart:typed_data';

import 'package:sodium/sodium_sumo.dart';

import 'cifratura.dart';
import 'derivazione.dart';
import 'eccezioni.dart';
import 'secret_key.dart';

/// Keyring (`keyring.bin`): la chiave dei dati (DEK) avvolta due volte,
/// con la password principale (Argon2id → KEK) e con la Secret Key.
///
/// Non contiene segreti in chiaro: può stare nel cloud. Chi lo legge senza
/// password né Secret Key non ottiene nulla.
class Keyring {
  const Keyring._({
    required this.idArchivio,
    required this.argon2,
    required this._dekDaPassword,
    required this._dekDaSecretKey,
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
    final id = json['id'];
    final argon2 = json['argon2'];
    final daPassword = json['dek_password'];
    final daSecretKey = json['dek_secret_key'];
    if (id is! String ||
        argon2 is! Map<String, Object?> ||
        daPassword is! String ||
        daSecretKey is! String) {
      throw const DatiNonValidiException();
    }
    return Keyring._(
      idArchivio: id,
      argon2: ParametriArgon2.daJson(argon2),
      dekDaPassword: base64.decode(daPassword),
      dekDaSecretKey: base64.decode(daSecretKey),
    );
  }

  static const int versioneCorrente = 1;

  /// Identificativo pubblico dell'archivio (es. `GF-7K3P-Q9XW`).
  final String idArchivio;
  final ParametriArgon2 argon2;
  final Uint8List _dekDaPassword;
  final Uint8List _dekDaSecretKey;

  /// Primo avvio: nuovo ID, nuova DEK casuale e nuova Secret Key da far salvare all'utente.
  static ({Keyring keyring, SecureKey dek, SecretKey secretKey}) crea(
    SodiumSumo sodium,
    String password, {
    ParametriArgon2? parametri,
  }) {
    final dek = Cifratore(sodium).nuovaChiave();
    final secretKey = SecretKey.genera(sodium);
    final idArchivio = nuovoIdArchivio(sodium);
    final argon2 = parametri ?? ParametriArgon2.nuovi(sodium);
    final keyring = Keyring._(
      idArchivio: idArchivio,
      argon2: argon2,
      dekDaPassword: _avvolgiConPassword(
        sodium,
        dek,
        password,
        argon2,
        idArchivio,
      ),
      dekDaSecretKey: _avvolgiConSecretKey(sodium, dek, secretKey, idArchivio),
    );
    return (keyring: keyring, dek: dek, secretKey: secretKey);
  }

  SecureKey apriConPassword(SodiumSumo sodium, String password) {
    final kek = argon2.derivaChiave(sodium, password);
    try {
      return _svolgi(
        sodium,
        _dekDaPassword,
        kek,
        _aadPassword(argon2, idArchivio),
      );
    } on DatiNonValidiException {
      throw const PasswordErrataException();
    } finally {
      kek.dispose();
    }
  }

  SecureKey apriConSecretKey(SodiumSumo sodium, SecretKey secretKey) {
    final chiave = secretKey.chiaveDiAvvolgimento(sodium);
    try {
      return _svolgi(
        sodium,
        _dekDaSecretKey,
        chiave,
        _aadSecretKey(idArchivio),
      );
    } on DatiNonValidiException {
      throw SecretKeyNonValidaException(
        'Questa Secret Key non è dell\'archivio $idArchivio.',
      );
    } finally {
      chiave.dispose();
    }
  }

  /// Cambio password: nuovo sale e nuovi parametri, la Secret Key resta valida.
  Keyring conNuovaPassword(
    SodiumSumo sodium,
    SecureKey dek,
    String nuovaPassword, {
    ParametriArgon2? parametri,
  }) {
    final nuoviParametri = parametri ?? ParametriArgon2.nuovi(sodium);
    return Keyring._(
      idArchivio: idArchivio,
      argon2: nuoviParametri,
      dekDaPassword: _avvolgiConPassword(
        sodium,
        dek,
        nuovaPassword,
        nuoviParametri,
        idArchivio,
      ),
      dekDaSecretKey: _dekDaSecretKey,
    );
  }

  /// Nuova Secret Key (es. quella vecchia è stata esposta): la precedente smette di funzionare.
  ({Keyring keyring, SecretKey secretKey}) conNuovaSecretKey(
    SodiumSumo sodium,
    SecureKey dek,
  ) {
    final secretKey = SecretKey.genera(sodium);
    return (
      keyring: Keyring._(
        idArchivio: idArchivio,
        argon2: argon2,
        dekDaPassword: _dekDaPassword,
        dekDaSecretKey: _avvolgiConSecretKey(
          sodium,
          dek,
          secretKey,
          idArchivio,
        ),
      ),
      secretKey: secretKey,
    );
  }

  Uint8List serializza() => utf8.encode(
    jsonEncode({
      'v': versioneCorrente,
      'id': idArchivio,
      'argon2': argon2.toJson(),
      'dek_password': base64.encode(_dekDaPassword),
      'dek_secret_key': base64.encode(_dekDaSecretKey),
    }),
  );

  static Uint8List _avvolgiConPassword(
    SodiumSumo sodium,
    SecureKey dek,
    String password,
    ParametriArgon2 argon2,
    String idArchivio,
  ) {
    final kek = argon2.derivaChiave(sodium, password);
    try {
      return _avvolgi(sodium, dek, kek, _aadPassword(argon2, idArchivio));
    } finally {
      kek.dispose();
    }
  }

  static Uint8List _avvolgiConSecretKey(
    SodiumSumo sodium,
    SecureKey dek,
    SecretKey secretKey,
    String idArchivio,
  ) {
    final chiave = secretKey.chiaveDiAvvolgimento(sodium);
    try {
      return _avvolgi(sodium, dek, chiave, _aadSecretKey(idArchivio));
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

  /// L'AAD include ID archivio e parametri Argon2: chi li altera nel file fa fallire l'apertura.
  static Uint8List _aadPassword(ParametriArgon2 argon2, String idArchivio) =>
      utf8.encode(
        'gf-keyring|v$versioneCorrente|$idArchivio|password|'
        '${jsonEncode(argon2.toJson())}',
      );

  static Uint8List _aadSecretKey(String idArchivio) =>
      utf8.encode('gf-keyring|v$versioneCorrente|$idArchivio|secret-key');
}
