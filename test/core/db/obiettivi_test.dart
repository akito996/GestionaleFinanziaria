import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/db/archivio.dart';
import 'package:gestionale_finanziaria/core/db/contabilita.dart';
import 'package:gestionale_finanziaria/core/db/obiettivi.dart';
import 'package:gestionale_finanziaria/core/db/pianificatore.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';

void main() {
  late Archivio db;
  late Contabilita c;
  late ObiettiviServizio ob;
  late Map<String, String> tipo;

  setUp(() async {
    db = Archivio.inMemoria();
    c = await Contabilita.apri(db);
    ob = ObiettiviServizio(
      db,
      c.orologio,
      adesso: () => DateTime(2026, 10, 10),
    );
    tipo = {for (final t in await c.tipi(AmbitoTipo.portafoglio)) t.nome: t.id};
  });

  tearDown(() => db.close());

  Future<Map<String, int>> saldi() async => {
    for (final p in await c.osservaPortafogli().first)
      p.portafoglio.nome: p.saldo,
  };

  test(
    'obiettivo personale: avanzamento, quanto al mese, salvadanaio',
    () async {
      final conto = await c.creaPortafoglio(
        nome: 'Conto',
        tipoId: tipo['Conto corrente']!,
        valuta: 'EUR',
        saldoIniziale: 300000,
      );
      final salvadanaio = await c.creaPortafoglio(
        nome: 'Salvadanaio',
        tipoId: tipo['Risparmi']!,
        valuta: 'EUR',
      );
      final id = await ob.crea(
        nome: 'Vacanza',
        tipo: TipoObiettivo.personale,
        importoObiettivo: 200000,
        scadenza: DateTime(2027, 6, 30),
        portafoglioId: salvadanaio,
      );
      await ob.versa(id, importo: 50000, portafoglioDaId: conto);

      final s = (await ob.stati()).single;
      expect(s.versato, 50000);
      expect(s.mancante, 150000);
      expect(s.avanzamento, 0.25);
      expect(s.mesiRimasti, 8); // ottobre 2026 → giugno 2027
      expect(s.alMese, 18750);
      // Il versamento è un trasferimento dal conto al salvadanaio.
      expect(await saldi(), {'Conto': 250000, 'Salvadanaio': 50000});
    },
  );

  test('colletta: quote uguali e personalizzate, chi è in regola', () async {
    final id = await ob.crea(
      nome: 'Regalo Anna',
      tipo: TipoObiettivo.colletta,
      importoObiettivo: 20000,
      partecipanti: [
        (nome: 'Io', quota: 8000),
        (nome: 'Marco', quota: null),
        (nome: 'Giulia', quota: null),
      ],
    );
    var s = (await ob.stati()).single;
    final quote = {for (final q in s.quote) q.partecipante.nome: q};
    expect(quote['Io']!.quota, 8000);
    expect(quote['Marco']!.quota, 6000); // (200 - 80) / 2
    expect(quote['Giulia']!.quota, 6000);

    await ob.versa(
      id,
      importo: 8000,
      partecipanteId: quote['Io']!.partecipante.id,
    );
    await ob.versa(
      id,
      importo: 2500,
      partecipanteId: quote['Marco']!.partecipante.id,
    );
    s = (await ob.stati()).single;
    final dopo = {for (final q in s.quote) q.partecipante.nome: q};
    expect(dopo['Io']!.inRegola, isTrue);
    expect(dopo['Marco']!.mancante, 3500);
    expect(dopo['Giulia']!.versato, 0);
    expect(s.versato, 10500);

    expect(
      s.riepilogo(),
      'Regalo Anna: 105,00 € di 200,00 €\n'
      '✅ Io: 80,00 € / 80,00 €\n'
      '⏳ Marco: 25,00 € / 60,00 € (mancano 35,00 €)\n'
      '⏳ Giulia: 0,00 € / 60,00 € (mancano 60,00 €)\n'
      'Mancano 95,00 €',
    );
  });

  test(
    'colletta registrata come entrata nel mio portafoglio, poi annullata',
    () async {
      final contanti = await c.creaPortafoglio(
        nome: 'Contanti',
        tipoId: tipo['Contanti']!,
        valuta: 'EUR',
      );
      final id = await ob.crea(
        nome: 'Cena di classe',
        tipo: TipoObiettivo.colletta,
        importoObiettivo: 30000,
        partecipanti: [(nome: 'Luca', quota: null)],
      );
      final luca = (await ob.stati()).single.quote.single.partecipante.id;
      final v = await ob.versa(
        id,
        importo: 3000,
        partecipanteId: luca,
        portafoglioDaId: contanti,
      );
      expect(await saldi(), {'Contanti': 3000});

      await ob.annullaVersamento(v);
      expect(await saldi(), {'Contanti': 0});
      expect((await ob.stati()).single.versato, 0);

      await ob.annullaVersamento(v, annullato: false);
      expect(await saldi(), {'Contanti': 3000});
    },
  );

  test('archiviazione e partecipante rimosso', () async {
    final id = await ob.crea(
      nome: 'Viaggio',
      tipo: TipoObiettivo.colletta,
      importoObiettivo: 90000,
      partecipanti: [
        (nome: 'A', quota: null),
        (nome: 'B', quota: null),
        (nome: 'C', quota: null),
      ],
    );
    final b = (await ob.stati()).single.quote[1].partecipante.id;
    await ob.rimuoviPartecipante(b);
    final s = (await ob.stati()).single;
    expect(s.quote, hasLength(2));
    expect(s.quote.first.quota, 45000);

    await ob.archivia(id);
    expect(await ob.stati(), isEmpty);
  });

  test("l'elenco si aggiorna anche se altri servizi osservano il database", () async {
    // Regressione: query di osservazione con lo stesso testo venivano condivise
    // da drift e ascoltavano le tabelle del primo servizio.
    final pian = Pianificatore(db, c.orologio);
    final altro = pian.osservaInArrivo().listen((_) {});
    addTearDown(altro.cancel);
    final valori = <int>[];
    final sub = ob.osserva().listen((l) => valori.add(l.length));
    addTearDown(sub.cancel);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await ob.crea(
      nome: 'Auto',
      tipo: TipoObiettivo.personale,
      importoObiettivo: 100000,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(valori.last, 1);
  });
}
