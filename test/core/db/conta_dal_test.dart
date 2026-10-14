import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/db/archivio.dart';
import 'package:gestionale_finanziaria/core/db/contabilita.dart';
import 'package:gestionale_finanziaria/core/db/costo_vita.dart';
import 'package:gestionale_finanziaria/core/db/notifiche.dart';
import 'package:gestionale_finanziaria/core/db/pianificatore.dart';
import 'package:gestionale_finanziaria/core/db/prestiti.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';
import 'package:gestionale_finanziaria/core/ricorrenza.dart';

/// "Conta dal": prestiti ed entrate già in corso quando li inserisci contano
/// solo da quel momento.
void main() {
  late Archivio db;
  late Contabilita c;
  late Pianificatore pian;
  late CostoVita cv;
  late PrestitiServizio prestiti;
  late NotificheServizio notifiche;
  late DateTime adesso;
  late String conto;

  setUp(() async {
    db = Archivio.inMemoria();
    c = await Contabilita.apri(db);
    adesso = DateTime(2026, 10, 14, 10);
    pian = Pianificatore(db, c.orologio, adesso: () => adesso);
    cv = CostoVita(db, c.orologio, pian, adesso: () => adesso);
    prestiti = PrestitiServizio(db, c.orologio, pian, adesso: () => adesso);
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

  Future<List<Movimento>> movimenti() =>
      (db.select(db.movimenti)..where((m) => m.eliminato.equals(false))).get();

  DatiPrestito auto({DateTime? contaDal}) => DatiPrestito(
    nome: 'Auto',
    tipo: TipoPrestito.rate,
    capitale: 600000,
    numeroRate: 12,
    importoRata: 50000,
    // Già in corso: la prima rata era il 10 luglio.
    primaRata: DateTime(2026, 7, 10),
    portafoglioId: conto,
    contaDal: contaDal,
  );

  test('prestito già in corso: niente rate passate, ma sono pagate', () async {
    final id = await prestiti.crea(auto());
    expect(await pian.registraScadute(), 0);
    expect(await movimenti(), isEmpty);

    final stato = (await prestiti.stati()).single;
    expect(stato.ratePagate, 4); // luglio, agosto, settembre, ottobre
    expect(stato.prossima!.data, DateTime(2026, 11, 10));
    expect(await prestiti.contaDal(id), DateTime(2026, 10, 14));

    // Nel costo della vita: la rata di ottobre (già pagata) non conta.
    final mesi = await cv.riepiloghi([
      DateTime(2026, 9),
      DateTime(2026, 10),
      DateTime(2026, 11),
    ]);
    expect([for (final m in mesi) m.rate.length], [0, 0, 1]);

    // La rata di novembre si registra da sola.
    adesso = DateTime(2026, 11, 10, 8);
    expect(await pian.registraScadute(), 1);
    expect((await movimenti()).single.data, '2026-11-10');
  });

  test('prestito già inserito: "Conta dal" toglie le rate registrate prima '
      '(e si può annullare)', () async {
    // Come un archivio di prima: contava dalla prima rata.
    final id = await prestiti.crea(auto(contaDal: DateTime(2026, 7, 10)));
    expect(await pian.registraScadute(), 4);

    final tolte = await prestiti.modifica(
      id,
      auto(contaDal: DateTime(2026, 10, 14)),
    );
    expect(tolte, hasLength(4));
    expect(await movimenti(), isEmpty);
    expect((await prestiti.stati()).single.ratePagate, 4); // pagate prima
    expect(await pian.registraScadute(), 0); // non tornano

    await pian.ripristinaMovimenti(tolte);
    expect(await movimenti(), hasLength(4));
  });

  test(
    'entrata già in corso: niente accrediti passati, né da confermare',
    () async {
      final voce = await cv.creaVoce(
        nome: 'Stipendio',
        tipo: TipoVoce.fissa,
        importo: 180000,
        natura: NaturaVoce.entrata,
      );
      await cv.impostaAddebito(
        voce,
        ricorrenza: Ricorrenza(inizio: DateTime(2026, 8, 10)),
        portafoglioId: conto,
        richiedeConferma: true,
      );
      expect(await notifiche.elenco(), isEmpty); // il 10 ottobre era prima
      expect(await cv.contaDal(voce), DateTime(2026, 10, 14));

      adesso = DateTime(2026, 11, 10, 9);
      expect((await notifiche.elenco()).single.tipo, TipoNotifica.daConfermare);
    },
  );

  test('spesa già in corso: si registra da oggi (oggi compreso)', () async {
    final voce = await cv.creaVoce(
      nome: 'Palestra',
      tipo: TipoVoce.fissa,
      importo: 4000,
    );
    await cv.impostaAddebito(
      voce,
      ricorrenza: Ricorrenza(
        inizio: DateTime(2026, 9, 14),
        frequenza: Frequenza.mensile,
      ),
      portafoglioId: conto,
    );
    expect(await pian.registraScadute(), 1); // il 14 ottobre, non settembre
    expect((await movimenti()).single.data, '2026-10-14');
  });
}
