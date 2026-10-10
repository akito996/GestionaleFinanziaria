import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/crypto/aad.dart';
import 'package:gestionale_finanziaria/core/crypto/cifratura.dart';
import 'package:gestionale_finanziaria/core/crypto/eccezioni.dart';
import 'package:sodium/sodium_sumo.dart';

void main() {
  late SodiumSumo sodium;
  late Cifratore cifratore;
  late SecureKey chiave;

  final dati = Uint8List.fromList(
    utf8.encode('12 € pizzeria, portafoglio Contanti'),
  );
  Uint8List aad({int sequenza = 7, String dispositivo = 'pc-casa'}) => aadPer(
    tipo: TipoDato.evento,
    utenteId: 'utente-1',
    dispositivoId: dispositivo,
    sequenza: sequenza,
  );

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() {
    cifratore = Cifratore(sodium);
    chiave = cifratore.nuovaChiave();
  });

  tearDown(() => chiave.dispose());

  test('cifra e decifra restituiscono i dati originali', () {
    final blob = cifratore.cifra(dati, chiave, aad: aad());

    expect(blob[0], Cifratore.versioneXChaCha20Poly1305);
    expect(blob.length, 1 + 24 + dati.length + 16);
    expect(cifratore.decifra(blob, chiave, aad: aad()), dati);
  });

  test('due cifrature degli stessi dati sono diverse (nonce casuale)', () {
    expect(
      cifratore.cifra(dati, chiave, aad: aad()),
      isNot(cifratore.cifra(dati, chiave, aad: aad())),
    );
  });

  test('con un\'altra chiave non si decifra', () {
    final blob = cifratore.cifra(dati, chiave, aad: aad());
    final altra = cifratore.nuovaChiave();
    addTearDown(altra.dispose);

    expect(
      () => cifratore.decifra(blob, altra, aad: aad()),
      throwsA(isA<DatiNonValidiException>()),
    );
  });

  test('un solo bit modificato fa fallire la decifratura', () {
    final blob = cifratore.cifra(dati, chiave, aad: aad());
    for (final posizione in [1, 30, blob.length - 1]) {
      final manomesso = Uint8List.fromList(blob)..[posizione] ^= 0x01;
      expect(
        () => cifratore.decifra(manomesso, chiave, aad: aad()),
        throwsA(isA<DatiNonValidiException>()),
        reason: 'byte $posizione',
      );
    }
  });

  test('anti-replay: altra sequenza o altro dispositivo non decifrano', () {
    final blob = cifratore.cifra(dati, chiave, aad: aad());

    expect(
      () => cifratore.decifra(blob, chiave, aad: aad(sequenza: 8)),
      throwsA(isA<DatiNonValidiException>()),
    );
    expect(
      () => cifratore.decifra(blob, chiave, aad: aad(dispositivo: 'telefono')),
      throwsA(isA<DatiNonValidiException>()),
    );
  });

  test('versione sconosciuta: errore esplicito, non dati corrotti', () {
    final blob = cifratore.cifra(dati, chiave, aad: aad());
    final futuro = Uint8List.fromList(blob)..[0] = 99;

    expect(
      () => cifratore.decifra(futuro, chiave, aad: aad()),
      throwsA(isA<VersioneNonSupportataException>()),
    );
  });

  test('blob troppo corto', () {
    expect(
      () => cifratore.decifra(Uint8List(10), chiave, aad: aad()),
      throwsA(isA<DatiNonValidiException>()),
    );
  });

  group('AAD', () {
    test('ogni campo cambia il risultato', () {
      final base = aad();
      expect(aad(sequenza: 8), isNot(base));
      expect(aad(dispositivo: 'altro'), isNot(base));
      expect(
        aadPer(
          tipo: TipoDato.allegato,
          utenteId: 'utente-1',
          dispositivoId: 'pc-casa',
          sequenza: 7,
        ),
        isNot(base),
      );
    });

    test('nessuna ambiguità tra campi adiacenti', () {
      Uint8List con(String u, String d) => aadPer(
        tipo: TipoDato.evento,
        utenteId: u,
        dispositivoId: d,
        sequenza: 1,
      );
      expect(con('ab', 'c'), isNot(con('a', 'bc')));
    });

    test('sequenza negativa rifiutata', () {
      expect(() => aad(sequenza: -1), throwsArgumentError);
    });
  });
}
