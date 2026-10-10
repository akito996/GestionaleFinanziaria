import 'package:drift/drift.dart';

import 'archivio.dart';
import 'carte_credito.dart';
import 'contabilita.dart';
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
      .asyncMap((_) => spesePerCategoria(da, a));

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
      .asyncMap((_) => saldoMensile(portafoglioId, finoA: finoA, mesi: mesi));

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
      .asyncMap((_) => patrimonio(carte, prestiti));

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
      .asyncMap((_) => cascataMese(mese));

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
      .asyncMap((_) => candeleSaldo(portafoglioId, finoA: finoA, mesi: mesi));

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
