import 'dart:convert';
import 'dart:io' show gzip;

import 'package:drift/drift.dart';
import 'package:sodium/sodium.dart';

import '../crypto/aad.dart';
import '../crypto/cifratura.dart';
import '../crypto/keyring.dart';
import '../db/archivio.dart';
import '../db/orologio.dart';
import 'righe.dart';
import 'sync_backend.dart';

/// Su Drive c'è un altro archivio (creato su un altro dispositivo, con un'altra
/// password e Secret Key): non si mescolano.
class ArchivioRemotoDiverso implements Exception {
  const ArchivioRemotoDiverso(this.idRemoto);

  final String idRemoto;

  @override
  String toString() => 'Su Google Drive c\'è un altro archivio ($idRemoto).';
}

/// Dati scritti da una versione più nuova dell'app.
class FormatoNonSupportato implements Exception {
  const FormatoNonSupportato();

  @override
  String toString() =>
      'I dati su Google Drive vengono da una versione più nuova dell\'app: '
      'aggiornala su questo dispositivo.';
}

/// Com'è andata una sincronizzazione.
class EsitoSync {
  const EsitoSync({required this.ricevute, required this.inviate});

  /// Righe arrivate dagli altri dispositivi e cambiate qui.
  final int ricevute;

  /// Righe cambiate qui e inviate agli altri.
  final int inviate;
}

/// Sincronizzazione con lo spazio remoto (ADR-001, scelta Qualità/Prezzo,
/// ADR-015): ogni dispositivo scrive solo i propri pacchetti di modifiche
/// cifrati, legge quelli degli altri e li unisce riga per riga (vince
/// l'orologio più recente). Ogni tanto un'istantanea completa: i dispositivi
/// nuovi partono da lì e i pacchetti vecchi si cancellano.
///
/// File nello spazio remoto (cartella nascosta dell'app):
/// - `keyring.bin`: la chiave dei dati avvolta (password e Secret Key), già
///   cifrata: chi la legge senza password né Secret Key non ottiene nulla;
/// - `eventi-<dispositivo>-<n>.bin`: pacchetti di modifiche;
/// - `istantanea-<tempo>-<dispositivo>.bin`: tutte le righe.
///
/// Pacchetti e istantanee: JSON compresso e cifrato (XChaCha20-Poly1305) con
/// una chiave derivata da quella dei dati, legato con l'AAD ad archivio,
/// dispositivo e numero: non si possono scambiare né riusare.
class Sincronizzatore {
  Sincronizzatore({
    required Archivio db,
    required OrologioLogico orologio,
    required Sodium sodium,
    required SecureKey dek,
    required this.idArchivio,
    required this._backend,
    required this._leggiKeyring,
    required this._scriviKeyring,
    DateTime Function()? adesso,
  }) : _db = db,
       _orologio = orologio,
       _sodium = sodium,
       _adesso = adesso ?? DateTime.now,
       _righe = RigheSincronizzate(db, orologio),
       // Chiave separata per la sincronizzazione, derivata da quella dei dati.
       _chiave = sodium.crypto.kdf.deriveFromKey(
         masterKey: dek,
         context: 'GFsync01',
         subkeyId: BigInt.one,
         subkeyLen: Cifratore.lunghezzaChiave,
       );

  /// Versione del formato di pacchetti e istantanee.
  static const formato = 1;

  /// Ogni quanti pacchetti propri si fa un'istantanea.
  static const pacchettiPerIstantanea = 30;

  /// Dopo quanto tempo un'istantanea è vecchia (se ci sono pacchetti nuovi).
  static const durataIstantanea = Duration(days: 7);

  final String idArchivio;
  final Archivio _db;
  final OrologioLogico _orologio;
  final Sodium _sodium;
  final SyncBackend _backend;
  final Future<Uint8List> Function() _leggiKeyring;
  final Future<void> Function(Uint8List) _scriviKeyring;
  final DateTime Function() _adesso;
  final RigheSincronizzate _righe;
  final SecureKey _chiave;

  String get _io => _orologio.dispositivoId;

  /// Libera la chiave (al blocco dell'archivio).
  void chiudi() => _chiave.dispose();

  /// Un giro completo: keyring, modifiche degli altri, modifiche di questo
  /// dispositivo, istantanea se serve.
  Future<EsitoSync> sincronizza() async {
    final remoti = await _elenca();
    await _allineaKeyring(remoti);
    await _riprendiOrologio();
    final ricevute = await _ricevi(remoti);
    final inviate = await _invia();
    await _compatta();
    await _scrivi('sync.ultima', _adesso().toIso8601String());
    return EsitoSync(ricevute: ricevute, inviate: inviate);
  }

  /// Dispositivo che scarica l'archivio da capo: svuota le righe e prende
  /// tutto da Drive (istantanea e pacchetti). Restituisce le righe arrivate.
  Future<int> scaricaTutto() async {
    await _righe.svuota();
    await _db.customStatement(
      "DELETE FROM impostazioni WHERE chiave LIKE 'sync.%'",
    );
    final remoti = await _elenca();
    await _scrivi('sync.keyring', _impronta(await _leggiKeyring()));
    final ricevute = await _ricevi(remoti);
    await _scrivi('sync.ultima', _adesso().toIso8601String());
    return ricevute;
  }

  /// Quando è riuscita l'ultima sincronizzazione (`null` = mai).
  Future<DateTime?> ultima() async {
    final v = await _leggi('sync.ultima');
    return v == null ? null : DateTime.tryParse(v);
  }

  /// L'archivio su Drive (`null` = non c'è ancora).
  static Future<String?> idArchivioRemoto(SyncBackend backend) async {
    final file = (await backend.elenca())
        .where((f) => f.nome == 'keyring.bin')
        .firstOrNull;
    return file == null
        ? null
        : Keyring.deserializza(await backend.scarica(file.id)).idArchivio;
  }

  /// Il keyring su Drive, per aprire l'archivio su un dispositivo nuovo.
  static Future<Uint8List?> keyringRemoto(SyncBackend backend) async {
    final file = (await backend.elenca())
        .where((f) => f.nome == 'keyring.bin')
        .firstOrNull;
    return file == null ? null : backend.scarica(file.id);
  }

  /// Mette da parte (senza cancellare: rinomina) l'archivio che c'è su Drive,
  /// per caricare al suo posto quello di questo dispositivo.
  static Future<void> metteDaParteRemoto(SyncBackend backend) async {
    final segno = DateTime.now().toUtc().millisecondsSinceEpoch;
    for (final f in await backend.elenca()) {
      if (!f.nome.startsWith('vecchio-')) {
        await backend.rinomina(f.id, 'vecchio-$segno-${f.nome}');
      }
    }
  }

  // --------------------------------------------------------------- keyring

  /// Primo dispositivo: carica il keyring. Poi tiene allineati locale e remoto
  /// (es. password cambiata con la Secret Key su un altro dispositivo).
  Future<void> _allineaKeyring(List<FileRemoto> remoti) async {
    final locale = await _leggiKeyring();
    final improntaLocale = _impronta(locale);
    final file = remoti.where((f) => f.nome == 'keyring.bin').firstOrNull;
    if (file == null) {
      await _backend.crea(
        'keyring.bin',
        locale,
        proprieta: {'tipo': 'keyring', 'archivio': idArchivio},
      );
      await _scrivi('sync.keyring', improntaLocale);
      return;
    }
    final remoto = await _backend.scarica(file.id);
    final idRemoto = Keyring.deserializza(remoto).idArchivio;
    if (idRemoto != idArchivio) {
      throw ArchivioRemotoDiverso(idRemoto);
    }
    final improntaRemota = _impronta(remoto);
    if (improntaRemota == improntaLocale) {
      await _scrivi('sync.keyring', improntaLocale);
      return;
    }
    final ultima = await _leggi('sync.keyring');
    if (ultima == improntaLocale) {
      // Cambiato altrove: la nuova password vale anche qui.
      await _scriviKeyring(remoto);
      await _scrivi('sync.keyring', improntaRemota);
    } else {
      // Cambiato qui (es. recupero con la Secret Key).
      await _backend.aggiorna(file.id, locale);
      await _scrivi('sync.keyring', improntaLocale);
    }
  }

  // ------------------------------------------------------------ ricevere

  Future<int> _ricevi(List<FileRemoto> remoti) async {
    var ricevute = 0;
    final applicati = await _applicati();
    final istantanee =
        remoti.where((f) => f.proprieta['tipo'] == 'istantanea').toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));
    final ultima = istantanee.lastOrNull;
    if (ultima != null && await _leggi('sync.istantanea') != ultima.nome) {
      final autore = ultima.proprieta['dispositivo']!;
      if (autore != _io) {
        final contenuto = _apri(
          await _backend.scarica(ultima.id),
          TipoDato.snapshot,
          autore,
          int.parse(ultima.proprieta['tempo']!),
        );
        ricevute += await _righe.unisci(_righeDi(contenuto));
        final vettore = (contenuto['vettore'] as Map? ?? const {})
            .cast<String, Object?>();
        for (final MapEntry(:key, :value) in vettore.entries) {
          if (key != _io && value is int && value > (applicati[key] ?? 0)) {
            applicati[key] = value;
            await _scrivi('sync.applicato.$key', '$value');
          }
        }
      }
      await _scrivi('sync.istantanea', ultima.nome);
    }

    final pacchetti =
        remoti
            .where(
              (f) =>
                  f.proprieta['tipo'] == 'eventi' &&
                  f.proprieta['dispositivo'] != _io,
            )
            .toList()
          ..sort((a, b) {
            final dispositivo = a.proprieta['dispositivo']!.compareTo(
              b.proprieta['dispositivo']!,
            );
            return dispositivo != 0
                ? dispositivo
                : int.parse(a.proprieta['seq']!)
                      .compareTo(int.parse(b.proprieta['seq']!));
          });
    for (final p in pacchetti) {
      final autore = p.proprieta['dispositivo']!;
      final seq = int.parse(p.proprieta['seq']!);
      if (seq <= (applicati[autore] ?? 0)) {
        continue;
      }
      final contenuto = _apri(
        await _backend.scarica(p.id),
        TipoDato.evento,
        autore,
        seq,
      );
      ricevute += await _righe.unisci(_righeDi(contenuto));
      applicati[autore] = seq;
      await _scrivi('sync.applicato.$autore', '$seq');
    }
    await _scrivi('sync.orologio', _orologio.adesso());
    return ricevute;
  }

  // -------------------------------------------------------------- inviare

  Future<int> _invia() async {
    final dopo = await _leggi('sync.inviato') ?? '';
    final righe = await _righe.modificateQui(dispositivo: _io, dopo: dopo);
    if (righe.isEmpty) {
      return 0;
    }
    final seq = int.parse(await _leggi('sync.seq') ?? '0') + 1;
    final blob = _chiudi(
      {
        'formato': formato,
        'schema': _db.schemaVersion,
        'dispositivo': _io,
        'seq': seq,
        'righe': righe,
      },
      TipoDato.evento,
      _io,
      seq,
    );
    await _backend.crea(
      'eventi-$_io-${seq.toString().padLeft(10, '0')}.bin',
      blob,
      proprieta: {
        'tipo': 'eventi',
        'dispositivo': _io,
        'seq': '$seq',
        'archivio': idArchivio,
      },
    );
    await _scrivi('sync.seq', '$seq');
    await _scrivi('sync.inviato', RigheSincronizzate.orologioMassimo(righe));
    return righe.values.fold<int>(0, (somma, r) => somma + r.length);
  }

  // ------------------------------------------------------------ compattare

  /// Istantanea quando non c'è, quando i propri pacchetti sono tanti o
  /// quando l'ultima è vecchia; poi via i propri pacchetti (sono tutti
  /// nell'istantanea) e le proprie istantanee precedenti.
  Future<void> _compatta() async {
    final remoti = await _elenca();
    final miei = remoti
        .where(
          (f) =>
              f.proprieta['tipo'] == 'eventi' &&
              f.proprieta['dispositivo'] == _io,
        )
        .toList();
    final istantanee =
        remoti.where((f) => f.proprieta['tipo'] == 'istantanea').toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));
    final ultima = istantanee.lastOrNull;
    final adesso = _adesso();
    final vecchia =
        ultima != null &&
        adesso
                .difference(
                  DateTime.fromMillisecondsSinceEpoch(
                    int.parse(ultima.proprieta['tempo']!),
                  ),
                )
                .compareTo(durataIstantanea) >
            0;
    if (ultima != null &&
        miei.length < pacchettiPerIstantanea &&
        !(vecchia && miei.isNotEmpty)) {
      return;
    }
    final tempo = adesso.millisecondsSinceEpoch;
    final vettore = {
      ...await _applicati(),
      _io: int.parse(await _leggi('sync.seq') ?? '0'),
    };
    final blob = _chiudi(
      {
        'formato': formato,
        'schema': _db.schemaVersion,
        'vettore': vettore,
        'righe': await _righe.tutte(),
      },
      TipoDato.snapshot,
      _io,
      tempo,
    );
    final nome = 'istantanea-${tempo.toString().padLeft(15, '0')}-$_io.bin';
    await _backend.crea(
      nome,
      blob,
      proprieta: {
        'tipo': 'istantanea',
        'dispositivo': _io,
        'tempo': '$tempo',
        'archivio': idArchivio,
      },
    );
    await _scrivi('sync.istantanea', nome);
    for (final f in miei) {
      await _backend.elimina(f.id);
    }
    for (final f in istantanee) {
      if (f.proprieta['dispositivo'] == _io) {
        await _backend.elimina(f.id);
      }
    }
  }

  // ------------------------------------------------------------- interni

  /// I file di questo archivio: quelli messi da parte ("vecchio-...") o di un
  /// altro archivio non si leggono mai.
  Future<List<FileRemoto>> _elenca() async => [
    for (final f in await _backend.elenca())
      if (!f.nome.startsWith('vecchio-') &&
          (f.nome == 'keyring.bin' || f.proprieta['archivio'] == idArchivio))
        f,
  ];

  Uint8List _chiudi(
    Map<String, Object?> contenuto,
    TipoDato tipo,
    String dispositivo,
    int numero,
  ) {
    final compresso = Uint8List.fromList(
      gzip.encode(utf8.encode(jsonEncode(contenuto))),
    );
    return Cifratore(_sodium).cifra(
      compresso,
      _chiave,
      aad: aadPer(
        tipo: tipo,
        utenteId: idArchivio,
        dispositivoId: dispositivo,
        sequenza: numero,
      ),
    );
  }

  Map<String, Object?> _apri(
    Uint8List blob,
    TipoDato tipo,
    String dispositivo,
    int numero,
  ) {
    final compresso = Cifratore(_sodium).decifra(
      blob,
      _chiave,
      aad: aadPer(
        tipo: tipo,
        utenteId: idArchivio,
        dispositivoId: dispositivo,
        sequenza: numero,
      ),
    );
    final contenuto =
        jsonDecode(utf8.decode(gzip.decode(compresso))) as Map<String, Object?>;
    final versione = contenuto['formato'];
    if (versione is! int || versione > formato) {
      throw const FormatoNonSupportato();
    }
    return contenuto;
  }

  static RighePerTabella _righeDi(Map<String, Object?> contenuto) => {
    for (final MapEntry(:key, :value)
        in (contenuto['righe'] as Map? ?? const {}).entries)
      '$key': [
        for (final r in value as List) (r as Map).cast<String, Object?>(),
      ],
  };

  /// Dopo un riavvio, l'orologio riparte da dove era arrivato con gli altri.
  Future<void> _riprendiOrologio() async {
    final ultimo = await _leggi('sync.orologio');
    if (ultimo != null) {
      _orologio.ricevi(ultimo);
    }
  }

  Future<Map<String, int>> _applicati() async => {
    for (final r in await (_db.select(
      _db.impostazioni,
    )..where((i) => i.chiave.like('sync.applicato.%'))).get())
      r.chiave.substring('sync.applicato.'.length): int.parse(r.valore),
  };

  String _impronta(Uint8List dati) =>
      base64.encode(_sodium.crypto.genericHash(message: dati, outLen: 32));

  Future<String?> _leggi(String chiave) async => (await (_db.select(
    _db.impostazioni,
  )..where((i) => i.chiave.equals(chiave))).getSingleOrNull())?.valore;

  Future<void> _scrivi(String chiave, String valore) => _db
      .into(_db.impostazioni)
      .insertOnConflictUpdate(
        ImpostazioniCompanion.insert(chiave: chiave, valore: valore),
      );
}
