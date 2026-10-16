import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/app.dart';
import 'package:gestionale_finanziaria/core/crypto/derivazione.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';
import 'package:gestionale_finanziaria/core/sessione.dart';
import 'package:gestionale_finanziaria/features/notifiche/campanella.dart';
import 'package:sodium/sodium_sumo.dart';

/// Barra in alto con il menu ☰, tema, portafogli archiviati ed eliminazione.
void main() {
  late SodiumSumo sodium;
  late Directory cartella;
  late Sessione sessione;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() async {
    cartella = await Directory.systemTemp.createTemp('menu_portafogli_test');
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
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(cosa.first);
    await tester.pump();
    await tester.tap(cosa.first);
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> avvia(WidgetTester tester) async {
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
      final c = sessione.contabilita;
      final tipi = {
        for (final t in [
          ...await c.tipi(AmbitoTipo.portafoglio),
          ...await c.tipi(AmbitoTipo.movimento),
        ])
          t.nome: t.id,
      };
      final contanti = await c.creaPortafoglio(
        nome: 'Contanti',
        tipoId: tipi['Contanti']!,
        valuta: 'EUR',
        saldoIniziale: 5000,
      );
      await c.creaPortafoglio(
        nome: 'Salvadanaio',
        tipoId: tipi['Contanti']!,
        valuta: 'EUR',
        saldoIniziale: 1000,
      );
      await c.registraMovimento(
        tipoId: tipi['Spesa']!,
        portafoglioId: contanti,
        importo: 1200,
        valuta: 'EUR',
        data: DateTime.now(),
        descrizione: 'Pizzeria',
      );
    });
    sessione.avviso = null;
    await tester.pumpWidget(GestionaleApp(sessione: sessione));
    await attendi(tester, find.text('Contanti'));
  }

  Future<void> chiudi(WidgetTester tester) async {
    sessione.blocca().ignore();
    await attendi(tester, find.text('Archivio bloccato'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('menu ☰: notifiche, esporta, personalizza; tema scuro', (
    tester,
  ) async {
    await avvia(tester);
    // Nessuna notifica: la campanella non è in vista.
    expect(
      find
          .descendant(
            of: find.byType(CampanellaNotifiche),
            matching: find.byType(IconButton),
          )
          .hitTestable(),
      findsNothing,
    );
    await tocca(tester, find.byTooltip('Altri strumenti').hitTestable());
    expect(find.text('Notifiche').hitTestable(), findsOneWidget);
    expect(find.text('Esporta').hitTestable(), findsOneWidget);
    expect(find.text('Personalizza').hitTestable(), findsOneWidget);
    expect(
      find.text('Scegli e ordina le schede della Panoramica'),
      findsOneWidget,
    );
    await tocca(tester, find.text('Notifiche').hitTestable());
    await attendi(tester, find.text('Tutte le notifiche'));
    await tester.tapAt(const Offset(10, 10)); // chiude il pannello
    await tester.pump(const Duration(milliseconds: 400));

    // Impostazioni › Aspetto: tema scuro, ricordato sul dispositivo.
    await tocca(tester, find.text('Impostazioni').hitTestable());
    await attendi(tester, find.text('Scuro'));
    await tocca(tester, find.text('Scuro'));
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      File('${cartella.path}/preferenze.json').readAsStringSync(),
      contains('scuro'),
    );
    await chiudi(tester);
  });

  testWidgets('gesto Indietro: sezione di prima, poi due volte per uscire', (
    tester,
  ) async {
    await avvia(tester);
    final chiamate = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (c) async {
        chiamate.add(c.method);
        return null;
      },
    );
    await tocca(tester, find.text('Movimenti').hitTestable());
    await tocca(tester, find.text('Impostazioni').hitTestable());
    await attendi(tester, find.text('Portafogli archiviati'));

    Future<void> indietro() async {
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 300));
    }

    Finder titolo(String testo) => find
        .descendant(of: find.byType(AppBar), matching: find.text(testo))
        .hitTestable();

    expect(titolo('Impostazioni'), findsOneWidget);
    await indietro();
    expect(titolo('Movimenti'), findsOneWidget);
    await indietro();
    expect(titolo('WalleCy'), findsOneWidget);
    await indietro();
    expect(
      find.text('Torna indietro ancora una volta per uscire'),
      findsOneWidget,
    );
    expect(chiamate, isNot(contains('SystemNavigator.pop')));
    await indietro();
    expect(chiamate, contains('SystemNavigator.pop'));
    await chiudi(tester);
  });

  testWidgets('archivia, ritrova in Impostazioni ed elimina con Annulla', (
    tester,
  ) async {
    await avvia(tester);
    await tocca(tester, find.text('Salvadanaio'));
    await attendi(tester, find.byTooltip('Archivia portafoglio'));
    await tocca(tester, find.byTooltip('Archivia portafoglio'));
    await tocca(tester, find.widgetWithText(FilledButton, 'Archivia'));
    // Si aspetta l'archivio, non il messaggio (sparisce da solo).
    for (var i = 0; i < 100; i++) {
      final archiviati = await tester.runAsync(
        () => sessione.contabilita.osservaPortafogli(archiviati: true).first,
      );
      if (archiviati!.isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 300));

    await tocca(tester, find.text('Impostazioni').hitTestable());
    await tocca(tester, find.text('Portafogli archiviati'));
    await attendi(tester, find.text('Salvadanaio'));
    await tocca(tester, find.byTooltip('Ripristina'));
    await attendi(tester, find.text('Nessun portafoglio archiviato'));
    await tocca(tester, find.byType(BackButton));

    // Elimina "Contanti" con il suo movimento, poi Annulla.
    await tocca(tester, find.text('Panoramica').hitTestable());
    await tocca(tester, find.text('Contanti'));
    await attendi(tester, find.byTooltip('Elimina portafoglio'));
    await tocca(tester, find.byTooltip('Elimina portafoglio'));
    await attendi(tester, find.textContaining('ha 1 movimento'));
    await tocca(tester, find.text('Elimina il portafoglio'));
    await tocca(tester, find.widgetWithText(FilledButton, 'Elimina'));
    await attendi(tester, find.text('"Contanti" eliminato'));
    // "Contanti" resta come tipo del Salvadanaio: si controlla l'archivio.
    Future<List<String>> portafogli() async => [
      for (final p in (await tester.runAsync(
        () => sessione.contabilita.osservaPortafogli().first,
      ))!)
        p.portafoglio.nome,
    ];
    expect(await portafogli(), ['Salvadanaio']);
    await tocca(tester, find.text('Annulla'));
    expect(await portafogli(), containsAll(['Contanti', 'Salvadanaio']));
    await chiudi(tester);
  });
}
