import 'package:drift/drift.dart';

import '../db/archivio.dart';
import '../db/orologio.dart';

/// Una riga di una tabella così come viaggia nei pacchetti: nome colonna SQL
/// → valore (testo, numero o `null`).
typedef Riga = Map<String, Object?>;

/// Righe per tabella (nome SQL).
typedef RighePerTabella = Map<String, List<Riga>>;

/// Le righe delle tabelle sincronizzate: lettura delle modifiche, unione con
/// quelle degli altri dispositivi (vince l'orologio più recente, riga per
/// riga, ADR-015) e svuotamento per scaricare un archivio da capo.
///
/// Lavora sui nomi SQL delle colonne: le colonne che un'altra versione
/// dell'app non conosce si ignorano, quelle che mancano restano predefinite.
class RigheSincronizzate {
  RigheSincronizzate(this._db, this._orologio);

  final Archivio _db;
  final OrologioLogico _orologio;
  final _colonne = <String, Set<String>>{};

  /// Le tabelle che viaggiano, nell'ordine in cui si applicano (prima quelle a
  /// cui le altre fanno riferimento). I report e le impostazioni restano del
  /// dispositivo: ognuno li ricalcola dai dati.
  static const tabelle = [
    'profili',
    'definizioni_tipo',
    'portafogli',
    'portafogli_condivisi',
    'membri',
    'categorie',
    'etichette',
    'voci_costo',
    'importi_voce',
    'variazioni_mese',
    'pianificazioni',
    'occorrenze',
    'carte_credito',
    'prestiti',
    'obiettivi',
    'partecipanti',
    'movimenti',
    'movimenti_etichette',
    'versamenti',
    'notifiche_lette',
    'righe_condivise',
  ];

  /// Tabelle che non viaggiano mai.
  static const locali = {'report', 'impostazioni'};

  Future<Set<String>> colonne(String tabella) async => _colonne[tabella] ??= {
    for (final r in await _db.customSelect('PRAGMA table_info($tabella)').get())
      r.read<String>('name'),
  };

  /// Righe cambiate su questo dispositivo ([dispositivo]) dopo l'orologio
  /// [dopo] (`''` = tutte).
  Future<RighePerTabella> modificateQui({
    required String dispositivo,
    required String dopo,
  }) async {
    final risultato = <String, List<Riga>>{};
    for (final t in tabelle) {
      // Orologio = 17 cifre, "-", id del dispositivo (vedi OrologioLogico).
      final righe = await _db
          .customSelect(
            'SELECT * FROM $t WHERE aggiornato_il > ? '
            'AND substr(aggiornato_il, 19) = ?',
            variables: [
              Variable.withString(dopo),
              Variable.withString(dispositivo),
            ],
          )
          .get();
      if (righe.isNotEmpty) {
        risultato[t] = [for (final r in righe) Map.of(r.data)];
      }
    }
    return risultato;
  }

  /// Tutte le righe (comprese quelle eliminate: anche le cancellazioni viaggiano).
  Future<RighePerTabella> tutte() async => {
    for (final t in tabelle)
      t: [
        for (final r in await _db.customSelect('SELECT * FROM $t').get())
          Map.of(r.data),
      ],
  };

  /// Cancella tutte le righe sincronizzate (dispositivo che scarica un
  /// archivio da capo). Le tabelle locali restano.
  Future<void> svuota() async {
    await _db.transaction(() async {
      await _db.customStatement('PRAGMA defer_foreign_keys = ON');
      for (final t in tabelle.reversed) {
        await _db.customStatement('DELETE FROM $t');
      }
    });
    _avvisaCambiate(tabelle);
  }

  /// L'orologio più alto tra [righe] (`''` se non ce ne sono).
  static String orologioMassimo(RighePerTabella righe) {
    var massimo = '';
    for (final elenco in righe.values) {
      for (final r in elenco) {
        final o = r['aggiornato_il'];
        if (o is String && o.compareTo(massimo) > 0) {
          massimo = o;
        }
      }
    }
    return massimo;
  }

  /// Unisce le righe di un altro dispositivo: una riga entra se qui non c'è o
  /// se il suo orologio è più recente. Restituisce quante righe sono cambiate.
  Future<int> unisci(RighePerTabella righe) async {
    var cambiate = 0;
    final toccate = <String>{};
    await _db.transaction(() async {
      // I riferimenti tra tabelle si controllano alla fine, non riga per riga.
      await _db.customStatement('PRAGMA defer_foreign_keys = ON');
      for (final t in tabelle) {
        final arrivate = righe[t];
        if (arrivate == null || arrivate.isEmpty) {
          continue;
        }
        final note = await colonne(t);
        final orologi = {
          for (final r
              in await _db
                  .customSelect('SELECT id, aggiornato_il FROM $t')
                  .get())
            r.read<String>('id'): r.read<String>('aggiornato_il'),
        };
        final coppie = t == 'movimenti' ? await _coppieMovimenti() : null;
        for (final arrivata in arrivate) {
          final id = arrivata['id'];
          final orologio = arrivata['aggiornato_il'];
          if (id is! String || orologio is! String) {
            continue;
          }
          _orologio.ricevi(orologio);
          final locale = orologi[id];
          if (locale != null && locale.compareTo(orologio) >= 0) {
            continue; // qui c'è già la versione più recente
          }
          var riga = {
            for (final MapEntry(:key, :value) in arrivata.entries)
              if (note.contains(key)) key: value,
          };
          if (coppie != null) {
            riga = await _risolviScadenzaDoppia(riga, coppie);
          }
          await _scrivi(t, riga);
          orologi[id] = riga['aggiornato_il']! as String;
          cambiate++;
          toccate.add(t);
        }
      }
    });
    _avvisaCambiate(toccate);
    return cambiate;
  }

  // ------------------------------------------------------------- interni

  Future<void> _scrivi(String tabella, Riga riga) {
    final nomi = riga.keys.toList();
    final aggiorna = [
      for (final n in nomi)
        if (n != 'id') '$n = excluded.$n',
    ];
    return _db.customStatement(
      'INSERT INTO $tabella (${nomi.join(', ')}) '
      'VALUES (${List.filled(nomi.length, '?').join(', ')}) '
      'ON CONFLICT(id) DO UPDATE SET ${aggiorna.join(', ')}',
      [for (final n in nomi) riga[n]],
    );
  }

  /// Movimenti registrati da una scadenza: (pianificazione, giorno) → id.
  Future<Map<String, String>> _coppieMovimenti() async => {
    for (final r
        in await _db
            .customSelect(
              'SELECT id, pianificazione_id, data_prevista FROM movimenti '
              'WHERE pianificazione_id IS NOT NULL AND data_prevista IS NOT NULL',
            )
            .get())
      '${r.read<String>('pianificazione_id')}|${r.read<String>('data_prevista')}':
          r.read<String>('id'),
  };

  /// Due dispositivi hanno registrato la stessa scadenza con id diversi (es.
  /// archivi di prima della v14): ne resta una sola, quella con l'id minore
  /// (scelta uguale su tutti i dispositivi); l'altra si stacca e si elimina,
  /// con un orologio nuovo così la correzione arriva anche agli altri.
  Future<Riga> _risolviScadenzaDoppia(
    Riga riga,
    Map<String, String> coppie,
  ) async {
    final pianificazione = riga['pianificazione_id'];
    final giorno = riga['data_prevista'];
    final id = riga['id']! as String;
    if (pianificazione == null || giorno == null) {
      return riga;
    }
    final chiave = '$pianificazione|$giorno';
    final altro = coppie[chiave];
    if (altro == null || altro == id) {
      coppie[chiave] = id;
      return riga;
    }
    if (altro.compareTo(id) < 0) {
      // Resta quella che c'è già: l'arrivata entra staccata ed eliminata.
      return {
        ...riga,
        'pianificazione_id': null,
        'data_prevista': null,
        'eliminato': 1,
        'aggiornato_il': _orologio.adesso(),
      };
    }
    await _db.customStatement(
      'UPDATE movimenti SET pianificazione_id = NULL, data_prevista = NULL, '
      'eliminato = 1, aggiornato_il = ? WHERE id = ?',
      [_orologio.adesso(), altro],
    );
    coppie[chiave] = id;
    return riga;
  }

  /// Le schermate aperte si aggiornano da sole (drift osserva le tabelle).
  void _avvisaCambiate(Iterable<String> nomi) {
    final insieme = nomi.toSet();
    final tabelle = _db.allTables.where(
      (t) => insieme.contains(t.actualTableName),
    );
    if (tabelle.isNotEmpty) {
      _db.markTablesUpdated(tabelle);
    }
  }
}
