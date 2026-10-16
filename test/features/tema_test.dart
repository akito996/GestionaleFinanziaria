import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/features/comuni/tema.dart';

/// Tema "Blu fedele all'icona": i blu dell'icona, testo ben leggibile.
void main() {
  double contrasto(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final (chiaro, scuro) = la > lb ? (la, lb) : (lb, la);
    return (chiaro + 0.05) / (scuro + 0.05);
  }

  test('chiaro: pulsanti blu scuro, testo leggibile', () {
    final s = TemaWalleCy.chiaro().colorScheme;
    expect(s.brightness, Brightness.light);
    expect(s.primary, TemaWalleCy.bluScuro);
    expect(contrasto(s.onPrimary, s.primary), greaterThan(4.5));
    expect(contrasto(s.onSurface, s.surface), greaterThan(7));
    expect(contrasto(s.onSurfaceVariant, s.surface), greaterThan(4.5));
  });

  test('scuro: pulsanti azzurri, testo leggibile', () {
    final s = TemaWalleCy.scuro().colorScheme;
    expect(s.brightness, Brightness.dark);
    expect(s.primary, TemaWalleCy.azzurroChiaro);
    expect(contrasto(s.onPrimary, s.primary), greaterThan(4.5));
    expect(contrasto(s.onSurface, s.surface), greaterThan(7));
    expect(contrasto(s.onSurfaceVariant, s.surface), greaterThan(4.5));
  });
}
