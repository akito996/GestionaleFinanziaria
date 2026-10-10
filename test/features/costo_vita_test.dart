import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/app.dart';
import 'package:gestionale_finanziaria/core/crypto/derivazione.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';
import 'package:gestionale_finanziaria/core/sessione.dart';
import 'package:gestionale_finanziaria/features/costo_vita/grafico_costo_vita.dart';
import 'package:sodium/sodium_sumo.dart';

void main() {
  late SodiumSumo sodium;
  late Directory cartella;
  late Sessione sessione;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() async {
    cartella = await Directory.systemTemp.createTemp('costo_vita_test');
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
    // L'archivio può essere ancora in chiusura dopo il blocco: la cartella
    // temporanea, se occupata, la ripulisce il sistema.
    try {
      await cartella.delete(recursive: true);
    } on FileSystemException {
      // ignorato
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

  testWidgets('configura, cambia solo per il mese, torna al predefinito', (
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

    // Sezione dalla barra laterale.
    await tocca(tester, find.text('Costo della vita').last);
    await attendi(tester, find.text('Quanto ti costa vivere ogni mese?'));

    // Suggerimento a un tocco: nome già scritto, si inserisce solo l'importo.
    await tocca(tester, find.text('Affitto o mutuo'));
    await attendi(tester, nelDialogo(find.text('Nuova spesa fissa')));
    await tester.enterText(nelDialogo(find.byType(TextFormField)).at(1), '800');
    await tocca(tester, nelDialogo(find.text('Aggiungi')));
    await attendi(tester, find.text('800,00 €'));
    expect(find.text('Quanto ti costa vivere ogni mese?'), findsNothing);
    expect(find.byType(GraficoCostoVita), findsWidgets);

    // Variabile con stima.
    await tocca(tester, find.text('Spesa alimentare'));
    await attendi(tester, nelDialogo(find.text('Nuova spesa variabile')));
    await tester.enterText(nelDialogo(find.byType(TextFormField)).at(1), '400');
    await tocca(tester, nelDialogo(find.text('Aggiungi')));
    await attendi(tester, find.text('1.200,00 €'));
    expect(find.textContaining('Speso 0,00 €'), findsOneWidget);

    // Solo per questo mese: 850 €.
    await tocca(tester, find.text('Affitto o mutuo'));
    await attendi(tester, nelDialogo(find.text('Importo')));
    await tester.enterText(nelDialogo(find.byType(TextFormField)).first, '850');
    await tocca(tester, nelDialogo(find.text('Salva')));
    await attendi(tester, find.textContaining('Solo questo mese'));
    await attendi(tester, find.text('1.250,00 €'));

    // Torna al predefinito.
    await tocca(tester, find.text('Affitto o mutuo'));
    await attendi(tester, nelDialogo(find.text('Torna al predefinito')));
    await tocca(tester, nelDialogo(find.text('Torna al predefinito')));
    await attendi(tester, find.text('1.200,00 €'));
    expect(find.textContaining('Solo questo mese'), findsNothing);

    // "Da domani": l'importo di oggi non cambia, compare l'avviso.
    await tocca(tester, find.text('Affitto o mutuo'));
    await attendi(tester, nelDialogo(find.text('Importo')));
    await tester.enterText(nelDialogo(find.byType(TextFormField)).first, '900');
    await tocca(tester, nelDialogo(find.text('Da domani in poi')));
    await tocca(tester, nelDialogo(find.text('Salva')));
    await attendi(tester, find.textContaining(': 900,00 €'));
    expect(find.text('1.200,00 €'), findsWidgets);

    await tocca(tester, find.byTooltip('Archivio aperto: tocca per bloccarlo'));
    await attendi(tester, find.text('Archivio bloccato'));
  });
}
