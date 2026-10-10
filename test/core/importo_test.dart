import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/importo.dart';

void main() {
  group('lettura di quello che scrive l\'utente', () {
    const casi = {
      '12': 1200,
      '12,5': 1250,
      '12,50': 1250,
      '12.50': 1250,
      '0,99': 99,
      ',5': 50,
      '1.234,56': 123456,
      '1,234.56': 123456,
      '1.234': 123400,
      '1.234.567': 123456700,
      '€ 7': 700,
      ' 7,00 € ': 700,
      '-15,30': -1530,
    };
    for (final MapEntry(key: testo, value: atteso) in casi.entries) {
      test('"$testo" → $atteso', () => expect(Importo.leggi(testo), atteso));
    }

    for (final testo in ['', 'abc', '12,345,6x', '1,2,3,4a', '€']) {
      test('"$testo" non valido', () => expect(Importo.leggi(testo), isNull));
    }
  });

  test('formato italiano', () {
    expect(Importo.formatta(123456, 'EUR'), '1.234,56 €');
    expect(Importo.formatta(5, 'EUR'), '0,05 €');
    expect(Importo.formatta(-1530, 'EUR'), '−15,30 €');
    expect(Importo.formatta(1200, 'EUR', conSegno: true), '+12,00 €');
    expect(Importo.formatta(100000000, 'USD'), '1.000.000,00 \$');
    expect(Importo.formatta(100, 'CHF'), '1,00 CHF');
  });

  test('testo per la modifica si rilegge uguale', () {
    for (final v in [0, 5, 1250, 123456, -1530]) {
      expect(Importo.leggi(Importo.perModifica(v)), v);
    }
  });
}
