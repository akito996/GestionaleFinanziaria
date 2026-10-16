import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/db/archivio.dart';
import 'package:gestionale_finanziaria/core/db/carte_credito.dart';
import 'package:gestionale_finanziaria/core/db/contabilita.dart';
import 'package:gestionale_finanziaria/core/db/pianificatore.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';

/// Eliminare un portafoglio: movimenti eliminati o spostati, collegamenti,
/// carte protette, tutto annullabile.
void main() {
  late Archivio db;
  late Contabilita c;
  late Map<String, String> tipo;
  late String contanti;
  late String conto;
  late String spesa;
  late String stipendio;
  late String prelievo;

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
    contanti = await c.creaPortafoglio(
      nome: 'Contanti',
      tipoId: tipo['Contanti']!,
      valuta: 'EUR',
      saldoIniziale: 5000,
    );
    conto = await c.creaPortafoglio(
      nome: 'Conto',
      tipoId: tipo['Conto corrente']!,
      valuta: 'EUR',
    );
    final giorno = DateTime(2026, 10, 10);
    spesa = await c.registraMovimento(
      tipoId: tipo['Spesa']!,
      portafoglioId: contanti,
      importo: 1200,
      valuta: 'EUR',
      data: giorno,
      descrizione: 'Pizzeria',
    );
    stipendio = await c.registraMovimento(
      tipoId: tipo['Entrata']!,
      portafoglioId: contanti,
      importo: 3000,
      valuta: 'EUR',
      data: giorno,
      descrizione: 'Mancia',
    );
    prelievo = await c.registraMovimento(
      tipoId: tipo['Trasferimento']!,
      portafoglioId: conto,
      destinazioneId: contanti,
      importo: 2000,
      valuta: 'EUR',
      data: giorno,
      descrizione: 'Prelievo',
    );
  });

  tearDown(() => db.close());

  Future<Movimento> movimento(String id) =>
      (db.select(db.movimenti)..where((m) => m.id.equals(id))).getSingle();

  Future<List<String>> nomi() async => [
    for (final p in await c.osservaPortafogli().first) p.portafoglio.nome,
  ];

  test('elimina con tutti i movimenti, poi annulla', () async {
    final collegati = await c.eliminazione.collegamenti(contanti);
    expect(collegati.movimenti, 3);
    expect(collegati.carta, isNull);

    final annulla = await c.eliminazione.elimina(
      contanti,
      daEliminare: {spesa, stipendio, prelievo},
    );
    expect(await nomi(), ['Conto']);
    expect((await movimento(spesa)).eliminato, isTrue);
    expect((await movimento(prelievo)).eliminato, isTrue);

    await annulla();
    expect(await nomi(), containsAll(['Contanti', 'Conto']));
    expect((await movimento(spesa)).eliminato, isFalse);
    expect((await movimento(prelievo)).eliminato, isFalse);
  });

  test(
    'tiene i movimenti spostandoli; il trasferimento verso sé sparisce',
    () async {
      final annulla = await c.eliminazione.elimina(contanti, spostaIn: conto);
      final s = await movimento(spesa);
      expect(s.eliminato, isFalse);
      expect(s.portafoglioId, conto);
      // Conto → Contanti diventerebbe Conto → Conto: eliminato.
      expect((await movimento(prelievo)).eliminato, isTrue);
      // Saldo del conto: −20 € prelievo tolto, −12 € pizzeria, +30 € mancia.
      final saldo = (await c.osservaPortafogli().first)
          .singleWhere((p) => p.portafoglio.id == conto)
          .saldo;
      expect(saldo, 3000 - 1200);

      await annulla();
      final dopo = await movimento(spesa);
      expect(dopo.portafoglioId, contanti);
      expect((await movimento(prelievo)).eliminato, isFalse);
    },
  );

  test(
    'sceglie quali eliminare; senza destinazione per gli altri: errore',
    () async {
      await expectLater(
        c.eliminazione.elimina(contanti, daEliminare: {spesa}),
        throwsArgumentError,
      );
      // Niente è cambiato (transazione annullata).
      expect((await movimento(spesa)).eliminato, isFalse);
      expect(await nomi(), containsAll(['Contanti', 'Conto']));

      await c.eliminazione.elimina(
        contanti,
        daEliminare: {spesa},
        spostaIn: conto,
      );
      expect((await movimento(spesa)).eliminato, isTrue);
      expect((await movimento(stipendio)).portafoglioId, conto);
    },
  );

  test('il conto di una carta di credito non si elimina da qui', () async {
    final pian = Pianificatore(db, c.orologio);
    final carte = CarteCreditoServizio(db, c.orologio, pian);
    await carte.crea(nome: 'Visa', contoAddebitoId: conto, giornoAddebito: 15);
    final collegati = await c.eliminazione.collegamenti(conto);
    expect(collegati.carta, isNotNull);
    await expectLater(
      c.eliminazione.elimina(conto, daEliminare: {prelievo}),
      throwsStateError,
    );
  });

  test('portafogli archiviati in un elenco a parte', () async {
    await c.archiviaPortafoglio(contanti);
    expect(await nomi(), ['Conto']);
    final archiviati = await c.osservaPortafogli(archiviati: true).first;
    expect(archiviati.map((p) => p.portafoglio.nome), ['Contanti']);
  });
}
