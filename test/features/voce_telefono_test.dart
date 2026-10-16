import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/app.dart';
import 'package:gestionale_finanziaria/core/crypto/derivazione.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';
import 'package:gestionale_finanziaria/core/sessione.dart';
import 'package:sodium/sodium_sumo.dart';

/// Entrate sul telefono: si aggiunge solo con "Nuova"; la finestra è a tutto
/// schermo, con i suggerimenti e la scelta "Fino a" senza sforamenti.
void main() {
  late SodiumSumo sodium;
  late Directory cartella;
  late Sessione sessione;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() async {
    cartella = await Directory.systemTemp.createTemp('voce_telefono_test');
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
      // archivio ancora in chiusura
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
    await tester.ensureVisible(cosa.first);
    await tester.pump();
    await tester.tap(cosa.first);
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('telefono: "Nuova" apre la finestra a tutto schermo', (
    tester,
  ) async {
    // Un telefono vero: 360 × 740 punti (anche per MediaQuery).
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
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
    await attendi(tester, find.text('Entrate'));

    await tocca(tester, find.text('Entrate').hitTestable().last);
    await attendi(tester, find.text('Quanto entra ogni mese?'));
    // Niente più inserimento nella pagina: solo il pulsante "Nuova".
    expect(find.byType(ActionChip).hitTestable(), findsNothing);
    await tocca(tester, find.text('Nuova').hitTestable());
    await attendi(tester, find.text('Nuova entrata fissa'));

    // A tutto schermo: chiudi a sinistra, "Aggiungi" in alto.
    final barra = find.ancestor(
      of: find.text('Nuova entrata fissa'),
      matching: find.byType(AppBar),
    );
    expect(barra, findsOneWidget);
    expect(
      find.descendant(of: barra, matching: find.byType(CloseButton)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: barra, matching: find.text('Aggiungi')),
      findsOneWidget,
    );

    // Suggerimento, data di accredito e scelta "Fino a".
    await tocca(tester, find.text('Stipendio'));
    await tocca(tester, find.text('Data di accredito'));
    await tocca(tester, find.text('Fino a'));
    expect(find.text('Fino a una data'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextFormField).at(1), '1800');
    await tocca(
      tester,
      find.descendant(of: barra, matching: find.text('Aggiungi')),
    );
    await attendi(tester, find.text('1.800,00 €'));

    sessione.blocca().ignore();
    await attendi(tester, find.text('Archivio bloccato'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
