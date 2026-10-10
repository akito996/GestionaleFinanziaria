import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/crypto/eccezioni.dart';
import 'package:gestionale_finanziaria/core/crypto/parole_bip39_it.dart';
import 'package:gestionale_finanziaria/core/crypto/recovery_key.dart';
import 'package:sodium/sodium_sumo.dart';

/// Vettori calcolati con un'implementazione BIP-39 indipendente (Python, hashlib).
const _vettori = {
  'zeri':
      'abaco abaco abaco abaco abaco abaco abaco abaco abaco abaco abaco abaco '
      'abaco abaco abaco abaco abaco abaco abaco abaco abaco abaco abaco angelo',
  'sequenza':
      'abaco alogeno mitigare alogeno fenomeno affetto bravura bronzina ampio '
      'gonfio elaborato bisonte accadere nessuno europa monile autunno risibile '
      'alce criceto renna apparire mana trincea',
  'uni':
      'zuppa zuppa zuppa zuppa zuppa zuppa zuppa zuppa zuppa zuppa zuppa zuppa '
      'zuppa zuppa zuppa zuppa zuppa zuppa zuppa zuppa zuppa zuppa zuppa vedetta',
};

void main() {
  late SodiumSumo sodium;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  test('lista BIP-39 italiana completa e con prefissi univoci', () {
    expect(paroleBip39It, hasLength(2048));
    expect(paroleBip39It.toSet(), hasLength(2048));
    expect(
      paroleBip39It.map((p) => p.substring(0, 4)).toSet(),
      hasLength(2048),
    );
  });

  group('vettori di prova', () {
    final entropie = {
      'zeri': Uint8List(32),
      'sequenza': Uint8List.fromList(List.generate(32, (i) => i)),
      'uni': Uint8List.fromList(List.filled(32, 0xFF)),
    };
    for (final MapEntry(key: nome, value: entropia) in entropie.entries) {
      test(nome, () {
        final rk = RecoveryKey.daEntropia(entropia);
        expect(rk.parole.join(' '), _vettori[nome]);
        expect(RecoveryKey.daParole(_vettori[nome]!).parole, rk.parole);
      });
    }
  });

  test('genera 24 parole che si rileggono nella stessa chiave', () {
    final rk = RecoveryKey.genera(sodium);
    expect(rk.parole, hasLength(RecoveryKey.numeroParole));

    final riletta = RecoveryKey.daParole(rk.parole.join(' '));
    final a = rk.chiaveDiAvvolgimento(sodium);
    final b = riletta.chiaveDiAvvolgimento(sodium);
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    expect(a, equals(b));
  });

  test('accetta maiuscole, a capo e le sole prime 4 lettere', () {
    final scritta = _vettori['sequenza']!
        .split(' ')
        .map((p) => p.substring(0, 4).toUpperCase())
        .join('\n');
    expect(
      RecoveryKey.daParole(scritta).parole.join(' '),
      _vettori['sequenza'],
    );
  });

  test('parole scambiate di posto: rifiutate dal controllo', () {
    final parole = _vettori['sequenza']!.split(' ');
    final scambiate = [...parole]
      ..[1] = parole[2]
      ..[2] = parole[1];
    expect(
      () => RecoveryKey.daParole(scambiate.join(' ')),
      throwsA(isA<RecoveryKeyNonValidaException>()),
    );
  });

  test('parola sconosciuta: indica quale', () {
    final parole = _vettori['zeri']!.split(' ')..[4] = 'pizzeria';
    expect(
      () => RecoveryKey.daParole(parole.join(' ')),
      throwsA(
        isA<RecoveryKeyNonValidaException>().having(
          (e) => e.messaggio,
          'messaggio',
          contains('n. 5'),
        ),
      ),
    );
  });

  test('numero di parole sbagliato', () {
    expect(
      () => RecoveryKey.daParole('abaco abaco abaco'),
      throwsA(isA<RecoveryKeyNonValidaException>()),
    );
  });

  test('chiavi diverse da Recovery Key diverse', () {
    final a = RecoveryKey.genera(sodium).chiaveDiAvvolgimento(sodium);
    final b = RecoveryKey.genera(sodium).chiaveDiAvvolgimento(sodium);
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    expect(a, isNot(equals(b)));
  });
}
