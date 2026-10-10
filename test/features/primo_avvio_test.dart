import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/app.dart';
import 'package:gestionale_finanziaria/core/crypto/derivazione.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';
import 'package:gestionale_finanziaria/core/sessione.dart';
import 'package:sodium/sodium_sumo.dart';

void main() {
  late SodiumSumo sodium;
  late Directory cartella;
  late Sessione sessione;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() async {
    cartella = await Directory.systemTemp.createTemp('primo_avvio_test');
    sessione = Sessione(
      sodium: sodium,
      deposito: DepositoLocale(cartella),
      costoArgon2: (
        ops: ParametriArgon2.opsMinimo,
        mem: ParametriArgon2.memMinima,
      ),
    );
  });

  tearDown(() async {
    await cartella.delete(recursive: true);
  });

  /// Aspetta il lavoro vero (isolate, file) finché compare [cosa].
  Future<void> attendi(WidgetTester tester, Finder cosa) async {
    for (var i = 0; i < 200 && cosa.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    expect(cosa, findsWidgets);
  }

  Future<void> tocca(WidgetTester tester, Finder cosa) async {
    await tester.ensureVisible(cosa);
    await tester.pump();
    await tester.tap(cosa);
    await tester.pump();
  }

  Future<void> avviaApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(sessione.avvia);
    await tester.pumpWidget(GestionaleApp(sessione: sessione));
  }

  Future<List<String>> finoAlleParole(WidgetTester tester) async {
    await avviaApp(tester);
    expect(find.text('Benvenuto in GestionaleFinanziaria'), findsOneWidget);
    await tocca(tester, find.text('Inizia'));

    final campi = find.byType(TextFormField);
    await tester.enterText(campi.at(0), 'Password-Lunga-1');
    await tester.enterText(campi.at(1), 'Password-Lunga-1');
    await tocca(tester, find.text('Continua'));
    await attendi(tester, find.text('Le ho scritte e messe al sicuro'));

    // Le 24 parole mostrate, nell'ordine.
    final riga = RegExp(r'^\s*(\d+)\. ([a-z]+)$');
    final parole = <int, String>{};
    for (final testo in tester.widgetList<RichText>(find.byType(RichText))) {
      final m = riga.firstMatch(testo.text.toPlainText());
      if (m != null) {
        parole[int.parse(m.group(1)!)] = m.group(2)!;
      }
    }
    expect(parole, hasLength(24));
    return [for (var i = 1; i <= 24; i++) parole[i]!];
  }

  Future<void> rispondi(
    WidgetTester tester,
    String Function(int numero) parolaN,
  ) async {
    final etichetta = RegExp(r'Parola n\. (\d+)');
    final campi = find.byType(TextField);
    for (var i = 0; i < campi.evaluate().length; i++) {
      final campo = tester.widget<TextField>(campi.at(i));
      final numero = int.parse(
        etichetta.firstMatch(campo.decoration!.labelText!)!.group(1)!,
      );
      await tester.enterText(campi.at(i), parolaN(numero));
    }
  }

  testWidgets('regole della password', (tester) async {
    await avviaApp(tester);
    await tocca(tester, find.text('Inizia'));
    final campi = find.byType(TextFormField);

    await tester.enterText(campi.at(0), 'corta');
    await tocca(tester, find.text('Continua'));
    expect(find.text('Servono almeno 12 caratteri.'), findsOneWidget);

    await tester.enterText(campi.at(0), 'Password-Lunga-1');
    await tester.enterText(campi.at(1), 'Password-Lunga-2');
    await tocca(tester, find.text('Continua'));
    expect(find.text('Le due password non coincidono.'), findsOneWidget);
  });

  testWidgets('primo avvio completo, poi blocco', (tester) async {
    final parole = await finoAlleParole(tester);

    // "Continua" resta disattivato finché non si conferma di averle scritte.
    final continua = find.widgetWithText(FilledButton, 'Continua');
    expect(tester.widget<FilledButton>(continua).onPressed, isNull);
    await tocca(tester, find.text('Le ho scritte e messe al sicuro'));
    await tocca(tester, continua);

    // Verifica con le prime 4 lettere in maiuscolo.
    await rispondi(tester, (n) => parole[n - 1].substring(0, 4).toUpperCase());
    await tocca(tester, find.text('Crea l\'archivio'));
    await attendi(tester, find.text('Archivio aperto'));
    expect(await DepositoLocale(cartella).esisteKeyring(), isTrue);

    await tocca(tester, find.byTooltip('Blocca'));
    await attendi(tester, find.text('Archivio bloccato'));
  });

  testWidgets('verifica sbagliata: archivio non creato', (tester) async {
    await finoAlleParole(tester);
    await tocca(tester, find.text('Le ho scritte e messe al sicuro'));
    await tocca(tester, find.widgetWithText(FilledButton, 'Continua'));

    await rispondi(tester, (_) => 'zzzz');
    await tocca(tester, find.text('Crea l\'archivio'));

    expect(find.textContaining('non corrisponde'), findsOneWidget);
    expect(await DepositoLocale(cartella).esisteKeyring(), isFalse);
    sessione.annullaNuovoArchivio();
  });
}
