import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/db/archivio.dart';
import 'package:gestionale_finanziaria/core/db/carte_credito.dart';
import 'package:gestionale_finanziaria/core/db/contabilita.dart';
import 'package:gestionale_finanziaria/core/db/costo_vita.dart';
import 'package:gestionale_finanziaria/core/db/obiettivi.dart';
import 'package:gestionale_finanziaria/core/db/pianificatore.dart';
import 'package:gestionale_finanziaria/core/db/prestiti.dart';
import 'package:gestionale_finanziaria/core/db/statistiche.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';
import 'package:gestionale_finanziaria/core/report/documento.dart';
import 'package:gestionale_finanziaria/core/report/esporta_report.dart';
import 'package:gestionale_finanziaria/core/report/report_automatici.dart';
import 'package:gestionale_finanziaria/core/report/report_personalizzati.dart';

void main() {
  late Archivio db;
  late Contabilita c;
  late CostoVita cv;
  late StatisticheServizio st;
  late ReportAutomatici report;
  late DateTime adesso;
  late String conto;
  late Map<String, String> tipi;

  setUp(() async {
    db = Archivio.inMemoria();
    c = await Contabilita.apri(db);
    adesso = DateTime(2025, 6, 1);
    final pian = Pianificatore(db, c.orologio, adesso: () => adesso);
    cv = CostoVita(db, c.orologio, pian, adesso: () => adesso);
    st = StatisticheServizio(db);
    report = ReportAutomatici(db, c.orologio, cv, st, adesso: () => adesso);
    tipi = {
      for (final t in [
        ...await c.tipi(AmbitoTipo.movimento),
        ...await c.tipi(AmbitoTipo.portafoglio),
      ])
        t.nome: t.id,
    };
    conto = await c.creaPortafoglio(
      nome: 'Conto',
      tipoId: tipi['Conto corrente']!,
      valuta: 'EUR',
    );
    // Voci dal giugno 2025; un'entrata e una spesa ogni mese fino a oggi.
    await cv.creaVoce(nome: 'Affitto', tipo: TipoVoce.fissa, importo: 80000);
    await cv.creaVoce(
      nome: 'Stipendio',
      tipo: TipoVoce.fissa,
      importo: 200000,
      natura: NaturaVoce.entrata,
    );
    for (
      var m = DateTime(2025, 6);
      m.isBefore(DateTime(2027, 2));
      m = DateTime(m.year, m.month + 1)
    ) {
      await c.registraMovimento(
        tipoId: tipi['Entrata']!,
        portafoglioId: conto,
        importo: 200000,
        valuta: 'EUR',
        data: DateTime(m.year, m.month, 27),
      );
      await c.registraMovimento(
        tipoId: tipi['Spesa']!,
        portafoglioId: conto,
        importo: 120000,
        valuta: 'EUR',
        data: DateTime(m.year, m.month, 5),
      );
    }
  });

  tearDown(() => db.close());

  Future<Set<String>> salvati() async => {
    for (final r in await report.osserva().first)
      '${r.periodicita}|${r.periodo}',
  };

  test(
    'report automatici: 12 mensili, annuali, poi restano solo gli annuali',
    () async {
      adesso = DateTime(2026, 10, 15);
      expect(await report.aggiorna(), 13); // 12 mensili + il 2025
      var presenti = await salvati();
      expect(presenti, contains('mensile|2026-09'));
      expect(presenti, contains('mensile|2025-10'));
      expect(presenti, isNot(contains('mensile|2025-09'))); // oltre 12 mesi
      expect(presenti, isNot(contains('mensile|2026-10'))); // mese in corso
      expect(presenti, contains('annuale|2025'));
      expect(await report.aggiorna(), 0); // già fatti

      // Contenuto: cifre del mese e andamento degli ultimi 12 mesi.
      final settembre = (await report.osserva().first).firstWhere(
        (r) => r.periodo == '2026-09',
      );
      final d = DocumentoReport.decodifica(settembre.contenuto);
      expect(d.titolo, 'Report di settembre 2026');
      final cifre = d.blocchi.whereType<CifreChiave>().single.cifre;
      int cifra(String nome) =>
          cifre.firstWhere((x) => x.etichetta == nome).importo;
      expect(cifra('Entrate previste'), 200000);
      expect(cifra('Costo della vita previsto'), 80000);
      expect(cifra('Entrate effettive'), 200000);
      expect(cifra('Uscite effettive'), 120000);
      expect(cifra('Margine previsto'), 120000);
      expect(cifra('Margine effettivo'), 80000);
      expect(
        d.blocchi.whereType<SerieReport>().single.etichette,
        hasLength(12),
      );

      // Quattro mesi dopo: nasce l'annuale 2026 e i mensili più vecchi di
      // 12 mesi spariscono (gli annuali restano).
      adesso = DateTime(2027, 2, 15);
      await report.aggiorna();
      presenti = await salvati();
      expect(presenti, containsAll(['annuale|2025', 'annuale|2026']));
      expect(presenti, contains('mensile|2027-01'));
      expect(presenti, contains('mensile|2026-02'));
      expect(presenti, isNot(contains('mensile|2026-01')));
      expect(presenti, isNot(contains('mensile|2025-10')));

      final anno = DocumentoReport.decodifica(
        (await report.osserva().first)
            .firstWhere((r) => r.periodo == '2025')
            .contenuto,
      );
      expect(anno.titolo, 'Report del 2025');
      final cifreAnno = anno.blocchi.whereType<CifreChiave>().single.cifre;
      // 7 mesi con dati nel 2025 (giugno-dicembre).
      expect(
        cifreAnno.firstWhere((x) => x.etichetta == 'Entrate effettive').importo,
        7 * 200000,
      );
    },
  );

  test('archivio vuoto: nessun report', () async {
    final vuoto = Archivio.inMemoria();
    addTearDown(vuoto.close);
    final cc = await Contabilita.apri(vuoto);
    final p = Pianificatore(vuoto, cc.orologio);
    final r = ReportAutomatici(
      vuoto,
      cc.orologio,
      CostoVita(vuoto, cc.orologio, p),
      StatisticheServizio(vuoto),
    );
    expect(await r.aggiorna(), 0);
  });

  test('intervalli: settimane da lunedì, tagliate sul periodo', () {
    final s = ReportPersonalizzati.intervalli(
      DateTime(2026, 10, 1), // giovedì
      DateTime(2026, 10, 14),
      Dettaglio.settimana,
    );
    expect(s.map((i) => (i.da.day, i.a.day)), [(1, 4), (5, 11), (12, 14)]);
    final m = ReportPersonalizzati.intervalli(
      DateTime(2026, 1, 15),
      DateTime(2026, 3, 10),
      Dettaglio.mese,
    );
    expect(m.map((i) => (i.da, i.a)), [
      (DateTime(2026, 1, 15), DateTime(2026, 1, 31)),
      (DateTime(2026, 2), DateTime(2026, 2, 28)),
      (DateTime(2026, 3), DateTime(2026, 3, 10)),
    ]);
    expect(
      ReportPersonalizzati.intervalli(
        DateTime(2020),
        DateTime(2026),
        Dettaglio.anno,
      ),
      hasLength(7),
    );
    expect(
      () => ReportPersonalizzati.intervalli(
        DateTime(2020),
        DateTime(2026),
        Dettaglio.giorno,
      ),
      throwsArgumentError,
    );
  });

  test('report personalizzato con tutti gli strumenti; PDF ed Excel', () async {
    adesso = DateTime(2026, 10, 15);
    final pian = Pianificatore(db, c.orologio, adesso: () => adesso);
    final personalizzati = ReportPersonalizzati(
      db,
      cv,
      st,
      CarteCreditoServizio(db, c.orologio, pian, adesso: () => adesso),
      PrestitiServizio(db, c.orologio, pian, adesso: () => adesso),
      ObiettiviServizio(db, c.orologio, adesso: () => adesso),
    );
    await db
        .into(db.obiettivi)
        .insert(
          ObiettiviCompanion.insert(
            id: 'o1',
            aggiornatoIl: '1',
            nome: 'Vacanza',
            tipo: TipoObiettivo.personale,
            importoObiettivoMinimo: 100000,
            portafoglioId: const Value(null),
          ),
        );
    final d = await personalizzati.crea(
      strumenti: StrumentoReport.values.toSet(),
      dettaglio: Dettaglio.mese,
      da: DateTime(2026, 7),
      a: DateTime(2026, 9, 30),
      creatoIl: adesso,
    );
    expect(d.titolo, 'Report del gestionale');
    final cifre = d.blocchi.whereType<CifreChiave>().first.cifre;
    expect(cifre.first.etichetta, 'Entrate');
    expect(cifre.first.importo, 3 * 200000);
    expect(cifre[1].importo, 3 * 120000);
    expect(d.blocchi.whereType<SerieReport>().first.etichette, [
      'lug 26',
      'ago 26',
      'set 26',
    ]);

    // Si salva e si rilegge uguale.
    final riletto = DocumentoReport.decodifica(d.codifica());
    expect(riletto.codifica(), d.codifica());

    final pdf = await EsportaReport.pdf(d);
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    final excel = EsportaReport.excel(d);
    expect(excel.take(2), [0x50, 0x4B]); // zip: "PK"
  });
}
