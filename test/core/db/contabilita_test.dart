import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/db/archivio.dart';
import 'package:gestionale_finanziaria/core/db/contabilita.dart';
import 'package:gestionale_finanziaria/core/db/orologio.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';

void main() {
  late Archivio db;
  late Contabilita c;
  late Map<String, String> tipo;

  setUp(() async {
    db = Archivio.inMemoria();
    c = await Contabilita.apri(db);
    tipo = {
      for (final t in [
        ...await c.tipi(AmbitoTipo.movimento),
        ...await c.tipi(AmbitoTipo.portafoglio),
      ])
        t.nome: t.id,
    };
  });

  tearDown(() => db.close());

  Future<Map<String, int>> saldi() async => {
    for (final p in await c.osservaPortafogli().first)
      p.portafoglio.nome: p.saldo,
  };

  test('saldi: iniziale + entrate − spese ± trasferimenti', () async {
    final contanti = await c.creaPortafoglio(
      nome: 'Contanti',
      tipoId: tipo['Contanti']!,
      valuta: 'EUR',
      saldoIniziale: 5000,
    );
    final conto = await c.creaPortafoglio(
      nome: 'Conto',
      tipoId: tipo['Conto corrente']!,
      valuta: 'EUR',
    );
    final oggi = DateTime(2026, 10, 10);

    await c.registraMovimento(
      tipoId: tipo['Spesa']!,
      portafoglioId: contanti,
      importo: 1200,
      valuta: 'EUR',
      data: oggi,
      descrizione: 'Pizzeria',
    );
    await c.registraMovimento(
      tipoId: tipo['Entrata']!,
      portafoglioId: conto,
      importo: 150000,
      valuta: 'EUR',
      data: oggi,
      descrizione: 'Stipendio',
    );
    await c.registraMovimento(
      tipoId: tipo['Trasferimento']!,
      portafoglioId: conto,
      destinazioneId: contanti,
      importo: 10000,
      valuta: 'EUR',
      data: oggi,
      descrizione: 'Prelievo',
    );

    expect(await saldi(), {
      'Contanti': 5000 - 1200 + 10000,
      'Conto': 150000 - 10000,
    });

    final movimenti = await c.osservaMovimenti().first;
    expect(movimenti, hasLength(3));
    final prelievo = movimenti.firstWhere(
      (m) => m.movimento.descrizione == 'Prelievo',
    );
    expect(prelievo.destinazione?.nome, 'Contanti');
    expect(prelievo.effettoSu(conto), -10000);
    expect(prelievo.effettoSu(contanti), 10000);

    final soloContanti = await c
        .osservaMovimenti(portafoglioId: contanti)
        .first;
    expect(soloContanti, hasLength(2));
  });

  test('elimina e ripristina (annulla) un movimento', () async {
    final contanti = await c.creaPortafoglio(
      nome: 'Contanti',
      tipoId: tipo['Contanti']!,
      valuta: 'EUR',
    );
    final id = await c.registraMovimento(
      tipoId: tipo['Spesa']!,
      portafoglioId: contanti,
      importo: 700,
      valuta: 'EUR',
      data: DateTime(2026, 10, 10),
    );
    expect((await saldi())['Contanti'], -700);

    await c.eliminaMovimento(id);
    expect((await saldi())['Contanti'], 0);
    expect(await c.osservaMovimenti().first, isEmpty);

    await c.ripristinaMovimento(id);
    expect((await saldi())['Contanti'], -700);
  });

  test('modifica movimento e portafoglio', () async {
    final contanti = await c.creaPortafoglio(
      nome: 'Contanti',
      tipoId: tipo['Contanti']!,
      valuta: 'EUR',
    );
    final id = await c.registraMovimento(
      tipoId: tipo['Spesa']!,
      portafoglioId: contanti,
      importo: 700,
      valuta: 'EUR',
      data: DateTime(2026, 10, 10),
    );
    await c.modificaMovimento(
      id,
      tipoId: tipo['Entrata']!,
      portafoglioId: contanti,
      importo: 900,
      valuta: 'EUR',
      data: DateTime(2026, 10, 9),
      descrizione: 'Rimborso',
    );
    await c.modificaPortafoglio(
      contanti,
      nome: 'Portamonete',
      tipoId: tipo['Contanti']!,
      valuta: 'EUR',
      saldoIniziale: 100,
    );
    expect(await saldi(), {'Portamonete': 1000});
    final m = (await c.osservaMovimenti().first).single.movimento;
    expect(m.data, '2026-10-09');
    expect(m.descrizione, 'Rimborso');
  });

  test('portafoglio archiviato: sparisce, si può ripristinare', () async {
    final id = await c.creaPortafoglio(
      nome: 'Vecchio conto',
      tipoId: tipo['Conto corrente']!,
      valuta: 'EUR',
    );
    await c.archiviaPortafoglio(id);
    expect(await saldi(), isEmpty);
    await c.archiviaPortafoglio(id, archiviato: false);
    expect(await saldi(), {'Vecchio conto': 0});
  });

  test(
    'regole: importo positivo, trasferimento verso un altro portafoglio',
    () async {
      final contanti = await c.creaPortafoglio(
        nome: 'Contanti',
        tipoId: tipo['Contanti']!,
        valuta: 'EUR',
      );
      expect(
        () => c.registraMovimento(
          tipoId: tipo['Spesa']!,
          portafoglioId: contanti,
          importo: 0,
          valuta: 'EUR',
          data: DateTime(2026, 10, 10),
        ),
        throwsArgumentError,
      );
      expect(
        () => c.registraMovimento(
          tipoId: tipo['Trasferimento']!,
          portafoglioId: contanti,
          destinazioneId: contanti,
          importo: 100,
          valuta: 'EUR',
          data: DateTime(2026, 10, 10),
        ),
        throwsArgumentError,
      );
    },
  );

  test('orologio logico: sempre crescente, id dispositivo stabile', () async {
    final o = await OrologioLogico.carica(db);
    final valori = List.generate(1000, (_) => o.adesso());
    final ordinati = [...valori]..sort();
    expect(valori, ordinati);
    expect(valori.toSet(), hasLength(1000));
    expect((await OrologioLogico.carica(db)).dispositivoId, o.dispositivoId);
  });
}
