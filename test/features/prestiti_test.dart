import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/app.dart';
import 'package:gestionale_finanziaria/core/crypto/derivazione.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';
import 'package:gestionale_finanziaria/core/db/prestiti.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';
import 'package:gestionale_finanziaria/core/sessione.dart';
import 'package:gestionale_finanziaria/features/notifiche/campanella.dart';
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
    // Totale addebitato per rata: 232,94 € + 1,50 € di spese.
    expect(nelDialogo(find.text('234,44 €')), findsOneWidget);
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

  testWidgets(
    "maxi rata: richiesta all'apertura, rimando, campanella, scelta",
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (_) async => null,
      );
      final oggi = DateTime.now();
      await tester.runAsync(() async {
        await sessione.avvia();
        await sessione.preparaNuovoArchivio('Password-Lunga-1');
        await sessione.confermaNuovoArchivio();
        // 4 rate da oggi: la maxi rata è fra 3 mesi (entro i 6). La prima è
        // oggi, non in un giorno fisso: con "Conta dal" le rate già passate
        // non contano (il test dipenderebbe dalla data).
        await sessione.prestiti.crea(
          DatiPrestito(
            nome: 'Auto',
            tipo: TipoPrestito.prestito,
            capitale: 1500000,
            numeroRate: 4,
            importoRata: 30000,
            maxiRata: 1400000,
            speseRata: 350,
            primaRata: DateTime(oggi.year, oggi.month, oggi.day),
          ),
        );
      });
      sessione.avviso = null;
      await tester.pumpWidget(GestionaleApp(sessione: sessione));

      // All'apertura: la domanda. "Ricordamelo più tardi" la rimanda.
      await attendi(tester, find.text('Maxi rata in arrivo'));
      expect(find.textContaining('14.003,50 €'), findsOneWidget);
      await tocca(tester, find.textContaining('Ricordamelo più tardi'));
      // La decisione resta nella campanella delle notifiche.
      final campanella = find
          .descendant(
            of: find.byType(CampanellaNotifiche),
            matching: find.byIcon(Icons.notifications_active_outlined),
          )
          .hitTestable();
      await attendi(tester, campanella);

      // Nel costo della vita: la rata del mese tra le spese fisse.
      await tocca(tester, find.text('Costo della vita').last);
      await attendi(tester, find.text('Prestiti e rate'));
      expect(find.textContaining('Rata 1 di 4'), findsOneWidget);
      expect(find.text('303,50 €'), findsWidgets);

      // Dalla campanella si decide: poi la notifica sparisce.
      await tocca(tester, campanella);
      final decisione = find.text('Maxi rata di "Auto": scegli cosa fare');
      await attendi(tester, decisione);
      await tocca(
        tester,
        find.byTooltip('Scegli: apri un altro prestito o paghi tutto'),
      );
      await attendi(tester, find.text("Pago tutto in un'unica soluzione"));
      await tocca(tester, find.text("Pago tutto in un'unica soluzione"));
      for (var i = 0; i < 200 && decisione.evaluate().isNotEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(decisione, findsNothing);
      await tocca(tester, find.byTooltip('Chiudi'));

      sessione.blocca().ignore();
      await attendi(tester, find.text('Archivio bloccato'));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    },
  );
}
