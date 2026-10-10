import 'package:drift/drift.dart';

import 'archivio.dart';
import 'contabilita.dart';
import 'id.dart';
import 'orologio.dart';
import 'tabelle.dart';

/// Da quando vale un nuovo importo predefinito (scelta dell'utente).
enum Decorrenza { domani, meseProssimo }

/// Una voce nel riepilogo di un mese.
class VoceDelMese {
  const VoceDelMese({
    required this.voce,
    required this.previsto,
    required this.predefinito,
    required this.variato,
    this.reale,
    this.prossimaModifica,
  });

  final VoceCosto voce;

  /// Importo del mese: la variazione del mese se c'è, altrimenti il predefinito.
  final int previsto;

  /// Importo predefinito valido nel mese (senza variazione).
  final int predefinito;

  /// `true` se per questo mese l'importo è stato cambiato a mano.
  final bool variato;

  /// Solo variabili con categoria: speso davvero nel mese (movimenti di uscita).
  final int? reale;

  /// Modifica già programmata (es. "da domani 850 €"), per mostrarla all'utente.
  final ({int importo, String dal})? prossimaModifica;

  bool get fissa => voce.tipo == TipoVoce.fissa;
}

class RiepilogoMese {
  const RiepilogoMese(this.mese, this.voci);

  /// Primo giorno del mese.
  final DateTime mese;
  final List<VoceDelMese> voci;

  int get fisse => _somma(voci.where((v) => v.fissa).map((v) => v.previsto));

  int get variabiliPreviste =>
      _somma(voci.where((v) => !v.fissa).map((v) => v.previsto));

  int get variabiliReali =>
      _somma(voci.where((v) => !v.fissa).map((v) => v.reale ?? 0));

  int get totalePrevisto => fisse + variabiliPreviste;

  static int _somma(Iterable<int> valori) =>
      valori.fold(0, (totale, v) => totale + v);
}

/// Costo della vita: voci fisse e variabili, importi predefiniti con decorrenza,
/// variazioni di un solo mese e confronto con le spese reali.
///
/// Regola dei mesi: per un mese passato vale l'importo in vigore l'ultimo giorno
/// del mese; per il mese in corso quello in vigore oggi; per i mesi futuri quello
/// del primo giorno. Così una modifica "da domani" si vede dal giorno dopo e lo
/// storico dei mesi già chiusi non cambia.
class CostoVita {
  CostoVita(this._db, this._orologio, {DateTime Function()? adesso})
    : _adesso = adesso ?? DateTime.now;

  final Archivio _db;
  final OrologioLogico _orologio;
  final DateTime Function() _adesso;

  // -------------------------------------------------------------- voci

  Future<String> creaVoce({
    required String nome,
    required String tipo,
    required int importo,
    String? categoriaId,
    String valuta = 'EUR',
  }) async {
    final id = nuovoId();
    final oggi = _adesso();
    await _db.transaction(() async {
      await _db
          .into(_db.vociCosto)
          .insert(
            VociCostoCompanion.insert(
              id: id,
              aggiornatoIl: _orologio.adesso(),
              nome: nome.trim(),
              tipo: tipo,
              categoriaId: Value(categoriaId),
              valuta: Value(valuta),
              ordine: Value(await _prossimoOrdine()),
            ),
          );
      // Una voce nuova vale già per il mese in corso.
      await _nuovoImporto(id, importo, DateTime(oggi.year, oggi.month));
    });
    return id;
  }

  Future<void> modificaVoce(
    String id, {
    required String nome,
    String? categoriaId,
  }) => (_db.update(_db.vociCosto)..where((v) => v.id.equals(id))).write(
    VociCostoCompanion(
      aggiornatoIl: Value(_orologio.adesso()),
      nome: Value(nome.trim()),
      categoriaId: Value(categoriaId),
    ),
  );

  /// Nuovo importo predefinito, da domani o dal 1° del mese prossimo.
  /// I mesi già passati non cambiano.
  Future<void> cambiaImportoPredefinito(
    String voceId,
    int importo,
    Decorrenza decorrenza,
  ) {
    final oggi = _adesso();
    final dal = switch (decorrenza) {
      Decorrenza.domani => DateTime(oggi.year, oggi.month, oggi.day + 1),
      Decorrenza.meseProssimo => DateTime(oggi.year, oggi.month + 1),
    };
    return _nuovoImporto(voceId, importo, dal);
  }

  /// Importo diverso solo per [mese] (il predefinito non cambia).
  Future<void> variaMese(String voceId, DateTime mese, int importo) async {
    final chiave = _chiaveMese(mese);
    final esistente =
        await (_db.select(_db.variazioniMese)..where(
              (v) =>
                  v.voceId.equals(voceId) &
                  v.mese.equals(chiave) &
                  v.eliminato.equals(false),
            ))
            .getSingleOrNull();
    if (esistente != null) {
      await (_db.update(
        _db.variazioniMese,
      )..where((v) => v.id.equals(esistente.id))).write(
        VariazioniMeseCompanion(
          aggiornatoIl: Value(_orologio.adesso()),
          importoMinimo: Value(importo),
        ),
      );
      return;
    }
    await _db
        .into(_db.variazioniMese)
        .insert(
          VariazioniMeseCompanion.insert(
            id: nuovoId(),
            aggiornatoIl: _orologio.adesso(),
            voceId: voceId,
            mese: chiave,
            importoMinimo: importo,
          ),
        );
  }

  /// Toglie la variazione del mese: torna a valere l'importo predefinito.
  Future<void> annullaVariazione(String voceId, DateTime mese) =>
      (_db.update(_db.variazioniMese)..where(
            (v) => v.voceId.equals(voceId) & v.mese.equals(_chiaveMese(mese)),
          ))
          .write(
            VariazioniMeseCompanion(
              aggiornatoIl: Value(_orologio.adesso()),
              eliminato: const Value(true),
            ),
          );

  Future<void> archiviaVoce(String id, {bool archiviata = true}) =>
      (_db.update(_db.vociCosto)..where((v) => v.id.equals(id))).write(
        VociCostoCompanion(
          aggiornatoIl: Value(_orologio.adesso()),
          archiviata: Value(archiviata),
        ),
      );

  // ---------------------------------------------------------- riepiloghi

  /// Riepilogo di un mese, aggiornato quando cambiano voci, importi o movimenti.
  Stream<RiepilogoMese> osservaMese(DateTime mese) =>
      _osserva().asyncMap((_) async => (await riepiloghi([mese])).single);

  /// Gli ultimi [quanti] mesi fino a [finoA] incluso (per il grafico).
  Stream<List<RiepilogoMese>> osservaStorico({
    required DateTime finoA,
    int quanti = 6,
  }) => _osserva().asyncMap(
    (_) => riepiloghi([
      for (var i = quanti - 1; i >= 0; i--)
        DateTime(finoA.year, finoA.month - i),
    ]),
  );

  Future<List<RiepilogoMese>> riepiloghi(List<DateTime> mesi) async {
    final voci =
        await (_db.select(_db.vociCosto)
              ..where(
                (v) => v.eliminato.equals(false) & v.archiviata.equals(false),
              )
              ..orderBy([
                (v) => OrderingTerm(expression: v.ordine),
                (v) => OrderingTerm(expression: v.nome),
              ]))
            .get();
    final importi = await (_db.select(
      _db.importiVoce,
    )..where((i) => i.eliminato.equals(false))).get();
    final variazioni = await (_db.select(
      _db.variazioniMese,
    )..where((v) => v.eliminato.equals(false))).get();
    final albero = AlberoCategorie(await _db.select(_db.categorie).get());

    final perVoce = <String, List<ImportoVoce>>{};
    for (final i in importi) {
      perVoce.putIfAbsent(i.voceId, () => []).add(i);
    }
    for (final lista in perVoce.values) {
      lista.sort((a, b) {
        final perData = a.validoDal.compareTo(b.validoDal);
        return perData != 0
            ? perData
            : a.aggiornatoIl.compareTo(b.aggiornatoIl);
      });
    }
    final variazioniPer = {
      for (final v in variazioni) '${v.voceId}|${v.mese}': v.importoMinimo,
    };

    final oggi = _adesso();
    final risultato = <RiepilogoMese>[];
    for (final m in mesi) {
      final mese = DateTime(m.year, m.month);
      final riferimento = _giornoDiRiferimento(mese, oggi);
      final spese = await _speseRealiPerCategoria(mese);
      final righe = <VoceDelMese>[];
      for (final voce in voci) {
        final storia = perVoce[voce.id] ?? const [];
        // Una voce creata dopo questo mese non c'era ancora.
        if (storia.isEmpty ||
            storia.first.validoDal.compareTo(
                  Contabilita.giorno(_ultimoGiorno(mese)),
                ) >
                0) {
          continue;
        }
        final predefinito = _importoAl(storia, riferimento) ?? 0;
        final variazione = variazioniPer['${voce.id}|${_chiaveMese(mese)}'];
        final futura = storia
            .where((i) => i.validoDal.compareTo(Contabilita.giorno(oggi)) > 0)
            .firstOrNull;
        int? reale;
        if (voce.tipo == TipoVoce.variabile && voce.categoriaId != null) {
          reale = albero
              .discendenti(voce.categoriaId!)
              .map((id) => spese[id] ?? 0)
              .fold<int>(0, (a, b) => a + b);
        }
        righe.add(
          VoceDelMese(
            voce: voce,
            previsto: variazione ?? predefinito,
            predefinito: predefinito,
            variato: variazione != null,
            reale: reale,
            prossimaModifica: futura == null
                ? null
                : (importo: futura.importoMinimo, dal: futura.validoDal),
          ),
        );
      }
      risultato.add(RiepilogoMese(mese, righe));
    }
    return risultato;
  }

  // ------------------------------------------------------------- interni

  Stream<void> _osserva() => _db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          _db.vociCosto,
          _db.importiVoce,
          _db.variazioniMese,
          _db.movimenti,
          _db.categorie,
        },
      )
      .watch();

  Future<void> _nuovoImporto(String voceId, int importo, DateTime dal) => _db
      .into(_db.importiVoce)
      .insert(
        ImportiVoceCompanion.insert(
          id: nuovoId(),
          aggiornatoIl: _orologio.adesso(),
          voceId: voceId,
          importoMinimo: importo,
          validoDal: Contabilita.giorno(dal),
        ),
      );

  /// Spese (uscite) del mese per categoria.
  Future<Map<String, int>> _speseRealiPerCategoria(DateTime mese) async {
    final righe = await _db
        .customSelect(
          '''
          SELECT m.categoria_id AS categoria, SUM(m.importo_minimo) AS totale
          FROM movimenti m JOIN definizioni_tipo t ON t.id = m.tipo_id
          WHERE m.eliminato = 0 AND t.effetto = 'uscita'
            AND m.categoria_id IS NOT NULL
            AND m.data BETWEEN ? AND ?
          GROUP BY m.categoria_id
          ''',
          variables: [
            Variable.withString(Contabilita.giorno(mese)),
            Variable.withString(Contabilita.giorno(_ultimoGiorno(mese))),
          ],
          readsFrom: {_db.movimenti, _db.definizioniTipo},
        )
        .get();
    return {
      for (final r in righe) r.read<String>('categoria'): r.read<int>('totale'),
    };
  }

  static int? _importoAl(List<ImportoVoce> storia, DateTime giorno) {
    final chiave = Contabilita.giorno(giorno);
    int? valore;
    for (final i in storia) {
      if (i.validoDal.compareTo(chiave) <= 0) {
        valore = i.importoMinimo;
      }
    }
    return valore;
  }

  static DateTime _giornoDiRiferimento(DateTime mese, DateTime oggi) {
    final meseCorrente = DateTime(oggi.year, oggi.month);
    if (mese.isBefore(meseCorrente)) {
      return _ultimoGiorno(mese);
    }
    if (mese == meseCorrente) {
      return DateTime(oggi.year, oggi.month, oggi.day);
    }
    return mese;
  }

  static DateTime _ultimoGiorno(DateTime mese) =>
      DateTime(mese.year, mese.month + 1, 0);

  static String _chiaveMese(DateTime mese) =>
      '${mese.year.toString().padLeft(4, '0')}-'
      '${mese.month.toString().padLeft(2, '0')}';

  Future<int> _prossimoOrdine() async {
    final massimo = _db.vociCosto.ordine.max();
    final riga = await (_db.selectOnly(
      _db.vociCosto,
    )..addColumns([massimo])).getSingle();
    return (riga.read(massimo) ?? -1) + 1;
  }
}
