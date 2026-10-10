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
    cartella = await Directory.systemTemp.createTemp('portafogli_test');
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

  Future<void> attendi(WidgetTester tester, Finder cosa) async {
    for (var i = 0; i < 200 && cosa.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      // Fa avanzare anche il tempo simulato (animazioni di apertura/chiusura).
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(cosa, findsWidgets);
  }

  Future<void> tocca(WidgetTester tester, Finder cosa) async {
    // Fine delle animazioni in corso (es. il pulsante "+ Movimento" che compare).
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(cosa);
    await tester.pump();
    await tester.tap(cosa);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Archivio nuovo e sbloccato, app sulla Panoramica.
  Future<void> archivioAperto(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
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
    // Niente notifica "Archivio creato" sopra i pulsanti durante il test.
    sessione.avviso = null;
    await tester.pumpWidget(GestionaleApp(sessione: sessione));
    await attendi(tester, find.text('Crea il tuo primo portafoglio'));
  }

  Finder nelDialogo(Finder f) =>
      find.descendant(of: find.byType(AlertDialog), matching: f);

  testWidgets('primo portafoglio, spesa, saldo aggiornato, elimina e annulla', (
    tester,
  ) async {
    await archivioAperto(tester);

    // Un tocco su "Contanti" apre il modulo già compilato.
    await tocca(tester, find.text('Contanti'));
    await attendi(tester, find.text('Nuovo portafoglio'));
    await attendi(tester, nelDialogo(find.text('Tipo')));
    expect(
      tester
          .widget<TextField>(nelDialogo(find.byType(TextField)).first)
          .controller!
          .text,
      'Contanti',
    );
    await tester.enterText(nelDialogo(find.byType(TextFormField)).last, '50');
    await tocca(tester, find.text('Crea'));
    await attendi(tester, find.text('50,00 €'));
    expect(find.text('Ultimi movimenti'), findsOneWidget);

    // Nuovo movimento: Spesa (predefinita) nel portafoglio Contanti.
    await tocca(tester, find.text('Movimento'));
    await attendi(tester, find.text('Nuovo movimento'));
    await attendi(tester, nelDialogo(find.text('Importo')));
    await tester.enterText(
      nelDialogo(find.byType(TextFormField)).first,
      '12,5',
    );
    await tester.enterText(
      nelDialogo(
        find.widgetWithText(TextFormField, 'Descrizione (facoltativa)'),
      ),
      'Pizzeria',
    );
    await tocca(tester, nelDialogo(find.text('Salva')));
    await attendi(tester, find.text('Pizzeria'));
    await attendi(tester, find.text('37,50 €'));
    expect(find.text('−12,50 €'), findsOneWidget);

    // Importo non valido: messaggio chiaro, niente salvataggio.
    await tocca(tester, find.text('Movimento'));
    await attendi(tester, find.text('Nuovo movimento'));
    await attendi(tester, nelDialogo(find.text('Importo')));
    await tester.enterText(nelDialogo(find.byType(TextFormField)).first, 'abc');
    await tocca(tester, nelDialogo(find.text('Salva')));
    expect(find.text('Scrivi un importo, per esempio 12,50'), findsOneWidget);
    await tocca(tester, nelDialogo(find.text('Annulla')));

    // Elimina dal menu e annulla dalla notifica.
    await tocca(tester, find.byTooltip('Altre azioni'));
    await tocca(tester, find.text('Elimina'));
    await attendi(tester, find.text('Movimento eliminato'));
    await attendi(tester, find.text('50,00 €'));
    expect(find.text('Pizzeria'), findsNothing);
    await tocca(tester, find.text('Annulla'));
    await attendi(tester, find.text('Pizzeria'));
    await attendi(tester, find.text('37,50 €'));

    await tocca(tester, find.byTooltip('Archivio aperto: tocca per bloccarlo'));
    await attendi(tester, find.text('Archivio bloccato'));
  });

  testWidgets('trasferimento tra due portafogli', (tester) async {
    await archivioAperto(tester);
    final c = sessione.contabilita;
    await tester.runAsync(() async {
      final tipi = {for (final t in await c.tipi('portafoglio')) t.nome: t.id};
      await c.creaPortafoglio(
        nome: 'Conto',
        tipoId: tipi['Conto corrente']!,
        valuta: 'EUR',
        saldoIniziale: 100000,
      );
      await c.creaPortafoglio(
        nome: 'Contanti',
        tipoId: tipi['Contanti']!,
        valuta: 'EUR',
      );
    });
    await attendi(tester, find.text('1.000,00 €'));

    await tocca(tester, find.text('Movimento'));
    await attendi(tester, find.text('Nuovo movimento'));
    await attendi(tester, nelDialogo(find.text('Importo')));
    await tocca(tester, nelDialogo(find.text('Trasferimento')));
    await tester.enterText(nelDialogo(find.byType(TextFormField)).first, '200');

    // "A": l'unico altro portafoglio.
    await tocca(tester, nelDialogo(find.text('A')));
    await tocca(tester, find.textContaining('Contanti ·').last);
    await tocca(tester, nelDialogo(find.text('Salva')));

    await attendi(tester, find.text('800,00 €'));
    await attendi(tester, find.text('Conto → Contanti · Oggi'));
    expect(find.text('200,00 €'), findsWidgets);

    await tocca(tester, find.byTooltip('Archivio aperto: tocca per bloccarlo'));
    await attendi(tester, find.text('Archivio bloccato'));
  });
}
