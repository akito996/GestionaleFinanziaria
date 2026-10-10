import 'dart:convert';
import 'dart:typed_data';

import 'package:sodium/sodium_sumo.dart';

import 'cifratura.dart';
import 'eccezioni.dart';

/// Parametri Argon2id per trasformare la password principale in una chiave (KEK).
/// Sono salvati nel keyring insieme al sale, così ogni dispositivo ottiene la stessa chiave.
class ParametriArgon2 {
  const ParametriArgon2({
    required this.sale,
    required this.opsLimit,
    required this.memLimit,
  });

  /// Nuovi parametri con sale casuale. Valori predefiniti: 3 passaggi, 64 MiB.
  factory ParametriArgon2.nuovi(
    SodiumSumo sodium, {
    int opsLimit = opsPredefinito,
    int memLimit = memPredefinita,
  }) {
    final parametri = ParametriArgon2(
      sale: sodium.randombytes.buf(sodium.crypto.pwhash.saltBytes),
      opsLimit: opsLimit,
      memLimit: memLimit,
    );
    parametri.verificaMinimi();
    return parametri;
  }

  factory ParametriArgon2.daJson(Map<String, Object?> json) {
    final algoritmo = json['alg'];
    final sale = json['sale'];
    final ops = json['ops'];
    final mem = json['mem'];
    if (algoritmo != nomeAlgoritmo ||
        sale is! String ||
        ops is! int ||
        mem is! int) {
      throw const DatiNonValidiException();
    }
    final parametri = ParametriArgon2(
      sale: base64.decode(sale),
      opsLimit: ops,
      memLimit: mem,
    );
    parametri.verificaMinimi();
    return parametri;
  }

  static const String nomeAlgoritmo = 'argon2id13';

  static const int opsPredefinito = 3;
  static const int memPredefinita = 64 * 1024 * 1024;

  /// Minimi accettati (raccomandazione OWASP per Argon2id: 19 MiB, 2 passaggi).
  /// Un keyring con valori più bassi viene rifiutato: protegge dal "downgrade".
  static const int opsMinimo = 2;
  static const int memMinima = 19 * 1024 * 1024;

  static const int _lunghezzaSale = 16;

  final Uint8List sale;
  final int opsLimit;
  final int memLimit;

  void verificaMinimi() {
    if (sale.length != _lunghezzaSale) {
      throw const ParametriNonSicuriException('Sale di lunghezza non valida.');
    }
    if (opsLimit < opsMinimo || memLimit < memMinima) {
      throw const ParametriNonSicuriException(
        'Parametri della password più deboli del minimo di sicurezza.',
      );
    }
  }

  Map<String, Object> toJson() => {
    'alg': nomeAlgoritmo,
    'sale': base64.encode(sale),
    'ops': opsLimit,
    'mem': memLimit,
  };

  /// Chiave da 256 bit derivata dalla password con Argon2id.
  ///
  /// Operazione volutamente lenta (centinaia di ms): nell'interfaccia va eseguita
  /// fuori dal thread grafico (`Sodium.runIsolated`).
  SecureKey derivaChiave(SodiumSumo sodium, String password) {
    if (password.isEmpty) {
      throw ArgumentError.value('', 'password', 'vuota');
    }
    verificaMinimi();
    return sodium.crypto.pwhash.callStr(
      outLen: Cifratore.lunghezzaChiave,
      password: password,
      salt: sale,
      opsLimit: opsLimit,
      memLimit: memLimit,
      alg: CryptoPwhashAlgorithm.argon2id13,
    );
  }
}
