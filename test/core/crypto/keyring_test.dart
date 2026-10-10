import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/crypto/derivazione.dart';
import 'package:gestionale_finanziaria/core/crypto/eccezioni.dart';
import 'package:gestionale_finanziaria/core/crypto/keyring.dart';
import 'package:gestionale_finanziaria/core/crypto/secret_key.dart';
import 'package:sodium/sodium_sumo.dart';

void main() {
  late SodiumSumo sodium;

  /// Minimi di sicurezza ammessi (19 MiB, 2 passaggi): test veloci senza scorciatoie.
  ParametriArgon2 minimi() => ParametriArgon2.nuovi(
    sodium,
    opsLimit: ParametriArgon2.opsMinimo,
    memLimit: ParametriArgon2.memMinima,
  );

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  Map<String, Object?> json(Keyring k) =>
      jsonDecode(utf8.decode(k.serializza())) as Map<String, Object?>;
  Uint8List byte(Map<String, Object?> j) => utf8.encode(jsonEncode(j));

  test('si apre con la password e restituisce la stessa chiave dei dati', () {
    final creato = Keyring.crea(
      sodium,
      'Password-Lunga-1',
      parametri: minimi(),
    );
    final dek = creato.keyring.apriConPassword(sodium, 'Password-Lunga-1');
    addTearDown(dek.dispose);

    expect(dek, equals(creato.dek));
    expect(dek.length, 32);
  });

  test('password errata', () {
    final creato = Keyring.crea(sodium, 'giusta', parametri: minimi());
    expect(
      () => creato.keyring.apriConPassword(sodium, 'sbagliata'),
      throwsA(isA<PasswordErrataException>()),
    );
  });

  test('si apre con la Secret Key letta dal testo', () {
    final creato = Keyring.crea(sodium, 'giusta', parametri: minimi());
    final letta = SecretKey.daTesto(creato.secretKey.testo);
    final dek = creato.keyring.apriConSecretKey(sodium, letta);
    addTearDown(dek.dispose);

    expect(dek, equals(creato.dek));
  });

  test('una Secret Key di un altro archivio non apre, e lo dice', () {
    final creato = Keyring.crea(sodium, 'giusta', parametri: minimi());
    expect(
      () => creato.keyring.apriConSecretKey(sodium, SecretKey.genera(sodium)),
      throwsA(
        isA<SecretKeyNonValidaException>().having(
          (e) => e.messaggio,
          'messaggio',
          contains(creato.keyring.idArchivio),
        ),
      ),
    );
  });

  test('ID archivio salvato nel keyring', () {
    final creato = Keyring.crea(sodium, 'giusta', parametri: minimi());
    final riletto = Keyring.deserializza(creato.keyring.serializza());
    expect(riletto.idArchivio, creato.keyring.idArchivio);
    expect(riletto.idArchivio, startsWith('GF-'));
  });

  test('serializza e rilegge (keyring.bin) senza segreti in chiaro', () {
    final creato = Keyring.crea(sodium, 'giusta', parametri: minimi());
    final testo = utf8.decode(creato.keyring.serializza());

    expect(testo, isNot(contains('giusta')));
    expect(testo, isNot(contains(creato.secretKey.testo)));

    final riletto = Keyring.deserializza(creato.keyring.serializza());
    final dek = riletto.apriConPassword(sodium, 'giusta');
    addTearDown(dek.dispose);
    expect(dek, equals(creato.dek));
  });

  test('cambio password: la vecchia non apre più, la Secret Key sì', () {
    final creato = Keyring.crea(sodium, 'vecchia', parametri: minimi());
    final nuovo = creato.keyring.conNuovaPassword(
      sodium,
      creato.dek,
      'nuova',
      parametri: minimi(),
    );

    expect(
      () => nuovo.apriConPassword(sodium, 'vecchia'),
      throwsA(isA<PasswordErrataException>()),
    );
    final daPassword = nuovo.apriConPassword(sodium, 'nuova');
    final daSecretKey = nuovo.apriConSecretKey(sodium, creato.secretKey);
    addTearDown(daPassword.dispose);
    addTearDown(daSecretKey.dispose);
    expect(daPassword, equals(creato.dek));
    expect(daSecretKey, equals(creato.dek));
  });

  test('nuova Secret Key: la vecchia smette di funzionare', () {
    final creato = Keyring.crea(sodium, 'giusta', parametri: minimi());
    final rinnovato = creato.keyring.conNuovaSecretKey(sodium, creato.dek);

    expect(
      () => rinnovato.keyring.apriConSecretKey(sodium, creato.secretKey),
      throwsA(isA<SecretKeyNonValidaException>()),
    );
    final dek = rinnovato.keyring.apriConSecretKey(sodium, rinnovato.secretKey);
    addTearDown(dek.dispose);
    expect(dek, equals(creato.dek));
  });

  group('manomissioni del file', () {
    test('parametri Argon2 abbassati sotto il minimo: rifiutati', () {
      final j = json(
        Keyring.crea(sodium, 'giusta', parametri: minimi()).keyring,
      );
      (j['argon2']! as Map<String, Object?>)['mem'] = 1024 * 1024;

      expect(
        () => Keyring.deserializza(byte(j)),
        throwsA(isA<ParametriNonSicuriException>()),
      );
    });

    test('parametri Argon2 cambiati (anche se validi): non apre', () {
      final j = json(
        Keyring.crea(sodium, 'giusta', parametri: minimi()).keyring,
      );
      (j['argon2']! as Map<String, Object?>)['ops'] =
          ParametriArgon2.opsMinimo + 1;

      expect(
        () => Keyring.deserializza(byte(j)).apriConPassword(sodium, 'giusta'),
        throwsA(isA<PasswordErrataException>()),
      );
    });

    test('ID archivio cambiato: non apre', () {
      final creato = Keyring.crea(sodium, 'giusta', parametri: minimi());
      final j = json(creato.keyring)..['id'] = 'GF-0000-0000';
      final alterato = Keyring.deserializza(byte(j));

      expect(
        () => alterato.apriConPassword(sodium, 'giusta'),
        throwsA(isA<PasswordErrataException>()),
      );
      expect(
        () => alterato.apriConSecretKey(sodium, creato.secretKey),
        throwsA(isA<SecretKeyNonValidaException>()),
      );
    });

    test('versione futura: errore esplicito', () {
      final j = json(
        Keyring.crea(sodium, 'giusta', parametri: minimi()).keyring,
      )..['v'] = 2;
      expect(
        () => Keyring.deserializza(byte(j)),
        throwsA(isA<VersioneNonSupportataException>()),
      );
    });

    test('file non valido', () {
      expect(
        () => Keyring.deserializza(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<DatiNonValidiException>()),
      );
    });
  });

  test('parametri predefiniti (64 MiB, 3 passaggi) funzionano', () {
    final parametri = ParametriArgon2.nuovi(sodium);
    expect(parametri.memLimit, 64 * 1024 * 1024);
    expect(parametri.opsLimit, 3);

    final creato = Keyring.crea(sodium, 'giusta', parametri: parametri);
    final dek = creato.keyring.apriConPassword(sodium, 'giusta');
    addTearDown(dek.dispose);
    expect(dek, equals(creato.dek));
  });

  test(
    'stessa password e stesso sale → stessa chiave; sale diverso → diversa',
    () {
      final p = minimi();
      final a = p.derivaChiave(sodium, 'giusta');
      final b = p.derivaChiave(sodium, 'giusta');
      final c = minimi().derivaChiave(sodium, 'giusta');
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      addTearDown(c.dispose);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    },
  );
}
