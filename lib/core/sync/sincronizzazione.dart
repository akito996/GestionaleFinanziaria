import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sodium/sodium.dart';

import '../db/archivio.dart';
import '../db/orologio.dart';
import 'accesso_google.dart';
import 'drive.dart';
import 'sincronizzatore.dart';
import 'sync_backend.dart';

/// A che punto è la sincronizzazione (per l'icona e la pagina).
enum FaseSync {
  /// Non attiva su questo dispositivo.
  spenta,

  /// Su questa build non c'è la configurazione di Google (es. build locale).
  nonDisponibile,
  inCorso,
  aggiornata,

  /// Serve di nuovo il consenso di Google (es. scaduto dopo 7 giorni in Test).
  accessoRichiesto,

  /// Su Drive c'è un altro archivio: l'utente sceglie cosa fare.
  archivioDiverso,
  errore,
}

@immutable
class StatoSync {
  const StatoSync(this.fase, {this.ultima, this.messaggio, this.idRemoto});

  final FaseSync fase;

  /// Ultima sincronizzazione riuscita.
  final DateTime? ultima;
  final String? messaggio;

  /// Con [FaseSync.archivioDiverso]: l'archivio che c'è su Drive.
  final String? idRemoto;
}

/// Crea lo spazio remoto dal client autorizzato (Drive; nei test, in memoria).
typedef CreaBackend = SyncBackend Function(http.Client client);

/// La sincronizzazione di questo dispositivo: accesa o spenta, quando gira e
/// com'è andata. Gira all'apertura, ogni 5 minuti e con "Sincronizza ora".
class Sincronizzazione {
  Sincronizzazione({
    required this._db,
    required this._orologio,
    required this._sodium,
    required this._dek,
    required this.idArchivio,
    required this.accesso,
    required this._leggiKeyring,
    required this._scriviKeyring,
    CreaBackend? creaBackend,
  }) : _creaBackend = creaBackend ?? DriveBackend.new;

  static const intervallo = Duration(minutes: 5);
  static const _chiaveAttiva = 'sincronizzazione.attiva';

  final String idArchivio;
  final AccessoGoogle accesso;
  final Archivio _db;
  final OrologioLogico _orologio;
  final Sodium _sodium;
  final SecureKey _dek;
  final Future<Uint8List> Function() _leggiKeyring;
  final Future<void> Function(Uint8List) _scriviKeyring;
  final CreaBackend _creaBackend;

  final stato = ValueNotifier(const StatoSync(FaseSync.spenta));
  bool _inCorso = false;
  bool _chiusa = false;

  /// Legge lo stato salvato all'apertura dell'archivio.
  Future<void> carica() async {
    if (!accesso.disponibile) {
      _imposta(const StatoSync(FaseSync.nonDisponibile));
      return;
    }
    final ultima = await _ultima();
    _imposta(
      await attiva()
          ? StatoSync(FaseSync.aggiornata, ultima: ultima)
          : StatoSync(FaseSync.spenta, ultima: ultima),
    );
  }

  Future<bool> attiva() async => await _leggi(_chiaveAttiva) == '1';

  /// Accende la sincronizzazione (chiede il consenso a Google se serve).
  Future<void> accendi() async {
    final riuscita = await _esegui((s) => s.sincronizza(), interattivo: true);
    if (riuscita) {
      await _scrivi(_chiaveAttiva, '1');
    }
  }

  /// Un giro, se è attiva. Con [interattivo] può chiedere di nuovo il
  /// consenso (dal pulsante "Sincronizza ora").
  Future<void> sincronizza({bool interattivo = false}) async {
    if (!accesso.disponibile || !await attiva()) {
      return;
    }
    await _esegui((s) => s.sincronizza(), interattivo: interattivo);
  }

  /// Spenta su questo dispositivo: i dati restano qui e su Drive.
  Future<void> spegni() async {
    await _scrivi(_chiaveAttiva, '0');
    _imposta(StatoSync(FaseSync.spenta, ultima: await _ultima()));
  }

  /// Su Drive c'è un altro archivio: lo mette da parte (rinominato, non
  /// cancellato) e carica quello di questo dispositivo.
  Future<void> sostituisciRemoto() async {
    final riuscita = await _esegui((s) async {
      await Sincronizzatore.metteDaParteRemoto(s.backend);
      await _db.customStatement(
        "DELETE FROM impostazioni WHERE chiave LIKE 'sync.%'",
      );
      await s.sincronizza();
    }, interattivo: true);
    if (riuscita) {
      await _scrivi(_chiaveAttiva, '1');
    }
  }

  /// Al blocco dell'archivio: niente più giri.
  void chiudi() {
    _chiusa = true;
    stato.dispose();
  }

  // ------------------------------------------------------------- interni

  Future<bool> _esegui(
    Future<void> Function(_Giro giro) azione, {
    required bool interattivo,
  }) async {
    if (_inCorso || _chiusa) {
      return false;
    }
    _inCorso = true;
    final ultima = await _ultima();
    _imposta(StatoSync(FaseSync.inCorso, ultima: ultima));
    try {
      var client = await accesso.client(interattivo: interattivo);
      if (client == null) {
        _imposta(StatoSync(FaseSync.accessoRichiesto, ultima: ultima));
        return false;
      }
      try {
        await _giro(client, azione);
      } on ErroreDrive catch (e) {
        if (!e.accessoScaduto) {
          rethrow;
        }
        // Token scaduto: un nuovo tentativo con un accesso rinnovato.
        await accesso.invalida();
        client = await accesso.client(interattivo: interattivo);
        if (client == null) {
          _imposta(StatoSync(FaseSync.accessoRichiesto, ultima: ultima));
          return false;
        }
        await _giro(client, azione);
      }
      _imposta(StatoSync(FaseSync.aggiornata, ultima: await _ultima()));
      return true;
    } on ArchivioRemotoDiverso catch (e) {
      _imposta(
        StatoSync(
          FaseSync.archivioDiverso,
          ultima: ultima,
          idRemoto: e.idRemoto,
        ),
      );
    } on FormatoNonSupportato catch (e) {
      _imposta(StatoSync(FaseSync.errore, ultima: ultima, messaggio: '$e'));
    } on SocketException {
      _errore(ultima, 'Nessuna connessione a Internet: riprovo tra poco.');
    } on http.ClientException {
      _errore(ultima, 'Google Drive non risponde: riprovo tra poco.');
    } on Object catch (e) {
      if ('$e'.contains('invalid_grant')) {
        // Consenso scaduto (in modalità Test dura 7 giorni).
        await accesso.invalida();
        _imposta(StatoSync(FaseSync.accessoRichiesto, ultima: ultima));
      } else {
        debugPrint('Sincronizzazione non riuscita: $e');
        _errore(ultima, 'Sincronizzazione non riuscita: $e');
      }
    } finally {
      _inCorso = false;
    }
    return false;
  }

  Future<void> _giro(
    http.Client client,
    Future<void> Function(_Giro giro) azione,
  ) async {
    final backend = _creaBackend(client);
    final sincronizzatore = Sincronizzatore(
      db: _db,
      orologio: _orologio,
      sodium: _sodium,
      dek: _dek,
      idArchivio: idArchivio,
      backend: backend,
      leggiKeyring: _leggiKeyring,
      scriviKeyring: _scriviKeyring,
    );
    try {
      await azione(_Giro(sincronizzatore, backend));
    } finally {
      sincronizzatore.chiudi();
      client.close();
    }
  }

  void _errore(DateTime? ultima, String messaggio) => _imposta(
    StatoSync(FaseSync.errore, ultima: ultima, messaggio: messaggio),
  );

  void _imposta(StatoSync nuovo) {
    if (!_chiusa) {
      stato.value = nuovo;
    }
  }

  Future<DateTime?> _ultima() async {
    final v = await _leggi('sync.ultima');
    return v == null ? null : DateTime.tryParse(v);
  }

  Future<String?> _leggi(String chiave) async => (await (_db.select(
    _db.impostazioni,
  )..where((i) => i.chiave.equals(chiave))).getSingleOrNull())?.valore;

  Future<void> _scrivi(String chiave, String valore) => _db
      .into(_db.impostazioni)
      .insertOnConflictUpdate(
        ImpostazioniCompanion.insert(chiave: chiave, valore: valore),
      );
}

/// Un giro di sincronizzazione: il sincronizzatore e lo spazio remoto.
class _Giro {
  const _Giro(this.sincronizzatore, this.backend);

  final Sincronizzatore sincronizzatore;
  final SyncBackend backend;

  Future<EsitoSync> sincronizza() => sincronizzatore.sincronizza();
}
