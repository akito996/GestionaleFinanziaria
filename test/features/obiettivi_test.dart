import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    cartella = await Directory.systemTemp.createTemp('obiettivi_test');
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
    try {
      await cartella.delete(recursive: true);
    } on FileSystemException {
      // ignorato: archivio ancora in chiusura
    }
  });

  Future<void> attendi(WidgetTester tester, Finder cosa) async {
    for (var i = 0; i < 200 && cosa.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(cosa, findsWidgets);
  }

  Future<void> tocca(WidgetTester tester, Finder cosa) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(cosa);
    await tester.pump();
    await tester.tap(cosa);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder nelDialogo(Finder f) =>
      find.descendant(of: find.byType(AlertDialog), matching: f);

  testWidgets('colletta: partecipanti, versamento, chi è in regola', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    await tester.runAsync(() async {
      await sessione.avvia();
      await sessione.preparaNuovoArchivio('Password-Lunga-1');
      await sessione.confermaNuovoArchivio();
    });
    sessione.avviso = null;
    await tester.pumpWidget(GestionaleApp(sessione: sessione));
    await attendi(tester, find.text('Crea il tuo primo portafoglio'));

    await tocca(tester, find.text('Obiettivi').last);
    await attendi(tester, find.textContaining('Metti da parte per qualcosa'));
    await tocca(tester, find.text('Nuovo'));
    await attendi(tester, nelDialogo(find.text('Colletta')));
    await tocca(tester, nelDialogo(find.text('Colletta')));
    await tester.enterText(
      nelDialogo(find.widgetWithText(TextFormField, 'Nome')),
      'Regalo Anna',
    );
    await tester.enterText(
      nelDialogo(find.widgetWithText(TextFormField, 'Totale da raccogliere')),
      '90',
    );
    for (final nome in ['Marco', 'Giulia']) {
      await tester.enterText(
        nelDialogo(find.widgetWithText(TextField, 'Aggiungi partecipante')),
        nome,
      );
      await tocca(tester, nelDialogo(find.byTooltip('Aggiungi')));
    }
    await tocca(tester, nelDialogo(find.text('Crea')));
    await attendi(tester, find.text('0 di 3 hanno versato la loro quota'));

    // Dettaglio: Marco versa la sua quota (30 €, proposta in automatico).
    await tocca(tester, find.text('Regalo Anna'));
    await attendi(tester, find.text('Partecipanti'));
    await tocca(tester, find.text('Marco'));
    await attendi(tester, nelDialogo(find.text('Nuovo versamento')));
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: nelDialogo(find.widgetWithText(TextFormField, 'Importo')),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text,
      '30,00',
    );
    await tocca(tester, nelDialogo(find.text('Registra')));
    await attendi(tester, find.text('Ha versato 30,00 €'));
    expect(find.text('30,00 €'), findsWidgets);

    // Riepilogo da condividere.
    await tocca(tester, find.byTooltip('Copia riepilogo'));
    await attendi(tester, find.text('Riepilogo copiato: incollalo dove vuoi'));

    sessione.blocca().ignore();
    await attendi(tester, find.text('Archivio bloccato'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
