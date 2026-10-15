import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/app.dart';
import 'package:gestionale_finanziaria/core/crypto/derivazione.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';
import 'package:gestionale_finanziaria/core/ricorrenza.dart';
import 'package:gestionale_finanziaria/core/sessione.dart';
import 'package:gestionale_finanziaria/features/notifiche/campanella.dart';
import 'package:gestionale_finanziaria/features/notifiche/notifiche_pagina.dart';
import 'package:gestionale_finanziaria/features/notifiche/riga_notifica.dart';
import 'package:sodium/sodium_sumo.dart';

void main() {
  late SodiumSumo sodium;
  late Directory cartella;
  late Sessione sessione;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() async {
    cartella = await Directory.systemTemp.createTemp('notifiche_test');
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

  Future<void> sparisce(WidgetTester tester, Finder cosa) async {
    for (var i = 0; i < 200 && cosa.evaluate().isNotEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(cosa, findsNothing);
  }

  Future<void> tocca(WidgetTester tester, Finder cosa) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(cosa);
    await tester.pump();
    await tester.tap(cosa);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Archivio con un conto; [prepara] aggiunge i dati del test.
  Future<String> apri(
    WidgetTester tester,
    Future<void> Function(String conto, Map<String, String> tipi) prepara,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    late String conto;
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
      conto = await c.creaPortafoglio(
        nome: 'ING CC',
        tipoId: tipi['Conto corrente']!,
        valuta: 'EUR',
      );
      await prepara(conto, tipi);
    });
    sessione.avviso = null;
    await tester.pumpWidget(GestionaleApp(sessione: sessione));
    await attendi(tester, find.text('Portafogli'));
    return conto;
  }

  Future<void> chiudi(WidgetTester tester) async {
    sessione.blocca().ignore();
    await attendi(tester, find.text('Archivio bloccato'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }

  Finder nelPannello(Finder f) =>
      find.descendant(of: find.byType(PannelloNotifiche), matching: f);

  Finder nellaPagina(Finder f) =>
      find.descendant(of: find.byType(NotifichePagina), matching: f);

  Finder azione(String titolo, String descrizione) => find.descendant(
    of: find.ancestor(
      of: find.text(titolo),
      matching: find.byType(RigaNotifica),
    ),
    matching: find.byTooltip(descrizione),
  );

  testWidgets(
    'notifiche: campanella, conferma con Annulla, sezione e conferma in massa',
    (tester) async {
      final oggi = DateUtils.dateOnly(DateTime.now());
      await apri(tester, (conto, _) async {
        final cv = sessione.costoVita;
        for (final (nome, importo) in [
          ('Stipendio', 180800),
          ('Lezione', 8000),
        ]) {
          final voce = await cv.creaVoce(
            nome: nome,
            tipo: TipoVoce.fissa,
            importo: importo,
            natura: NaturaVoce.entrata,
          );
          await cv.impostaAddebito(
            voce,
            ricorrenza: Ricorrenza(inizio: oggi),
            portafoglioId: conto,
            richiedeConferma: true,
          );
        }
        final affitto = await cv.creaVoce(
          nome: 'Affitto',
          tipo: TipoVoce.fissa,
          importo: 70000,
        );
        await cv.impostaAddebito(
          affitto,
          ricorrenza: Ricorrenza(inizio: oggi.add(const Duration(days: 2))),
          portafoglioId: conto,
        );
      });

      // La campanella dice quante notifiche ci sono da vedere.
      await attendi(tester, find.byTooltip('Notifiche: 3 da vedere'));
      await tocca(
        tester,
        find
            .descendant(
              of: find.byType(CampanellaNotifiche),
              matching: find.byType(IconButton),
            )
            .first,
      );
      await attendi(tester, find.text('Stipendio'));
      expect(find.text('Da confermare · oggi'), findsNWidgets(2));
      expect(find.text('Si registra da sola tra 2 giorni'), findsNothing);
      expect(find.textContaining('Si registra da sola'), findsOneWidget);

      // Conferma: registrato, con "Annulla" e la "x" per chiudere l'avviso.
      await tocca(
        tester,
        azione('Stipendio', 'Conferma: registra il movimento'),
      );
      await attendi(tester, find.text('Registrato: "Stipendio" 1.808,00 €'));
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.byIcon(Icons.close),
        ),
        findsOneWidget,
      );
      await sparisce(tester, nelPannello(find.text('Stipendio')));
      await tocca(tester, find.text('Annulla'));
      await attendi(tester, nelPannello(find.text('Stipendio')));

      // Un avviso letto sparisce dalla campanella.
      await tocca(tester, azione('Affitto', 'Segna come letta'));
      await sparisce(tester, nelPannello(find.text('Affitto')));
      await attendi(tester, find.byTooltip('Notifiche: 2 da vedere'));

      // Sezione Notifiche: scorciatoia "Da confermare" e conferma in massa.
      await tocca(tester, find.text('Tutte le notifiche'));
      await attendi(tester, find.text('Da confermare (2)'));
      // Le lette restano qui.
      expect(nellaPagina(find.text('Affitto')), findsOneWidget);
      await tocca(tester, find.text('Da confermare (2)'));
      await sparisce(tester, nellaPagina(find.text('Affitto')));
      await tocca(tester, find.text('Seleziona tutte'));
      await tocca(tester, find.text('Conferma (2)'));
      await attendi(tester, find.text('Confermate 2 scadenze'));
      await attendi(tester, find.text('Niente da confermare.'));

      await tocca(tester, find.byType(BackButton));
      await attendi(tester, find.text('Ultimi movimenti'));
      await attendi(tester, find.text('Stipendio'));
      expect(find.text('Lezione'), findsOneWidget);
      await chiudi(tester);
    },
  );

  testWidgets('movimenti: dalla Panoramica, ricerca e filtri', (tester) async {
    await apri(tester, (conto, tipi) async {
      final oggi = DateTime.now();
      for (final (tipo, importo, descrizione) in [
        ('Entrata', 180800, 'Stipendio HD'),
        ('Spesa', 2000, 'Spesa Lidl'),
        ('Spesa', 14250, 'Rata auto'),
      ]) {
        await sessione.contabilita.registraMovimento(
          tipoId: tipi[tipo]!,
          portafoglioId: conto,
          importo: importo,
          valuta: 'EUR',
          data: oggi,
          descrizione: descrizione,
        );
      }
    });

    await tocca(tester, find.text('Tutti i movimenti'));
    final riepilogo = find.textContaining('movimenti · Entrate');
    await attendi(tester, find.textContaining('3 movimenti'));

    // Ricerca (parte quando smetti di scrivere).
    await tester.enterText(
      find.widgetWithText(
        TextField,
        'Cerca: descrizione, categoria, portafoglio o importo',
      ),
      'lidl',
    );
    await attendi(tester, find.textContaining('1 movimento ·'));
    expect(riepilogo, findsNothing);
    await tocca(tester, find.byTooltip('Cancella la ricerca'));
    await attendi(tester, find.textContaining('3 movimenti'));

    // Solo le entrate, poi via i filtri.
    await tocca(tester, find.text('Entrate').hitTestable().last);
    await attendi(tester, find.textContaining('1 movimento ·'));
    await tocca(tester, find.text('Togli i filtri'));
    await attendi(tester, find.textContaining('3 movimenti'));
    await chiudi(tester);
  });
  testWidgets('telefono: filtri nel pannello, valgono solo con "Applica"', (
    tester,
  ) async {
    await apri(tester, (conto, tipi) async {
      for (final (tipo, descrizione) in [
        ('Entrata', 'Stipendio HD'),
        ('Spesa', 'Spesa Lidl'),
      ]) {
        await sessione.contabilita.registraMovimento(
          tipoId: tipi[tipo]!,
          portafoglioId: conto,
          importo: 1000,
          valuta: 'EUR',
          data: DateTime.now(),
          descrizione: descrizione,
        );
      }
    });
    await tester.binding.setSurfaceSize(const Size(400, 800));
    await tester.pump();
    await tocca(tester, find.text('Movimenti').hitTestable().last);
    await attendi(tester, find.text('Tutti i movimenti'));
    expect(find.textContaining('Cerca:'), findsNothing); // nel pannello

    // "Annulla": niente cambia.
    await tocca(tester, find.text('Filtri'));
    await tocca(tester, find.text('Uscite'));
    await tocca(tester, find.text('Annulla'));
    await attendi(tester, find.textContaining('2 movimenti'));

    // "Applica": solo le uscite.
    await tocca(tester, find.text('Filtri'));
    await tocca(tester, find.text('Uscite'));
    await tocca(tester, find.text('Applica'));
    await attendi(tester, find.text('Filtri (1)'));
    await attendi(tester, find.textContaining('1 movimento ·'));
    expect(find.text('Uscite'), findsOneWidget); // nel riepilogo dei filtri

    await tocca(tester, find.byTooltip('Togli i filtri'));
    await attendi(tester, find.textContaining('2 movimenti'));
    await chiudi(tester);
  });
}
