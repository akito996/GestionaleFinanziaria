import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/ricorrenza.dart';

void main() {
  DateTime d(int a, int m, int g) => DateTime(a, m, g);

  test('mensile senza fine', () {
    final r = Ricorrenza(inizio: d(2026, 10, 5));
    expect(r.tra(d(2026, 10, 1), d(2027, 1, 31)), [
      d(2026, 10, 5),
      d(2026, 11, 5),
      d(2026, 12, 5),
      d(2027, 1, 5),
    ]);
    expect(r.ultima, isNull);
  });

  test('il 31: ultimo giorno nei mesi corti, poi torna al 31', () {
    final r = Ricorrenza(inizio: d(2027, 1, 31));
    expect(r.tra(d(2027, 1, 1), d(2027, 5, 31)), [
      d(2027, 1, 31),
      d(2027, 2, 28),
      d(2027, 3, 31),
      d(2027, 4, 30),
      d(2027, 5, 31),
    ]);
    // Anno bisestile.
    expect(Ricorrenza(inizio: d(2028, 1, 31)).nelMese(d(2028, 2, 1)), [
      d(2028, 2, 29),
    ]);
  });

  test('bimestrale e annuale', () {
    final bim = Ricorrenza(
      inizio: d(2026, 11, 20),
      frequenza: Frequenza.bimestrale,
    );
    expect(bim.tra(d(2026, 11, 1), d(2027, 6, 30)), [
      d(2026, 11, 20),
      d(2027, 1, 20),
      d(2027, 3, 20),
      d(2027, 5, 20),
    ]);
    expect(bim.nelMese(d(2026, 12, 1)), isEmpty);

    final ann = Ricorrenza(
      inizio: d(2026, 3, 15),
      frequenza: Frequenza.annuale,
    );
    expect(ann.tra(d(2026, 1, 1), d(2028, 12, 31)), [
      d(2026, 3, 15),
      d(2027, 3, 15),
      d(2028, 3, 15),
    ]);
  });

  test('settimanale', () {
    final r = Ricorrenza(
      inizio: d(2026, 10, 28),
      frequenza: Frequenza.settimanale,
    );
    expect(r.nelMese(d(2026, 11, 1)), [
      d(2026, 11, 4),
      d(2026, 11, 11),
      d(2026, 11, 18),
      d(2026, 11, 25),
    ]);
  });

  test('fine per numero di addebiti', () {
    final r = Ricorrenza(inizio: d(2026, 10, 10), occorrenze: 3);
    expect(r.tra(d(2026, 1, 1), d(2030, 1, 1)), [
      d(2026, 10, 10),
      d(2026, 11, 10),
      d(2026, 12, 10),
    ]);
    expect(r.ultima, d(2026, 12, 10));
    expect(r.prossima(d(2026, 12, 11)), isNull);
  });

  test('fine per data (inclusa)', () {
    final r = Ricorrenza(inizio: d(2026, 10, 10), fine: d(2027, 1, 10));
    expect(r.tra(d(2026, 1, 1), d(2030, 1, 1)).last, d(2027, 1, 10));
    expect(r.ultima, d(2027, 1, 10));
    expect(r.prossima(d(2027, 1, 11)), isNull);
  });

  test('prossima data', () {
    final r = Ricorrenza(inizio: d(2026, 10, 5));
    expect(r.prossima(d(2026, 10, 5)), d(2026, 10, 5));
    expect(r.prossima(d(2026, 10, 6)), d(2026, 11, 5));
    expect(r.prossima(d(2026, 1, 1)), d(2026, 10, 5));
  });

  test('descrizione leggibile', () {
    expect(
      Ricorrenza(inizio: d(2026, 10, 5)).descrizione(),
      'Ogni mese il giorno 5',
    );
    expect(
      Ricorrenza(
        inizio: d(2026, 10, 5),
        frequenza: Frequenza.bimestrale,
        occorrenze: 6,
      ).descrizione(),
      'Ogni 2 mesi, il giorno 5, per 6 volte',
    );
    expect(
      Ricorrenza(inizio: d(2026, 10, 5), fine: d(2027, 12, 31)).descrizione(),
      'Ogni mese il giorno 5, fino al 31/12/2027',
    );
  });
}
