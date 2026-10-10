import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/crypto/eccezioni.dart';
import 'package:gestionale_finanziaria/core/crypto/secret_key.dart';
import 'package:sodium/sodium_sumo.dart';

/// Vettori calcolati con un'implementazione indipendente (Python, hashlib).
const _vettori = {
  'zeri':
      'GF1-00000-00000-00000-00000-00000-00000-00000-00000-00000-00000-06CT0',
  'sequenza':
      'GF1-000G4-0R40M-30E20-9185G-R38E1-W8124-GK2GA-HC5RR-34D1P-70X3R-FP638',
  'uni':
      'GF1-ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ-ZTZ5G',
};

void main() {
  late SodiumSumo sodium;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  group('vettori di prova', () {
    final entropie = {
      'zeri': Uint8List(32),
      'sequenza': Uint8List.fromList(List.generate(32, (i) => i)),
      'uni': Uint8List.fromList(List.filled(32, 0xFF)),
    };
    for (final MapEntry(key: nome, value: entropia) in entropie.entries) {
      test(nome, () {
        expect(SecretKey.daEntropia(entropia).testo, _vettori[nome]);
        expect(SecretKey.daTesto(_vettori[nome]!).testo, _vettori[nome]);
      });
    }
  });

  test('genera, rilegge e ottiene la stessa chiave', () {
    final sk = SecretKey.genera(sodium);
    expect(sk.testo, startsWith('GF1-'));
    expect(sk.testo, hasLength(4 + 11 * 5 + 10));

    final a = sk.chiaveDiAvvolgimento(sodium);
    final b = SecretKey.daTesto(sk.testo).chiaveDiAvvolgimento(sodium);
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    expect(a, equals(b));
  });

  test('legge il file completo, minuscole, spazi e O/I/L ambigue', () {
    final testo = _vettori['sequenza']!;
    final file =
        'GestionaleFinanziaria - Secret Key\r\n\r\n'
        'ID archivio: GF-7K3P-Q9XW\r\n'
        'Secret Key:  $testo\r\n'
        'Creata il:   10/10/2026\r\n';
    expect(SecretKey.daTesto(file).testo, testo);

    final scritta = testo
        .toLowerCase()
        .replaceAll('-', ' ')
        .replaceAll('0', 'o');
    expect(SecretKey.daTesto(scritta).testo, testo);
  });

  test('un carattere sbagliato viene scoperto', () {
    final testo = _vettori['sequenza']!;
    final sbagliata = testo.replaceRange(10, 11, testo[10] == 'A' ? 'B' : 'A');
    expect(
      () => SecretKey.daTesto(sbagliata),
      throwsA(
        isA<SecretKeyNonValidaException>().having(
          (e) => e.messaggio,
          'messaggio',
          contains('errore di battitura'),
        ),
      ),
    );
  });

  test('incompleta o senza prefisso', () {
    expect(
      () => SecretKey.daTesto(_vettori['zeri']!.substring(0, 50)),
      throwsA(isA<SecretKeyNonValidaException>()),
    );
    expect(
      () => SecretKey.daTesto('testo qualsiasi'),
      throwsA(isA<SecretKeyNonValidaException>()),
    );
  });

  test('ID archivio: formato GF-XXXX-XXXX e diversi tra loro', () {
    final ids = List.generate(200, (_) => nuovoIdArchivio(sodium));
    expect(ids.toSet(), hasLength(200));
    expect(
      ids.every(
        RegExp(r'^GF-[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}$').hasMatch,
      ),
      isTrue,
    );
  });
}
