import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/db/archivio.dart';
import 'package:gestionale_finanziaria/core/db/contabilita.dart';
import 'package:gestionale_finanziaria/core/db/costo_vita.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';

void main() {
  late Archivio db;
  late Contabilita c;
  late CostoVita cv;
  late DateTime adesso;

  final ottobre = DateTime(2026, 10);
  final settembre = DateTime(2026, 9);
  final novembre = DateTime(2026, 11);

  setUp(() async {
    db = Archivio.inMemoria();
    c = await Contabilita.apri(db);
    adesso = DateTime(2026, 10, 10, 15);
    cv = CostoVita(db, c.orologio, adesso: () => adesso);
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
}
