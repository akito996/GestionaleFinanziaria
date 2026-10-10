import 'package:drift/drift.dart';

import '../prestiti/ammortamento.dart';
import '../ricorrenza.dart';
import 'archivio.dart';
import 'contabilita.dart';
import 'id.dart';
import 'orologio.dart';
import 'pianificatore.dart';
import 'tabelle.dart';

/// Dati del modulo di un prestito.
class DatiPrestito {
  const DatiPrestito({
    required this.nome,
    required this.tipo,
    required this.capitale,
    required this.numeroRate,
    required this.importoRata,
    required this.primaRata,
    this.frequenza = Frequenza.mensile,
    this.finanziatore = '',
    this.tanPuntiBase,
    this.taegPuntiBase,
    this.portafoglioId,
    this.categoriaId,
    this.note = '',
  });

  final String nome;
  final String tipo;
  final int capitale;
  final int numeroRate;
  final int importoRata;
  final DateTime primaRata;
  final Frequenza frequenza;
  final String finanziatore;
  final int? tanPuntiBase;
  final int? taegPuntiBase;
  final String? portafoglioId;
  final String? categoriaId;
  final String note;
}

/// Una rata con la sua data e se è già stata pagata (registrata).
class RataDatata {
  const RataDatata(this.piano, this.data, {required this.pagata});

  final RataPiano piano;
  final DateTime data;
  final bool pagata;
}

class PrestitoConStato {
  const PrestitoConStato({
    required this.prestito,
    required this.rate,
    required this.ratePagate,
  });

  final Prestito prestito;
  final List<RataDatata> rate;
  final int ratePagate;

  int get rateRimanenti => prestito.numeroRate - ratePagate;

  RataDatata? get prossima => rate.where((r) => !r.pagata).firstOrNull;

  DateTime? get fine => rate.isEmpty ? null : rate.last.data;

  /// Debito residuo dopo l'ultima rata pagata (dal piano di ammortamento).
  int get debitoResiduo => ratePagate == 0
      ? prestito.capitaleMinimo
      : rate[ratePagate - 1].piano.debitoResiduo;

  /// Quanto resta da pagare in rate (capitale + interessi futuri).
  int get daPagare => rate
      .where((r) => !r.pagata)
      .fold(0, (totale, r) => totale + r.piano.rata);

  double get avanzamento =>
      prestito.numeroRate == 0 ? 0 : ratePagate / prestito.numeroRate;
}

/// Prestiti e rate: ogni rata è un pagamento programmato a importo fisso che si
/// registra da solo nel giorno previsto, nella categoria scelta.
class PrestitiServizio {
  PrestitiServizio(
    this._db,
    this._orologio,
    this._pianificatore, {
    DateTime Function()? adesso,
  }) : _adesso = adesso ?? DateTime.now;

  final Archivio _db;
  final OrologioLogico _orologio;
  final Pianificatore _pianificatore;
  final DateTime Function() _adesso;

  Future<String> crea(DatiPrestito d) async {
    final id = nuovoId();
    await _db
        .into(_db.prestiti)
        .insert(
          PrestitiCompanion.insert(
            id: id,
            aggiornatoIl: _orologio.adesso(),
            nome: d.nome.trim(),
            tipo: d.tipo,
            finanziatore: Value(d.finanziatore.trim()),
            capitaleMinimo: d.capitale,
            numeroRate: d.numeroRate,
            importoRataMinimo: d.importoRata,
            tanPuntiBase: Value(d.tanPuntiBase),
            taegPuntiBase: Value(d.taegPuntiBase),
            primaRata: Contabilita.giorno(d.primaRata),
            frequenza: Value(d.frequenza.codice),
            portafoglioId: Value(d.portafoglioId),
            categoriaId: Value(
              d.categoriaId ?? await categoriaPredefinita(d.tipo),
            ),
            note: Value(d.note),
          ),
        );
    await _aggiornaRate(id);
    return id;
  }

  Future<void> modifica(String id, DatiPrestito d) async {
    await (_db.update(_db.prestiti)..where((p) => p.id.equals(id))).write(
      PrestitiCompanion(
        aggiornatoIl: Value(_orologio.adesso()),
        nome: Value(d.nome.trim()),
        tipo: Value(d.tipo),
        finanziatore: Value(d.finanziatore.trim()),
        capitaleMinimo: Value(d.capitale),
        numeroRate: Value(d.numeroRate),
        importoRataMinimo: Value(d.importoRata),
        tanPuntiBase: Value(d.tanPuntiBase),
        taegPuntiBase: Value(d.taegPuntiBase),
        primaRata: Value(Contabilita.giorno(d.primaRata)),
        frequenza: Value(d.frequenza.codice),
        portafoglioId: Value(d.portafoglioId),
        categoriaId: Value(d.categoriaId),
        note: Value(d.note),
      ),
    );
    await _aggiornaRate(id);
  }

  /// Archivia (es. estinto in anticipo): le rate future non si registrano più.
  Future<void> archivia(String id, {bool archiviato = true}) async {
    await (_db.update(_db.prestiti)..where((p) => p.id.equals(id))).write(
      PrestitiCompanion(
        aggiornatoIl: Value(_orologio.adesso()),
        archiviato: Value(archiviato),
      ),
    );
    await (_db.update(_db.pianificazioni)..where(
          (p) =>
              p.origine.equals(OriginePianificazione.prestito) &
              p.origineId.equals(id),
        ))
        .write(
          PianificazioniCompanion(
            aggiornatoIl: Value(_orologio.adesso()),
            attiva: Value(!archiviato),
          ),
        );
  }

  Stream<List<PrestitoConStato>> osserva() => _db
      .customSelect(
        'SELECT 1 AS osserva_prestiti', // testo univoco: drift condivide le query uguali
        readsFrom: {_db.prestiti, _db.movimenti, _db.pianificazioni},
      )
      .watch()
      .asyncMap((_) => stati());

  Future<List<PrestitoConStato>> stati() async {
    final prestiti =
        await (_db.select(_db.prestiti)
              ..where(
                (p) => p.eliminato.equals(false) & p.archiviato.equals(false),
              )
              ..orderBy([(p) => OrderingTerm(expression: p.primaRata)]))
            .get();
    final risultato = <PrestitoConStato>[];
    for (final p in prestiti) {
      risultato.add(await stato(p));
    }
    return risultato;
  }

  Future<PrestitoConStato> stato(Prestito p) async {
    final frequenza = Frequenza.daCodice(p.frequenza);
    final piano = Ammortamento.piano(
      capitale: p.capitaleMinimo,
      numeroRate: p.numeroRate,
      tanPuntiBase:
          p.tanPuntiBase ??
          Ammortamento.tanDaRata(
            capitale: p.capitaleMinimo,
            numeroRate: p.numeroRate,
            rata: p.importoRataMinimo,
            rateAllAnno: _rateAllAnno(frequenza),
          ) ??
          0,
      rataFissa: p.importoRataMinimo,
      rateAllAnno: _rateAllAnno(frequenza),
    );
    final date = Ricorrenza(
      inizio: Contabilita.daGiorno(p.primaRata),
      frequenza: frequenza,
      occorrenze: p.numeroRate,
    ).tra(Contabilita.daGiorno(p.primaRata), DateTime(9999));
    final pagate = await _dateRegistrate(p.id);
    final oggi = _oggi();
    final rate = <RataDatata>[];
    for (var i = 0; i < piano.length && i < date.length; i++) {
      final data = date[i];
      // Senza conto le rate non si registrano: si considerano pagate alla scadenza.
      final pagata = p.portafoglioId == null
          ? !data.isAfter(oggi)
          : pagate.contains(Contabilita.giorno(data));
      rate.add(RataDatata(piano[i], data, pagata: pagata));
    }
    return PrestitoConStato(
      prestito: p,
      rate: rate,
      ratePagate: rate.where((r) => r.pagata).length,
    );
  }

  /// Sottocategoria di "Finanziamenti" adatta al tipo di prestito.
  Future<String?> categoriaPredefinita(String tipo) async {
    final nome = switch (tipo) {
      TipoPrestito.mutuo => 'Mutuo',
      TipoPrestito.rate => 'Pagamenti a rate',
      _ => 'Prestiti',
    };
    final padre =
        await (_db.select(_db.categorie)..where(
              (c) => c.nome.equals(categoriaFinanziamenti) & c.padreId.isNull(),
            ))
            .getSingleOrNull();
    if (padre == null) {
      return null;
    }
    final figlia =
        await (_db.select(_db.categorie)
              ..where((c) => c.nome.equals(nome) & c.padreId.equals(padre.id)))
            .getSingleOrNull();
    return (figlia ?? padre).id;
  }

  // ------------------------------------------------------------- interni

  DateTime _oggi() {
    final a = _adesso();
    return DateTime(a.year, a.month, a.day);
  }

  static int _rateAllAnno(Frequenza f) => switch (f) {
    Frequenza.settimanale => 52,
    _ => 12 ~/ f.mesi,
  };

  Future<Set<String>> _dateRegistrate(String prestitoId) async {
    final p = await _pianificatore.perOrigine(
      OriginePianificazione.prestito,
      prestitoId,
    );
    if (p == null) {
      return {};
    }
    final righe =
        await (_db.selectOnly(_db.movimenti)
              ..addColumns([_db.movimenti.dataPrevista])
              ..where(
                _db.movimenti.pianificazioneId.equals(p.id) &
                    _db.movimenti.eliminato.equals(false),
              ))
            .get();
    return {
      for (final r in righe)
        if (r.read(_db.movimenti.dataPrevista) case final String d) d,
    };
  }

  Future<void> _aggiornaRate(String id) async {
    final p = await (_db.select(
      _db.prestiti,
    )..where((x) => x.id.equals(id))).getSingle();
    await _pianificatore.salva(
      DatiPianificazione(
        origine: OriginePianificazione.prestito,
        origineId: id,
        ricorrenza: Ricorrenza(
          inizio: Contabilita.daGiorno(p.primaRata),
          frequenza: Frequenza.daCodice(p.frequenza),
          occorrenze: p.numeroRate,
        ),
        portafoglioId: p.portafoglioId,
        categoriaId: p.categoriaId,
        descrizione: 'Rata ${p.nome}',
        importo: p.importoRataMinimo,
        valuta: p.valuta,
      ),
    );
  }
}
