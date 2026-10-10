import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:sodium/sodium.dart';

import 'eccezioni.dart';
import 'parole_bip39_it.dart';

/// Recovery Key: 24 parole (standard BIP-39, lista italiana) = 256 bit casuali + 8 bit di controllo.
///
/// Serve a riaprire i dati se si perde la password principale. Non viene mai salvata
/// dall'app: l'utente la scrive su carta (o nel suo password manager).
class RecoveryKey {
  RecoveryKey._(this._entropia);

  factory RecoveryKey.genera(Sodium sodium) =>
      RecoveryKey._(sodium.randombytes.buf(_byteEntropia));

  /// Legge le parole scritte dall'utente: maiuscole, spazi e a capo non contano;
  /// bastano le prime 4 lettere di ogni parola (sono univoche nella lista).
  factory RecoveryKey.daParole(String testo) {
    final parole = testo
        .toLowerCase()
        .split(RegExp(r'[\s,;.\-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parole.length != numeroParole) {
      throw RecoveryKeyNonValidaException(
        'Servono $numeroParole parole, ne hai scritte ${parole.length}.',
      );
    }

    final bit = StringBuffer();
    for (var i = 0; i < parole.length; i++) {
      final indice = _indiceDi(parole[i]);
      if (indice == null) {
        throw RecoveryKeyNonValidaException(
          'La parola n. ${i + 1} ("${parole[i]}") non fa parte della lista.',
        );
      }
      bit.write(indice.toRadixString(2).padLeft(_bitPerParola, '0'));
    }

    final tuttiBit = bit.toString();
    final entropia = Uint8List(_byteEntropia);
    for (var i = 0; i < _byteEntropia; i++) {
      entropia[i] = int.parse(tuttiBit.substring(i * 8, i * 8 + 8), radix: 2);
    }
    if (tuttiBit.substring(_byteEntropia * 8) != _bitControllo(entropia)) {
      throw const RecoveryKeyNonValidaException(
        'Le parole non sono corrette: controlla di averle copiate tutte e nell\'ordine giusto.',
      );
    }
    return RecoveryKey._(entropia);
  }

  /// Solo per i test: Recovery Key da 32 byte noti.
  factory RecoveryKey.daEntropia(Uint8List entropia) {
    if (entropia.length != _byteEntropia) {
      throw ArgumentError.value(entropia.length, 'entropia', 'servono 32 byte');
    }
    return RecoveryKey._(Uint8List.fromList(entropia));
  }

  static const int numeroParole = 24;

  static const int _byteEntropia = 32;
  static const int _bitPerParola = 11;

  /// Contesto KDF (8 byte esatti): separa questa chiave da ogni altro uso dell'entropia.
  static const String _contestoKdf = 'GFrecov1';

  static final Map<String, int> _perPrefisso = {
    for (var i = 0; i < paroleBip39It.length; i++)
      paroleBip39It[i].substring(0, 4): i,
  };

  final Uint8List _entropia;

  List<String> get parole {
    final bit =
        _entropia.map((b) => b.toRadixString(2).padLeft(8, '0')).join() +
        _bitControllo(_entropia);
    return [
      for (var i = 0; i < bit.length; i += _bitPerParola)
        paroleBip39It[int.parse(bit.substring(i, i + _bitPerParola), radix: 2)],
    ];
  }

  /// Chiave da 256 bit che avvolge la chiave dei dati nel keyring.
  SecureKey chiaveDiAvvolgimento(Sodium sodium) {
    final master = SecureKey.fromList(sodium, _entropia);
    try {
      return sodium.crypto.kdf.deriveFromKey(
        masterKey: master,
        context: _contestoKdf,
        subkeyId: BigInt.one,
        subkeyLen: 32,
      );
    } finally {
      master.dispose();
    }
  }

  /// Azzera l'entropia in memoria quando non serve più.
  void cancella() => _entropia.fillRange(0, _entropia.length, 0);

  static int? _indiceDi(String parola) {
    if (parola.length < 4) {
      return null;
    }
    final indice = _perPrefisso[parola.substring(0, 4)];
    if (indice == null || !paroleBip39It[indice].startsWith(parola)) {
      return null;
    }
    return indice;
  }

  /// Primi 8 bit dello SHA-256 dell'entropia (256 / 32), come da BIP-39.
  static String _bitControllo(Uint8List entropia) =>
      sha256.convert(entropia).bytes[0].toRadixString(2).padLeft(8, '0');
}
