import 'package:drift/drift.dart';

import '../ricorrenza.dart';
import 'archivio.dart';
import 'contabilita.dart';
import 'id.dart';
import 'orologio.dart';
import 'tabelle.dart';

/// Calcola l'importo di una scadenza quando non è fisso (es. il costo della vita
/// usa l'importo del mese, la carta il saldo da addebitare). `null` = salta.
typedef CalcoloImporto = Future<int?> Function(
  Pianificazione pianificazione,
  DateTime data,
);

/// Dati per creare o aggiornare un pagamento programmato.
class DatiPianificazione {
  const DatiPianificazione({
    required this.origine,
    this.origineId,
    required this.ricorrenza,
    this.portafoglioId,
    this.destinazioneId,
    this.tipoId,
    this.categoriaId,
    this.descrizione = '',
    this.importo,
    this.valuta = 'EUR',
    this.avvisoGiorni = 3,
  });

  final String origine;
  final String? origineId;
  final Ricorrenza ricorrenza;
  final String? portafoglioId;
  final String? destinazioneId;
  final String? tipoId;
  final String? categoriaId;
  final String descrizione;
  final int? importo;
  final String valuta;
  final int avvisoGiorni;
}

/// Una scadenza futura non ancora registrata.
class ScadenzaInArrivo {
  const ScadenzaInArrivo({
    required this.pianificazione,
    required this.data,
    required this.importo,
    required this.giorniMancanti,
  });

  final Pianificazione pianificazione;
  final DateTime data;
  final int importo;
  final int giorniMancanti;

  /// Dentro la finestra di avviso (di solito 3 giorni).
  bool get daAvvisare => giorniMancanti <= pianificazione.avvisoGiorni;
}

/// Pagamenti programmati: nel giorno previsto diventano movimenti (anche se l'app
/// viene aperta dopo: si recuperano tutti quelli mancanti). Un movimento generato
/// cancellato dall'utente non viene ricreato.
class Pianificatore {
  Pianificatore(this._db, this._orologio, {DateTime Function()? adesso})
    : _adesso = adesso ?? DateTime.now;

  final Archivio _db;
  final OrologioLogico _orologio;
  final DateTime Function() _adesso;
  final Map<String, CalcoloImporto> _calcoli = {};

  /// Ogni origine (costo della vita, carta, prestito) registra il proprio calcolo.
  void registraCalcolo(String origine, CalcoloImporto calcolo) =>
      _calcoli[origine] = calcolo;

  static Ricorrenza ricorrenzaDi(Pianificazione p) => Ricorrenza(
    inizio: Contabilita.daGiorno(p.inizio),
    frequenza: Frequenza.daCodice(p.frequenza),
    fine: p.fine == null ? null : Contabilita.daGiorno(p.fine!),
    occorrenze: p.occorrenze,
  );

  Future<Pianificazione?> perOrigine(String origine, String origineId) =>
      (_db.select(_db.pianificazioni)..where(
            (p) =>
                p.origine.equals(origine) &
                p.origineId.equals(origineId) &
                p.eliminato.equals(false),
          ))
          .getSingleOrNull();

  Future<List<Pianificazione>> attive() => (_db.select(
    _db.pianificazioni,
  )..where((p) => p.eliminato.equals(false) & p.attiva.equals(true))).get();

  /// Crea o aggiorna (per origine + id) il pagamento programmato.
  Future<String> salva(DatiPianificazione d) async {
    final esistente = d.origineId == null
        ? null
        : await perOrigine(d.origine, d.origineId!);
    final r = d.ricorrenza;
    final valori = PianificazioniCompanion(
      aggiornatoIl: Value(_orologio.adesso()),
      origine: Value(d.origine),
      origineId: Value(d.origineId),
      portafoglioId: Value(d.portafoglioId),
      destinazioneId: Value(d.destinazioneId),
      tipoId: Value(d.tipoId),
      categoriaId: Value(d.categoriaId),
      descrizione: Value(d.descrizione),
      importoMinimo: Value(d.importo),
      valuta: Value(d.valuta),
      inizio: Value(Contabilita.giorno(r.inizio)),
      frequenza: Value(r.frequenza.codice),
      fine: Value(r.fine == null ? null : Contabilita.giorno(r.fine!)),
      occorrenze: Value(r.occorrenze),
      avvisoGiorni: Value(d.avvisoGiorni),
      attiva: const Value(true),
      eliminato: const Value(false),
    );
    if (esistente != null) {
      await (_db.update(
        _db.pianificazioni,
      )..where((p) => p.id.equals(esistente.id))).write(valori);
      return esistente.id;
    }
    final id = nuovoId();
    await _db.into(_db.pianificazioni).insert(valori.copyWith(id: Value(id)));
    return id;
  }

  /// Toglie il pagamento programmato (i movimenti già registrati restano).
  Future<void> rimuovi(String origine, String origineId) =>
      (_db.update(_db.pianificazioni)..where(
            (p) => p.origine.equals(origine) & p.origineId.equals(origineId),
          ))
          .write(
            PianificazioniCompanion(
              aggiornatoIl: Value(_orologio.adesso()),
              eliminato: const Value(true),
            ),
          );

  /// Registra tutte le scadenze arrivate (fino a oggi compreso) e non ancora
  /// registrate. Restituisce quanti movimenti ha creato.
  Future<int> registraScadute() async {
    final oggi = _oggi();
    var creati = 0;
    for (final p in await attive()) {
      if (p.portafoglioId == null) {
        continue; // solo promemoria
      }
      final date = ricorrenzaDi(p).tra(Contabilita.daGiorno(p.inizio), oggi);
      if (date.isEmpty) {
        continue;
      }
      final giaFatte = await _dateRegistrate(p.id);
      for (final data in date) {
        if (giaFatte.contains(Contabilita.giorno(data))) {
          continue;
        }
        final importo = await _importo(p, data);
        if (importo == null || importo <= 0) {
          continue;
        }
        await _creaMovimento(p, data, importo);
        creati++;
      }
    }
    return creati;
  }

  /// Scadenze dei prossimi [giorni] giorni (oggi compreso) non ancora registrate.
  Future<List<ScadenzaInArrivo>> inArrivo({
    int giorni = 30,
    String? portafoglioId,
  }) async {
    final oggi = _oggi();
    final limite = DateTime(oggi.year, oggi.month, oggi.day + giorni);
    final risultato = <ScadenzaInArrivo>[];
    for (final p in await attive()) {
      if (portafoglioId != null &&
          p.portafoglioId != portafoglioId &&
          p.destinazioneId != portafoglioId) {
        continue;
      }
      final giaFatte = await _dateRegistrate(p.id);
      for (final data in ricorrenzaDi(p).tra(oggi, limite)) {
        if (giaFatte.contains(Contabilita.giorno(data))) {
          continue;
        }
        final importo = await _importo(p, data);
        if (importo == null || importo <= 0) {
          continue;
        }
        risultato.add(
          ScadenzaInArrivo(
            pianificazione: p,
            data: data,
            importo: importo,
            giorniMancanti: data.difference(oggi).inDays,
          ),
        );
      }
    }
    risultato.sort((a, b) => a.data.compareTo(b.data));
    return risultato;
  }

  /// Come [inArrivo], aggiornato quando cambiano scadenze o movimenti.
  Stream<List<ScadenzaInArrivo>> osservaInArrivo({
    int giorni = 30,
    String? portafoglioId,
  }) => _db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          _db.pianificazioni,
          _db.movimenti,
          _db.vociCosto,
          _db.importiVoce,
          _db.variazioniMese,
        },
      )
      .watch()
      .asyncMap((_) => inArrivo(giorni: giorni, portafoglioId: portafoglioId));

  // ------------------------------------------------------------- interni

  DateTime _oggi() {
    final a = _adesso();
    return DateTime(a.year, a.month, a.day);
  }

  Future<Set<String>> _dateRegistrate(String pianificazioneId) async {
    // Anche i movimenti eliminati contano: l'utente li ha tolti apposta.
    final righe =
        await (_db.selectOnly(_db.movimenti)
              ..addColumns([_db.movimenti.dataPrevista])
              ..where(_db.movimenti.pianificazioneId.equals(pianificazioneId)))
            .get();
    return {
      for (final r in righe)
        if (r.read(_db.movimenti.dataPrevista) case final String d) d,
    };
  }

  Future<int?> _importo(Pianificazione p, DateTime data) async {
    if (p.importoMinimo != null) {
      return p.importoMinimo;
    }
    final calcolo = _calcoli[p.origine];
    return calcolo == null ? null : calcolo(p, data);
  }

  Future<void> _creaMovimento(
    Pianificazione p,
    DateTime data,
    int importo,
  ) async {
    final tipoId = p.tipoId ?? await _tipoSpesa();
    await _db
        .into(_db.movimenti)
        .insert(
          MovimentiCompanion.insert(
            id: nuovoId(),
            aggiornatoIl: _orologio.adesso(),
            tipoId: tipoId,
            portafoglioId: p.portafoglioId!,
            portafoglioDestinazioneId: Value(p.destinazioneId),
            categoriaId: Value(p.categoriaId),
            importoMinimo: importo,
            valuta: p.valuta,
            data: Contabilita.giorno(data),
            descrizione: Value(p.descrizione),
            pianificazioneId: Value(p.id),
            dataPrevista: Value(Contabilita.giorno(data)),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<String> _tipoSpesa() async =>
      (await (_db.select(_db.definizioniTipo)..where(
                (t) =>
                    t.ambito.equals(AmbitoTipo.movimento) &
                    t.effetto.equals(EffettoSaldo.uscita) &
                    t.diSistema.equals(true),
              ))
              .get())
          .first
          .id;
}
