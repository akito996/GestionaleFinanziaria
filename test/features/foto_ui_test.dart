import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/app.dart';
import 'package:gestionale_finanziaria/core/crypto/derivazione.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';
import 'package:gestionale_finanziaria/core/foto/lettura_foto.dart';
import 'package:gestionale_finanziaria/core/sessione.dart';
import 'package:gestionale_finanziaria/features/foto/foto.dart';
import 'package:sodium/sodium_sumo.dart';

/// Lettore finto: [righe] per ogni foto; lo zoom restituisce la stessa riga.
class _LettoreFinto implements LettoreFoto {
  _LettoreFinto(this.righe);

  final List<String> righe;

  @override
  Future<FotoLetta> leggi(String percorso) async => FotoLetta(
    larghezza: 1000,
    altezza: righe.length * 40 + 40,
    righe: [
      for (final (i, t) in righe.indexed)
        RigaLetta(t, Riquadro(50, 20 + i * 40, 900, 50 + i * 40)),
    ],
  );

  @override
  Future<ZonaLetta> zona(
    String percorso,
    Riquadro zona, {
    bool riga = true,
  }) async {
    final i = ((zona.sopra + zona.sotto) / 2 - 20) ~/ 40;
    return ZonaLetta(
      testo: righe[i.clamp(0, righe.length - 1)],
      affidabilita: 90,
      // PNG 1x1: la zona ingrandita mostrata all'utente.
      immagine: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQ'
        'DwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      ),
    );
  }

  @override
  Future<void> chiudi() async {}
}

void main() {
  late SodiumSumo sodium;
  late Directory cartella;
  late Sessione sessione;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() async {
    cartella = await Directory.systemTemp.createTemp('foto_ui_test');
    sessione = Sessione(
      sodium: sodium,
      deposito: DepositoLocale(cartella),
      costoArgon2: (
        ops: ParametriArgon2.opsMinimo,
        mem: ParametriArgon2.memMinima,
      ),
    );
    fotoDisponibile = () => true;
    prendiFoto = (_) async => '${cartella.path}/foto-inesistente.jpg';
    // Nei test niente scaricamento del modello preciso.
    preparaModelloPreciso = () async {};
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

  Future<void> apri(WidgetTester tester) async {
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
      final c = sessione.contabilita;
      final tipo = (await c.tipi(AmbitoTipo.portafoglio))
          .firstWhere((t) => t.nome == 'Conto corrente');
      await c.creaPortafoglio(nome: 'ING CC', tipoId: tipo.id, valuta: 'EUR');
    });
    sessione.avviso = null;
    await tester.pumpWidget(GestionaleApp(sessione: sessione));
    await attendi(tester, find.text('Portafogli'));
  }

  Future<void> chiudi(WidgetTester tester) async {
    sessione.blocca().ignore();
    await attendi(tester, find.text('Archivio bloccato'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('scontrino dalla foto: dati controllati e movimento salvato', (
    tester,
  ) async {
    final oggi = DateTime.now();
    final data =
        '${oggi.day.toString().padLeft(2, '0')}-'
        '${oggi.month.toString().padLeft(2, '0')}-${oggi.year}';
    lettoreFoto = _LettoreFinto([
      'ESSELUNGA S.P.A.',
      'DOCUMENTO COMMERCIALE',
      'Pane 2,10',
      'TOTALE COMPLESSIVO 23,40',
      '$data 10:21',
    ]);
    await apri(tester);

    await tocca(tester, find.byTooltip('Nuovo movimento (Ctrl+N)'));
    // Il pulsante si attiva quando il modulo è pronto.
    await attendi(tester, find.text('Descrizione (facoltativa)'));
    await tocca(tester, find.byTooltip('Leggi da una foto dello scontrino'));
    await tocca(tester, find.text('Scatta una foto'));
    await attendi(tester, find.text('Ecco cosa ho letto'));
    expect(find.text('Esselunga S.p.a.'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(3)); // le zone ingrandite
    await tocca(tester, find.text('Usa questi dati'));

    await attendi(tester, find.text('Nuovo movimento'));
    final descrizione = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Descrizione (facoltativa)'),
    );
    expect(descrizione.controller!.text, 'Esselunga S.p.a.');
    await tocca(tester, find.text('Salva'));
    // Salvato: il modulo si chiude e il movimento è nell'elenco.
    await attendi(tester, find.text('−23,40 €'));
    expect(find.text('−23,40 €'), findsOneWidget);
    await chiudi(tester);
  });

  testWidgets('prestito dal contratto fotografato (due pagine)', (
    tester,
  ) async {
    lettoreFoto = _LettoreFinto([
      'INFORMAZIONI EUROPEE DI BASE SUL CREDITO AI CONSUMATORI',
      'Finanziatore: Banca Esempio S.p.A.',
      'Importo totale del credito € 10.000,00',
      'n. 48 rate mensili di € 232,94',
      'Tasso annuo nominale (TAN) fisso 6,50 %',
      'Tasso annuo effettivo globale (TAEG) 7,12 %',
    ]);
    await apri(tester);
    await tocca(tester, find.text('Prestiti'));
    await attendi(tester, find.text('Prestiti e rate'));
    await tocca(tester, find.text('Nuovo').hitTestable());
    await tocca(tester, find.text('Fotografa il contratto'));
    await tocca(tester, find.text('Scatta una foto'));
    await attendi(tester, find.text('1 pagina pronta'));
    await tocca(tester, find.text("Aggiungi un'altra pagina"));
    await tocca(tester, find.text('Scatta una foto'));
    await attendi(tester, find.text('2 pagine pronte'));
    await tocca(tester, find.text('Leggi il contratto'));
    await attendi(
      tester,
      find.widgetWithText(TextFormField, 'TAN (facoltativo)'),
    );
    final tan = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'TAN (facoltativo)'),
    );
    expect(tan.controller!.text, '6,50');
    await tocca(tester, find.text('Annulla').last);
    await chiudi(tester);
  });
}
