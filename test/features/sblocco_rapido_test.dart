import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/app.dart';
import 'package:gestionale_finanziaria/core/crypto/derivazione.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';
import 'package:gestionale_finanziaria/core/sessione.dart';
import 'package:gestionale_finanziaria/core/sicurezza/cassaforte.dart';
import 'package:gestionale_finanziaria/features/comuni/blocco_automatico.dart';
import 'package:sodium/sodium_sumo.dart';

import '../cassaforte_finta.dart';

/// Sblocco con impronta, viso o PIN e blocco automatico (ADR-016).
void main() {
  late SodiumSumo sodium;
  late Directory cartella;
  late CassaforteFinta cassaforte;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() async {
    cartella = await Directory.systemTemp.createTemp('sblocco_rapido_test');
    cassaforte = CassaforteFinta();
  });

  tearDown(() async {
    try {
      await cartella.delete(recursive: true);
    } on FileSystemException {
      // archivio ancora in chiusura
    }
  });

  Sessione nuovaSessione() => Sessione(
    sodium: sodium,
    deposito: DepositoLocale(cartella),
    costoArgon2: (
      ops: ParametriArgon2.opsMinimo,
      mem: ParametriArgon2.memMinima,
    ),
    cassaforte: cassaforte,
  );

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

  Future<void> avvia(WidgetTester tester, Sessione sessione) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    await tester.runAsync(sessione.avvia);
    await tester.pumpWidget(GestionaleApp(sessione: sessione));
  }

  /// Archivio nuovo con lo sblocco rapido già attivo, poi bloccato.
  Future<void> preparaConRapido() async {
    final sessione = nuovaSessione();
    await sessione.avvia();
    await sessione.preparaNuovoArchivio('Password-Lunga-1');
    await sessione.confermaNuovoArchivio();
    await sessione.attivaSbloccoRapido();
    await sessione.blocca();
    sessione.dispose();
  }

  Future<void> chiudi(WidgetTester tester, Sessione sessione) async {
    if (sessione.fase == FaseSessione.sbloccata) {
      sessione.blocca().ignore();
      await attendi(tester, find.text('Archivio bloccato'));
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('all\'avvio la verifica parte da sola e apre l\'archivio', (
    tester,
  ) async {
    await tester.runAsync(preparaConRapido);
    final sessione = nuovaSessione();
    await avvia(tester, sessione);
    await attendi(tester, find.text('Panoramica'));
    expect(cassaforte.verifiche, 2); // attivazione + questo sblocco
    await chiudi(tester, sessione);
  });

  testWidgets('dopo il lucchetto: pulsante, non parte da solo', (tester) async {
    await tester.runAsync(preparaConRapido);
    final sessione = nuovaSessione();
    cassaforte.annulla = true; // all'avvio l'utente annulla
    await avvia(tester, sessione);
    await attendi(tester, find.text('Sblocca con impronta, viso o PIN'));
    expect(find.text('Sblocca con la password'), findsOneWidget);
    // La verifica partita da sola viene annullata: il pulsante si riattiva.
    final pulsante = find.ancestor(
      of: find.text('Sblocca con impronta, viso o PIN'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    bool attivo() =>
        tester.widget<ButtonStyleButton>(pulsante.first).onPressed != null;
    for (var i = 0; i < 100 && (cassaforte.annulla || !attivo()); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(attivo(), isTrue);
    expect(sessione.fase, FaseSessione.bloccata);

    await tocca(tester, find.text('Sblocca con impronta, viso o PIN'));
    await attendi(tester, find.text('Panoramica'));

    // Lucchetto: si resta sulla pagina di sblocco, senza verifica automatica.
    final prima = cassaforte.verifiche;
    sessione.blocca().ignore();
    await attendi(tester, find.text('Archivio bloccato'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(cassaforte.verifiche, prima);
    await chiudi(tester, sessione);
  });

  testWidgets('chiave annullata dal sistema: spiega e chiede la password', (
    tester,
  ) async {
    await tester.runAsync(preparaConRapido);
    cassaforte.chiaveAnnullata = true;
    final sessione = nuovaSessione();
    await avvia(tester, sessione);
    await attendi(tester, find.textContaining('Lo sblocco rapido si è spento'));
    expect(find.text('Sblocca con impronta, viso o PIN'), findsNothing);
    expect(find.text('Sblocca'), findsOneWidget);
    await chiudi(tester, sessione);
  });

  testWidgets('dopo la password propone di attivarlo; "Attiva"', (
    tester,
  ) async {
    final sessione = nuovaSessione();
    await tester.runAsync(() async {
      await sessione.avvia();
      await sessione.preparaNuovoArchivio('Password-Lunga-1');
      await sessione.confermaNuovoArchivio();
      await sessione.blocca();
    });
    await avvia(tester, sessione);
    await tester.enterText(find.byType(TextField), 'Password-Lunga-1');
    await tocca(tester, find.text('Sblocca'));
    await attendi(tester, find.text('Sblocco più veloce'));
    await tocca(tester, find.text('Attiva'));
    await attendi(tester, find.textContaining('attivo. Ogni'));
    expect(sessione.sicurezza.rapidoAttivo, isTrue);
    await chiudi(tester, sessione);
  });

  testWidgets('"Non ora": non lo ripropone; Impostazioni lo attivano', (
    tester,
  ) async {
    final sessione = nuovaSessione();
    await tester.runAsync(() async {
      await sessione.avvia();
      await sessione.preparaNuovoArchivio('Password-Lunga-1');
      await sessione.confermaNuovoArchivio();
      await sessione.blocca();
    });
    await avvia(tester, sessione);
    await tester.enterText(find.byType(TextField), 'Password-Lunga-1');
    await tocca(tester, find.text('Sblocca'));
    await attendi(tester, find.text('Sblocco più veloce'));
    await tocca(tester, find.text('Non ora'));
    await attendi(tester, find.textContaining('Impostazioni › Sicurezza'));
    expect(sessione.sicurezza.rapidoAttivo, isFalse);

    // Impostazioni (sul telefono in "Altro").
    await tocca(tester, find.text('Altro'));
    await tocca(tester, find.text('Impostazioni'));
    await attendi(tester, find.text('Sblocco con impronta, viso o PIN'));
    await tocca(tester, find.byType(Switch));
    await attendi(tester, find.textContaining('Attivo. La password'));
    expect(sessione.sicurezza.rapidoAttivo, isTrue);

    // Blocco automatico: "Subito".
    await tocca(tester, find.text('Blocco automatico'));
    await tocca(tester, find.text('Subito'));
    await attendi(tester, find.text('In secondo piano: subito'));
    expect(sessione.sicurezza.bloccoAutomatico, Duration.zero);

    // Di nuovo con la password: nessuna proposta.
    sessione.blocca().ignore();
    await attendi(tester, find.text('Sblocca con la password'));
    await tester.enterText(find.byType(TextField), 'Password-Lunga-1');
    await tocca(tester, find.text('Sblocca con la password'));
    await attendi(tester, find.text('Panoramica'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Sblocco più veloce'), findsNothing);
    await chiudi(tester, sessione);
  });

  group('blocco automatico', () {
    /// Archivio con sblocco rapido e il blocco automatico scelto, aperto
    /// all'avvio con la verifica automatica.
    Future<Sessione> aperta(WidgetTester tester, Duration? blocco) async {
      final sessione = nuovaSessione();
      await tester.runAsync(() async {
        await sessione.avvia();
        await sessione.preparaNuovoArchivio('Password-Lunga-1');
        await sessione.confermaNuovoArchivio();
        await sessione.attivaSbloccoRapido();
        await sessione.sicurezza.impostaBloccoAutomatico(blocco);
        await sessione.blocca();
      });
      await avvia(tester, sessione);
      await attendi(tester, find.text('Panoramica'));
      return sessione;
    }

    void inSecondoPiano(WidgetTester tester) {
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    }

    void davanti(WidgetTester tester) {
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }

    /// In secondo piano l'app non disegna (come sul telefono): si guarda lo
    /// stato dell'archivio, non lo schermo.
    Future<void> bloccata(WidgetTester tester, Sessione sessione) async {
      for (var i = 0; i < 100 && sessione.fase != FaseSessione.bloccata; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(sessione.fase, FaseSessione.bloccata);
    }

    testWidgets('"Subito": si blocca e al ritorno si riapre col dito', (
      tester,
    ) async {
      final sessione = await aperta(tester, Duration.zero);
      final prima = cassaforte.verifiche;
      inSecondoPiano(tester);
      await bloccata(tester, sessione);
      // In secondo piano la verifica non parte.
      await tester.pump(const Duration(milliseconds: 200));
      expect(cassaforte.verifiche, prima);
      davanti(tester);
      await attendi(tester, find.text('Panoramica'));
      expect(cassaforte.verifiche, prima + 1);
      await chiudi(tester, sessione);
    });

    testWidgets('dopo 1 minuto in secondo piano', (tester) async {
      final sessione = await aperta(tester, const Duration(minutes: 1));
      inSecondoPiano(tester);
      await tester.pump(const Duration(seconds: 30));
      expect(sessione.fase, FaseSessione.sbloccata);
      await tester.pump(const Duration(seconds: 31));
      await bloccata(tester, sessione);
      davanti(tester);
      await attendi(tester, find.text('Panoramica'));
      await chiudi(tester, sessione);
    });

    testWidgets('"Mai" e fotocamera/file: non si blocca', (tester) async {
      final sessione = await aperta(tester, Duration.zero);
      // Fotocamera o scelta di un file: l'app va in secondo piano per scelta.
      await senzaBloccoAutomatico(() async {
        inSecondoPiano(tester);
        await tester.pump(const Duration(milliseconds: 100));
      });
      expect(sessione.fase, FaseSessione.sbloccata);
      davanti(tester);
      await tester.pump(const Duration(milliseconds: 100));

      await tester.runAsync(
        () => sessione.sicurezza.impostaBloccoAutomatico(null),
      );
      inSecondoPiano(tester);
      await tester.pump(const Duration(minutes: 10));
      davanti(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(sessione.fase, FaseSessione.sbloccata);
      await chiudi(tester, sessione);
    });
  });

  test('senza sblocco rapido sul dispositivo: nessuna proposta', () async {
    cassaforte.stato = DisponibilitaCassaforte.nessunMetodo;
    final sessione = nuovaSessione();
    await sessione.avvia();
    await sessione.preparaNuovoArchivio('Password-Lunga-1');
    await sessione.confermaNuovoArchivio();
    expect(sessione.prendiPropostaAttivazione(), isFalse);
    await sessione.blocca();
    sessione.dispose();
  });
}
