import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/db/archivio.dart';
import 'package:gestionale_finanziaria/core/db/contabilita.dart';
import 'package:gestionale_finanziaria/core/db/pianificatore.dart';
import 'package:gestionale_finanziaria/core/db/prestiti.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';

void main() {
  late Archivio db;
  late Contabilita c;
  late Pianificatore pian;
  late PrestitiServizio prestiti;
  late DateTime adesso;
  late String conto;

  setUp(() async {
    db = Archivio.inMemoria();
    c = await Contabilita.apri(db);
    adesso = DateTime(2026, 10, 10);
    pian = Pianificatore(db, c.orologio, adesso: () => adesso);
    prestiti = PrestitiServizio(db, c.orologio, pian, adesso: () => adesso);
    final tipo = (await c.tipi(AmbitoTipo.portafoglio))
        .firstWhere((t) => t.nome == 'Conto corrente');
    conto = await c.creaPortafoglio(
      nome: 'Conto',
      tipoId: tipo.id,
      valuta: 'EUR',
      saldoIniziale: 100000,
    );
  });

  tearDown(() => db.close());

  test(
    'paga in 3 rate: rate registrate da sole in "Pagamenti a rate"',
    () async {
      await prestiti.crea(
        DatiPrestito(
          nome: 'Lavatrice',
          tipo: TipoPrestito.rate,
          capitale: 30000,
          numeroRate: 3,
          importoRata: 10000,
          primaRata: DateTime(2026, 10, 15),
          portafoglioId: conto,
        ),
      );
      var s = (await prestiti.stati()).single;
      expect(s.ratePagate, 0);
      expect(s.prossima!.data, DateTime(2026, 10, 15));
      expect(s.fine, DateTime(2026, 12, 15));
      expect(s.debitoResiduo, 30000);
      expect(s.daPagare, 30000);

      adesso = DateTime(2026, 10, 16);
      expect(await pian.registraScadute(), 1);
      final mov = (await c.osservaMovimenti().first).single;
      expect(mov.movimento.importoMinimo, 10000);
      expect(mov.movimento.descrizione, 'Rata Lavatrice');
      expect(mov.categoria?.nome, 'Pagamenti a rate');

      s = (await prestiti.stati()).single;
      expect(s.ratePagate, 1);
      expect(s.rateRimanenti, 2);
      expect(s.prossima!.data, DateTime(2026, 11, 15));
      expect(s.debitoResiduo, 20000);

      // Fine del piano: nessuna rata in più.
      adesso = DateTime(2027, 3, 1);
      expect(await pian.registraScadute(), 2);
      expect(await pian.registraScadute(), 0);
      s = (await prestiti.stati()).single;
      expect(s.ratePagate, 3);
      expect(s.prossima, isNull);
      expect(s.avanzamento, 1.0);
    },
  );

  test(
    'mutuo senza conto: solo promemoria, rate passate considerate pagate',
    () async {
      await prestiti.crea(
        DatiPrestito(
          nome: 'Mutuo casa',
          tipo: TipoPrestito.mutuo,
          capitale: 15000000,
          numeroRate: 300,
          importoRata: 79015,
          tanPuntiBase: 320,
          primaRata: DateTime(2026, 1, 31),
        ),
      );
      expect(await pian.registraScadute(), 0);
      final s = (await prestiti.stati()).single;
      // Gennaio-settembre 2026: 9 rate già scadute.
      expect(s.ratePagate, 9);
      expect(s.prossima!.data, DateTime(2026, 10, 31));
      expect(s.rate[1].data, DateTime(2026, 2, 28)); // fine mese
      expect(s.debitoResiduo, lessThan(15000000));
      expect(s.prestito.categoriaId, isNotNull);
      expect(await pian.inArrivo(giorni: 30), hasLength(1));
    },
  );

  test('archiviato (estinto): le rate future non si registrano', () async {
    final id = await prestiti.crea(
      DatiPrestito(
        nome: 'Auto',
        tipo: TipoPrestito.prestito,
        capitale: 1000000,
        numeroRate: 48,
        importoRata: 23715,
        primaRata: DateTime(2026, 10, 5),
        portafoglioId: conto,
      ),
    );
    await prestiti.archivia(id);
    expect(await prestiti.stati(), isEmpty);
    adesso = DateTime(2026, 12, 10);
    expect(await pian.registraScadute(), 0);
  });

  test('modifica: nuova rata e nuove date per le rate future', () async {
    final id = await prestiti.crea(
      DatiPrestito(
        nome: 'Bici',
        tipo: TipoPrestito.rate,
        capitale: 60000,
        numeroRate: 6,
        importoRata: 10000,
        primaRata: DateTime(2026, 11, 1),
        portafoglioId: conto,
      ),
    );
    await prestiti.modifica(
      id,
      DatiPrestito(
        nome: 'Bici elettrica',
        tipo: TipoPrestito.rate,
        capitale: 60000,
        numeroRate: 4,
        importoRata: 15000,
        primaRata: DateTime(2026, 11, 20),
        portafoglioId: conto,
      ),
    );
    final s = (await prestiti.stati()).single;
    expect(s.rate, hasLength(4));
    expect(s.prossima!.data, DateTime(2026, 11, 20));
    final p = await pian.perOrigine('prestito', id);
    expect(p!.importoMinimo, 15000);
    expect(p.descrizione, 'Rata Bici elettrica');
  });

  test(
    "maxi rata finale: l'ultima rata si registra con il suo importo",
    () async {
      await prestiti.crea(
        DatiPrestito(
          nome: 'Auto',
          tipo: TipoPrestito.prestito,
          capitale: 1200000,
          numeroRate: 3,
          importoRata: 300000,
          maxiRata: 600000,
          primaRata: DateTime(2026, 10, 15),
          portafoglioId: conto,
        ),
      );
      var s = (await prestiti.stati()).single;
      expect(s.daPagare, 1200000);
      expect(s.rate.last.piano.rata, 600000);

      adesso = DateTime(2026, 12, 1);
      final arrivo = await pian.inArrivo(giorni: 30);
      expect(arrivo.single.importo, 600000);
      expect(arrivo.single.data, DateTime(2026, 12, 15));

      adesso = DateTime(2027, 1, 1);
      expect(await pian.registraScadute(), 3);
      final importi = [
        for (final m in await c.osservaMovimenti().first)
          m.movimento.importoMinimo,
      ]..sort();
      expect(importi, [300000, 300000, 600000]);
      s = (await prestiti.stati()).single;
      expect(s.debitoResiduo, 0);
    },
  );

  test('spese di incasso: il movimento è rata + spese, il piano no', () async {
    await prestiti.crea(
      DatiPrestito(
        nome: 'Auto',
        tipo: TipoPrestito.prestito,
        capitale: 1200000,
        numeroRate: 3,
        importoRata: 300000,
        maxiRata: 600000,
        speseRata: 350,
        primaRata: DateTime(2026, 10, 15),
        portafoglioId: conto,
      ),
    );
    var s = (await prestiti.stati()).single;
    expect(s.rate.first.piano.rata, 300000); // il piano resta sulla rata
    expect(s.daPagare, 1200000 + 3 * 350);
    expect((await pian.inArrivo(giorni: 10)).single.importo, 300350);

    adesso = DateTime(2027, 1, 1);
    expect(await pian.registraScadute(), 3);
    final importi = [
      for (final m in await c.osservaMovimenti().first)
        m.movimento.importoMinimo,
    ]..sort();
    expect(importi, [300350, 300350, 600350]);
    s = (await prestiti.stati()).single;
    expect(s.debitoResiduo, 0);
    expect(s.daPagare, 0);
  });
}
