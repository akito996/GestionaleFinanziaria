import 'package:drift/drift.dart';

import 'archivio.dart';
import 'contabilita.dart';

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
