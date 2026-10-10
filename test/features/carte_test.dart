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
    cartella = await Directory.systemTemp.createTemp('carte_test');
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

  testWidgets('nuova carta, spesa con la carta, avviso sul conto collegato', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    await tester.runAsync(() async {
      await sessione.avvia();
      await sessione.preparaNuovoArchivio('Password-Lunga-1');
      await sessione.confermaNuovoArchivio();
      final tipo = (await sessione.contabilita.tipi('portafoglio'))
          .firstWhere((t) => t.nome == 'Conto corrente');
      await sessione.contabilita.creaPortafoglio(
        nome: 'Conto',
        tipoId: tipo.id,
        valuta: 'EUR',
        saldoIniziale: 100000,
      );
    });
    sessione.avviso = null;
    await tester.pumpWidget(GestionaleApp(sessione: sessione));
    await attendi(tester, find.text('1.000,00 €'));

    await tocca(tester, find.text('Carte').last);
    await attendi(tester, find.text('Aggiungi la tua carta di credito'));
    await tocca(tester, find.text('Nuova carta'));
    await attendi(tester, nelDialogo(find.text('Nuova carta di credito')));
    await tester.enterText(
      nelDialogo(find.byType(TextFormField)).first,
      'Visa',
    );
    await attendi(tester, nelDialogo(find.text('Conto')));
    await tocca(tester, nelDialogo(find.text('Aggiungi')));
    await attendi(tester, find.text('Spesa con la carta'));
    expect(find.text('Visa'), findsWidgets);

    // Spesa con la carta: il modulo propone già la carta.
    await tocca(tester, find.text('Spesa con la carta'));
    await attendi(tester, nelDialogo(find.text('Importo')));
    await tester.enterText(nelDialogo(find.byType(TextFormField)).first, '42');
    await tocca(tester, nelDialogo(find.text('Salva')));
    await attendi(tester, find.text('Debito totale: 42,00 €'));

    // Avviso nel conto collegato.
    await tocca(tester, find.text('Panoramica').last);
    await attendi(tester, find.text('Conto'));
    await tocca(tester, find.text('Conto').first);
    await attendi(tester, find.textContaining('Carta "Visa" su "Conto"'));
    expect(find.textContaining('debito totale 42,00 €'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tocca(tester, find.byTooltip('Archivio aperto: tocca per bloccarlo'));
    await attendi(tester, find.text('Archivio bloccato'));
    // Smonta l'interfaccia e smaltisce i timer di chiusura dei flussi di dati.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
