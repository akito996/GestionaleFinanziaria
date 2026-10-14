import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/db/archivio.dart';
import 'package:gestionale_finanziaria/core/db/contabilita.dart';
import 'package:gestionale_finanziaria/core/db/costo_vita.dart';
import 'package:gestionale_finanziaria/core/db/notifiche.dart';
import 'package:gestionale_finanziaria/core/db/pianificatore.dart';
import 'package:gestionale_finanziaria/core/db/prestiti.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';
import 'package:gestionale_finanziaria/core/ricorrenza.dart';

void main() {
  late Archivio db;
  late Contabilita c;
  late CostoVita cv;
  late Pianificatore pian;
  late NotificheServizio notifiche;
  late DateTime adesso;
  late String conto;

  setUp(() async {
    db = Archivio.inMemoria();
    c = await Contabilita.apri(db);
    adesso = DateTime(2026, 10, 10, 15);
    pian = Pianificatore(db, c.orologio, adesso: () => adesso);
    cv = CostoVita(db, c.orologio, pian, adesso: () => adesso);
    final prestiti = PrestitiServizio(
      db,
      c.orologio,
      pian,
      adesso: () => adesso,
    );
    notifiche = NotificheServizio(
      db,
      c.orologio,
      pian,
      prestiti,
      adesso: () => adesso,
    );
    final tipo = (await c.tipi(AmbitoTipo.portafoglio))
        .firstWhere((t) => t.nome == 'Conto corrente');
    conto = await c.creaPortafoglio(
      nome: 'Conto',
      tipoId: tipo.id,
      valuta: 'EUR',
    );
  });

  tearDown(() => db.close());

  Future<String> voce(
    String nome,
    int importo,
    DateTime primo, {
    String natura = NaturaVoce.spesa,
    bool conferma = false,
    bool conPortafoglio = true,
  }) async {
    final id = await cv.creaVoce(
      nome: nome,
      tipo: TipoVoce.fissa,
      importo: importo,
      natura: natura,
    );
    await cv.impostaAddebito(
      id,
      ricorrenza: Ricorrenza(inizio: primo),
      portafoglioId: conPortafoglio ? conto : null,
      richiedeConferma: conferma,
    );
    return id;
  }

  Future<List<Movimento>> movimenti() =>
      (db.select(db.movimenti)..where((m) => m.eliminato.equals(false))).get();

  Future<Notifica?> notifica(String titolo) async =>
      (await notifiche.elenco()).where((n) => n.titolo == titolo).firstOrNull;

  group('entrata con conferma', () {
    test('compare nel giorno previsto e non si registra da sola', () async {
      await voce(
        'Stipendio',
        180800,
        DateTime(2026, 10, 12),
        natura: NaturaVoce.entrata,
        conferma: true,
      );
      // Le entrate non si annunciano prima.
      expect(await notifica('Stipendio'), isNull);

      adesso = DateTime(2026, 10, 12, 9);
      expect(await pian.registraScadute(), 0);
      final n = (await notifica('Stipendio'))!;
      expect(n.tipo, TipoNotifica.daConfermare);
      expect(n.entrata, isTrue);
      expect(n.importo, 180800);
      expect(n.attiva, isTrue);

      // Letta ma non decisa: resta (serve una scelta).
      await notifiche.segnaLette([n]);
      expect((await notifica('Stipendio'))!.attiva, isTrue);

      // Il giorno dopo è ancora lì.
      adesso = DateTime(2026, 10, 13, 9);
      expect((await notifica('Stipendio'))!.tipo, TipoNotifica.daConfermare);
    });

    test('conferma: registra il movimento; "Annulla" lo toglie', () async {
      await voce(
        'Stipendio',
        180800,
        DateTime(2026, 10, 12),
        natura: NaturaVoce.entrata,
        conferma: true,
      );
      adesso = DateTime(2026, 10, 14, 9);
      final indietro = await notifiche.conferma([
        (await notifica('Stipendio'))!,
      ]);
      final registrato = (await movimenti()).single;
      expect(registrato.data, '2026-10-12');
      expect(registrato.importoMinimo, 180800);
      // Confermata dall'utente: niente avviso "registrata".
      expect(await notifica('Stipendio'), isNull);

      await indietro();
      expect(await movimenti(), isEmpty);
      expect((await notifica('Stipendio'))!.tipo, TipoNotifica.daConfermare);
    });

    test('conferma in massa', () async {
      await voce(
        'Lezione A',
        8000,
        DateTime(2026, 10, 10),
        natura: NaturaVoce.entrata,
        conferma: true,
      );
      await voce(
        'Lezione B',
        7000,
        DateTime(2026, 10, 10),
        natura: NaturaVoce.entrata,
        conferma: true,
      );
      final elenco = await notifiche.elenco();
      expect(
        elenco.where((n) => n.tipo == TipoNotifica.daConfermare),
        hasLength(2),
      );
      await notifiche.conferma(elenco);
      expect(await movimenti(), hasLength(2));
      expect(await notifiche.elenco(), isEmpty);
    });
  });

  group('uscita automatica', () {
    test(
      'avviso 3 giorni prima, poi "registrata" finché non la leggi',
      () async {
        await voce('Affitto', 70000, DateTime(2026, 10, 13));
        final prima = (await notifica('Affitto'))!;
        expect(prima.tipo, TipoNotifica.inArrivo);
        expect(prima.entrata, isFalse);

        adesso = DateTime(2026, 10, 13, 8);
        expect(await pian.registraScadute(), 1);
        final dopo = (await notifica('Affitto'))!;
        expect(dopo.tipo, TipoNotifica.registrata);
        expect(dopo.confermabile, isFalse);
        expect(dopo.attiva, isTrue);

        await notifiche.segnaLette([dopo]);
        expect((await notifica('Affitto'))!.attiva, isFalse);

        // Dopo una settimana l'avviso "registrata" non c'è più.
        adesso = DateTime(2026, 10, 21, 8);
        expect(await notifica('Affitto'), isNull);
      },
    );

    test('conferma in anticipo: registrata oggi, non di nuovo', () async {
      await voce('Affitto', 70000, DateTime(2026, 10, 12));
      await notifiche.conferma([(await notifica('Affitto'))!]);
      expect((await movimenti()).single.data, '2026-10-10');
      adesso = DateTime(2026, 10, 12, 8);
      expect(await pian.registraScadute(), 0);
    });

    test('riprogramma: si registra nel nuovo giorno', () async {
      await voce('Affitto', 70000, DateTime(2026, 10, 12));
      final n = (await notifica('Affitto'))!;
      final indietro = await notifiche.sposta(n, DateTime(2026, 10, 20));
      expect(await notifica('Affitto'), isNull); // ora è lontana

      adesso = DateTime(2026, 10, 12, 8);
      expect(await pian.registraScadute(), 0);
      adesso = DateTime(2026, 10, 20, 8);
      expect(await pian.registraScadute(), 1);
      final m = (await movimenti()).single;
      expect(m.data, '2026-10-20');
      expect(m.dataPrevista, '2026-10-12');
      // Il mese dopo torna nel giorno solito.
      expect(
        (await pian.inArrivo(giorni: 30)).first.data,
        DateTime(2026, 11, 12),
      );

      expect(indietro, isNotNull);
    });

    test('annulla solo questa volta (e "Ripristina")', () async {
      await voce('Affitto', 70000, DateTime(2026, 10, 12));
      final indietro = await notifiche.annulla((await notifica('Affitto'))!);
      adesso = DateTime(2026, 10, 12, 8);
      expect(await pian.registraScadute(), 0);
      expect(await notifica('Affitto'), isNull);

      await indietro();
      expect(await pian.registraScadute(), 1);
    });
  });

  test('promemoria senza portafoglio: "fatto" lo toglie', () async {
    await voce(
      'Cessione del quinto',
      28600,
      DateTime(2026, 10, 10),
      conPortafoglio: false,
    );
    final n = (await notifica('Cessione del quinto'))!;
    expect(n.tipo, TipoNotifica.promemoria);
    final indietro = await notifiche.conferma([n]);
    expect(await movimenti(), isEmpty);
    expect(await notifica('Cessione del quinto'), isNull);
    await indietro();
    expect((await notifica('Cessione del quinto'))!.attiva, isTrue);
  });

  test('si aggiorna da sola quando cambiano le scadenze', () async {
    final valori = <int>[];
    final iscrizione = notifiche.osserva().listen((l) => valori.add(l.length));
    await pumpEventQueue();
    await voce('Affitto', 70000, DateTime(2026, 10, 12));
    await pumpEventQueue();
    await iscrizione.cancel();
    expect(valori.first, 0);
    expect(valori.last, 1);
  });
}
