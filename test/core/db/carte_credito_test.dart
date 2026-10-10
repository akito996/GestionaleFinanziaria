import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/db/archivio.dart';
import 'package:gestionale_finanziaria/core/db/carte_credito.dart';
import 'package:gestionale_finanziaria/core/db/contabilita.dart';
import 'package:gestionale_finanziaria/core/db/pianificatore.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';

void main() {
  late Archivio db;
  late Contabilita c;
  late Pianificatore pian;
  late CarteCreditoServizio carte;
  late DateTime adesso;
  late Map<String, String> tipo;
  late String conto;

  setUp(() async {
    db = Archivio.inMemoria();
    c = await Contabilita.apri(db);
    adesso = DateTime(2026, 10, 10);
    pian = Pianificatore(db, c.orologio, adesso: () => adesso);
    carte = CarteCreditoServizio(db, c.orologio, pian, adesso: () => adesso);
    tipo = {
      for (final t in [
        ...await c.tipi(AmbitoTipo.movimento),
        ...await c.tipi(AmbitoTipo.portafoglio),
      ])
        t.nome: t.id,
    };
    conto = await c.creaPortafoglio(
      nome: 'Conto',
      tipoId: tipo['Conto corrente']!,
      valuta: 'EUR',
      saldoIniziale: 200000,
    );
  });

  tearDown(() => db.close());

  Future<CartaConStato> stato() async => (await carte.stati()).single;

  Future<void> spesaCarta(String portafoglio, int importo, DateTime data) =>
      c.registraMovimento(
        tipoId: tipo['Spesa']!,
        portafoglioId: portafoglio,
        importo: importo,
        valuta: 'EUR',
        data: data,
      );

  Future<Map<String, int>> saldi() async => {
    for (final p in await c.osservaPortafogli().first)
      p.portafoglio.nome: p.saldo,
  };

  test(
    'la carta è un portafoglio "Carta di credito" con valuta del conto',
    () async {
      await carte.crea(
        nome: 'Visa',
        contoAddebitoId: conto,
        giornoAddebito: 15,
      );
      final s = await stato();
      expect(s.portafoglio.nome, 'Visa');
      expect(s.portafoglio.valuta, 'EUR');
      expect(s.conto.nome, 'Conto');
      expect(s.prossimoAddebito, DateTime(2026, 10, 15));
      expect(s.chiusura, DateTime(2026, 9, 30));
      expect(tipo.containsKey(tipoCartaDiCredito), isTrue);
    },
  );

  test('spese di ottobre addebitate il 15 novembre, una volta sola', () async {
    await carte.crea(nome: 'Visa', contoAddebitoId: conto, giornoAddebito: 15);
    final visa = (await stato()).portafoglio.id;
    await spesaCarta(visa, 3000, DateTime(2026, 10, 8));
    await spesaCarta(visa, 7000, DateTime(2026, 10, 12));

    // Il 15 ottobre si addebita settembre: nulla da pagare, nessun movimento.
    var s = await stato();
    expect(s.daAddebitare, 0);
    expect(s.debitoTotale, 10000);
    adesso = DateTime(2026, 10, 16);
    expect(await pian.registraScadute(), 0);

    s = await stato();
    expect(s.prossimoAddebito, DateTime(2026, 11, 15));
    expect(s.chiusura, DateTime(2026, 10, 31));
    expect(s.daAddebitare, 10000);

    // Avviso sul conto collegato.
    adesso = DateTime(2026, 11, 13);
    final arrivo = await pian.inArrivo(giorni: 30, portafoglioId: conto);
    expect(arrivo.single.data, DateTime(2026, 11, 15));
    expect(arrivo.single.importo, 10000);
    expect(arrivo.single.daAvvisare, isTrue);
    expect(arrivo.single.pianificazione.descrizione, 'Addebito carta Visa');

    // Una spesa di novembre va all'addebito di dicembre.
    await spesaCarta(visa, 5000, DateTime(2026, 11, 3));
    expect((await stato()).daAddebitare, 10000);
    expect((await stato()).debitoTotale, 15000);

    adesso = DateTime(2026, 11, 16);
    expect(await pian.registraScadute(), 1);
    expect(await pian.registraScadute(), 0);
    expect(await saldi(), {'Conto': 200000 - 10000, 'Visa': -5000});

    s = await stato();
    expect(s.prossimoAddebito, DateTime(2026, 12, 15));
    expect(s.daAddebitare, 5000);

    // App chiusa fino a gennaio: si recupera dicembre (gennaio è a zero).
    adesso = DateTime(2027, 1, 20);
    expect(await pian.registraScadute(), 1);
    expect(await saldi(), {'Conto': 200000 - 15000, 'Visa': 0});
  });

  test('chiusura personalizzata: spese fino al 20 del mese prima', () async {
    await carte.crea(
      nome: 'Amex',
      contoAddebitoId: conto,
      giornoAddebito: 10,
      giornoChiusura: 20,
    );
    final amex = (await stato()).portafoglio.id;
    await spesaCarta(amex, 1000, DateTime(2026, 10, 19));
    await spesaCarta(amex, 2000, DateTime(2026, 10, 21));

    adesso = DateTime(2026, 10, 25);
    final s = await stato();
    expect(s.prossimoAddebito, DateTime(2026, 11, 10));
    expect(s.chiusura, DateTime(2026, 10, 20));
    expect(s.daAddebitare, 1000);
  });

  test('plafond e archiviazione', () async {
    final id = await carte.crea(
      nome: 'Visa',
      contoAddebitoId: conto,
      giornoAddebito: 15,
      plafond: 100000,
    );
    final visa = (await stato()).portafoglio.id;
    await spesaCarta(visa, 25000, DateTime(2026, 10, 9));
    expect((await stato()).usoPlafond, 0.25);

    await carte.archivia(id);
    expect(await carte.stati(), isEmpty);
    adesso = DateTime(2026, 11, 20);
    expect(await pian.registraScadute(), 0);

    await carte.archivia(id, archiviata: false);
    expect(await pian.registraScadute(), 1);
  });

  test('modifica: nuovo giorno e conto aggiornano l\'addebito', () async {
    final altro = await c.creaPortafoglio(
      nome: 'Conto 2',
      tipoId: tipo['Conto corrente']!,
      valuta: 'EUR',
    );
    final id = await carte.crea(
      nome: 'Visa',
      contoAddebitoId: conto,
      giornoAddebito: 15,
    );
    await carte.modifica(
      id,
      nome: 'Visa Oro',
      contoAddebitoId: altro,
      giornoAddebito: 5,
    );
    final s = await stato();
    expect(s.portafoglio.nome, 'Visa Oro');
    expect(s.conto.nome, 'Conto 2');
    expect(s.prossimoAddebito, DateTime(2026, 11, 5));
    final p = await pian.perOrigine('carta', id);
    expect(p!.portafoglioId, altro);
    expect(p.descrizione, 'Addebito carta Visa Oro');
  });
}
