import 'dart:isolate';
import 'dart:typed_data';

import 'package:sodium/sodium_sumo.dart';

import 'derivazione.dart';
import 'keyring.dart';
import 'secret_key.dart';

/// Costo di Argon2id: passaggi e memoria in byte.
typedef CostoArgon2 = ({int ops, int mem});

const CostoArgon2 costoArgon2Predefinito = (
  ops: ParametriArgon2.opsPredefinito,
  mem: ParametriArgon2.memPredefinita,
);

/// Nuovo archivio appena creato: da salvare solo dopo che l'utente ha messo al sicuro
/// la Secret Key.
typedef ArchivioCreato = ({
  Uint8List keyring,
  SecureKey dek,
  String idArchivio,
  String secretKey,
});

/// Operazioni sul keyring che usano Argon2id (lente per scelta): girano in un isolate
/// separato, così l'interfaccia resta fluida. La chiave dei dati torna al chiamante
/// come [SecureKey] (memoria protetta di libsodium).
abstract final class OperazioniChiavi {
  static Future<ArchivioCreato> crea(
    SodiumSumo sodium,
    String password, {
    CostoArgon2 costo = costoArgon2Predefinito,
  }) async {
    final (keyring, dek, id, testo) = await Isolate.run(() {
      final creato = Keyring.crea(
        sodium,
        password,
        parametri: ParametriArgon2.nuovi(
          sodium,
          opsLimit: costo.ops,
          memLimit: costo.mem,
        ),
      );
      final testo = creato.secretKey.testo;
      creato.secretKey.cancella();
      return (
        creato.keyring.serializza(),
        _trasferibile(sodium, creato.dek),
        creato.keyring.idArchivio,
        testo,
      );
    });
    return (
      keyring: keyring,
      dek: sodium.materializeTransferrableSecureKey(dek),
      idArchivio: id,
      secretKey: testo,
    );
  }

  static Future<SecureKey> apriConPassword(
    SodiumSumo sodium,
    Uint8List keyring,
    String password,
  ) async {
    final dek = await Isolate.run(
      () => _trasferibile(
        sodium,
        Keyring.deserializza(keyring).apriConPassword(sodium, password),
      ),
    );
    return sodium.materializeTransferrableSecureKey(dek);
  }

  /// Password dimenticata: apre con la Secret Key e imposta una nuova password.
  /// La Secret Key resta la stessa.
  static Future<({Uint8List keyring, SecureKey dek})> recupera(
    SodiumSumo sodium,
    Uint8List keyring,
    String testoSecretKey,
    String nuovaPassword, {
    CostoArgon2 costo = costoArgon2Predefinito,
  }) async {
    // Controllo veloce del formato prima del lavoro pesante (errori immediati).
    SecretKey.daTesto(testoSecretKey).cancella();

    final (nuovoKeyring, dek) = await Isolate.run(() {
      final vecchio = Keyring.deserializza(keyring);
      final secretKey = SecretKey.daTesto(testoSecretKey);
      final dek = vecchio.apriConSecretKey(sodium, secretKey);
      secretKey.cancella();
      final nuovo = vecchio.conNuovaPassword(
        sodium,
        dek,
        nuovaPassword,
        parametri: ParametriArgon2.nuovi(
          sodium,
          opsLimit: costo.ops,
          memLimit: costo.mem,
        ),
      );
      return (nuovo.serializza(), _trasferibile(sodium, dek));
    });
    return (
      keyring: nuovoKeyring,
      dek: sodium.materializeTransferrableSecureKey(dek),
    );
  }

  static TransferrableSecureKey _trasferibile(Sodium sodium, SecureKey chiave) {
    try {
      return sodium.createTransferrableSecureKey(chiave);
    } finally {
      chiave.dispose();
    }
  }
}
