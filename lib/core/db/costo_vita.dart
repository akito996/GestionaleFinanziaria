import 'package:drift/drift.dart';

import '../ricorrenza.dart';

import 'archivio.dart';
import 'contabilita.dart';
import 'id.dart';
import 'orologio.dart';
import 'osservazione.dart';
import 'pianificatore.dart';
import 'prestiti.dart';
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
    this.addebito,
    this.dateAddebito = const [],
    int? importoUnitario,
  }) : importoUnitario = importoUnitario ?? predefinito;

  /// Importo di un singolo addebito (per le voci non mensili diverso dal totale
  /// del mese).
  final int importoUnitario;

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

  /// Data di addebito e regola (se impostate): da qui nascono i movimenti automatici.
  final Pianificazione? addebito;

  /// Giorni del mese in cui scalano i soldi.
  final List<DateTime> dateAddebito;

  bool get fissa => voce.tipo == TipoVoce.fissa;

  /// Spesa non mensile suddivisa nei mesi (es. 1.200 €/anno → 100 € al mese).
  bool get ripartita =>
      voce.ripartita &&
      addebito != null &&
      Frequenza.daCodice(addebito!.frequenza) != Frequenza.mensile;
}

/// Rata di un prestito che cade nel mese: conta tra le spese fisse del costo
/// della vita fino all'estinzione.
class RataDelMese {
  const RataDelMese({
    required this.prestito,
    required this.importo,
    required this.date,
    required this.numero,
  });

  final Prestito prestito;

  /// Quanto esce dal conto: rata (o maxi rata) + spese di incasso.
  final int importo;
  final List<DateTime> date;

  /// Numero della (prima) rata del mese, da 1 a [Prestito.numeroRate].
  final int numero;

  bool get maxi =>
      prestito.maxiRataMinimo != null && numero == prestito.numeroRate;
}

class RiepilogoMese {
  const RiepilogoMese(this.mese, this.voci, {this.rate = const []});

  /// Primo giorno del mese.
  final DateTime mese;
  final List<VoceDelMese> voci;

  /// Rate dei prestiti del mese (comprese nelle [fisse]).
  final List<RataDelMese> rate;

  /// Nessuna voce e nessun prestito: c'è ancora tutto da configurare.
  bool get vuoto => voci.isEmpty && rate.isEmpty;

  int get ratePrestiti => _somma(rate.map((r) => r.importo));

  /// Spese fisse del mese, comprese le rate dei prestiti.
  int get fisse =>
      _somma(voci.where((v) => v.fissa).map((v) => v.previsto)) + ratePrestiti;

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
  CostoVita(
    this._db,
    this._orologio,
    this._pianificatore, {
    DateTime Function()? adesso,
  }) : _adesso = adesso ?? DateTime.now {
    // Importo di ogni addebito: variazione del mese se c'è, altrimenti il
    // predefinito in vigore quel giorno.
    _pianificatore.registraCalcolo(
      OriginePianificazione.costoVita,
      (p, data) async =>
          p.origineId == null ? null : importoAl(p.origineId!, data),
    );
  }

  final Archivio _db;
  final OrologioLogico _orologio;
  final Pianificatore _pianificatore;
  final DateTime Function() _adesso;

  /// Quota mensile di una spesa pagata [importo] alla volta con frequenza [f]
  /// (es. 1.200 € ogni anno → 100 € al mese; ogni settimana × 52 / 12).
  static int quotaMensile(int importo, Frequenza f) => switch (f) {
    Frequenza.settimanale => (importo * 52 / 12).round(),
    Frequenza.mensile => importo,
    _ => (importo / f.mesi).round(),
  };

  // ------------------------------------------------------------ addebito

  /// Imposta (o toglie, con [ricorrenza] `null`) la data in cui scalano i soldi.
  /// Con un [portafoglioId] il movimento viene registrato da solo nel giorno
  /// previsto; senza, è solo un promemoria.
  /// Per le entrate previste è la data di accredito: il movimento registrato
  /// è un'entrata.
  Future<void> impostaAddebito(
    String voceId, {
    Ricorrenza? ricorrenza,
    String? portafoglioId,
  }) async {
    if (ricorrenza == null) {
      await _pianificatore.rimuovi(OriginePianificazione.costoVita, voceId);
      return;
    }
    final voce = await (_db.select(
      _db.vociCosto,
    )..where((v) => v.id.equals(voceId))).getSingle();
    final entrata = voce.natura == NaturaVoce.entrata;
    String? valuta;
    if (portafoglioId != null) {
      valuta = (await (_db.select(
        _db.portafogli,
      )..where((p) => p.id.equals(portafoglioId))).getSingle()).valuta;
    }
    await _pianificatore.salva(
      DatiPianificazione(
        origine: OriginePianificazione.costoVita,
        origineId: voceId,
        ricorrenza: ricorrenza,
        portafoglioId: portafoglioId,
        categoriaId: voce.categoriaId,
        tipoId: entrata ? await _tipoEntrata() : null,
        descrizione: voce.nome,
        valuta: valuta ?? voce.valuta,
      ),
    );
  }

  Future<String> _tipoEntrata() async =>
      (await (_db.select(_db.definizioniTipo)..where(
                (t) =>
                    t.ambito.equals(AmbitoTipo.movimento) &
                    t.effetto.equals(EffettoSaldo.entrata) &
                    t.diSistema.equals(true),
              ))
              .get())
          .first
          .id;

  /// Importo di un addebito di [voceId] nel giorno [data].
  Future<int?> importoAl(String voceId, DateTime data) async {
    final variazione =
        await (_db.select(_db.variazioniMese)..where(
              (v) =>
                  v.voceId.equals(voceId) &
                  v.mese.equals(_chiaveMese(data)) &
                  v.eliminato.equals(false),
            ))
            .getSingleOrNull();
    if (variazione != null) {
      return variazione.importoMinimo;
    }
    final storia =
        await (_db.select(_db.importiVoce)
              ..where(
                (i) => i.voceId.equals(voceId) & i.eliminato.equals(false),
              )
              ..orderBy([
                (i) => OrderingTerm(expression: i.validoDal),
                (i) => OrderingTerm(expression: i.aggiornatoIl),
              ]))
            .get();
    return _importoAl(storia, data);
  }

  // -------------------------------------------------------------- voci

  Future<String> creaVoce({
    required String nome,
    required String tipo,
    required int importo,
    String? categoriaId,
    String valuta = 'EUR',
    bool ripartita = false,
    String natura = NaturaVoce.spesa,
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
              ripartita: Value(ripartita),
              natura: Value(natura),
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
    String? tipo,
    bool? ripartita,
  }) async {
    await (_db.update(_db.vociCosto)..where((v) => v.id.equals(id))).write(
      VociCostoCompanion(
        aggiornatoIl: Value(_orologio.adesso()),
        nome: Value(nome.trim()),
        categoriaId: Value(categoriaId),
        tipo: tipo == null ? const Value.absent() : Value(tipo),
        ripartita: ripartita == null ? const Value.absent() : Value(ripartita),
      ),
    );
    // Nome e categoria anche sui movimenti che verranno registrati da qui in poi.
    await (_db.update(_db.pianificazioni)..where(
          (p) =>
              p.origine.equals(OriginePianificazione.costoVita) &
              p.origineId.equals(id),
        ))
        .write(
          PianificazioniCompanion(
            aggiornatoIl: Value(_orologio.adesso()),
            descrizione: Value(nome.trim()),
            categoriaId: Value(categoriaId),
          ),
        );
  }

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

  /// Archivia la voce e sospende i suoi addebiti automatici (reversibile).
  Future<void> archiviaVoce(String id, {bool archiviata = true}) async {
    await (_db.update(_db.vociCosto)..where((v) => v.id.equals(id))).write(
      VociCostoCompanion(
        aggiornatoIl: Value(_orologio.adesso()),
        archiviata: Value(archiviata),
      ),
    );
    await (_db.update(_db.pianificazioni)..where(
          (p) =>
              p.origine.equals(OriginePianificazione.costoVita) &
              p.origineId.equals(id),
        ))
        .write(
          PianificazioniCompanion(
            aggiornatoIl: Value(_orologio.adesso()),
            attiva: Value(!archiviata),
          ),
        );
  }

  /// Elimina la voce (anche dai mesi passati) e ferma i suoi addebiti
  /// automatici. I movimenti già registrati restano. Annullabile con
  /// [ripristinaVoce].
  Future<void> eliminaVoce(String id) => _impostaEliminata(id, true);

  Future<void> ripristinaVoce(String id) => _impostaEliminata(id, false);

  Future<void> _impostaEliminata(String id, bool eliminata) =>
      _db.transaction(() async {
        await (_db.update(_db.vociCosto)..where((v) => v.id.equals(id))).write(
          VociCostoCompanion(
            aggiornatoIl: Value(_orologio.adesso()),
            eliminato: Value(eliminata),
          ),
        );
        await (_db.update(_db.pianificazioni)..where(
              (p) =>
                  p.origine.equals(OriginePianificazione.costoVita) &
                  p.origineId.equals(id),
            ))
            .write(
              PianificazioniCompanion(
                aggiornatoIl: Value(_orologio.adesso()),
                attiva: Value(!eliminata),
              ),
            );
      });

  // ---------------------------------------------------------- riepiloghi

  /// Riepilogo di un mese, aggiornato quando cambiano voci, importi o movimenti.
  Stream<RiepilogoMese> osservaMese(
    DateTime mese, {
    String natura = NaturaVoce.spesa,
  }) => _osserva().ricalcola(
    (_) async => (await riepiloghi([mese], natura: natura)).single,
  );

  /// Gli ultimi [quanti] mesi fino a [finoA] incluso (per il grafico).
  Stream<List<RiepilogoMese>> osservaStorico({
    required DateTime finoA,
    int quanti = 6,
    String natura = NaturaVoce.spesa,
  }) => _osserva().ricalcola(
    (_) => riepiloghi([
      for (var i = quanti - 1; i >= 0; i--)
        DateTime(finoA.year, finoA.month - i),
    ], natura: natura),
  );

  /// Riepiloghi dei [mesi]: costo della vita ([NaturaVoce.spesa], con le rate
  /// dei prestiti) o entrate previste ([NaturaVoce.entrata]).
  Future<List<RiepilogoMese>> riepiloghi(
    List<DateTime> mesi, {
    String natura = NaturaVoce.spesa,
  }) async {
    final entrate = natura == NaturaVoce.entrata;
    final voci =
        await (_db.select(_db.vociCosto)
              ..where(
                (v) =>
                    v.eliminato.equals(false) &
                    v.archiviata.equals(false) &
                    v.natura.equals(natura),
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
    final addebiti = {
      for (final p
          in await (_db.select(_db.pianificazioni)..where(
                (p) =>
                    p.origine.equals(OriginePianificazione.costoVita) &
                    p.eliminato.equals(false),
              ))
              .get())
        p.origineId: p,
    };

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

    final prestiti =
        await (_db.select(_db.prestiti)..where(
              (p) => p.eliminato.equals(false) & p.archiviato.equals(false),
            ))
            .get();

    final oggi = _adesso();
    final risultato = <RiepilogoMese>[];
    for (final m in mesi) {
      final mese = DateTime(m.year, m.month);
      final riferimento = _giornoDiRiferimento(mese, oggi);
      final spese = await _realiPerCategoria(
        mese,
        entrate ? EffettoSaldo.entrata : EffettoSaldo.uscita,
      );
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
        final addebito = addebiti[voce.id];
        var dateAddebito = const <DateTime>[];
        int predefinito;
        if (addebito != null &&
            voce.ripartita &&
            Frequenza.daCodice(addebito.frequenza) != Frequenza.mensile) {
          // Suddivisa nei mesi: una quota ogni mese (anche prima del primo
          // addebito, come accantonamento) fino al mese dell'ultimo addebito.
          final regola = Pianificatore.ricorrenzaDi(addebito);
          final ultima = regola.ultima;
          if (ultima != null &&
              DateTime(ultima.year, ultima.month).isBefore(mese)) {
            continue;
          }
          dateAddebito = regola.nelMese(mese);
          predefinito = quotaMensile(
            _importoAl(storia, riferimento) ?? 0,
            regola.frequenza,
          );
        } else if (addebito != null) {
          final regola = Pianificatore.ricorrenzaDi(addebito);
          // Fuori dal periodo della voce (prima dell'inizio o dopo la fine): non conta.
          final ultima = regola.ultima;
          if (regola.inizio.isAfter(_ultimoGiorno(mese)) ||
              (ultima != null && ultima.isBefore(mese))) {
            continue;
          }
          dateAddebito = regola.nelMese(mese);
          predefinito = regola.frequenza == Frequenza.mensile
              ? _importoAl(storia, riferimento) ?? 0
              : dateAddebito
                    .map((d) => _importoAl(storia, d) ?? 0)
                    .fold(0, (a, b) => a + b);
        } else {
          predefinito = _importoAl(storia, riferimento) ?? 0;
        }
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
            addebito: addebito,
            dateAddebito: dateAddebito,
            importoUnitario: _importoAl(storia, riferimento) ?? 0,
          ),
        );
      }
      risultato.add(
        RiepilogoMese(
          mese,
          righe,
          rate: entrate ? const [] : _rateDelMese(prestiti, mese),
        ),
      );
    }
    return risultato;
  }

  // ------------------------------------------------------------- interni

  /// Rate dei prestiti che cadono nel mese, fino all'estinzione.
  static List<RataDelMese> _rateDelMese(
    List<Prestito> prestiti,
    DateTime mese,
  ) {
    final risultato = <RataDelMese>[];
    for (final p in prestiti) {
      final regola = Ricorrenza(
        inizio: Contabilita.daGiorno(p.primaRata),
        frequenza: Frequenza.daCodice(p.frequenza),
        occorrenze: p.numeroRate,
      );
      final date = regola.nelMese(mese);
      if (date.isEmpty) {
        continue;
      }
      final importo = date
          .map((d) => PrestitiServizio.importoRataAl(p, d))
          .fold<int>(0, (a, b) => a + b);
      if (importo <= 0) {
        continue; // es. maxi rata rifinanziata: dal conto non esce
      }
      risultato.add(
        RataDelMese(
          prestito: p,
          importo: importo,
          date: date,
          numero: regola.tra(regola.inizio, date.first).length,
        ),
      );
    }
    risultato.sort((a, b) => a.date.first.compareTo(b.date.first));
    return risultato;
  }

  Stream<void> _osserva() => _db
      .customSelect(
        'SELECT 1 AS osserva_costo_vita', // testo univoco: drift condivide le query uguali
        readsFrom: {
          _db.vociCosto,
          _db.importiVoce,
          _db.variazioniMese,
          _db.movimenti,
          _db.categorie,
          _db.pianificazioni,
          _db.prestiti,
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

  /// Uscite (o entrate, con [effetto]) del mese per categoria.
  Future<Map<String, int>> _realiPerCategoria(
    DateTime mese,
    String effetto,
  ) async {
    final righe = await _db
        .customSelect(
          '''
          SELECT m.categoria_id AS categoria, SUM(m.importo_minimo) AS totale
          FROM movimenti m JOIN definizioni_tipo t ON t.id = m.tipo_id
          WHERE m.eliminato = 0 AND t.effetto = ?
            AND m.categoria_id IS NOT NULL
            AND m.data BETWEEN ? AND ?
          GROUP BY m.categoria_id
          ''',
          variables: [
            Variable.withString(effetto),
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
