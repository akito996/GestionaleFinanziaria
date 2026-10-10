import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/app.dart';
import 'package:gestionale_finanziaria/core/crypto/derivazione.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';
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
    cartella = await Directory.systemTemp.createTemp('panoramica_test');
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

  Future<void> assestamento(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> tocca(WidgetTester tester, Finder cosa) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(cosa);
    await tester.pump();
    await tester.tap(cosa);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> apri(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1300, 1800));
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
          ...await c.tipi(AmbitoTipo.movimento),
          ...await c.tipi(AmbitoTipo.portafoglio),
        ])
          t.nome: t.id,
      };
      final conto = await c.creaPortafoglio(
        nome: 'Conto principale',
        tipoId: tipi['Conto corrente']!,
        valuta: 'EUR',
        saldoIniziale: 100000,
      );
      for (final nome in ['Fondo casa', 'Fondo viaggi']) {
        await c.creaPortafoglio(
          nome: nome,
          tipoId: tipi['Risparmi']!,
          valuta: 'EUR',
          saldoIniziale: 20000,
          gruppo: 'Risparmi',
        );
      }
      await sessione.carte.crea(
        nome: 'Visa',
        contoAddebitoId: conto,
        giornoAddebito: 15,
      );
      final visa = (await sessione.carte.stati()).single.portafoglio.id;
      await c.registraMovimento(
        tipoId: tipi['Spesa']!,
        portafoglioId: visa,
        importo: 4200,
        valuta: 'EUR',
        data: DateTime.now(),
      );
    });
    sessione.avviso = null;
    await tester.pumpWidget(GestionaleApp(sessione: sessione));
    await attendi(tester, find.text('Conto principale'));
    await assestamento(tester);
  }

  Future<void> chiudi(WidgetTester tester) async {
    sessione.blocca().ignore();
    await attendi(tester, find.text('Archivio bloccato'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('gruppi, preferiti e carta dentro il conto', (tester) async {
    await apri(tester);

    // La carta non è un riquadro a sé: il suo avviso è nel conto collegato.
    expect(find.text('Visa'), findsNothing);
    expect(find.textContaining('Carta "Visa"'), findsOneWidget);

    // Il gruppo parte chiuso; un tocco lo apre.
    expect(find.text('Risparmi'), findsWidgets);
    expect(find.text('Fondo casa'), findsNothing);
    await tocca(tester, find.text('2 portafogli'));
    await attendi(tester, find.text('Fondo casa'));

    // Preferito: resta visibile anche con il gruppo chiuso.
    final stella = find.descendant(
      of: find.ancestor(
        of: find.text('Fondo casa'),
        matching: find.byType(ListTile),
      ),
      matching: find.byTooltip('Aggiungi ai preferiti'),
    );
    await tocca(tester, stella);
    await attendi(tester, find.byTooltip('Togli dai preferiti'));
    await tocca(tester, find.text('1 portafoglio'));
    await assestamento(tester);
    expect(find.text('Fondo casa'), findsOneWidget);
    expect(find.text('Fondo viaggi'), findsNothing);

    await chiudi(tester);
  });

  testWidgets('categorie: albero aperto nella sezione, chiuso nel movimento', (
    tester,
  ) async {
    await apri(tester);

    await tocca(tester, find.text('Categorie').last);
    await attendi(tester, find.text('Bollette'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Cerca (es. luce, spesa, auto)').first,
      'boll',
    );
    await tester.pump();
    expect(find.text('Casa › Bollette'), findsOneWidget);

    // Nel movimento le categorie partono raggruppate (chiuse).
    await tocca(tester, find.text('Panoramica').last);
    await tocca(tester, find.byTooltip('Nuovo movimento (Ctrl+N)'));
    await attendi(tester, find.text('Categoria (facoltativa)'));
    await tocca(tester, find.text('Categoria (facoltativa)'));
    await attendi(tester, find.text('Nessuna categoria'));
    final dialogo = find.byType(AlertDialog).last;
    expect(
      find.descendant(of: dialogo, matching: find.text('Casa')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialogo, matching: find.text('Bollette')),
      findsNothing,
    );
    await tocca(
      tester,
      find.descendant(
        of: find.ancestor(
          of: find.descendant(of: dialogo, matching: find.text('Casa')),
          matching: find.byType(ListTile),
        ),
        matching: find.byTooltip('Apri'),
      ),
    );
    expect(
      find.descendant(of: dialogo, matching: find.text('Bollette')),
      findsOneWidget,
    );
    await tocca(
      tester,
      find.descendant(of: dialogo, matching: find.text('Bollette')),
    );
    await attendi(tester, find.text('Casa › Bollette'));

    await chiudi(tester);
  });
}
