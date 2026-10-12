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

/// Layout su telefono e tablet, in verticale e in orizzontale: tutte le
/// sezioni e le finestre principali. Qualsiasi sforamento (testo o riga che
/// esce dal bordo) fa fallire il test, come succederebbe sul dispositivo vero.
void main() {
  late SodiumSumo sodium;
  late Directory cartella;
  late Sessione sessione;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() async {
    cartella = await Directory.systemTemp.createTemp('schermi_test');
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
    final scorrevoli = find.byType(Scrollable).hitTestable();
    if (scorrevoli.evaluate().isEmpty) {
      return;
    }
    // Il più grande: la pagina, non la barra laterale.
    final pagina = scorrevoli.evaluate().reduce((a, b) {
      final sa = (a.renderObject! as RenderBox).size;
      final sb = (b.renderObject! as RenderBox).size;
      return sa.width * sa.height >= sb.width * sb.height ? a : b;
    });
    for (var i = 0; i < 12; i++) {
      await tester.drag(
        find.byElementPredicate((e) => e == pagina),
        const Offset(0, -500),
      );
      await assestamento(tester);
    }
  }

  /// Torna in cima alla pagina visibile.
  Future<void> scorriInCima(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      final scorrevoli = find.byType(Scrollable).hitTestable();
      if (scorrevoli.evaluate().isEmpty) {
        return;
      }
      await tester.drag(scorrevoli.last, const Offset(0, 500));
      await assestamento(tester);
    }
  }

  Future<void> chiudiDialogo(WidgetTester tester) async {
    await tester.tapAt(const Offset(4, 4)); // fuori dal dialogo
    await assestamento(tester);
  }

  /// Va a una sezione: dalla barra (laterale o in basso) o dal menu "Altro".
  Future<void> vaiA(WidgetTester tester, String sezione) async {
    if (find.text(sezione).hitTestable().evaluate().isEmpty) {
      await tocca(tester, find.text('Altro').hitTestable());
      await attendi(tester, find.text(sezione).hitTestable());
    }
    await tocca(tester, find.text(sezione).hitTestable().last);
    await assestamento(tester);
  }

  Future<void> prepara(DateTime oggi) async {
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
    // Nomi e importi lunghi: il caso peggiore per gli schermi stretti.
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
    for (final nome in ['Carta di credito aziendale', 'Carta viaggi']) {
      await sessione.carte.crea(
        nome: nome,
        contoAddebitoId: conto,
        giornoAddebito: 15,
      );
    }
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
    for (final nome in ['Finanziamento auto con maxi rata', 'Lavatrice']) {
      await sessione.prestiti.crea(
        DatiPrestito(
          nome: nome,
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
    }
    for (final nome in ['Vacanza estiva in montagna con la famiglia', 'Auto']) {
      await sessione.obiettivi.crea(
        nome: nome,
        tipo: TipoObiettivo.personale,
        importoObiettivo: 300000,
      );
    }
  }

  for (final (nome, schermo) in const [
    ('telefono piccolo', Size(360, 740)),
    ('telefono in orizzontale', Size(740, 360)),
    ('tablet piccolo in verticale', Size(600, 960)),
    ('tablet in verticale', Size(800, 1280)),
    ('tablet in orizzontale', Size(1280, 800)),
  ]) {
    testWidgets('$nome: sezioni e finestre senza sforamenti', (tester) async {
      await tester.binding.setSurfaceSize(schermo);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (_) async => null,
      );
      final oggi = DateTime.now();
      await tester.runAsync(() => prepara(oggi));
      // Messaggio di conferma lungo (sul telefono usciva dal bordo).
      sessione.avviso =
          'Archivio sbloccato · 3 pagamenti programmati registrati';
      await tester.pumpWidget(GestionaleApp(sessione: sessione));

      // All'apertura: le richieste sulle maxi rate (rimandate).
      for (var i = 0; i < 2; i++) {
        await attendi(tester, find.text('Maxi rata in arrivo'));
        await tocca(tester, find.textContaining('Ricordamelo più tardi'));
        await assestamento(tester);
      }

      // Panoramica, tutta.
      await attendi(tester, find.text('Portafogli'));
      await scorriTutto(tester);

      // Nuovo movimento, calendario, personalizzazione ed export.
      await tocca(tester, find.byTooltip('Nuovo movimento (Ctrl+N)'));
      await attendi(tester, find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField).first, '1234567');
      await assestamento(tester);
      await tocca(tester, find.byIcon(Icons.calendar_month_outlined));
      await attendi(tester, find.text('Scegli'));
      await tocca(tester, find.text('Annulla').last);
      await assestamento(tester);
      await chiudiDialogo(tester);
      await tocca(tester, find.byTooltip('Personalizza la Panoramica'));
      await attendi(tester, find.text('Ripristina'));
      await chiudiDialogo(tester);
      await tocca(tester, find.byTooltip('Esporta (PDF o Excel)'));
      await assestamento(tester);
      await chiudiDialogo(tester);

      for (final sezione in ['Costo della vita', 'Carte', 'Prestiti']) {
        await vaiA(tester, sezione);
        await scorriTutto(tester);
      }
      // Dettaglio del prestito e suo modulo.
      await scorriInCima(tester);
      await tocca(
        tester,
        find.text('Finanziamento auto con maxi rata').hitTestable().last,
      );
      await attendi(tester, find.text('Importo finanziato'));
      await scorriTutto(tester);
      await tocca(tester, find.byTooltip('Modifica'));
      await attendi(tester, find.text('Modifica prestito'));
      await scorriTutto(tester);
      await tocca(tester, find.text('Annulla').last);
      await assestamento(tester);
      await tocca(tester, find.byType(BackButton));
      await assestamento(tester);

      for (final sezione in ['Obiettivi', 'Categorie']) {
        await vaiA(tester, sezione);
        await scorriTutto(tester);
      }

      sessione.blocca().ignore();
      await attendi(tester, find.text('Archivio bloccato'));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  }
}
