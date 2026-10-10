import 'package:drift/drift.dart';

import 'archivio.dart';
import 'id.dart';
import 'orologio.dart';
import 'tabelle.dart';

/// Portafoglio con il saldo calcolato (saldo iniziale + movimenti).
class PortafoglioConSaldo {
  const PortafoglioConSaldo(this.portafoglio, this.tipo, this.saldo);

  final Portafoglio portafoglio;
  final DefinizioneTipo tipo;

  /// In unità minime (centesimi).
  final int saldo;
}

/// Movimento con quello che serve per mostrarlo (tipo, portafogli coinvolti).
class MovimentoDettaglio {
  const MovimentoDettaglio(
    this.movimento,
    this.tipo,
    this.portafoglio,
    this.destinazione,
    this.categoria,
  );

  final Movimento movimento;
  final DefinizioneTipo tipo;
  final Portafoglio portafoglio;
  final Portafoglio? destinazione;
  final Categoria? categoria;

  /// Effetto sul saldo di [portafoglioId] (positivo = entra, negativo = esce).
  int effettoSu(String portafoglioId) {
    final importo = movimento.importoMinimo;
    return switch (tipo.effetto) {
      EffettoSaldo.entrata => importo,
      EffettoSaldo.uscita => -importo,
      EffettoSaldo.trasferimento =>
        movimento.portafoglioDestinazioneId == portafoglioId
            ? importo
            : -importo,
      _ => 0,
    };
  }
}

/// Operazioni su portafogli e movimenti. Tutte le letture sono "osservabili":
/// l'interfaccia si aggiorna da sola quando i dati cambiano.
/// Le cancellazioni sono morbide (`eliminato = true`) e si possono annullare.
class Contabilita {
  Contabilita._(this._db, this._orologio);

  static Future<Contabilita> apri(Archivio db) async =>
      Contabilita._(db, await OrologioLogico.carica(db));

  final Archivio _db;
  final OrologioLogico _orologio;

  /// Orologio condiviso con gli altri servizi dell'archivio.
  OrologioLogico get orologio => _orologio;

  // ---------------------------------------------------------------- tipi

  Future<List<DefinizioneTipo>> tipi(String ambito) =>
      (_db.select(_db.definizioniTipo)
            ..where(
              (t) =>
                  t.ambito.equals(ambito) &
                  t.eliminato.equals(false) &
                  t.archiviato.equals(false),
            )
            ..orderBy([(t) => OrderingTerm(expression: t.ordine)]))
          .get();

  // ---------------------------------------------------------- portafogli

  /// Portafogli non archiviati, con saldo, in ordine.
  Stream<List<PortafoglioConSaldo>> osservaPortafogli() {
    const sql = '''
      SELECT p.id AS id,
        p.saldo_iniziale_minimo
        + COALESCE((SELECT SUM(CASE t.effetto
              WHEN 'entrata' THEN m.importo_minimo
              WHEN 'uscita' THEN -m.importo_minimo
              WHEN 'trasferimento' THEN -m.importo_minimo
              ELSE 0 END)
            FROM movimenti m JOIN definizioni_tipo t ON t.id = m.tipo_id
            WHERE m.portafoglio_id = p.id AND m.eliminato = 0), 0)
        + COALESCE((SELECT SUM(m.importo_minimo)
            FROM movimenti m JOIN definizioni_tipo t ON t.id = m.tipo_id
            WHERE m.portafoglio_destinazione_id = p.id AND m.eliminato = 0
              AND t.effetto = 'trasferimento'), 0) AS saldo
      FROM portafogli p
      WHERE p.eliminato = 0 AND p.archiviato = 0
    ''';
    final saldi = _db
        .customSelect(
          sql,
          readsFrom: {_db.portafogli, _db.movimenti, _db.definizioniTipo},
        )
        .watch();
    return saldi.asyncMap((righe) async {
      final perId = {
        for (final r in righe) r.read<String>('id'): r.read<int>('saldo'),
      };
      final query =
          _db.select(_db.portafogli).join([
              innerJoin(
                _db.definizioniTipo,
                _db.definizioniTipo.id.equalsExp(_db.portafogli.tipoId),
              ),
            ])
            ..where(
              _db.portafogli.eliminato.equals(false) &
                  _db.portafogli.archiviato.equals(false),
            )
            ..orderBy([
              OrderingTerm(expression: _db.portafogli.ordine),
              OrderingTerm(expression: _db.portafogli.nome),
            ]);
      return [
        for (final r in await query.get())
          PortafoglioConSaldo(
            r.readTable(_db.portafogli),
            r.readTable(_db.definizioniTipo),
            perId[r.readTable(_db.portafogli).id] ?? 0,
          ),
      ];
    });
  }

  Future<String> creaPortafoglio({
    required String nome,
    required String tipoId,
    required String valuta,
    int saldoIniziale = 0,
  }) async {
    final id = nuovoId();
    final ordine = await _prossimoOrdine();
    await _db
        .into(_db.portafogli)
        .insert(
          PortafogliCompanion.insert(
            id: id,
            aggiornatoIl: _orologio.adesso(),
            tipoId: tipoId,
            nome: nome.trim(),
            valuta: valuta,
            saldoInizialeMinimo: Value(saldoIniziale),
            ordine: Value(ordine),
          ),
        );
    return id;
  }

  Future<void> modificaPortafoglio(
    String id, {
    required String nome,
    required String tipoId,
    required String valuta,
    required int saldoIniziale,
  }) => (_db.update(_db.portafogli)..where((p) => p.id.equals(id))).write(
    PortafogliCompanion(
      aggiornatoIl: Value(_orologio.adesso()),
      nome: Value(nome.trim()),
      tipoId: Value(tipoId),
      valuta: Value(valuta),
      saldoInizialeMinimo: Value(saldoIniziale),
    ),
  );

  /// Archiviato = nascosto dagli elenchi, movimenti conservati. Reversibile.
  Future<void> archiviaPortafoglio(String id, {bool archiviato = true}) =>
      (_db.update(_db.portafogli)..where((p) => p.id.equals(id))).write(
        PortafogliCompanion(
          aggiornatoIl: Value(_orologio.adesso()),
          archiviato: Value(archiviato),
        ),
      );

  Future<int> _prossimoOrdine() async {
    final massimo = _db.portafogli.ordine.max();
    final riga = await (_db.selectOnly(
      _db.portafogli,
    )..addColumns([massimo])).getSingle();
    return (riga.read(massimo) ?? -1) + 1;
  }

  // ----------------------------------------------------------- categorie

  /// Tutte le categorie attive (l'albero si ricostruisce con [AlberoCategorie]).
  Stream<List<Categoria>> osservaCategorie() =>
      (_db.select(_db.categorie)
            ..where(
              (c) => c.eliminato.equals(false) & c.archiviata.equals(false),
            )
            ..orderBy([
              (c) => OrderingTerm(expression: c.ordine),
              (c) => OrderingTerm(expression: c.nome),
            ]))
          .watch();

  Future<String> creaCategoria({required String nome, String? padreId}) async {
    final id = nuovoId();
    await _db
        .into(_db.categorie)
        .insert(
          CategorieCompanion.insert(
            id: id,
            aggiornatoIl: _orologio.adesso(),
            nome: nome.trim(),
            padreId: Value(padreId),
            ordine: const Value(1000),
          ),
        );
    return id;
  }

  Future<void> rinominaCategoria(String id, String nome) =>
      (_db.update(_db.categorie)..where((c) => c.id.equals(id))).write(
        CategorieCompanion(
          aggiornatoIl: Value(_orologio.adesso()),
          nome: Value(nome.trim()),
        ),
      );

  /// Archiviata = non più proposta; i movimenti già registrati la conservano.
  /// Le sottocategorie spariscono con lei. Reversibile.
  Future<void> archiviaCategoria(String id, {bool archiviata = true}) =>
      (_db.update(_db.categorie)..where((c) => c.id.equals(id))).write(
        CategorieCompanion(
          aggiornatoIl: Value(_orologio.adesso()),
          archiviata: Value(archiviata),
        ),
      );

  // ----------------------------------------------------------- movimenti

  /// Movimenti più recenti (di tutti i portafogli o di uno solo).
  Stream<List<MovimentoDettaglio>> osservaMovimenti({
    String? portafoglioId,
    int limite = 50,
  }) {
    final destinazione = _db.alias(_db.portafogli, 'destinazione');
    final query =
        _db.select(_db.movimenti).join([
            innerJoin(
              _db.definizioniTipo,
              _db.definizioniTipo.id.equalsExp(_db.movimenti.tipoId),
            ),
            innerJoin(
              _db.portafogli,
              _db.portafogli.id.equalsExp(_db.movimenti.portafoglioId),
            ),
            leftOuterJoin(
              destinazione,
              destinazione.id.equalsExp(
                _db.movimenti.portafoglioDestinazioneId,
              ),
            ),
            leftOuterJoin(
              _db.categorie,
              _db.categorie.id.equalsExp(_db.movimenti.categoriaId),
            ),
          ])
          ..where(_db.movimenti.eliminato.equals(false))
          ..orderBy([
            OrderingTerm.desc(_db.movimenti.data),
            OrderingTerm.desc(_db.movimenti.aggiornatoIl),
          ])
          ..limit(limite);
    if (portafoglioId != null) {
      query.where(
        _db.movimenti.portafoglioId.equals(portafoglioId) |
            _db.movimenti.portafoglioDestinazioneId.equals(portafoglioId),
      );
    }
    return query.watch().map(
      (righe) => [
        for (final r in righe)
          MovimentoDettaglio(
            r.readTable(_db.movimenti),
            r.readTable(_db.definizioniTipo),
            r.readTable(_db.portafogli),
            r.readTableOrNull(destinazione),
            r.readTableOrNull(_db.categorie),
          ),
      ],
    );
  }

  /// Movimenti tra [da] e [a] (inclusi), dal più vecchio (per l'export).
  Future<List<MovimentoDettaglio>> movimentiTra(DateTime da, DateTime a) async {
    final destinazione = _db.alias(_db.portafogli, 'destinazione');
    final query =
        _db.select(_db.movimenti).join([
            innerJoin(
              _db.definizioniTipo,
              _db.definizioniTipo.id.equalsExp(_db.movimenti.tipoId),
            ),
            innerJoin(
              _db.portafogli,
              _db.portafogli.id.equalsExp(_db.movimenti.portafoglioId),
            ),
            leftOuterJoin(
              destinazione,
              destinazione.id.equalsExp(
                _db.movimenti.portafoglioDestinazioneId,
              ),
            ),
            leftOuterJoin(
              _db.categorie,
              _db.categorie.id.equalsExp(_db.movimenti.categoriaId),
            ),
          ])
          ..where(
            _db.movimenti.eliminato.equals(false) &
                _db.movimenti.data.isBetweenValues(giorno(da), giorno(a)),
          )
          ..orderBy([
            OrderingTerm.asc(_db.movimenti.data),
            OrderingTerm.asc(_db.movimenti.aggiornatoIl),
          ]);
    return [
      for (final r in await query.get())
        MovimentoDettaglio(
          r.readTable(_db.movimenti),
          r.readTable(_db.definizioniTipo),
          r.readTable(_db.portafogli),
          r.readTableOrNull(destinazione),
          r.readTableOrNull(_db.categorie),
        ),
    ];
  }

  Future<String> registraMovimento({
    required String tipoId,
    required String portafoglioId,
    String? destinazioneId,
    String? categoriaId,
    required int importo,
    required String valuta,
    required DateTime data,
    String descrizione = '',
  }) async {
    _controlla(importo, portafoglioId, destinazioneId);
    final id = nuovoId();
    await _db
        .into(_db.movimenti)
        .insert(
          MovimentiCompanion.insert(
            id: id,
            aggiornatoIl: _orologio.adesso(),
            tipoId: tipoId,
            portafoglioId: portafoglioId,
            portafoglioDestinazioneId: Value(destinazioneId),
            categoriaId: Value(categoriaId),
            importoMinimo: importo,
            valuta: valuta,
            data: giorno(data),
            descrizione: Value(descrizione.trim()),
          ),
        );
    return id;
  }

  Future<void> modificaMovimento(
    String id, {
    required String tipoId,
    required String portafoglioId,
    String? destinazioneId,
    String? categoriaId,
    required int importo,
    required String valuta,
    required DateTime data,
    String descrizione = '',
  }) {
    _controlla(importo, portafoglioId, destinazioneId);
    return (_db.update(_db.movimenti)..where((m) => m.id.equals(id))).write(
      MovimentiCompanion(
        aggiornatoIl: Value(_orologio.adesso()),
        tipoId: Value(tipoId),
        portafoglioId: Value(portafoglioId),
        portafoglioDestinazioneId: Value(destinazioneId),
        categoriaId: Value(categoriaId),
        importoMinimo: Value(importo),
        valuta: Value(valuta),
        data: Value(giorno(data)),
        descrizione: Value(descrizione.trim()),
      ),
    );
  }

  /// Cancellazione morbida: [ripristinaMovimento] la annulla.
  Future<void> eliminaMovimento(String id) => _segnaEliminato(id, true);

  Future<void> ripristinaMovimento(String id) => _segnaEliminato(id, false);

  Future<void> _segnaEliminato(String id, bool eliminato) =>
      (_db.update(_db.movimenti)..where((m) => m.id.equals(id))).write(
        MovimentiCompanion(
          aggiornatoIl: Value(_orologio.adesso()),
          eliminato: Value(eliminato),
        ),
      );

  static void _controlla(
    int importo,
    String portafoglioId,
    String? destinazioneId,
  ) {
    if (importo <= 0) {
      throw ArgumentError.value(
        importo,
        'importo',
        'deve essere maggiore di 0',
      );
    }
    if (destinazioneId == portafoglioId) {
      throw ArgumentError.value(
        destinazioneId,
        'destinazioneId',
        'un trasferimento va verso un altro portafoglio',
      );
    }
  }

  /// Data contabile AAAA-MM-GG (giorno locale dell'utente).
  static String giorno(DateTime data) =>
      '${data.year.toString().padLeft(4, '0')}-'
      '${data.month.toString().padLeft(2, '0')}-'
      '${data.day.toString().padLeft(2, '0')}';

  static DateTime daGiorno(String testo) => DateTime.parse(testo);
}

/// Albero delle categorie costruito da un elenco piatto.
class AlberoCategorie {
  AlberoCategorie(List<Categoria> tutte)
    : perId = {for (final c in tutte) c.id: c},
      _figli = {} {
    for (final c in tutte) {
      // Una categoria il cui padre non c'è più (archiviato) sparisce con lui.
      if (c.padreId == null || perId.containsKey(c.padreId)) {
        _figli.putIfAbsent(c.padreId, () => []).add(c);
      }
    }
  }

  final Map<String, Categoria> perId;
  final Map<String?, List<Categoria>> _figli;

  List<Categoria> figli(String? padreId) => _figli[padreId] ?? const [];

  List<Categoria> get radici => figli(null);

  /// "Casa › Bollette › Luce".
  String percorso(String id) {
    final nomi = <String>[];
    String? corrente = id;
    final visti = <String>{};
    while (corrente != null && visti.add(corrente)) {
      final c = perId[corrente];
      if (c == null) {
        break;
      }
      nomi.insert(0, c.nome);
      corrente = c.padreId;
    }
    return nomi.join(' › ');
  }

  /// La categoria e tutte le sue sottocategorie (a qualsiasi profondità).
  Set<String> discendenti(String id) {
    final risultato = <String>{id};
    final daVisitare = [id];
    while (daVisitare.isNotEmpty) {
      for (final f in figli(daVisitare.removeLast())) {
        if (risultato.add(f.id)) {
          daVisitare.add(f.id);
        }
      }
    }
    return risultato;
  }

  /// Visita in profondità: (categoria, livello) nell'ordine di un elenco ad albero.
  List<(Categoria, int)> inOrdine() {
    final out = <(Categoria, int)>[];
    void visita(String? padre, int livello) {
      for (final c in figli(padre)) {
        out.add((c, livello));
        visita(c.id, livello + 1);
      }
    }

    visita(null, 0);
    return out;
  }
}
