import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:sodium/sodium.dart';

import 'eccezioni.dart';

/// Secret Key: 256 bit casuali che riaprono l'archivio se si dimentica la password.
///
/// Formato testo (v1): `GF1-XXXXX-XXXXX-…` = 32 byte + 2 byte di controllo (SHA-256)
/// in Base32 Crockford: niente caratteri ambigui, maiuscole/minuscole e trattini
/// non contano, O/I/L vengono letti come 0/1/1. Il prefisso `GF1` è la versione del formato.
///
/// L'app non la salva mai: l'utente la conserva come file o testo.
class SecretKey {
  SecretKey._(this._entropia);

  factory SecretKey.genera(Sodium sodium) =>
      SecretKey._(sodium.randombytes.buf(_byteEntropia));

  /// Legge la Secret Key incollata o letta da un file: il testo può contenere
  /// altre righe (es. il file completo), viene cercata la riga con il prefisso `GF1`.
  factory SecretKey.daTesto(String testo) {
    final riga = RegExp(
      // Solo sulla stessa riga: spazi, tabulazioni e trattini sono ammessi.
      r'GF1[ \t-]*([0-9A-Za-z][0-9A-Za-z \t-]*)',
      caseSensitive: false,
    ).firstMatch(testo);
    if (riga == null) {
      throw const SecretKeyNonValidaException(
        'Non trovo una Secret Key: deve iniziare con "GF1-".',
      );
    }
    final simboli = riga
        .group(1)!
        .toUpperCase()
        .replaceAll(RegExp(r'[\s-]'), '')
        .replaceAll('O', '0')
        .replaceAll(RegExp('[IL]'), '1');
    if (simboli.length != _lunghezzaSimboli) {
      throw const SecretKeyNonValidaException(
        'La Secret Key è incompleta o ha caratteri in più: copiala di nuovo per intero.',
      );
    }
    final byte = _decodifica(simboli);
    if (byte == null) {
      throw const SecretKeyNonValidaException(
        'La Secret Key contiene caratteri non validi.',
      );
    }
    final entropia = Uint8List.sublistView(byte, 0, _byteEntropia);
    final controllo = Uint8List.sublistView(byte, _byteEntropia);
    if (!_uguali(controllo, _controllo(entropia))) {
      throw const SecretKeyNonValidaException(
        'La Secret Key contiene un errore di battitura: copiala di nuovo.',
      );
    }
    return SecretKey._(Uint8List.fromList(entropia));
  }

  /// Solo per i test: Secret Key da 32 byte noti.
  factory SecretKey.daEntropia(Uint8List entropia) {
    if (entropia.length != _byteEntropia) {
      throw ArgumentError.value(entropia.length, 'entropia', 'servono 32 byte');
    }
    return SecretKey._(Uint8List.fromList(entropia));
  }

  static const String prefisso = 'GF1';

  static const int _byteEntropia = 32;
  static const int _byteControllo = 2;
  static const int _lunghezzaSimboli =
      55; // (32 + 2) * 8 / 5, arrotondato per eccesso
  static const int _gruppo = 5;

  /// Contesto KDF (8 byte esatti): separa questa chiave da ogni altro uso dell'entropia.
  static const String _contestoKdf = 'GFrecov1';

  static const String alfabeto = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  final Uint8List _entropia;

  /// Testo da mostrare, salvare o copiare: `GF1-XXXXX-XXXXX-…`.
  String get testo {
    final simboli = _codifica(
      Uint8List.fromList([..._entropia, ..._controllo(_entropia)]),
    );
    final gruppi = [
      for (var i = 0; i < simboli.length; i += _gruppo)
        simboli.substring(i, i + _gruppo),
    ];
    return '$prefisso-${gruppi.join('-')}';
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

  static Uint8List _controllo(Uint8List entropia) => Uint8List.fromList(
    sha256.convert(entropia).bytes.sublist(0, _byteControllo),
  );

  static String _codifica(Uint8List byte) {
    final out = StringBuffer();
    var buffer = 0;
    var bit = 0;
    for (final b in byte) {
      buffer = (buffer << 8) | b;
      bit += 8;
      while (bit >= 5) {
        bit -= 5;
        out.write(alfabeto[(buffer >> bit) & 0x1F]);
      }
      buffer &= (1 << bit) - 1;
    }
    if (bit > 0) {
      out.write(alfabeto[(buffer << (5 - bit)) & 0x1F]);
    }
    return out.toString();
  }

  static Uint8List? _decodifica(String simboli) {
    final out = BytesBuilder();
    var buffer = 0;
    var bit = 0;
    for (final c in simboli.split('')) {
      final valore = alfabeto.indexOf(c);
      if (valore < 0) {
        return null;
      }
      buffer = (buffer << 5) | valore;
      bit += 5;
      if (bit >= 8) {
        bit -= 8;
        out.addByte((buffer >> bit) & 0xFF);
      }
      buffer &= (1 << bit) - 1;
    }
    // I bit avanzati (riempimento) devono essere zero.
    if (buffer != 0) {
      return null;
    }
    return out.toBytes();
  }

  static bool _uguali(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// ID dell'archivio, es. `GF-7K3P-Q9XW`: non è segreto, serve solo a riconoscere
/// a quale archivio appartiene una Secret Key (nel file e nelle impostazioni).
String nuovoIdArchivio(Sodium sodium) {
  final byte = sodium.randombytes.buf(5);
  var valore = 0;
  for (final b in byte) {
    valore = (valore << 8) | b;
  }
  final simboli = StringBuffer();
  for (var i = 7; i >= 0; i--) {
    simboli.write(SecretKey.alfabeto[(valore >> (i * 5)) & 0x1F]);
  }
  final s = simboli.toString();
  return 'GF-${s.substring(0, 4)}-${s.substring(4)}';
}
