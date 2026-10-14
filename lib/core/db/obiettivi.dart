import 'package:drift/drift.dart';

import '../importo.dart';
import 'archivio.dart';
import 'contabilita.dart';
import 'id.dart';
import 'orologio.dart';
import 'osservazione.dart';
import 'tabelle.dart';

/// Situazione di un partecipante di una colletta.
class QuotaPartecipante {
  const QuotaPartecipante(this.partecipante, this.quota, this.versato);

  final Partecipante partecipante;

  /// Quanto deve versare (quota personalizzata o parte uguale).
  final int quota;
  final int versato;

  int get mancante => quota - versato > 0 ? quota - versato : 0;

  bool get inRegola => versato >= quota;
}

class ObiettivoConStato {
  const ObiettivoConStato({
    required this.obiettivo,
    required this.versato,
    required this.versamenti,
    required this.quote,
    required this.oggi,
  });

  final Obiettivo obiettivo;
  final int versato;
  final List<Versamento> versamenti;
  final List<QuotaPartecipante> quote;
  final DateTime oggi;

  bool get colletta => obiettivo.tipo == TipoObiettivo.colletta;

  int get mancante {
    final m = obiettivo.importoObiettivoMinimo - versato;
    return m > 0 ? m : 0;
  }

  double get avanzamento => obiettivo.importoObiettivoMinimo <= 0
      ? 1
      : (versato / obiettivo.importoObiettivoMinimo).clamp(0.0, 1.0);

  bool get raggiunto => versato >= obiettivo.importoObiettivoMinimo;

  /// Soldi del portafoglio dell'obiettivo ([Obiettivi.portafoglioId]) messi
  /// da parte: finché l'obiettivo non è raggiunto si considera suo tutto il
  /// versato; dopo, l'importo dell'obiettivo (il di più è libero).
  int get riservato {
    if (obiettivo.portafoglioId == null || versato <= 0) {
      return 0;
    }
    return raggiunto ? obiettivo.importoObiettivoMinimo : versato;
  }

  DateTime? get scadenza => obiettivo.scadenza == null
      ? null
      : Contabilita.daGiorno(obiettivo.scadenza!);

  /// Mesi interi rimasti fino alla scadenza (almeno 1 se non è passata).
  int? get mesiRimasti {
    final s = scadenza;
    if (s == null || s.isBefore(oggi)) {
      return null;
    }
    final mesi = (s.year - oggi.year) * 12 + s.month - oggi.month;
    return mesi < 1 ? 1 : mesi;
  }

  /// Quanto mettere da parte ogni mese per arrivare in tempo.
  int? get alMese {
    final mesi = mesiRimasti;
    return mesi == null || raggiunto ? null : (mancante / mesi).ceil();
  }

  /// Testo da copiare e condividere (es. nella chat del gruppo).
  String riepilogo() {
    final o = obiettivo;
    String euro(int v) => Importo.formatta(v, o.valuta);
    final righe = <String>[
      '${o.nome}: ${euro(versato)} di ${euro(o.importoObiettivoMinimo)}',
      if (colletta)
        for (final q in quote)
          '${q.inRegola ? '✅' : '⏳'} ${q.partecipante.nome}: '
              '${euro(q.versato)} / ${euro(q.quota)}'
              '${q.inRegola ? '' : ' (mancano ${euro(q.mancante)})'}',
      if (!raggiunto) 'Mancano ${euro(mancante)}',
    ];
    return righe.join('\n');
  }
}

/// Obiettivi di risparmio personali e collette con partecipanti e quote.
class ObiettiviServizio {
  ObiettiviServizio(this._db, this._orologio, {DateTime Function()? adesso})
    : _adesso = adesso ?? DateTime.now;

  final Archivio _db;
  final OrologioLogico _orologio;
  final DateTime Function() _adesso;

  Future<String> crea({
    required String nome,
    required String tipo,
    required int importoObiettivo,
    DateTime? scadenza,
    String? portafoglioId,
    List<({String nome, int? quota})> partecipanti = const [],
  }) async {
    final id = nuovoId();
    await _db.transaction(() async {
      await _db
          .into(_db.obiettivi)
          .insert(
            ObiettiviCompanion.insert(
              id: id,
              aggiornatoIl: _orologio.adesso(),
              nome: nome.trim(),
              tipo: tipo,
              importoObiettivoMinimo: importoObiettivo,
              scadenza: Value(
                scadenza == null ? null : Contabilita.giorno(scadenza),
              ),
              portafoglioId: Value(portafoglioId),
            ),
          );
      for (final p in partecipanti) {
        await aggiungiPartecipante(id, p.nome, quota: p.quota);
      }
    });
    return id;
  }

  Future<void> modifica(
    String id, {
    required String nome,
    required int importoObiettivo,
    DateTime? scadenza,
    String? portafoglioId,
  }) => (_db.update(_db.obiettivi)..where((o) => o.id.equals(id))).write(
    ObiettiviCompanion(
      aggiornatoIl: Value(_orologio.adesso()),
      nome: Value(nome.trim()),
      importoObiettivoMinimo: Value(importoObiettivo),
      scadenza: Value(scadenza == null ? null : Contabilita.giorno(scadenza)),
      portafoglioId: Value(portafoglioId),
    ),
  );

  Future<void> archivia(String id, {bool archiviato = true}) =>
      (_db.update(_db.obiettivi)..where((o) => o.id.equals(id))).write(
        ObiettiviCompanion(
          aggiornatoIl: Value(_orologio.adesso()),
          archiviato: Value(archiviato),
        ),
      );

  Future<String> aggiungiPartecipante(
    String obiettivoId,
    String nome, {
    int? quota,
  }) async {
    final id = nuovoId();
    await _db
        .into(_db.partecipanti)
        .insert(
          PartecipantiCompanion.insert(
            id: id,
            aggiornatoIl: _orologio.adesso(),
            obiettivoId: obiettivoId,
            nome: nome.trim(),
            quotaMinimo: Value(quota),
          ),
        );
    return id;
  }

  Future<void> modificaPartecipante(String id, String nome, {int? quota}) =>
      (_db.update(_db.partecipanti)..where((p) => p.id.equals(id))).write(
        PartecipantiCompanion(
          aggiornatoIl: Value(_orologio.adesso()),
          nome: Value(nome.trim()),
          quotaMinimo: Value(quota),
        ),
      );

  Future<void> rimuoviPartecipante(String id) =>
      (_db.update(_db.partecipanti)..where((p) => p.id.equals(id))).write(
        PartecipantiCompanion(
          aggiornatoIl: Value(_orologio.adesso()),
          eliminato: const Value(true),
        ),
      );

  /// Nuovo versamento. Con [portafoglioDaId] viene registrato anche il movimento:
  /// per un obiettivo personale con portafoglio è un trasferimento verso il
  /// portafoglio dell'obiettivo, altrimenti un'entrata (colletta) nel portafoglio.
  Future<String> versa(
    String obiettivoId, {
    required int importo,
    String? partecipanteId,
    DateTime? data,
    String nota = '',
    String? portafoglioDaId,
  }) async {
    if (importo <= 0) {
      throw ArgumentError.value(
        importo,
        'importo',
        'deve essere maggiore di 0',
      );
    }
    final giorno = data ?? _adesso();
    final obiettivo = await (_db.select(
      _db.obiettivi,
    )..where((o) => o.id.equals(obiettivoId))).getSingle();
    final id = nuovoId();
    await _db.transaction(() async {
      String? movimentoId;
      if (portafoglioDaId != null) {
        movimentoId = await _movimentoPer(
          obiettivo,
          portafoglioDaId,
          importo,
          giorno,
        );
      }
      await _db
          .into(_db.versamenti)
          .insert(
            VersamentiCompanion.insert(
              id: id,
              aggiornatoIl: _orologio.adesso(),
              obiettivoId: obiettivoId,
              partecipanteId: Value(partecipanteId),
              importoMinimo: importo,
              data: Contabilita.giorno(giorno),
              nota: Value(nota.trim()),
              movimentoId: Value(movimentoId),
            ),
          );
    });
    return id;
  }

  /// Toglie il versamento (e il movimento collegato, se c'è). Reversibile.
  Future<void> annullaVersamento(String id, {bool annullato = true}) async {
    final v = await (_db.select(
      _db.versamenti,
    )..where((x) => x.id.equals(id))).getSingle();
    await (_db.update(_db.versamenti)..where((x) => x.id.equals(id))).write(
      VersamentiCompanion(
        aggiornatoIl: Value(_orologio.adesso()),
        eliminato: Value(annullato),
      ),
    );
    if (v.movimentoId != null) {
      await (_db.update(
        _db.movimenti,
      )..where((m) => m.id.equals(v.movimentoId!))).write(
        MovimentiCompanion(
          aggiornatoIl: Value(_orologio.adesso()),
          eliminato: Value(annullato),
        ),
      );
    }
  }

  Stream<List<ObiettivoConStato>> osserva() => _db
      .customSelect(
        'SELECT 1 AS osserva_obiettivi', // testo univoco: drift condivide le query uguali
        readsFrom: {_db.obiettivi, _db.partecipanti, _db.versamenti},
      )
      .watch()
      .ricalcola((_) => stati());

  Future<List<ObiettivoConStato>> stati() async {
    final obiettivi =
        await (_db.select(_db.obiettivi)
              ..where(
                (o) => o.eliminato.equals(false) & o.archiviato.equals(false),
              )
              ..orderBy([(o) => OrderingTerm(expression: o.nome)]))
            .get();
    final partecipanti = await (_db.select(
      _db.partecipanti,
    )..where((p) => p.eliminato.equals(false))).get();
    final versamenti =
        await (_db.select(_db.versamenti)
              ..where((v) => v.eliminato.equals(false))
              ..orderBy([(v) => OrderingTerm.desc(v.data)]))
            .get();
    final a = _adesso();
    final oggi = DateTime(a.year, a.month, a.day);
    return [
      for (final o in obiettivi)
        _stato(
          o,
          partecipanti.where((p) => p.obiettivoId == o.id).toList(),
          versamenti.where((v) => v.obiettivoId == o.id).toList(),
          oggi,
        ),
    ];
  }

  static ObiettivoConStato _stato(
    Obiettivo o,
    List<Partecipante> partecipanti,
    List<Versamento> versamenti,
    DateTime oggi,
  ) {
    final versato = versamenti.fold<int>(0, (t, v) => t + v.importoMinimo);
    // Quote: personalizzate dove indicate, il resto diviso in parti uguali.
    final fisse = partecipanti
        .where((p) => p.quotaMinimo != null)
        .fold<int>(0, (t, p) => t + p.quotaMinimo!);
    final liberi = partecipanti.where((p) => p.quotaMinimo == null).length;
    final restante = o.importoObiettivoMinimo - fisse;
    final parteUguale = liberi == 0 || restante <= 0
        ? 0
        : (restante / liberi).ceil();
    final quote = [
      for (final p in partecipanti)
        QuotaPartecipante(
          p,
          p.quotaMinimo ?? parteUguale,
          versamenti
              .where((v) => v.partecipanteId == p.id)
              .fold(0, (t, v) => t + v.importoMinimo),
        ),
    ];
    return ObiettivoConStato(
      obiettivo: o,
      versato: versato,
      versamenti: versamenti,
      quote: quote,
      oggi: oggi,
    );
  }

  Future<String> _movimentoPer(
    Obiettivo o,
    String portafoglioDaId,
    int importo,
    DateTime data,
  ) async {
    final personaleConSalvadanaio =
        o.tipo == TipoObiettivo.personale &&
        o.portafoglioId != null &&
        o.portafoglioId != portafoglioDaId;
    final effetto = personaleConSalvadanaio
        ? EffettoSaldo.trasferimento
        : EffettoSaldo.entrata;
    final tipo =
        await (_db.select(_db.definizioniTipo)..where(
              (t) =>
                  t.ambito.equals(AmbitoTipo.movimento) &
                  t.effetto.equals(effetto) &
                  t.diSistema.equals(true),
            ))
            .getSingle();
    final portafoglio = await (_db.select(
      _db.portafogli,
    )..where((p) => p.id.equals(portafoglioDaId))).getSingle();
    final id = nuovoId();
    await _db
        .into(_db.movimenti)
        .insert(
          MovimentiCompanion.insert(
            id: id,
            aggiornatoIl: _orologio.adesso(),
            tipoId: tipo.id,
            portafoglioId: portafoglioDaId,
            portafoglioDestinazioneId: Value(
              personaleConSalvadanaio ? o.portafoglioId : null,
            ),
            importoMinimo: importo,
            valuta: portafoglio.valuta,
            data: Contabilita.giorno(data),
            descrizione: Value(o.nome),
          ),
        );
    return id;
  }
}
