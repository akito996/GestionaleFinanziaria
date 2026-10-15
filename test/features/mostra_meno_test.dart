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

/// "Mostra meno" / "Mostra di più" sul telefono: dopo il tocco il pulsante per
/// riaprire resta sullo schermo (la pagina non salta altrove) e non ci sono
/// errori.
void main() {
  late SodiumSumo sodium;
  late Directory cartella;
  late Sessione sessione;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() async {
    cartella = await Directory.systemTemp.createTemp('mostra_meno_test');
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

  Future<void> assestamento(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Scorre la pagina in giù finché [cosa] esiste (le liste costruiscono solo
  /// quello che sta vicino allo schermo).
  Future<void> cercaScorrendo(WidgetTester tester, Finder cosa) async {
    for (var i = 0; i < 20 && cosa.evaluate().isEmpty; i++) {
      final scorrevoli = find.byType(Scrollable).hitTestable();
      final pagina = scorrevoli.evaluate().reduce((a, b) {
        final sa = (a.renderObject! as RenderBox).size;
        final sb = (b.renderObject! as RenderBox).size;
        return sa.width * sa.height >= sb.width * sb.height ? a : b;
      });
      await tester.drag(
        find.byElementPredicate((e) => e == pagina),
        const Offset(0, -300),
      );
      await assestamento(tester);
    }
    expect(cosa, findsWidgets);
  }

  /// Scorre la pagina finché [cosa] è sullo schermo.
  Future<void> portaInVista(WidgetTester tester, Finder cosa) async {
    await tester.ensureVisible(cosa.first);
    await assestamento(tester);
  }

  Future<void> tocca(WidgetTester tester, Finder cosa) async {
    await portaInVista(tester, cosa);
    await tester.tap(cosa.first);
    await assestamento(tester);
  }

  void restaInVista(Finder cosa, String dove) => expect(
    cosa.hitTestable(),
    findsWidgets,
    reason: '$dove: dopo "Mostra meno" il pulsante per riaprire è sparito',
  );

  Future<void> prepara() async {
    await sessione.avvia();
    await sessione.preparaNuovoArchivio('Password-Lunga-1');
    await sessione.confermaNuovoArchivio();
    final c = sessione.contabilita;
    final tipi = {
      for (final t in await c.tipi(AmbitoTipo.portafoglio)) t.nome: t.id,
    };
    String? conto;
    for (var i = 1; i <= 8; i++) {
      final id = await c.creaPortafoglio(
        nome: 'Portafoglio $i',
        tipoId: tipi['Conto corrente']!,
        valuta: 'EUR',
        saldoIniziale: 10000 * i,
      );
      conto ??= id;
    }
    for (final (nome, tipo) in [
      ('Affitto', TipoVoce.fissa),
      ('Luce', TipoVoce.fissa),
      ('Gas', TipoVoce.fissa),
      ('Internet', TipoVoce.fissa),
      ('Spesa', TipoVoce.variabile),
      ('Carburante', TipoVoce.variabile),
      ('Ristoranti', TipoVoce.variabile),
      ('Farmacia', TipoVoce.variabile),
    ]) {
      await sessione.costoVita.creaVoce(nome: nome, tipo: tipo, importo: 5000);
    }
    final oggi = DateTime.now();
    for (final nome in ['Auto', 'Lavatrice', 'Divano']) {
      await sessione.prestiti.crea(
        DatiPrestito(
          nome: nome,
          tipo: TipoPrestito.prestito,
          capitale: 300000,
          numeroRate: 12,
          importoRata: 26000,
          primaRata: DateTime(oggi.year, oggi.month, 20),
          portafoglioId: conto,
        ),
      );
    }
    for (final nome in ['Vacanza', 'Bici', 'Computer']) {
      await sessione.obiettivi.crea(
        nome: nome,
        tipo: TipoObiettivo.personale,
        importoObiettivo: 100000,
      );
    }
    for (final (nome, tipo) in [
      ('Stipendio', TipoVoce.fissa),
      ('Affitto incassato', TipoVoce.fissa),
      ('Lezioni private', TipoVoce.variabile),
      ('Vendite online', TipoVoce.variabile),
      ('Rimborsi', TipoVoce.variabile),
      ('Regali', TipoVoce.variabile),
    ]) {
      await sessione.costoVita.creaVoce(
        nome: nome,
        tipo: tipo,
        importo: 20000,
        natura: NaturaVoce.entrata,
      );
    }
    for (final nome in ['Carta oro', 'Carta viaggi', 'Carta spesa']) {
      await sessione.carte.crea(
        nome: nome,
        contoAddebitoId: conto!,
        giornoAddebito: 15,
      );
    }
  }

  testWidgets(
    'telefono: "Mostra meno" non fa sparire il pulsante per riaprire',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (_) async => null,
      );
      await tester.runAsync(prepara);
      sessione.avviso = null;
      await tester.pumpWidget(GestionaleApp(sessione: sessione));
      await attendi(tester, find.text('Portafogli'));
      await assestamento(tester);

      // Panoramica: portafogli.
      await tocca(tester, find.textContaining('Mostra altro ('));
      await tocca(tester, find.text('Mostra meno'));
      restaInVista(find.textContaining('Mostra altro ('), 'Portafogli');

      // Costo della vita: l'ultima sezione (variabili), in fondo alla pagina.
      await tocca(tester, find.text('Costo della vita').hitTestable().last);
      await attendi(tester, find.text('Spese fisse'));
      await cercaScorrendo(tester, find.text('Spese variabili'));
      final variabili = find.ancestor(
        of: find.text('Spese variabili'),
        matching: find.byType(ListTile),
      );
      await tocca(
        tester,
        find.descendant(of: variabili, matching: find.byTooltip('Mostra meno')),
      );
      restaInVista(
        find.descendant(
          of: variabili,
          matching: find.byTooltip('Mostra di più'),
        ),
        'Costo della vita',
      );

      // Prestiti: tutte ridotte e poi una sola aperta e richiusa.
      await tocca(tester, find.text('Altro'));
      await tocca(tester, find.text('Prestiti'));
      await attendi(tester, find.text('Debito residuo totale'));
      await tocca(tester, find.text('Mostra meno'));
      restaInVista(find.text('Mostra di più'), 'Prestiti');
      await tocca(tester, find.text('Divano'));
      await tocca(tester, find.text('Mostra meno').last);
      restaInVista(find.text('Divano'), 'Prestiti (una voce)');

      // Obiettivi: come i prestiti.
      await tocca(tester, find.text('Altro'));
      await tocca(tester, find.text('Obiettivi'));
      await attendi(tester, find.text('Computer'));
      await tocca(tester, find.text('Mostra meno'));
      restaInVista(find.text('Mostra di più'), 'Obiettivi');
      await tocca(tester, find.text('Vacanza'));
      await tocca(tester, find.text('Mostra meno').last);
      restaInVista(find.text('Vacanza'), 'Obiettivi (una voce)');

      // Entrate: l'ultima sezione, in fondo alla pagina.
      await tocca(tester, find.text('Entrate').hitTestable().last);
      await attendi(tester, find.text('Entrate fisse'));
      await cercaScorrendo(tester, find.text('Entrate variabili'));
      final entrateVariabili = find.ancestor(
        of: find.text('Entrate variabili'),
        matching: find.byType(ListTile),
      );
      await tocca(
        tester,
        find.descendant(
          of: entrateVariabili,
          matching: find.byTooltip('Mostra meno'),
        ),
      );
      restaInVista(
        find.descendant(
          of: entrateVariabili,
          matching: find.byTooltip('Mostra di più'),
        ),
        'Entrate',
      );

      // Carte: tutte ridotte, poi una sola aperta e richiusa.
      await tocca(tester, find.text('Altro'));
      await tocca(tester, find.text('Carte'));
      await attendi(tester, find.text('Carta spesa'));
      await tocca(tester, find.text('Mostra meno'));
      restaInVista(find.text('Mostra di più'), 'Carte');
      await tocca(tester, find.text('Carta viaggi'));
      await tocca(tester, find.text('Mostra meno').last);
      restaInVista(find.text('Carta viaggi'), 'Carte (una voce)');

      // Categorie: un ramo chiuso in fondo all'albero resta in vista.
      await tocca(tester, find.text('Altro'));
      await tocca(tester, find.text('Categorie'));
      await attendi(tester, find.byTooltip('Chiudi'));
      await cercaScorrendo(tester, find.byTooltip('Chiudi').hitTestable());
      final ramo = find.byTooltip('Chiudi').hitTestable().last;
      final riga = find.ancestor(of: ramo, matching: find.byType(ListTile));
      final nome = tester
          .widget<Text>(
            find.descendant(of: riga.first, matching: find.byType(Text)).last,
          )
          .data!;
      await tocca(tester, ramo);
      restaInVista(find.text(nome), 'Categorie');

      sessione.blocca().ignore();
      await attendi(tester, find.text('Archivio bloccato'));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    },
  );
}
