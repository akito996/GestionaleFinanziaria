import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/db/archivio.dart';
import 'package:gestionale_finanziaria/core/db/contabilita.dart';
import 'package:gestionale_finanziaria/core/db/costo_vita.dart';
import 'package:gestionale_finanziaria/core/db/pianificatore.dart';
import 'package:gestionale_finanziaria/core/db/prestiti.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';
import 'package:gestionale_finanziaria/core/ricorrenza.dart';

void main() {
  late Archivio db;
  late Contabilita c;
  late CostoVita cv;
  late Pianificatore pian;
  late DateTime adesso;

  final ottobre = DateTime(2026, 10);
  final settembre = DateTime(2026, 9);
  final novembre = DateTime(2026, 11);

  setUp(() async {
    db = Archivio.inMemoria();
    c = await Contabilita.apri(db);
    adesso = DateTime(2026, 10, 10, 15);
    pian = Pianificatore(db, c.orologio, adesso: () => adesso);
    cv = CostoVita(db, c.orologio, pian, adesso: () => adesso);
  });

  tearDown(() => db.close());

  Future<VoceDelMese?> voce(String nome, DateTime mese) async =>
      (await cv.riepiloghi([mese])).single.voci
          .where((v) => v.voce.nome == nome)
          .firstOrNull;

  Future<String> categoria(String nome) async =>
      (await c.osservaCategorie().first).firstWhere((x) => x.nome == nome).id;

  test('voce fissa: vale dal mese in cui la crei, non prima', () async {
    await cv.creaVoce(nome: 'Affitto', tipo: TipoVoce.fissa, importo: 80000);
    expect((await voce('Affitto', ottobre))!.previsto, 80000);
    expect((await voce('Affitto', novembre))!.previsto, 80000);
    expect(await voce('Affitto', settembre), isNull);
  });

  test(
    'cambio "da domani": si vede dal giorno dopo, con avviso prima',
    () async {
      final id = await cv.creaVoce(
        nome: 'Affitto',
        tipo: TipoVoce.fissa,
        importo: 80000,
      );
      await cv.cambiaImportoPredefinito(id, 85000, Decorrenza.domani);

      final oggi = (await voce('Affitto', ottobre))!;
      expect(oggi.previsto, 80000);
      expect(oggi.prossimaModifica, (importo: 85000, dal: '2026-10-11'));

      adesso = DateTime(2026, 10, 11, 8);
      final domani = (await voce('Affitto', ottobre))!;
      expect(domani.previsto, 85000);
      expect(domani.prossimaModifica, isNull);
      expect((await voce('Affitto', novembre))!.previsto, 85000);
    },
  );

  test(
    'cambio "dal mese prossimo": il mese in corso resta invariato',
    () async {
      final id = await cv.creaVoce(
        nome: 'Luce',
        tipo: TipoVoce.fissa,
        importo: 12000,
      );
      await cv.cambiaImportoPredefinito(id, 10000, Decorrenza.meseProssimo);

      expect((await voce('Luce', ottobre))!.previsto, 12000);
      expect((await voce('Luce', novembre))!.previsto, 10000);

      // A dicembre i mesi passati mostrano ciascuno il proprio importo.
      adesso = DateTime(2026, 12, 3);
      expect((await voce('Luce', ottobre))!.previsto, 12000);
      expect((await voce('Luce', novembre))!.previsto, 10000);
    },
  );

  test('variazione di un solo mese, poi annullata', () async {
    final id = await cv.creaVoce(
      nome: 'Gas',
      tipo: TipoVoce.fissa,
      importo: 6000,
    );
    await cv.variaMese(id, ottobre, 9500);
    await cv.variaMese(id, ottobre, 9000); // seconda modifica dello stesso mese

    final ott = (await voce('Gas', ottobre))!;
    expect(ott.previsto, 9000);
    expect(ott.predefinito, 6000);
    expect(ott.variato, isTrue);
    expect((await voce('Gas', novembre))!.previsto, 6000);

    await cv.annullaVariazione(id, ottobre);
    final dopo = (await voce('Gas', ottobre))!;
    expect(dopo.previsto, 6000);
    expect(dopo.variato, isFalse);
  });

  test(
    'variabile: stima e spese reali della categoria e sottocategorie',
    () async {
      final alimentari = await categoria('Alimentari');
      final spesa = await categoria('Spesa');
      final ristoranti = await categoria('Ristoranti e bar');
      final carburante = await categoria('Carburante');

      await cv.creaVoce(
        nome: 'Mangiare',
        tipo: TipoVoce.variabile,
        importo: 40000,
        categoriaId: alimentari,
      );

      final tipi = {
        for (final t in [
          ...await c.tipi(AmbitoTipo.movimento),
          ...await c.tipi(AmbitoTipo.portafoglio),
        ])
          t.nome: t.id,
      };
      final contanti = await c.creaPortafoglio(
        nome: 'Contanti',
        tipoId: tipi['Contanti']!,
        valuta: 'EUR',
      );
      Future<void> uscita(int importo, String categoria, DateTime data) =>
          c.registraMovimento(
            tipoId: tipi['Spesa']!,
            portafoglioId: contanti,
            categoriaId: categoria,
            importo: importo,
            valuta: 'EUR',
            data: data,
          );
      await uscita(7530, spesa, DateTime(2026, 10, 2));
      await uscita(2500, ristoranti, DateTime(2026, 10, 9));
      await uscita(5000, carburante, DateTime(2026, 10, 5)); // altra categoria
      await uscita(9999, spesa, DateTime(2026, 9, 30)); // altro mese
      // Un'entrata nella stessa categoria non conta come spesa.
      await c.registraMovimento(
        tipoId: tipi['Entrata']!,
        portafoglioId: contanti,
        categoriaId: spesa,
        importo: 1000,
        valuta: 'EUR',
        data: DateTime(2026, 10, 3),
      );

      final v = (await voce('Mangiare', ottobre))!;
      expect(v.previsto, 40000);
      expect(v.reale, 7530 + 2500);
    },
  );

  test('totali del mese e storico per il grafico', () async {
    await cv.creaVoce(nome: 'Affitto', tipo: TipoVoce.fissa, importo: 80000);
    final internet = await cv.creaVoce(
      nome: 'Internet',
      tipo: TipoVoce.fissa,
      importo: 3000,
    );
    await cv.creaVoce(nome: 'Svago', tipo: TipoVoce.variabile, importo: 15000);

    final mese = (await cv.riepiloghi([ottobre])).single;
    expect(mese.fisse, 83000);
    expect(mese.variabiliPreviste, 15000);
    expect(mese.totalePrevisto, 98000);
    expect(mese.variabiliReali, 0);

    await cv.archiviaVoce(internet);
    expect((await cv.riepiloghi([ottobre])).single.fisse, 80000);

    final storico = await cv.osservaStorico(finoA: novembre, quanti: 3).first;
    expect(storico.map((m) => m.mese), [settembre, ottobre, novembre]);
    expect(storico.map((m) => m.totalePrevisto), [0, 95000, 95000]);
  });

  test('il riepilogo si aggiorna da solo quando cambia qualcosa', () async {
    final valori = <int>[];
    final sub = cv
        .osservaMese(ottobre)
        .listen((r) => valori.add(r.totalePrevisto));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await cv.creaVoce(nome: 'Affitto', tipo: TipoVoce.fissa, importo: 80000);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    expect(valori.first, 0);
    expect(valori.last, 80000);
  });

  group('data di addebito', () {
    Future<String> contoCorrente() async {
      final tipo = (await c.tipi(AmbitoTipo.portafoglio))
          .firstWhere((t) => t.nome == 'Conto corrente');
      return c.creaPortafoglio(nome: 'Conto', tipoId: tipo.id, valuta: 'EUR');
    }

    test('bolletta bimestrale: conta solo nei mesi con addebito', () async {
      final luce = await cv.creaVoce(
        nome: 'Luce',
        tipo: TipoVoce.variabile,
        importo: 12000,
      );
      await cv.impostaAddebito(
        luce,
        ricorrenza: Ricorrenza(
          inizio: DateTime(2026, 10, 20),
          frequenza: Frequenza.bimestrale,
        ),
      );
      expect((await voce('Luce', ottobre))!.previsto, 12000);
      expect((await voce('Luce', ottobre))!.dateAddebito, [
        DateTime(2026, 10, 20),
      ]);
      expect((await voce('Luce', novembre))!.previsto, 0);
      expect((await voce('Luce', DateTime(2026, 12)))!.previsto, 12000);
    });

    test('fine dopo N addebiti: i mesi successivi non contano', () async {
      final rata = await cv.creaVoce(
        nome: 'Corso',
        tipo: TipoVoce.fissa,
        importo: 5000,
      );
      await cv.impostaAddebito(
        rata,
        ricorrenza: Ricorrenza(inizio: DateTime(2026, 10, 1), occorrenze: 2),
      );
      expect((await voce('Corso', ottobre))!.previsto, 5000);
      expect((await voce('Corso', novembre))!.previsto, 5000);
      expect(await voce('Corso', DateTime(2026, 12)), isNull);
    });

    test(
      'registrazione automatica: una volta sola, anche aprendo dopo',
      () async {
        final conto = await contoCorrente();
        final affitto = await cv.creaVoce(
          nome: 'Affitto',
          tipo: TipoVoce.fissa,
          importo: 80000,
          categoriaId: await categoria('Affitto o mutuo'),
        );
        await cv.impostaAddebito(
          affitto,
          ricorrenza: Ricorrenza(inizio: DateTime(2026, 10, 5)),
          portafoglioId: conto,
        );

        expect(await pian.registraScadute(), 1); // 5 ottobre
        expect(await pian.registraScadute(), 0); // già fatto

        final ottobreMov = (await c.osservaMovimenti().first).single;
        expect(ottobreMov.movimento.data, '2026-10-05');
        expect(ottobreMov.movimento.importoMinimo, 80000);
        expect(ottobreMov.movimento.descrizione, 'Affitto');
        expect(ottobreMov.categoria?.nome, 'Affitto o mutuo');

        // Dicembre: importo cambiato solo per dicembre; l'app riaperta il 6/12
        // recupera novembre e dicembre.
        await cv.variaMese(affitto, DateTime(2026, 12), 85000);
        adesso = DateTime(2026, 12, 6);
        expect(await pian.registraScadute(), 2);
        final importi = {
          for (final m in await c.osservaMovimenti().first)
            m.movimento.data: m.movimento.importoMinimo,
        };
        expect(importi, {
          '2026-10-05': 80000,
          '2026-11-05': 80000,
          '2026-12-05': 85000,
        });

        // Un movimento automatico cancellato dall'utente non torna.
        final novembreId = (await c.osservaMovimenti().first)
            .firstWhere((m) => m.movimento.data == '2026-11-05')
            .movimento
            .id;
        await c.eliminaMovimento(novembreId);
        expect(await pian.registraScadute(), 0);
      },
    );

    test('avviso 3 giorni prima e voce archiviata sospesa', () async {
      final conto = await contoCorrente();
      final gas = await cv.creaVoce(
        nome: 'Gas',
        tipo: TipoVoce.variabile,
        importo: 6000,
      );
      await cv.impostaAddebito(
        gas,
        ricorrenza: Ricorrenza(inizio: DateTime(2026, 10, 13)),
        portafoglioId: conto,
      );

      final arrivo = await pian.inArrivo(giorni: 10);
      expect(arrivo.single.data, DateTime(2026, 10, 13));
      expect(arrivo.single.importo, 6000);
      expect(arrivo.single.giorniMancanti, 3);
      expect(arrivo.single.daAvvisare, isTrue);
      expect(
        (await pian.inArrivo(giorni: 10, portafoglioId: conto)),
        hasLength(1),
      );

      await cv.archiviaVoce(gas);
      expect(await pian.inArrivo(giorni: 10), isEmpty);
      adesso = DateTime(2026, 10, 14);
      expect(await pian.registraScadute(), 0);

      await cv.archiviaVoce(gas, archiviata: false);
      expect(await pian.registraScadute(), 1);
    });

    test('senza portafoglio è solo un promemoria', () async {
      final voceId = await cv.creaVoce(
        nome: 'Acqua',
        tipo: TipoVoce.variabile,
        importo: 3000,
      );
      await cv.impostaAddebito(
        voceId,
        ricorrenza: Ricorrenza(inizio: DateTime(2026, 10, 1)),
      );
      expect(await pian.registraScadute(), 0);
      expect(await pian.inArrivo(), isNotEmpty);
    });

    test('spesa annuale suddivisa nei mesi: 1.200 € → 100 € al mese', () async {
      final bollo = await cv.creaVoce(
        nome: 'Assicurazione',
        tipo: TipoVoce.fissa,
        importo: 120000,
        ripartita: true,
      );
      await cv.impostaAddebito(
        bollo,
        ricorrenza: Ricorrenza(
          inizio: DateTime(2027, 3, 15),
          frequenza: Frequenza.annuale,
        ),
      );
      // Anche prima del primo pagamento: è la quota da mettere da parte.
      for (final mese in [ottobre, novembre, DateTime(2027, 3)]) {
        final v = (await voce('Assicurazione', mese))!;
        expect(v.previsto, 10000);
        expect(v.ripartita, isTrue);
        expect(v.importoUnitario, 120000);
      }
      expect((await voce('Assicurazione', DateTime(2027, 3)))!.dateAddebito, [
        DateTime(2027, 3, 15),
      ]);

      // Senza suddivisione: tutto nel mese del pagamento.
      await cv.modificaVoce(bollo, nome: 'Assicurazione', ripartita: false);
      expect(await voce('Assicurazione', ottobre), isNull);
      expect(
        (await voce('Assicurazione', DateTime(2027, 3)))!.previsto,
        120000,
      );
      expect(
        CostoVita.quotaMensile(1200, Frequenza.settimanale),
        5200,
        reason: '12 € a settimana = 52 € al mese',
      );
    });

    test("suddivisa e finita: dopo l'ultimo addebito non conta più", () async {
      final corso = await cv.creaVoce(
        nome: 'Corso',
        tipo: TipoVoce.fissa,
        importo: 60000,
        ripartita: true,
      );
      await cv.impostaAddebito(
        corso,
        ricorrenza: Ricorrenza(
          inizio: DateTime(2026, 10, 1),
          frequenza: Frequenza.semestrale,
          occorrenze: 1,
        ),
      );
      expect((await voce('Corso', ottobre))!.previsto, 10000);
      expect(await voce('Corso', novembre), isNull);
    });

    test(
      'voce eliminata: sparisce e si ferma; "Annulla" la ripristina',
      () async {
        final conto = await contoCorrente();
        final palestra = await cv.creaVoce(
          nome: 'Palestra',
          tipo: TipoVoce.fissa,
          importo: 4000,
        );
        await cv.impostaAddebito(
          palestra,
          ricorrenza: Ricorrenza(inizio: DateTime(2026, 10, 20)),
          portafoglioId: conto,
        );
        expect(await pian.inArrivo(), hasLength(1));

        await cv.eliminaVoce(palestra);
        expect(await voce('Palestra', ottobre), isNull);
        expect(await pian.inArrivo(), isEmpty);
        adesso = DateTime(2026, 10, 25);
        expect(await pian.registraScadute(), 0);

        await cv.ripristinaVoce(palestra);
        expect((await voce('Palestra', ottobre))!.previsto, 4000);
        expect(await pian.registraScadute(), 1);
      },
    );
  });

  test(
    "le rate dei prestiti contano tra le fisse fino all'estinzione",
    () async {
      final prestiti = PrestitiServizio(
        db,
        c.orologio,
        pian,
        adesso: () => adesso,
      );
      final id = await prestiti.crea(
        DatiPrestito(
          nome: 'Auto',
          tipo: TipoPrestito.prestito,
          capitale: 1200000,
          numeroRate: 3,
          importoRata: 300000,
          maxiRata: 600000,
          speseRata: 350,
          primaRata: DateTime(2026, 10, 15),
        ),
      );
      final mesi = await cv.riepiloghi([
        ottobre,
        novembre,
        DateTime(2026, 12),
        DateTime(2027, 1),
      ]);
      expect(mesi[0].vuoto, isFalse); // anche senza altre voci
      expect(mesi[0].rate.single.importo, 300350); // rata + spese
      expect(mesi[0].rate.single.numero, 1);
      expect(mesi[0].fisse, 300350);
      expect(mesi[1].totalePrevisto, 300350);
      expect(mesi[2].rate.single.maxi, isTrue);
      expect(mesi[2].fisse, 600350);
      expect(mesi[3].rate, isEmpty); // estinto

      // Maxi rata rifinanziata: nel mese della scadenza non esce dal conto.
      await prestiti.decidiMaxi(id, DecisioneMaxi.rifinanzia);
      expect((await cv.riepiloghi([DateTime(2026, 12)])).single.rate, isEmpty);
    },
  );

  test(
    'entrate previste: separate dal costo della vita, accredito automatico',
    () async {
      final tipo = (await c.tipi(AmbitoTipo.portafoglio))
          .firstWhere((t) => t.nome == 'Conto corrente');
      final conto = await c.creaPortafoglio(
        nome: 'Conto',
        tipoId: tipo.id,
        valuta: 'EUR',
      );
      await cv.creaVoce(nome: 'Affitto', tipo: TipoVoce.fissa, importo: 80000);
      final stipendio = await cv.creaVoce(
        nome: 'Stipendio',
        tipo: TipoVoce.fissa,
        importo: 210000,
        natura: NaturaVoce.entrata,
      );
      final extra = await cv.creaVoce(
        nome: 'Lavori extra',
        tipo: TipoVoce.variabile,
        importo: 30000,
        categoriaId: await categoria('Altre entrate'),
        natura: NaturaVoce.entrata,
      );

      final spese = (await cv.riepiloghi([ottobre])).single;
      final entrate = (await cv.riepiloghi([
        ottobre,
      ], natura: NaturaVoce.entrata)).single;
      expect(spese.voci.map((v) => v.voce.nome), ['Affitto']);
      expect(entrate.voci.map((v) => v.voce.nome), [
        'Stipendio',
        'Lavori extra',
      ]);
      expect(entrate.totalePrevisto, 240000);

      // "Ricevuto davvero": le entrate della categoria, non le uscite.
      final tipi = {
        for (final t in await c.tipi(AmbitoTipo.movimento)) t.nome: t.id,
      };
      for (final (t, importo) in [('Entrata', 12000), ('Spesa', 5000)]) {
        await c.registraMovimento(
          tipoId: tipi[t]!,
          portafoglioId: conto,
          categoriaId: await categoria('Altre entrate'),
          importo: importo,
          valuta: 'EUR',
          data: DateTime(2026, 10, 3),
        );
      }
      final ricevuto = (await cv.riepiloghi([
        ottobre,
      ], natura: NaturaVoce.entrata)).single;
      expect(ricevuto.voci.firstWhere((v) => v.voce.id == extra).reale, 12000);

      // Accredito automatico dello stipendio: si registra come entrata.
      await cv.impostaAddebito(
        stipendio,
        ricorrenza: Ricorrenza(inizio: DateTime(2026, 10, 10)),
        portafoglioId: conto,
      );
      expect(await pian.registraScadute(), 1);
      final mov = (await c.osservaMovimenti().first).firstWhere(
        (m) => m.movimento.descrizione == 'Stipendio',
      );
      expect(mov.tipo.effetto, EffettoSaldo.entrata);
      expect(mov.movimento.importoMinimo, 210000);
    },
  );
}
