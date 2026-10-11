import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/db/archivio.dart';
import 'package:gestionale_finanziaria/core/db/carte_credito.dart';
import 'package:gestionale_finanziaria/core/db/contabilita.dart';
import 'package:gestionale_finanziaria/core/db/pianificatore.dart';
import 'package:gestionale_finanziaria/core/db/prestiti.dart';
import 'package:gestionale_finanziaria/core/db/statistiche.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';

void main() {
  late Archivio db;
  late Contabilita c;
  late StatisticheServizio st;
  late Map<String, String> tipo;
  late Map<String, String> cat;

  setUp(() async {
    db = Archivio.inMemoria();
    c = await Contabilita.apri(db);
    st = StatisticheServizio(db);
    tipo = {
      for (final t in [
        ...await c.tipi(AmbitoTipo.movimento),
        ...await c.tipi(AmbitoTipo.portafoglio),
      ])
        t.nome: t.id,
    };
    cat = {for (final x in await c.osservaCategorie().first) x.nome: x.id};
  });

  tearDown(() => db.close());

  Future<void> mov(
    String tipoMov,
    String portafoglio,
    int importo,
    DateTime data, {
    String? categoria,
    String? destinazione,
  }) => c.registraMovimento(
    tipoId: tipo[tipoMov]!,
    portafoglioId: portafoglio,
    destinazioneId: destinazione,
    categoriaId: categoria == null ? null : cat[categoria],
    importo: importo,
    valuta: 'EUR',
    data: data,
  );

  test('entrate e uscite per mese e per anno, senza trasferimenti', () async {
    final conto = await c.creaPortafoglio(
      nome: 'Conto',
      tipoId: tipo['Conto corrente']!,
      valuta: 'EUR',
    );
    final risparmi = await c.creaPortafoglio(
      nome: 'Risparmi',
      tipoId: tipo['Risparmi']!,
      valuta: 'EUR',
    );
    await mov('Entrata', conto, 200000, DateTime(2025, 10, 1));
    await mov('Spesa', conto, 50000, DateTime(2025, 10, 8));
    await mov('Entrata', conto, 210000, DateTime(2026, 9, 1));
    await mov('Spesa', conto, 90000, DateTime(2026, 9, 9));
    await mov('Spesa', conto, 30000, DateTime(2026, 9, 25));
    await mov('Entrata', conto, 210000, DateTime(2026, 10, 1));
    await mov('Spesa', conto, 60000, DateTime(2026, 10, 5));
    // Un trasferimento non è né entrata né uscita.
    await mov(
      'Trasferimento',
      conto,
      100000,
      DateTime(2026, 10, 6),
      destinazione: risparmi,
    );

    final mesi = await st.entrateUscitePerMese(
      finoA: DateTime(2026, 10, 11),
      mesi: 13,
    );
    expect(mesi, hasLength(13));
    expect(mesi.first.periodo, DateTime(2025, 10));
    expect(mesi.first.entrate, 200000);
    expect(mesi.last.periodo, DateTime(2026, 10));
    expect(mesi.last.entrate, 210000);
    expect(mesi.last.uscite, 60000);
    expect(mesi.last.differenza, 150000);
    expect(mesi[1].entrate, 0); // novembre 2025: niente

    final anni = await st.entrateUscitePerAnno(finoA: DateTime(2026, 10, 11));
    expect(anni.map((a) => a.periodo.year), [2025, 2026]);
    expect(anni.last.entrate, 420000);
    expect(anni.last.uscite, 180000);
    expect(anni.first.risparmio, closeTo(0.75, 0.001));

    // 1-11 ottobre contro 1-11 settembre: la spesa del 25/9 non conta.
    final mese = await st.confronto(DateTime(2026, 10, 11));
    expect(mese.attuale.uscite, 60000);
    expect(mese.precedente.uscite, 90000);
    expect(
      ConfrontoPeriodo.variazione(mese.attuale.uscite, mese.precedente.uscite),
      closeTo(-1 / 3, 0.001),
    );
    final anno = await st.confronto(DateTime(2026, 10, 11), anno: true);
    expect(anno.precedente.entrate, 200000); // fino all'11/10/2025
    expect(anno.attuale.entrate, 420000);
  });

  test('cascata del mese: inizio + entrate − spese = fine', () async {
    final conto = await c.creaPortafoglio(
      nome: 'Conto',
      tipoId: tipo['Conto corrente']!,
      valuta: 'EUR',
      saldoIniziale: 100000,
    );
    await mov('Spesa', conto, 5000, DateTime(2026, 9, 20), categoria: 'Spesa');
    await mov('Entrata', conto, 200000, DateTime(2026, 10, 1));
    await mov('Spesa', conto, 30000, DateTime(2026, 10, 3), categoria: 'Spesa');
    await mov(
      'Spesa',
      conto,
      10000,
      DateTime(2026, 10, 5),
      categoria: 'Carburante',
    );

    final passi = await st.cascataMese(DateTime(2026, 10));
    expect(passi.first.etichetta, 'Inizio mese');
    expect(passi.first.valore, 95000);
    expect(passi.last.valore, 95000 + 200000 - 40000);
    final variazioni = passi
        .where((p) => !p.totale)
        .fold<int>(0, (t, p) => t + p.valore);
    expect(passi.first.valore + variazioni, passi.last.valore);
    expect(passi.map((p) => p.etichetta), contains('Alimentari'));
    expect(passi.map((p) => p.etichetta), contains('Trasporti'));
  });

  test('candele: apertura, massimo, minimo e chiusura del mese', () async {
    final conto = await c.creaPortafoglio(
      nome: 'Conto',
      tipoId: tipo['Conto corrente']!,
      valuta: 'EUR',
      saldoIniziale: 100000,
    );
    await mov('Entrata', conto, 50000, DateTime(2026, 10, 2));
    await mov('Spesa', conto, 120000, DateTime(2026, 10, 15));
    await mov('Entrata', conto, 30000, DateTime(2026, 10, 25));

    final candele = await st.candeleSaldo(
      conto,
      finoA: DateTime(2026, 10),
      mesi: 2,
    );
    expect(candele, hasLength(2));
    final ottobre = candele.last;
    expect(ottobre.apertura, 100000);
    expect(ottobre.massimo, 150000);
    expect(ottobre.minimo, 30000);
    expect(ottobre.chiusura, 60000);
    expect(ottobre.crescita, isFalse);
    // Settembre senza movimenti: candela piatta.
    expect(candele.first.apertura, candele.first.chiusura);
  });

  test('stato patrimoniale: attività, passività e netto', () async {
    final pian = Pianificatore(db, c.orologio);
    final carte = CarteCreditoServizio(db, c.orologio, pian);
    final prestiti = PrestitiServizio(db, c.orologio, pian);
    final conto = await c.creaPortafoglio(
      nome: 'Conto',
      tipoId: tipo['Conto corrente']!,
      valuta: 'EUR',
      saldoIniziale: 300000,
    );
    await c.creaPortafoglio(
      nome: 'Salvadanaio',
      tipoId: tipo['Risparmi']!,
      valuta: 'EUR',
      saldoIniziale: 50000,
    );
    await carte.crea(nome: 'Visa', contoAddebitoId: conto, giornoAddebito: 15);
    final visa = (await carte.stati()).single.portafoglio.id;
    await mov('Spesa', visa, 12000, DateTime.now());
    await prestiti.crea(
      DatiPrestito(
        nome: 'Auto',
        tipo: TipoPrestito.prestito,
        capitale: 1000000,
        numeroRate: 48,
        importoRata: 23715,
        tanPuntiBase: 650,
        primaRata: DateTime.now().add(const Duration(days: 30)),
      ),
    );

    final p = await st.patrimonio(carte, prestiti);
    expect(
      {for (final v in p.attivita) v.nome: v.importo},
      {'Conto corrente': 300000, 'Risparmi': 50000},
    );
    expect(
      {for (final v in p.passivita) v.nome: v.importo},
      {'Prestiti e mutui': 1000000, 'Carte di credito': 12000},
    );
    expect(p.netto, 350000 - 1012000);
  });
}
