import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/app.dart';
import 'package:gestionale_finanziaria/core/crypto/derivazione.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';
import 'package:gestionale_finanziaria/core/sessione.dart';
import 'package:sodium/sodium_sumo.dart';

const _secci = '''
INFORMAZIONI EUROPEE DI BASE SUL CREDITO AI CONSUMATORI
Finanziatore: Banca Esempio S.p.A.
Importo totale del credito € 10.000,00
n. 48 rate mensili di € 232,94
Scadenza prima rata: 05/12/2026
Tasso annuo nominale (TAN) fisso 6,50 %
Tasso annuo effettivo globale (TAEG) 7,12 %
Spese di incasso rata: € 1,50
''';

void main() {
  late SodiumSumo sodium;
  late Directory cartella;
  late Sessione sessione;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() async {
    cartella = await Directory.systemTemp.createTemp('prestiti_test');
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

  testWidgets('contratto incollato → prestito; il blocco chiude il dettaglio', (
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

    await tocca(tester, find.text('Prestiti').last);
    await attendi(tester, find.text('Mutui, prestiti e acquisti a rate'));
    await tocca(tester, find.text('Nuovo'));
    await attendi(tester, find.text('Incolla il testo del contratto'));
    await tocca(tester, find.text('Incolla il testo del contratto'));
    await attendi(tester, nelDialogo(find.text('Leggi')));
    await tester.enterText(nelDialogo(find.byType(TextField)), _secci);
    await tocca(tester, nelDialogo(find.text('Leggi')));

    await attendi(tester, find.text('Ho trovato 7 dati nel contratto'));
    await tester.enterText(
      nelDialogo(find.widgetWithText(TextFormField, 'Nome')),
      'Prestito auto',
    );
    await attendi(tester, nelDialogo(find.text('Categoria delle rate')));
    await tocca(tester, nelDialogo(find.text('Aggiungi')));
    await attendi(tester, find.text('0 rate pagate su 48 · restano 48'));
    expect(find.textContaining('Prossima rata:'), findsOneWidget);
    // Rata + spese di incasso, come sull'estratto conto.
    expect(find.textContaining('5 dic · 234,44 €'), findsOneWidget);

    // Dettaglio con il piano delle rate.
    await tocca(tester, find.text('Prestito auto'));
    await attendi(tester, find.text('Piano delle rate'));

    // Blocco (es. automatico): il dettaglio non deve restare visibile.
    sessione.blocca().ignore();
    await attendi(tester, find.text('Archivio bloccato'));
    await tester.pump(
      const Duration(milliseconds: 600),
    ); // animazione di chiusura
    expect(find.text('Piano delle rate'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
