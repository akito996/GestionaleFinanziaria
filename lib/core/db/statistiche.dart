import 'package:drift/drift.dart';

import 'archivio.dart';
import 'carte_credito.dart';
import 'contabilita.dart';
import 'osservazione.dart';
import 'prestiti.dart';

/// Spesa di una categoria principale in un periodo.
class SpesaCategoria {
  const SpesaCategoria(this.categoria, this.icona, this.totale);

  /// `null` = movimenti senza categoria.
  final String? categoria;
  final String? icona;
  final int totale;
}

/// Saldo di un portafoglio alla fine di un mese.
class SaldoMese {
  const SaldoMese(this.mese, this.saldo);

  final DateTime mese;
  final int saldo;
}

/// Una voce dello stato patrimoniale.
class VocePatrimonio {
  const VocePatrimonio(this.nome, this.importo);

  final String nome;
  final int importo;
}

/// Stato patrimoniale: cosa possiedi (attività) e cosa devi (passività).
class Patrimonio {
  const Patrimonio(this.attivita, this.passivita);

  final List<VocePatrimonio> attivita;
  final List<VocePatrimonio> passivita;

  int get totaleAttivita => attivita.fold(0, (t, v) => t + v.importo);
  int get totalePassivita => passivita.fold(0, (t, v) => t + v.importo);
  int get netto => totaleAttivita - totalePassivita;
}

/// Un passo del grafico a cascata (waterfall).
class PassoCascata {
  const PassoCascata(this.etichetta, this.valore, {this.totale = false});

  final String etichetta;

  /// Variazione (+ entrata, − uscita) oppure valore assoluto se [totale].
  final int valore;
  final bool totale;
}

/// Saldo di un mese in forma di candela: apertura, massimo, minimo, chiusura.
class CandelaSaldo {
  const CandelaSaldo(
    this.mese,
    this.apertura,
    this.massimo,
    this.minimo,
    this.chiusura,
  );

  final DateTime mese;
  final int apertura;
  final int massimo;
  final int minimo;
  final int chiusura;

  bool get crescita => chiusura >= apertura;
}

/// Entrate e uscite di un periodo (mese o anno). I trasferimenti tra i propri
/// portafogli non contano: non sono né guadagni né spese.
class EntrateUscite {
  const EntrateUscite(this.periodo, this.entrate, this.uscite);

  /// Primo giorno del mese (o dell'anno).
  final DateTime periodo;
  final int entrate;
  final int uscite;

  /// Quanto resta (positivo) o quanto manca (negativo).
  int get differenza => entrate - uscite;

  /// Parte delle entrate messa da parte (0,25 = 25%); `null` senza entrate.
  double? get risparmio => entrate == 0 ? null : differenza / entrate;
}

/// Periodo in corso confrontato con lo stesso tratto del periodo prima
/// (es. 1-11 ottobre contro 1-11 settembre): confronto alla pari.
class ConfrontoPeriodo {
  const ConfrontoPeriodo(this.attuale, this.precedente);

  final EntrateUscite attuale;
  final EntrateUscite precedente;

  /// Variazione percentuale (0,12 = +12%); `null` se prima era zero.
  static double? variazione(int adesso, int prima) =>
      prima == 0 ? null : (adesso - prima) / prima;
}

/// Dati aggregati per grafici ed export, e preferenze locali dei grafici.
class StatisticheServizio {
  StatisticheServizio(this._db);

  final Archivio _db;

  /// Spese (uscite) tra [da] e [a] raggruppate per categoria principale,
  /// dalla più grande alla più piccola.
  Future<List<SpesaCategoria>> spesePerCategoria(
    DateTime da,
    DateTime a,
  ) async {
    final categorie = AlberoCategorie(await _db.select(_db.categorie).get());
    final righe = await _db
        .customSelect(
          '''
          SELECT m.categoria_id AS categoria, SUM(m.importo_minimo) AS totale
          FROM movimenti m JOIN definizioni_tipo t ON t.id = m.tipo_id
          WHERE m.eliminato = 0 AND t.effetto = 'uscita'
            AND m.data BETWEEN ? AND ?
          GROUP BY m.categoria_id
          ''',
          variables: [
            Variable.withString(Contabilita.giorno(da)),
            Variable.withString(Contabilita.giorno(a)),
          ],
          readsFrom: {_db.movimenti, _db.definizioniTipo},
        )
        .get();
    final perRadice = <String?, int>{};
    for (final r in righe) {
      final id = r.readNullable<String>('categoria');
      final radice = id == null ? null : _radice(categorie, id);
      perRadice.update(
        radice,
        (v) => v + r.read<int>('totale'),
        ifAbsent: () => r.read<int>('totale'),
      );
    }
    final risultato = [
      for (final MapEntry(key: id, value: totale) in perRadice.entries)
        SpesaCategoria(
          id == null ? null : categorie.perId[id]?.nome,
          id == null ? null : categorie.perId[id]?.icona,
          totale,
        ),
    ]..sort((x, y) => y.totale.compareTo(x.totale));
    return risultato;
  }

  Stream<List<SpesaCategoria>> osservaSpesePerCategoria(
    DateTime da,
    DateTime a,
  ) => _db
      .customSelect(
        'SELECT 1 AS osserva_spese_per_categoria',
        readsFrom: {_db.movimenti, _db.categorie},
      )
      .watch()
      .ricalcola((_) => spesePerCategoria(da, a));

  /// Saldo di fine mese degli ultimi [mesi] mesi fino a [finoA] (incluso).
  Future<List<SaldoMese>> saldoMensile(
    String portafoglioId, {
    required DateTime finoA,
    int mesi = 12,
  }) async {
    final risultato = <SaldoMese>[];
    for (var i = mesi - 1; i >= 0; i--) {
      final mese = DateTime(finoA.year, finoA.month - i);
      final fine = DateTime(mese.year, mese.month + 1, 0);
      final riga = await _db
          .customSelect(
            '''
            SELECT p.saldo_iniziale_minimo
              + COALESCE((SELECT SUM(CASE t.effetto
                    WHEN 'entrata' THEN m.importo_minimo
                    WHEN 'uscita' THEN -m.importo_minimo
                    WHEN 'trasferimento' THEN -m.importo_minimo
                    ELSE 0 END)
                  FROM movimenti m JOIN definizioni_tipo t ON t.id = m.tipo_id
                  WHERE m.portafoglio_id = p.id AND m.eliminato = 0
                    AND m.data <= ?), 0)
              + COALESCE((SELECT SUM(m.importo_minimo)
                  FROM movimenti m JOIN definizioni_tipo t ON t.id = m.tipo_id
                  WHERE m.portafoglio_destinazione_id = p.id AND m.eliminato = 0
                    AND t.effetto = 'trasferimento' AND m.data <= ?), 0) AS saldo
            FROM portafogli p WHERE p.id = ?
            ''',
            variables: [
              Variable.withString(Contabilita.giorno(fine)),
              Variable.withString(Contabilita.giorno(fine)),
              Variable.withString(portafoglioId),
            ],
          )
          .getSingle();
      risultato.add(SaldoMese(mese, riga.read<int>('saldo')));
    }
    return risultato;
  }

  Stream<List<SaldoMese>> osservaSaldoMensile(
    String portafoglioId, {
    required DateTime finoA,
    int mesi = 12,
  }) => _db
      .customSelect(
        'SELECT 1 AS osserva_saldo_mensile',
        readsFrom: {_db.movimenti, _db.portafogli},
      )
      .watch()
      .ricalcola((_) => saldoMensile(portafoglioId, finoA: finoA, mesi: mesi));

  // ------------------------------------------------- entrate e uscite

  /// Entrate e uscite tra [da] e [a] (inclusi).
  Future<EntrateUscite> entrateUsciteTra(DateTime da, DateTime a) async {
    final riga = await _db
        .customSelect(
          '''
          SELECT
            COALESCE(SUM(CASE WHEN t.effetto = 'entrata' THEN m.importo_minimo END), 0) AS entrate,
            COALESCE(SUM(CASE WHEN t.effetto = 'uscita' THEN m.importo_minimo END), 0) AS uscite
          FROM movimenti m JOIN definizioni_tipo t ON t.id = m.tipo_id
          WHERE m.eliminato = 0 AND m.data BETWEEN ? AND ?
          ''',
          variables: [
            Variable.withString(Contabilita.giorno(da)),
            Variable.withString(Contabilita.giorno(a)),
          ],
        )
        .getSingle();
    return EntrateUscite(
      DateTime(da.year, da.month),
      riga.read<int>('entrate'),
      riga.read<int>('uscite'),
    );
  }

  /// Gli ultimi [mesi] mesi fino a [finoA] (incluso), dal più vecchio.
  Future<List<EntrateUscite>> entrateUscitePerMese({
    required DateTime finoA,
    int mesi = 12,
  }) async {
    final primo = DateTime(finoA.year, finoA.month - mesi + 1);
    final per = await _perPeriodo(
      primo,
      DateTime(finoA.year, finoA.month + 1, 0),
      'substr(m.data, 1, 7)',
    );
    return [
      for (var i = 0; i < mesi; i++)
        _periodo(per, DateTime(primo.year, primo.month + i), 7),
    ];
  }

  /// Gli ultimi [anni] anni fino a quello di [finoA] (incluso), dal più
  /// vecchio, a partire dal primo anno con movimenti.
  Future<List<EntrateUscite>> entrateUscitePerAnno({
    required DateTime finoA,
    int anni = 5,
  }) async {
    final primoMovimento = await _db
        .customSelect(
          'SELECT MIN(data) AS primo FROM movimenti WHERE eliminato = 0',
        )
        .getSingle();
    final primoAnno =
        int.tryParse(
          (primoMovimento.readNullable<String>('primo') ?? '').split('-').first,
        ) ??
        finoA.year;
    final da = primoAnno > finoA.year - anni + 1
        ? primoAnno
        : finoA.year - anni + 1;
    final per = await _perPeriodo(
      DateTime(da),
      DateTime(finoA.year, 12, 31),
      'substr(m.data, 1, 4)',
    );
    return [
      for (var anno = da; anno <= finoA.year; anno++)
        _periodo(per, DateTime(anno), 4),
    ];
  }

  /// Dall'inizio del mese (o dell'anno, con [anno]) fino a [oggi], contro lo
  /// stesso tratto del mese (o dell'anno) prima.
  Future<ConfrontoPeriodo> confronto(DateTime oggi, {bool anno = false}) async {
    final giorno = DateTime(oggi.year, oggi.month, oggi.day);
    if (anno) {
      final prima = DateTime(giorno.year - 1, giorno.month, 1);
      return ConfrontoPeriodo(
        await entrateUsciteTra(DateTime(giorno.year), giorno),
        await entrateUsciteTra(
          DateTime(giorno.year - 1),
          DateTime(
            prima.year,
            prima.month,
            _giornoValido(prima.year, prima.month, giorno.day),
          ),
        ),
      );
    }
    final mesePrima = DateTime(giorno.year, giorno.month - 1);
    return ConfrontoPeriodo(
      await entrateUsciteTra(DateTime(giorno.year, giorno.month), giorno),
      await entrateUsciteTra(
        mesePrima,
        DateTime(
          mesePrima.year,
          mesePrima.month,
          _giornoValido(mesePrima.year, mesePrima.month, giorno.day),
        ),
      ),
    );
  }

  /// Mesi e anni insieme, con i confronti: un solo stream per la scheda.
  Stream<
    ({
      List<EntrateUscite> mesi,
      List<EntrateUscite> anni,
      ConfrontoPeriodo confrontoMese,
      ConfrontoPeriodo confrontoAnno,
    })
  >
  osservaEntrateUscite(DateTime oggi) => _db
      .customSelect(
        'SELECT 1 AS osserva_entrate_uscite',
        readsFrom: {_db.movimenti, _db.definizioniTipo},
      )
      .watch()
      .ricalcola(
        (_) async => (
          mesi: await entrateUscitePerMese(finoA: oggi),
          anni: await entrateUscitePerAnno(finoA: oggi),
          confrontoMese: await confronto(oggi),
          confrontoAnno: await confronto(oggi, anno: true),
        ),
      );

  Future<Map<String, ({int entrate, int uscite})>> _perPeriodo(
    DateTime da,
    DateTime a,
    String chiave,
  ) async {
    final righe = await _db
        .customSelect(
          '''
          SELECT $chiave AS periodo,
            COALESCE(SUM(CASE WHEN t.effetto = 'entrata' THEN m.importo_minimo END), 0) AS entrate,
            COALESCE(SUM(CASE WHEN t.effetto = 'uscita' THEN m.importo_minimo END), 0) AS uscite
          FROM movimenti m JOIN definizioni_tipo t ON t.id = m.tipo_id
          WHERE m.eliminato = 0 AND m.data BETWEEN ? AND ?
          GROUP BY periodo
          ''',
          variables: [
            Variable.withString(Contabilita.giorno(da)),
            Variable.withString(Contabilita.giorno(a)),
          ],
        )
        .get();
    return {
      for (final r in righe)
        r.read<String>('periodo'): (
          entrate: r.read<int>('entrate'),
          uscite: r.read<int>('uscite'),
        ),
    };
  }

  static EntrateUscite _periodo(
    Map<String, ({int entrate, int uscite})> per,
    DateTime inizio,
    int lunghezza,
  ) {
    final v = per[Contabilita.giorno(inizio).substring(0, lunghezza)];
    return EntrateUscite(inizio, v?.entrate ?? 0, v?.uscite ?? 0);
  }

  static int _giornoValido(int anno, int mese, int giorno) {
    final ultimo = DateTime(anno, mese + 1, 0).day;
    return giorno > ultimo ? ultimo : giorno;
  }

  // ------------------------------------------- patrimonio, cascata, candele

  /// Saldo di un portafoglio alla fine del giorno [data].
  Future<int> saldoAl(String portafoglioId, DateTime data) async {
    final g = Contabilita.giorno(data);
    final riga = await _db
        .customSelect(
          '''
          SELECT p.saldo_iniziale_minimo
            + COALESCE((SELECT SUM(CASE t.effetto
                  WHEN 'entrata' THEN m.importo_minimo
                  WHEN 'uscita' THEN -m.importo_minimo
                  WHEN 'trasferimento' THEN -m.importo_minimo
                  ELSE 0 END)
                FROM movimenti m JOIN definizioni_tipo t ON t.id = m.tipo_id
                WHERE m.portafoglio_id = p.id AND m.eliminato = 0
                  AND m.data <= ?), 0)
            + COALESCE((SELECT SUM(m.importo_minimo)
                FROM movimenti m JOIN definizioni_tipo t ON t.id = m.tipo_id
                WHERE m.portafoglio_destinazione_id = p.id AND m.eliminato = 0
                  AND t.effetto = 'trasferimento' AND m.data <= ?), 0) AS saldo
          FROM portafogli p WHERE p.id = ?
          ''',
          variables: [
            Variable.withString(g),
            Variable.withString(g),
            Variable.withString(portafoglioId),
          ],
        )
        .getSingle();
    return riga.read<int>('saldo');
  }

  /// Stato patrimoniale di oggi: attività = portafogli con saldo positivo
  /// (raggruppati per tipo); passività = debiti delle carte, debito residuo dei
  /// prestiti, portafogli in rosso.
  Future<Patrimonio> patrimonio(
    CarteCreditoServizio carte,
    PrestitiServizio prestiti,
  ) async {
    final portafogli =
        await (_db.select(_db.portafogli).join([
              innerJoin(
                _db.definizioniTipo,
                _db.definizioniTipo.id.equalsExp(_db.portafogli.tipoId),
              ),
            ])..where(
              _db.portafogli.eliminato.equals(false) &
                  _db.portafogli.archiviato.equals(false),
            ))
            .get();
    final idCarte = {for (final c in await carte.stati()) c.portafoglio.id};
    final oggi = DateTime.now();
    final perTipo = <String, int>{};
    var inRosso = 0;
    for (final r in portafogli) {
      final p = r.readTable(_db.portafogli);
      final tipo = r.readTable(_db.definizioniTipo);
      if (idCarte.contains(p.id) || tipo.nome == tipoCartaDiCredito) {
        continue;
      }
      final saldo = await saldoAl(p.id, oggi);
      if (saldo >= 0) {
        perTipo.update(tipo.nome, (v) => v + saldo, ifAbsent: () => saldo);
      } else {
        inRosso -= saldo;
      }
    }
    final debitoCarte = (await carte.stati()).fold<int>(
      0,
      (t, c) => t + c.debitoTotale,
    );
    final debitoPrestiti = (await prestiti.stati()).fold<int>(
      0,
      (t, p) => t + p.debitoResiduo,
    );
    return Patrimonio(
      [
        for (final MapEntry(key: nome, value: v) in perTipo.entries)
          if (v > 0) VocePatrimonio(nome, v),
      ]..sort((a, b) => b.importo.compareTo(a.importo)),
      [
        if (debitoPrestiti > 0)
          VocePatrimonio('Prestiti e mutui', debitoPrestiti),
        if (debitoCarte > 0) VocePatrimonio('Carte di credito', debitoCarte),
        if (inRosso > 0) VocePatrimonio('Conti in rosso', inRosso),
      ],
    );
  }

  Stream<Patrimonio> osservaPatrimonio(
    CarteCreditoServizio carte,
    PrestitiServizio prestiti,
  ) => _db
      .customSelect(
        'SELECT 1 AS osserva_patrimonio',
        readsFrom: {
          _db.movimenti,
          _db.portafogli,
          _db.prestiti,
          _db.carteCredito,
        },
      )
      .watch()
      .ricalcola((_) => patrimonio(carte, prestiti));

  /// Cascata di un mese: saldo totale a inizio mese → entrate → spese per
  /// categoria principale (le 5 maggiori + "Altre") → saldo a fine mese.
  Future<List<PassoCascata>> cascataMese(DateTime mese) async {
    final inizio = DateTime(mese.year, mese.month);
    final fine = DateTime(mese.year, mese.month + 1, 0);
    final ids =
        await (_db.selectOnly(_db.portafogli)
              ..addColumns([_db.portafogli.id])
              ..where(
                _db.portafogli.eliminato.equals(false) &
                    _db.portafogli.archiviato.equals(false),
              ))
            .get();
    var saldoIniziale = 0;
    var saldoFinale = 0;
    for (final r in ids) {
      final id = r.read(_db.portafogli.id)!;
      saldoIniziale += await saldoAl(
        id,
        inizio.subtract(const Duration(days: 1)),
      );
      saldoFinale += await saldoAl(id, fine);
    }
    final entrate = await _db
        .customSelect(
          '''
          SELECT COALESCE(SUM(m.importo_minimo), 0) AS totale
          FROM movimenti m JOIN definizioni_tipo t ON t.id = m.tipo_id
          WHERE m.eliminato = 0 AND t.effetto = 'entrata' AND m.data BETWEEN ? AND ?
          ''',
          variables: [
            Variable.withString(Contabilita.giorno(inizio)),
            Variable.withString(Contabilita.giorno(fine)),
          ],
        )
        .getSingle();
    final spese = await spesePerCategoria(inizio, fine);
    final principali = spese.take(5).toList();
    final altre = spese.skip(5).fold<int>(0, (t, s) => t + s.totale);
    return [
      PassoCascata('Inizio mese', saldoIniziale, totale: true),
      if (entrate.read<int>('totale') > 0)
        PassoCascata('Entrate', entrate.read<int>('totale')),
      for (final s in principali)
        PassoCascata(s.categoria ?? 'Senza categoria', -s.totale),
      if (altre > 0) PassoCascata('Altre spese', -altre),
      PassoCascata('Fine mese', saldoFinale, totale: true),
    ];
  }

  Stream<List<PassoCascata>> osservaCascataMese(DateTime mese) => _db
      .customSelect(
        'SELECT 1 AS osserva_cascata',
        readsFrom: {_db.movimenti, _db.portafogli, _db.categorie},
      )
      .watch()
      .ricalcola((_) => cascataMese(mese));

  /// Candele mensili del saldo di un portafoglio (giorno per giorno).
  Future<List<CandelaSaldo>> candeleSaldo(
    String portafoglioId, {
    required DateTime finoA,
    int mesi = 12,
  }) async {
    final risultato = <CandelaSaldo>[];
    for (var i = mesi - 1; i >= 0; i--) {
      final mese = DateTime(finoA.year, finoA.month - i);
      final fine = DateTime(mese.year, mese.month + 1, 0);
      var saldo = await saldoAl(
        portafoglioId,
        mese.subtract(const Duration(days: 1)),
      );
      final apertura = saldo;
      var massimo = saldo;
      var minimo = saldo;
      final righe = await _db
          .customSelect(
            '''
            SELECT m.data AS data,
              SUM(CASE
                WHEN t.effetto = 'entrata' AND m.portafoglio_id = ? THEN m.importo_minimo
                WHEN t.effetto = 'uscita' AND m.portafoglio_id = ? THEN -m.importo_minimo
                WHEN t.effetto = 'trasferimento' AND m.portafoglio_id = ? THEN -m.importo_minimo
                WHEN t.effetto = 'trasferimento' AND m.portafoglio_destinazione_id = ? THEN m.importo_minimo
                ELSE 0 END) AS variazione
            FROM movimenti m JOIN definizioni_tipo t ON t.id = m.tipo_id
            WHERE m.eliminato = 0 AND m.data BETWEEN ? AND ?
              AND (m.portafoglio_id = ? OR m.portafoglio_destinazione_id = ?)
            GROUP BY m.data ORDER BY m.data
            ''',
            variables: [
              for (var k = 0; k < 4; k++) Variable.withString(portafoglioId),
              Variable.withString(Contabilita.giorno(mese)),
              Variable.withString(Contabilita.giorno(fine)),
              Variable.withString(portafoglioId),
              Variable.withString(portafoglioId),
            ],
          )
          .get();
      for (final r in righe) {
        saldo += r.read<int>('variazione');
        if (saldo > massimo) {
          massimo = saldo;
        }
        if (saldo < minimo) {
          minimo = saldo;
        }
      }
      risultato.add(CandelaSaldo(mese, apertura, massimo, minimo, saldo));
    }
    return risultato;
  }

  Stream<List<CandelaSaldo>> osservaCandeleSaldo(
    String portafoglioId, {
    required DateTime finoA,
    int mesi = 12,
  }) => _db
      .customSelect(
        'SELECT 1 AS osserva_candele',
        readsFrom: {_db.movimenti, _db.portafogli},
      )
      .watch()
      .ricalcola((_) => candeleSaldo(portafoglioId, finoA: finoA, mesi: mesi));

  // ------------------------------------------------- preferenze dei grafici

  Future<String?> preferenza(String chiave) async => (await (_db.select(
    _db.impostazioni,
  )..where((i) => i.chiave.equals('pref.$chiave'))).getSingleOrNull())?.valore;

  Future<void> salvaPreferenza(String chiave, String valore) => _db
      .into(_db.impostazioni)
      .insertOnConflictUpdate(
        ImpostazioniCompanion.insert(chiave: 'pref.$chiave', valore: valore),
      );

  static String _radice(AlberoCategorie albero, String id) {
    var corrente = id;
    final visti = <String>{};
    while (visti.add(corrente)) {
      final padre = albero.perId[corrente]?.padreId;
      if (padre == null || !albero.perId.containsKey(padre)) {
        break;
      }
      corrente = padre;
    }
    return corrente;
  }
}
