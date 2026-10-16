import 'dart:convert';
import 'dart:typed_data';

import 'package:sodium/sodium.dart';

/// La "persona" dei portafogli condivisi (ADR-019): una coppia di chiavi per
/// ricevere (X25519) e una per firmare (Ed25519).
///
/// Le chiavi si **ricavano dalla chiave dei dati** dell'archivio: sono le
/// stesse su tutti i dispositivi dello stesso archivio, non si salvano e non
/// si sincronizzano, e non possono nascerne due diverse. Cambiare la password
/// non le cambia (la chiave dei dati resta la stessa).
class IdentitaPersona {
  IdentitaPersona._(this._sodium, this._scambio, this._firma);

  /// Ricava le chiavi dalla chiave dei dati [dek] (32 byte).
  factory IdentitaPersona.daChiaveDati(Sodium sodium, SecureKey dek) {
    KeyPair coppia(int numero, KeyPair Function(SecureKey seme) genera) {
      final seme = sodium.crypto.kdf.deriveFromKey(
        masterKey: dek,
        context: _contesto,
        subkeyId: BigInt.from(numero),
        subkeyLen: 32,
      );
      try {
        return genera(seme);
      } finally {
        seme.dispose();
      }
    }

    return IdentitaPersona._(
      sodium,
      coppia(1, sodium.crypto.box.seedKeyPair),
      coppia(2, sodium.crypto.sign.seedKeyPair),
    );
  }

  /// Contesto della derivazione (8 caratteri, fisso: cambiarlo cambierebbe
  /// le chiavi di tutti).
  static const _contesto = 'GFperso1';

  final Sodium _sodium;
  final KeyPair _scambio;
  final KeyPair _firma;

  /// Chiave pubblica per ricevere (X25519): la chiave di un portafoglio si
  /// cifra per questa.
  Uint8List get pubblicaScambio => _scambio.publicKey;

  /// Chiave pubblica per verificare le firme (Ed25519).
  Uint8List get pubblicaFirma => _firma.publicKey;

  /// Firma [messaggio] (64 byte).
  Uint8List firma(Uint8List messaggio) => _sodium.crypto.sign.detached(
    message: messaggio,
    secretKey: _firma.secretKey,
  );

  /// La firma di [messaggio] è di chi ha la chiave pubblica [pubblicaFirma]?
  static bool firmaValida(
    Sodium sodium, {
    required Uint8List messaggio,
    required Uint8List firma,
    required Uint8List pubblicaFirma,
  }) {
    try {
      return sodium.crypto.sign.verifyDetached(
        message: messaggio,
        signature: firma,
        publicKey: pubblicaFirma,
      );
    } on SodiumException {
      return false;
    }
  }

  /// Cifra [segreto] perché lo possa aprire solo chi ha la chiave privata di
  /// [pubblicaScambio] (es. la chiave del portafoglio per un membro).
  static Uint8List sigillaPer(
    Sodium sodium, {
    required Uint8List segreto,
    required Uint8List pubblicaScambio,
  }) => sodium.crypto.box.seal(message: segreto, publicKey: pubblicaScambio);

  /// Apre ciò che è stato sigillato per questa persona. Lancia
  /// [SodiumException] se non era per lei o è stato alterato.
  Uint8List apri(Uint8List sigillato) => _sodium.crypto.box.sealOpen(
    cipherText: sigillato,
    publicKey: _scambio.publicKey,
    secretKey: _scambio.secretKey,
  );

  /// Codice di sicurezza di due persone (lo stesso per entrambe): 12 gruppi
  /// da 5 cifre ricavati dalle loro chiavi pubbliche. Se coincide sui due
  /// schermi (a voce o inquadrando il QR), nessuno si è messo in mezzo.
  static String codiceSicurezza(
    Sodium sodium,
    ({Uint8List scambio, Uint8List firma}) a,
    ({Uint8List scambio, Uint8List firma}) b,
  ) {
    final chiavi = [
      [...a.firma, ...a.scambio],
      [...b.firma, ...b.scambio],
    ]..sort((x, y) => base64.encode(x).compareTo(base64.encode(y)));
    final impronta = sodium.crypto.genericHash(
      message: Uint8List.fromList([
        ...utf8.encode('wallecy-codice-sicurezza-v1'),
        ...chiavi[0],
        ...chiavi[1],
      ]),
      outLen: 60,
    );
    return [
      for (var i = 0; i < 12; i++)
        (impronta
                    .sublist(i * 5, i * 5 + 5)
                    .fold<int>(0, (n, b) => (n << 8) | b) %
                100000)
            .toString()
            .padLeft(5, '0'),
    ].join(' ');
  }

  /// Libera le chiavi private.
  void chiudi() {
    _scambio.secretKey.dispose();
    _firma.secretKey.dispose();
  }
}
