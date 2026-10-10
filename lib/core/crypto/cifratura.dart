import 'dart:typed_data';

import 'package:sodium/sodium.dart';

import 'eccezioni.dart';

/// Cifratura autenticata dei dati (crypto-agility: ogni blob dichiara la sua versione).
///
/// Formato del blob v1:
/// `[versione: 1 byte][nonce: 24 byte][testo cifrato + tag Poly1305: 16 byte]`
///
/// Il byte di versione fa parte dei dati autenticati: non si può cambiare senza far fallire
/// la decifratura. Il chiamante passa l'[aad] (vedi `aad.dart`), che lega il blob al suo
/// contesto: un blob spostato su un altro dispositivo o un'altra sequenza non si decifra.
class Cifratore {
  Cifratore(this._sodium);

  final Sodium _sodium;

  /// v1 = XChaCha20-Poly1305-IETF, nonce casuale da 24 byte.
  static const int versioneXChaCha20Poly1305 = 1;

  static const int versioneCorrente = versioneXChaCha20Poly1305;

  static const int lunghezzaChiave = 32;

  static const int _lunghezzaNonce = 24;
  static const int _lunghezzaTag = 16;
  static const int _lunghezzaMinima = 1 + _lunghezzaNonce + _lunghezzaTag;

  Aead get _aead => _sodium.crypto.aeadXChaCha20Poly1305IETF;

  /// Nuova chiave casuale da 256 bit (es. la chiave dei dati, DEK).
  SecureKey nuovaChiave() => _aead.keygen();

  Uint8List cifra(Uint8List dati, SecureKey chiave, {required Uint8List aad}) {
    final nonce = _sodium.randombytes.buf(_aead.nonceBytes);
    final cifrato = _aead.encrypt(
      message: dati,
      nonce: nonce,
      key: chiave,
      additionalData: _aadConVersione(versioneCorrente, aad),
    );
    return (BytesBuilder(copy: false)
          ..addByte(versioneCorrente)
          ..add(nonce)
          ..add(cifrato))
        .toBytes();
  }

  Uint8List decifra(
    Uint8List blob,
    SecureKey chiave, {
    required Uint8List aad,
  }) {
    if (blob.length < _lunghezzaMinima) {
      throw const DatiNonValidiException();
    }
    final versione = blob[0];
    if (versione != versioneXChaCha20Poly1305) {
      throw VersioneNonSupportataException(versione);
    }
    try {
      return _aead.decrypt(
        cipherText: Uint8List.sublistView(blob, 1 + _lunghezzaNonce),
        nonce: Uint8List.sublistView(blob, 1, 1 + _lunghezzaNonce),
        key: chiave,
        additionalData: _aadConVersione(versione, aad),
      );
    } on SodiumException {
      throw const DatiNonValidiException();
    }
  }

  static Uint8List _aadConVersione(int versione, Uint8List aad) =>
      (BytesBuilder(copy: false)
            ..addByte(versione)
            ..add(aad))
          .toBytes();
}
