import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/versione.dart';

void main() {
  test('la versione mostrata coincide con quella di pubspec.yaml', () {
    final riga = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((r) => r.startsWith('version:'));
    final versione = riga.split(':').last.trim().split('+').first;
    expect(Versione.numero, versione);
    expect(Versione.firma, startsWith('v$versione'));
  });
}
