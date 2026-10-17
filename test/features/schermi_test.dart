import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/app.dart';
import 'package:gestionale_finanziaria/core/crypto/derivazione.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';
import 'package:gestionale_finanziaria/core/db/prestiti.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';
import 'package:gestionale_finanziaria/core/ricorrenza.dart';
import 'package:gestionale_finanziaria/core/sessione.dart';
import 'package:gestionale_finanziaria/core/sync/accesso_google.dart';
import 'package:gestionale_finanziaria/core/sync/backend_memoria.dart';
import 'package:gestionale_finanziaria/features/notifiche/campanella.dart';
import 'package:http/http.dart' as http;
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
      accessoGoogle: _AccessoFinto(),
      creaBackend: (_) => BackendInMemoria(),
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

  /// Scorre la pagina visibile di [passo] per 12 volte (in giù = negativo).
  Future<void> scorri(WidgetTester tester, double passo) async {
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
    final posizione = (pagina as StatefulElement).state as ScrollableState;
    for (var i = 0; i < 12; i++) {
      // Già in cima: un altro trascinamento verso il basso sarebbe
      // "trascina per aggiornare".
      if (passo > 0 && posizione.position.extentBefore == 0) {
        break;
      }
      await tester.drag(
        find.byElementPredicate((e) => e == pagina),
        Offset(0, passo),
      );
      await assestamento(tester);
    }
  }

  /// Scorre fino in fondo la pagina visibile (così si costruisce tutto).
  Future<void> scorriTutto(WidgetTester tester) => scorri(tester, -500);

  /// Torna in cima alla pagina visibile.
  Future<void> scorriInCima(WidgetTester tester) => scorri(tester, 500);

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
      final obiettivo = await sessione.obiettivi.crea(
        nome: nome,
        tipo: TipoObiettivo.personale,
        importoObiettivo: 300000,
        portafoglioId: conto,
      );
      await sessione.obiettivi.versa(obiettivo, importo: 120000, data: oggi);
    }
    // Notifiche: entrate da confermare oggi e un promemoria senza portafoglio.
    for (final nome in [
      'Lezione privata con un nome molto lungo da confermare',
      'Stipendio',
    ]) {
      final voce = await sessione.costoVita.creaVoce(
        nome: nome,
        tipo: TipoVoce.fissa,
        importo: 1234567,
        natura: NaturaVoce.entrata,
      );
      await sessione.costoVita.impostaAddebito(
        voce,
        ricorrenza: Ricorrenza(inizio: oggi),
        portafoglioId: conto,
        richiedeConferma: true,
      );
    }
    final promemoria = await sessione.costoVita.creaVoce(
      nome: 'Rata cessione del quinto: promemoria',
      tipo: TipoVoce.fissa,
      importo: 28600,
    );
    await sessione.costoVita.impostaAddebito(
      promemoria,
      ricorrenza: Ricorrenza(inizio: oggi),
    );
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
      await scorriInCima(tester);

      // Il portafoglio con i soldi messi da parte per gli obiettivi.
      await tocca(
        tester,
        find.text('Conto corrente principale di famiglia').hitTestable().first,
      );
      await attendi(tester, find.textContaining('Di questi soldi'));
      await scorriTutto(tester);
      await tocca(tester, find.byType(BackButton));
      await assestamento(tester);

      // Campanella: pannello e sezione Notifiche con la selezione.
      await tocca(
        tester,
        find
            .descendant(
              of: find.byType(CampanellaNotifiche),
              matching: find.byType(IconButton),
            )
            .hitTestable(),
      );
      await attendi(tester, find.text('Tutte le notifiche'));
      await attendi(tester, find.text('Stipendio'));
      await tocca(tester, find.text('Tutte le notifiche'));
      await attendi(tester, find.text('Seleziona tutte'));
      await tocca(tester, find.text('Seleziona tutte'));
      await attendi(tester, find.textContaining('Conferma ('));
      await scorriTutto(tester);
      await tocca(tester, find.byType(BackButton));
      await assestamento(tester);

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
      // Esporta e Personalizza sono nel menu ☰.
      await tocca(
        tester,
        find.byTooltip('Altri strumenti').hitTestable().first,
      );
      await tocca(tester, find.text('Personalizza').hitTestable());
      await attendi(tester, find.text('Ripristina'));
      await chiudiDialogo(tester);
      await tocca(
        tester,
        find.byTooltip('Altri strumenti').hitTestable().first,
      );
      await tocca(tester, find.text('Esporta').hitTestable());
      await assestamento(tester);
      await chiudiDialogo(tester);

      // Sincronizzazione (spenta: pulsante per accenderla).
      await tocca(
        tester,
        find.byTooltip('Sincronizzazione spenta').hitTestable().first,
      );
      await attendi(
        tester,
        find.text('PC, telefono e tablet sempre allineati'),
      );
      await scorriTutto(tester);
      expect(find.text('Accendi con Google Drive'), findsOneWidget);
      await tocca(tester, find.byType(BackButton));
      await assestamento(tester);

      // Movimenti, anche con le date a scelta.
      await vaiA(tester, 'Movimenti');
      if (find.text('Scegli le date').hitTestable().evaluate().isEmpty) {
        // Telefono e tablet: ricerca e opzioni sono nel pannello "Filtri".
        await tocca(tester, find.text('Filtri'));
      }
      await tocca(tester, find.text('Scegli le date'));
      await attendi(tester, find.text('Dal'));
      await scorriTutto(tester);
      if (find.text('Applica').evaluate().isNotEmpty) {
        await tocca(tester, find.text('Applica'));
        await assestamento(tester);
        await scorriTutto(tester);
      }

      for (final sezione in [
        'Costo della vita',
        'Entrate',
        'Carte',
        'Prestiti',
      ]) {
        await vaiA(tester, sezione);
        await scorriTutto(tester);
      }
      // Prestiti: "Mostra meno" (una riga per prestito) e ritorno.
      await scorriInCima(tester);
      await tocca(tester, find.text('Mostra meno').hitTestable().first);
      await attendi(tester, find.text('Mostra di più'));
      await scorriTutto(tester);
      await scorriInCima(tester);
      await tocca(tester, find.text('Mostra di più').hitTestable().first);
      await assestamento(tester);
      // Dettaglio del prestito e suo modulo.
      await scorriInCima(tester);
      // (tocca lo porta in vista: con "Mostra meno" in cima sta più in basso)
      await tocca(tester, find.text('Finanziamento auto con maxi rata').first);
      await attendi(tester, find.text('Importo finanziato'));
      await scorriTutto(tester);
      await tocca(tester, find.byTooltip('Modifica'));
      await attendi(tester, find.text('Modifica prestito'));
      await scorriTutto(tester);
      await tocca(tester, find.text('Annulla').last);
      await assestamento(tester);
      await tocca(tester, find.byType(BackButton));
      await assestamento(tester);

      for (final sezione in ['Obiettivi', 'Categorie', 'Report']) {
        await vaiA(tester, sezione);
        await scorriTutto(tester);
      }
      // Un report creato e mostrato a schermo (sul telefono, prima le opzioni).
      await scorriInCima(tester);
      if (find.text('Opzioni').hitTestable().evaluate().isNotEmpty) {
        await tocca(tester, find.text('Opzioni'));
        await attendi(tester, find.text('Opzioni del report'));
        await scorriTutto(tester);
        await tocca(tester, find.text('Applica'));
        await assestamento(tester);
      }
      await tocca(tester, find.text('Crea il report'));
      await attendi(tester, find.text('Report del gestionale'));
      await scorriTutto(tester);
      await tocca(tester, find.byType(BackButton));
      await assestamento(tester);

      sessione.blocca().ignore();
      await attendi(tester, find.text('Archivio bloccato'));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  }
}

/// Google finto: la pagina della sincronizzazione si vede come sul telefono.
class _AccessoFinto implements AccessoGoogle {
  @override
  bool get disponibile => true;

  @override
  Future<http.Client?> client({required bool interattivo}) async => null;

  @override
  Future<void> invalida() async {}

  @override
  Future<void> esci() async {}
}
