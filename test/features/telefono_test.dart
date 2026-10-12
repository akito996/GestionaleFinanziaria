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
import 'package:sodium/sodium_sumo.dart';

/// Layout da telefono: tutte le sezioni e le finestre principali su uno
/// schermo piccolo. Qualsiasi sforamento (testo o riga che esce dal bordo)
/// fa fallire il test, come succederebbe sul telefono vero.
void main() {
  late SodiumSumo sodium;
  late Directory cartella;
  late Sessione sessione;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() async {
    cartella = await Directory.systemTemp.createTemp('telefono_test');
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

  /// Scorre fino in fondo la pagina visibile (così si costruisce tutto).
  Future<void> scorriTutto(WidgetTester tester) async {
    final scorrevole = find.byType(Scrollable).hitTestable().first;
    for (var i = 0; i < 12; i++) {
      await tester.drag(scorrevole, const Offset(0, -500));
      await assestamento(tester);
    }
  }

  Future<void> chiudiDialogo(WidgetTester tester) async {
    await tester.tapAt(const Offset(4, 4)); // fuori dal dialogo
    await assestamento(tester);
  }

  testWidgets('telefono piccolo: sezioni e finestre senza sforamenti', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
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
      final c = sessione.contabilita;
      final tipi = {
        for (final t in [
          ...await c.tipi(AmbitoTipo.movimento),
          ...await c.tipi(AmbitoTipo.portafoglio),
        ])
          t.nome: t.id,
      };
      // Nomi e importi lunghi: il caso peggiore per lo schermo stretto.
      final conto = await c.creaPortafoglio(
        nome: 'Conto corrente principale di famiglia',
        tipoId: tipi['Conto corrente']!,
        valuta: 'EUR',
        saldoIniziale: 123456789,
      );
      await c.impostaPreferito(conto, true);
      for (final nome in ['Contanti', 'Risparmi', 'Fondo emergenze']) {
        await c.creaPortafoglio(
          nome: nome,
          tipoId: tipi['Contanti']!,
          valuta: 'EUR',
          saldoIniziale: 100000,
        );
      }
      await sessione.carte.crea(
        nome: 'Carta di credito aziendale',
        contoAddebitoId: conto,
        giornoAddebito: 15,
      );
      await c.registraMovimento(
        tipoId: tipi['Spesa']!,
        portafoglioId: conto,
        importo: 1234567,
        valuta: 'EUR',
        data: oggi,
        descrizione: 'Spesa con una descrizione molto lunga per il telefono',
      );
      await c.registraMovimento(
        tipoId: tipi['Entrata']!,
        portafoglioId: conto,
        importo: 345678,
        valuta: 'EUR',
        data: oggi,
      );
      await sessione.costoVita.creaVoce(
        nome: 'Assicurazione casa e responsabilità civile',
        tipo: TipoVoce.fissa,
        importo: 120000,
      );
      await sessione.prestiti.crea(
        DatiPrestito(
          nome: 'Finanziamento auto con maxi rata',
          tipo: TipoPrestito.prestito,
          capitale: 1470720,
          numeroRate: 4,
          importoRata: 13900,
          maxiRata: 1099600,
          speseRata: 350,
          primaRata: DateTime(oggi.year, oggi.month, 10),
          portafoglioId: conto,
        ),
      );
      await sessione.obiettivi.crea(
        nome: 'Vacanza estiva in montagna con la famiglia',
        tipo: TipoObiettivo.personale,
        importoObiettivo: 300000,
      );
    });
    // Messaggio di conferma lungo (sul telefono usciva dal bordo).
    sessione.avviso = 'Archivio sbloccato · 3 pagamenti programmati registrati';
    await tester.pumpWidget(GestionaleApp(sessione: sessione));

    // All'apertura: la richiesta sulla maxi rata.
    await attendi(tester, find.text('Maxi rata in arrivo'));
    await tocca(tester, find.textContaining('Ricordamelo più tardi'));

    // Panoramica, tutta.
    await attendi(tester, find.text('Portafogli'));
    await scorriTutto(tester);

    // Nuovo movimento e personalizzazione della Panoramica.
    await tocca(tester, find.byTooltip('Nuovo movimento (Ctrl+N)'));
    await attendi(tester, find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField).first, '1234567');
    await assestamento(tester);
    await chiudiDialogo(tester);
    await tocca(tester, find.byTooltip('Personalizza la Panoramica'));
    await attendi(tester, find.text('Ripristina'));
    await chiudiDialogo(tester);
    await tocca(tester, find.byTooltip('Esporta (PDF o Excel)'));
    await assestamento(tester);
    await chiudiDialogo(tester);

    // Le sezioni della barra in basso.
    for (final sezione in ['Costo della vita', 'Carte', 'Prestiti']) {
      await tocca(tester, find.text(sezione).last);
      await assestamento(tester);
      await scorriTutto(tester);
    }
    // Dettaglio del prestito e suo modulo.
    await tocca(tester, find.text('Finanziamento auto con maxi rata').last);
    await attendi(tester, find.text('Piano delle rate'));
    await scorriTutto(tester);
    await tocca(tester, find.byTooltip('Modifica'));
    await attendi(tester, find.text('Modifica prestito'));
    await scorriTutto(tester);
    await tocca(tester, find.text('Annulla').last);
    await assestamento(tester);
    await tocca(tester, find.byType(BackButton));
    await assestamento(tester);

    // Le sezioni in "Altro".
    for (final sezione in ['Obiettivi', 'Categorie']) {
      await tocca(tester, find.text('Altro'));
      await attendi(tester, find.text(sezione));
      await tocca(tester, find.text(sezione).last);
      await assestamento(tester);
      await scorriTutto(tester);
    }

    sessione.blocca().ignore();
    await attendi(tester, find.text('Archivio bloccato'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
