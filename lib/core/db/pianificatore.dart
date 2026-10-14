import 'package:drift/drift.dart';

import '../ricorrenza.dart';
import 'archivio.dart';
import 'contabilita.dart';
import 'id.dart';
import 'orologio.dart';
import 'osservazione.dart';
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
    this.richiedeConferma = false,
    this.registraDal,
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

  /// Vedi [Pianificazioni.richiedeConferma].
  final bool richiedeConferma;

  /// "Conta dal" ([Pianificazioni.registraDal]). `null` = alla creazione
  /// oggi (conta solo da quando la inserisci), alla modifica resta com'è.
  final DateTime? registraDal;
}

/// Una scadenza futura non ancora registrata.
class ScadenzaInArrivo {
  ScadenzaInArrivo({
    required this.pianificazione,
    required this.data,
    DateTime? dataPrevista,
    required this.importo,
    required this.giorniMancanti,
  }) : dataPrevista = dataPrevista ?? data;

  final Pianificazione pianificazione;

  /// Il giorno in cui avviene (quello scelto dall'utente, se l'ha spostata).
  final DateTime data;

  /// Il giorno della regola.
  final DateTime dataPrevista;
  final int importo;
  final int giorniMancanti;

  /// Dentro la finestra di avviso (di solito 3 giorni).
  bool get daAvvisare => giorniMancanti <= pianificazione.avvisoGiorni;
}

/// Una scadenza con tutto quello che serve per le notifiche: importo, scelta
/// dell'utente e movimento registrato (anche se eliminato).
class SituazioneScadenza {
  const SituazioneScadenza({
    required this.pianificazione,
    required this.dataPrevista,
    required this.data,
    required this.importo,
    this.movimento,
    this.scelta,
  });

  final Pianificazione pianificazione;
  final DateTime dataPrevista;
  final DateTime data;

  /// `null` = importo non disponibile (es. voce variabile senza stima).
  final int? importo;
  final Movimento? movimento;
  final Occorrenza? scelta;
}

/// Pagamenti programmati: nel giorno previsto diventano movimenti (anche se l'app
/// viene aperta dopo: si recuperano tutti quelli mancanti). Un movimento generato
/// cancellato dall'utente non viene ricreato.
///
/// Con [Pianificazioni.richiedeConferma] la scadenza non si registra da sola:
/// l'utente la conferma, la sposta o la annulla (vedi le notifiche).
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
      richiedeConferma: Value(d.richiedeConferma),
      registraDal: d.registraDal == null
          ? const Value.absent()
          : Value(Contabilita.giorno(d.registraDal!)),
    );
    if (esistente != null) {
      await (_db.update(
        _db.pianificazioni,
      )..where((p) => p.id.equals(esistente.id))).write(valori);
      return esistente.id;
    }
    final id = nuovoId();
    await _db
        .into(_db.pianificazioni)
        .insert(
          valori.copyWith(
            id: Value(id),
            // Già in corso quando la inserisci: conta solo da oggi.
            registraDal: Value(Contabilita.giorno(d.registraDal ?? _oggi())),
          ),
        );
    return id;
  }

  /// "Conta dal" su una scadenza già esistente: le scadenze prima di [dal] non
  /// si registrano più e i movimenti già registrati per quelle scadenze si
  /// eliminano. Restituisce gli id eliminati (per "Annulla" con
  /// [ripristinaMovimenti]).
  Future<List<String>> contaDal(String pianificazioneId, DateTime dal) async {
    final giorno = Contabilita.giorno(dal);
    return _db.transaction(() async {
      await (_db.update(
        _db.pianificazioni,
      )..where((p) => p.id.equals(pianificazioneId))).write(
        PianificazioniCompanion(
          aggiornatoIl: Value(_orologio.adesso()),
          registraDal: Value(giorno),
        ),
      );
      final prima =
          await (_db.select(_db.movimenti)..where(
                (m) =>
                    m.pianificazioneId.equals(pianificazioneId) &
                    m.dataPrevista.isSmallerThanValue(giorno) &
                    m.eliminato.equals(false),
              ))
              .get();
      final ids = [for (final m in prima) m.id];
      await _segnaEliminati(ids, true);
      return ids;
    });
  }

  /// Rimette i movimenti tolti da [contaDal].
  Future<void> ripristinaMovimenti(List<String> ids) =>
      _segnaEliminati(ids, false);

  Future<void> _segnaEliminati(List<String> ids, bool eliminato) async {
    if (ids.isEmpty) {
      return;
    }
    await (_db.update(_db.movimenti)..where((m) => m.id.isIn(ids))).write(
      MovimentiCompanion(
        aggiornatoIl: Value(_orologio.adesso()),
        eliminato: Value(eliminato),
      ),
    );
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
  /// registrate, tranne quelle che chiedono conferma. Restituisce quanti
  /// movimenti ha creato.
  Future<int> registraScadute() async {
    final oggi = _oggi();
    var creati = 0;
    for (final p in await attive()) {
      if (p.portafoglioId == null || p.richiedeConferma) {
        continue; // promemoria, o decide l'utente
      }
      final scelte = await _scelte(p.id);
      final date = _scadenzeTra(
        p,
        Contabilita.daGiorno(p.inizio),
        oggi,
        scelte,
      );
      if (date.isEmpty) {
        continue;
      }
      final giaFatte = await _dateRegistrate(p.id);
      for (final (prevista, data, _) in date) {
        if (giaFatte.contains(Contabilita.giorno(prevista))) {
          continue;
        }
        final importo = await _importo(p, prevista);
        if (importo == null || importo <= 0) {
          continue;
        }
        await _creaMovimento(p, prevista, data, importo);
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
      final scelte = await _scelte(p.id);
      for (final (prevista, data, _) in _scadenzeTra(p, oggi, limite, scelte)) {
        if (giaFatte.contains(Contabilita.giorno(prevista))) {
          continue;
        }
        final importo = await _importo(p, prevista);
        if (importo == null || importo <= 0) {
          continue;
        }
        risultato.add(
          ScadenzaInArrivo(
            pianificazione: p,
            data: data,
            dataPrevista: prevista,
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
        'SELECT 1 AS osserva_pianificatore', // testo univoco: drift condivide le query uguali
        readsFrom: tabelleOsservate,
      )
      .watch()
      .ricalcola((_) => inArrivo(giorni: giorni, portafoglioId: portafoglioId));

  /// Tabelle da cui dipendono scadenze e importi (per chi le osserva).
  Set<ResultSetImplementation<dynamic, dynamic>> get tabelleOsservate => {
    _db.pianificazioni,
    _db.occorrenze,
    _db.movimenti,
    _db.vociCosto,
    _db.importiVoce,
    _db.variazioniMese,
  };

  /// Tutte le scadenze con il giorno (vero) tra [da] e [a], registrate o no,
  /// con la scelta dell'utente. Le annullate e le fatte non ci sono.
  Future<List<SituazioneScadenza>> situazione(DateTime da, DateTime a) async {
    final risultato = <SituazioneScadenza>[];
    for (final p in await attive()) {
      final scelte = await _scelte(p.id);
      final date = _scadenzeTra(p, da, a, scelte);
      if (date.isEmpty) {
        continue;
      }
      final movimenti = {
        for (final m in await (_db.select(
          _db.movimenti,
        )..where((m) => m.pianificazioneId.equals(p.id))).get())
          if (m.dataPrevista case final String d) d: m,
      };
      for (final (prevista, data, scelta) in date) {
        final chiave = Contabilita.giorno(prevista);
        risultato.add(
          SituazioneScadenza(
            pianificazione: p,
            dataPrevista: prevista,
            data: data,
            importo: await _importo(p, prevista),
            movimento: movimenti[chiave],
            scelta: scelta,
          ),
        );
      }
    }
    risultato.sort((a, b) => a.data.compareTo(b.data));
    return risultato;
  }

  // ------------------------------------------------- scelte dell'utente

  /// Conferma la scadenza: registra il movimento (nel giorno previsto, o oggi
  /// se è in anticipo) e ne restituisce l'id. Un promemoria senza portafoglio
  /// viene segnato come fatto (`null`).
  Future<String?> conferma(Pianificazione p, DateTime dataPrevista) async {
    if (p.portafoglioId == null) {
      await scegli(p.id, dataPrevista, stato: StatoOccorrenza.fatta);
      return null;
    }
    final importo = await _importo(p, dataPrevista);
    if (importo == null || importo <= 0) {
      return null;
    }
    final scelta = await _scelta(p.id, dataPrevista);
    final oggi = _oggi();
    final data = _dataEffettiva(dataPrevista, scelta) ?? dataPrevista;
    return _creaMovimento(
      p,
      dataPrevista,
      data.isAfter(oggi) ? oggi : data,
      importo,
    );
  }

  /// Annulla una conferma: il movimento sparisce e la scadenza torna in
  /// attesa (si stacca dalla scadenza, così non conta come registrata).
  Future<void> annullaConferma(String movimentoId) =>
      (_db.update(_db.movimenti)..where((m) => m.id.equals(movimentoId))).write(
        MovimentiCompanion(
          aggiornatoIl: Value(_orologio.adesso()),
          eliminato: const Value(true),
          pianificazioneId: const Value(null),
          dataPrevista: const Value(null),
        ),
      );

  /// La scelta dell'utente su una scadenza (`null` = nessuna).
  Future<Occorrenza?> scelta(String pianificazioneId, DateTime dataPrevista) =>
      _scelta(pianificazioneId, dataPrevista);

  /// Sposta, annulla o segna come fatta una scadenza ([stato] `null` = torna
  /// com'era). Spostarla nel suo giorno equivale a nessuna scelta.
  Future<void> scegli(
    String pianificazioneId,
    DateTime dataPrevista, {
    String? stato,
    DateTime? nuovaData,
  }) {
    final prevista = Contabilita.giorno(dataPrevista);
    final nuova = nuovaData == null ? null : Contabilita.giorno(nuovaData);
    final senzaScelta =
        stato == null ||
        (stato == StatoOccorrenza.spostata && nuova == prevista);
    return _db
        .into(_db.occorrenze)
        .insertOnConflictUpdate(
          OccorrenzeCompanion.insert(
            id: '$pianificazioneId:$prevista',
            aggiornatoIl: _orologio.adesso(),
            pianificazioneId: pianificazioneId,
            dataPrevista: prevista,
            stato: Value(senzaScelta ? null : stato),
            nuovaData: Value(
              !senzaScelta && stato == StatoOccorrenza.spostata ? nuova : null,
            ),
          ),
        );
  }

  // ------------------------------------------------------------- interni

  DateTime _oggi() {
    final a = _adesso();
    return DateTime(a.year, a.month, a.day);
  }

  Future<Map<String, Occorrenza>> _scelte(String pianificazioneId) async => {
    for (final o
        in await (_db.select(_db.occorrenze)..where(
              (o) =>
                  o.pianificazioneId.equals(pianificazioneId) &
                  o.eliminato.equals(false),
            ))
            .get())
      o.dataPrevista: o,
  };

  Future<Occorrenza?> _scelta(String pianificazioneId, DateTime dataPrevista) =>
      (_db.select(_db.occorrenze)..where(
            (o) =>
                o.pianificazioneId.equals(pianificazioneId) &
                o.dataPrevista.equals(Contabilita.giorno(dataPrevista)) &
                o.eliminato.equals(false),
          ))
          .getSingleOrNull();

  /// Il giorno vero di una scadenza: `null` se annullata o fatta.
  static DateTime? _dataEffettiva(DateTime prevista, Occorrenza? scelta) =>
      switch (scelta?.stato) {
        StatoOccorrenza.annullata || StatoOccorrenza.fatta => null,
        StatoOccorrenza.spostata when scelta!.nuovaData != null =>
          Contabilita.daGiorno(scelta.nuovaData!),
        _ => prevista,
      };

  /// Scadenze (giorno della regola, giorno vero, scelta) con il giorno vero
  /// tra [da] e [a], comprese quelle spostate qui da fuori.
  List<(DateTime, DateTime, Occorrenza?)> _scadenzeTra(
    Pianificazione p,
    DateTime da,
    DateTime a,
    Map<String, Occorrenza> scelte,
  ) {
    bool dentro(DateTime d) => !d.isBefore(da) && !d.isAfter(a);
    // "Conta dal": quelle prima erano già avvenute quando è stata inserita.
    final dal = p.registraDal == null
        ? null
        : Contabilita.daGiorno(p.registraDal!);
    bool contata(DateTime prevista) => dal == null || !prevista.isBefore(dal);
    final regola = ricorrenzaDi(p);
    final out = <(DateTime, DateTime, Occorrenza?)>[];
    final viste = <String>{};
    for (final prevista in regola.tra(da, a)) {
      if (!contata(prevista)) {
        continue;
      }
      final chiave = Contabilita.giorno(prevista);
      viste.add(chiave);
      final scelta = scelte[chiave];
      final data = _dataEffettiva(prevista, scelta);
      if (data != null && dentro(data)) {
        out.add((prevista, data, scelta));
      }
    }
    for (final scelta in scelte.values) {
      if (scelta.stato != StatoOccorrenza.spostata ||
          scelta.nuovaData == null ||
          viste.contains(scelta.dataPrevista)) {
        continue;
      }
      final prevista = Contabilita.daGiorno(scelta.dataPrevista);
      final data = Contabilita.daGiorno(scelta.nuovaData!);
      // Solo se il giorno appartiene ancora alla regola (la voce può cambiare).
      if (dentro(data) &&
          contata(prevista) &&
          regola.tra(prevista, prevista).isNotEmpty) {
        out.add((prevista, data, scelta));
      }
    }
    out.sort((x, y) => x.$2.compareTo(y.$2));
    return out;
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

  Future<String> _creaMovimento(
    Pianificazione p,
    DateTime prevista,
    DateTime data,
    int importo,
  ) async {
    final giorno = Contabilita.giorno(prevista);
    // Già registrata (es. con un id di prima): resta quella.
    final esistente =
        await (_db.select(_db.movimenti)..where(
              (m) =>
                  m.pianificazioneId.equals(p.id) &
                  m.dataPrevista.equals(giorno),
            ))
            .getSingleOrNull();
    if (esistente != null) {
      return esistente.id;
    }
    final tipoId = p.tipoId ?? await _tipoSpesa();
    // Id fisso per scadenza: due dispositivi che registrano la stessa
    // scadenza scrivono la stessa riga, e la sincronizzazione le unisce.
    // Se c'era (conferma annullata), torna in vita.
    final id = 'scadenza:${p.id}:$giorno';
    await _db
        .into(_db.movimenti)
        .insertOnConflictUpdate(
          MovimentiCompanion.insert(
            id: id,
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
            dataPrevista: Value(giorno),
            eliminato: const Value(false),
          ),
        );
    return id;
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
