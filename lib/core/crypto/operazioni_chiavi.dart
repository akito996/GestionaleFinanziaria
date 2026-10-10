import 'dart:isolate';
import 'dart:typed_data';

import 'package:sodium/sodium_sumo.dart';

import 'derivazione.dart';
import 'keyring.dart';
import 'recovery_key.dart';

/// Costo di Argon2id: passaggi e memoria in byte.
typedef CostoArgon2 = ({int ops, int mem});

const CostoArgon2 costoArgon2Predefinito = (
  ops: ParametriArgon2.opsPredefinito,
  mem: ParametriArgon2.memPredefinita,
);

/// Operazioni sul keyring che usano Argon2id (lente per scelta): girano in un isolate
/// separato, così l'interfaccia resta fluida. La chiave dei dati torna al chiamante
/// come [SecureKey] (memoria protetta di libsodium).
abstract final class OperazioniChiavi {
  /// Nuovo archivio: keyring da salvare, chiave dei dati e 24 parole da mostrare una volta.
  static Future<({Uint8List keyring, SecureKey dek, List<String> parole})> crea(
    SodiumSumo sodium,
    String password, {
    CostoArgon2 costo = costoArgon2Predefinito,
  }) async {
    final (keyring, dek, parole) = await Isolate.run(() {
      final creato = Keyring.crea(
        sodium,
        password,
        parametri: ParametriArgon2.nuovi(
          sodium,
          opsLimit: costo.ops,
          memLimit: costo.mem,
        ),
      );
      final parole = creato.recoveryKey.parole;
      creato.recoveryKey.cancella();
      return (
        creato.keyring.serializza(),
        _trasferibile(sodium, creato.dek),
        parole,
      );
    });
    return (
      keyring: keyring,
      dek: sodium.materializeTransferrableSecureKey(dek),
      parole: parole,
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

  /// Password dimenticata: apre con la Recovery Key e imposta una nuova password.
  /// La Recovery Key resta la stessa.
  static Future<({Uint8List keyring, SecureKey dek})> recupera(
    SodiumSumo sodium,
    Uint8List keyring,
    String paroleRecovery,
    String nuovaPassword, {
    CostoArgon2 costo = costoArgon2Predefinito,
  }) async {
    // Controllo veloce delle parole prima del lavoro pesante (errori immediati).
    RecoveryKey.daParole(paroleRecovery).cancella();

    final (nuovoKeyring, dek) = await Isolate.run(() {
      final vecchio = Keyring.deserializza(keyring);
      final recoveryKey = RecoveryKey.daParole(paroleRecovery);
      final dek = vecchio.apriConRecoveryKey(sodium, recoveryKey);
      recoveryKey.cancella();
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
