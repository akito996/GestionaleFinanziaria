import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:crypto/crypto.dart' show sha256;
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sodium/sodium.dart';

import '../crypto/cifratura.dart';
import '../db/archivio.dart';
import '../db/contabilita.dart';
import '../db/id.dart';
import '../db/orologio.dart';
import '../db/tabelle.dart';
import 'accesso_drive_file.dart';
import 'drive_condiviso.dart';
import 'identita_persona.dart';
import 'invito.dart';

/// Esito di un invito.
enum EsitoInvito {
  invitato,

  /// La persona è già nel portafoglio.
  giaPresente,

  /// Già invitata ma non ancora entrata: l'invito è stato rimandato.
  rimandato,

  /// È l'email del proprietario stesso.
  seiTu,
  annullato,
}

/// Esito di "Unisciti a un portafoglio condiviso".
enum EsitoIngresso {
  /// L'invito è scaduto (nessuna risposta entro un'ora).
  scaduto,

  /// Entrato: il portafoglio è già qui.
  entrato,

  /// In attesa che l'app del proprietario consegni la chiave.
  inAttesa,

  /// Tra i file scelti non c'è il registro del portafoglio.
  nessunRegistro,

  /// Il registro non invita questo account Google.
  nonInvitato,

  /// Manca il proprio file tra quelli scelti: vanno scelti tutti.
  fileMancanti,
  annullato,
}

/// Il registro o un file non è valido (firma, formato, chiave cambiata).
final class CondivisoNonValido implements Exception {
  const CondivisoNonValido(this.motivo);

  final String motivo;

  @override
  String toString() => 'Portafoglio condiviso non valido: $motivo';
}

/// Com'è andato l'ultimo giro dei portafogli condivisi.
enum FaseCondivisi {
  /// Nessun portafoglio condiviso su questo dispositivo.
  nessuno,
  aggiornati,

  /// Manca il consenso di Google: serve un tocco su ⟳ (o "Aggiorna ora").
  accessoRichiesto,
  errore,
}

@immutable
class StatoCondivisi {
  const StatoCondivisi(this.fase, {this.ultima, this.messaggio});

  final FaseCondivisi fase;

  /// Ultimo giro riuscito.
  final DateTime? ultima;
  final String? messaggio;
}

/// Un portafoglio condiviso con le sue persone (per le schermate).
typedef VistaCondiviso = ({
  PortafoglioCondiviso info,
  String nome,
  List<Membro> membri,
});

/// Portafogli condivisi (ADR-019): invito, ingresso del membro e
/// sincronizzazione attraverso una cartella di Google Drive.
///
/// - Il **proprietario** crea la cartella (dentro «WalleCy»), il **registro**
///   (membri, chiavi pubbliche, chiave del portafoglio sigillata per ognuno,
///   firmato da lui) e un file per ogni persona.
/// - Ogni persona scrive solo il **proprio file**: le sue chiavi pubbliche e,
///   cifrate con la chiave del portafoglio, tutte le righe che conosce
///   (portafoglio e movimenti), **ognuna firmata** da chi l'ha cambiata.
/// - Chi legge unisce riga per riga (vale l'orologio più recente) e accetta
///   solo le modifiche dell'autore della voce o del proprietario.
class PortafogliCondivisiServizio {
  PortafogliCondivisiServizio({
    required this._db,
    required this._contabilita,
    required this._sodium,
    required this._identita,
    required this.accesso,
    DriveCondiviso Function(http.Client client)? creaDrive,
    DateTime Function()? adesso,
  }) : _creaDrive = creaDrive ?? DriveCondiviso.new,
       _adesso = adesso ?? DateTime.now;

  final DateTime Function() _adesso;

  /// Tempo per accettare un invito: poi scade e il proprietario lo sa.
  static const durataInvito = Duration(hours: 1);

  final _avvisi = StreamController<String>.broadcast();

  /// Messaggi per il proprietario (es. un invito scaduto senza risposta).
  Stream<String> get avvisi => _avvisi.stream;

  /// Entro quando deve accettare [m] (`null` se non è in attesa).
  DateTime? scadenzaInvito(Membro m) => scadenzaDi(m);

  /// Come [scadenzaInvito], senza servizio (per le schermate).
  static DateTime? scadenzaDi(Membro m) {
    final quando = m.invitatoIl;
    if (m.stato != StatoMembro.invitato || quando == null) {
      return null;
    }
    return DateTime.tryParse(quando)?.add(durataInvito);
  }

  /// Le persone che non fanno più parte di un portafoglio condiviso (uscite,
  /// tolte, invito scaduto, o condivisione finita): le loro voci restano,
  /// segnate come "ex membro".
  ValueListenable<Set<String>> get exMembri {
    _osservaEx ??=
        (_db.select(_db.membri)..where(
              (m) => m.stato.isIn([StatoMembro.uscito, StatoMembro.scaduto]),
            ))
            .watch()
            .listen(
              (elenco) => _exMembri.value = {for (final m in elenco) m.id},
            );
    return _exMembri;
  }

  final _exMembri = ValueNotifier<Set<String>>(const {});
  StreamSubscription<List<Membro>>? _osservaEx;

  void chiudi() {
    _chiuso = true;
    _avvisi.close();
    _osservaEx?.cancel();
    _exMembri.dispose();
    stato.dispose();
  }

  bool _chiuso = false;

  /// Ogni quanto si controllano i portafogli condivisi con l'app aperta. Il
  /// controllo è leggero: si chiede a Drive solo il numero di versione dei
  /// file e si scarica soltanto ciò che è cambiato.
  static const intervallo = Duration(minutes: 1);

  /// Com'è andato l'ultimo giro (icona ⟳, pagina della sincronizzazione).
  final stato = ValueNotifier(const StatoCondivisi(FaseCondivisi.nessuno));

  /// C'è (di nuovo) un portafoglio condiviso: partono i controlli di ogni
  /// minuto, senza aspettare il prossimo giro completo.
  void _ciSono() {
    if (stato.value.fase == FaseCondivisi.nessuno) {
      _imposta(StatoCondivisi(FaseCondivisi.aggiornati, ultima: _adesso()));
    }
  }

  void _imposta(StatoCondivisi nuovo) {
    if (!_chiuso) {
      stato.value = nuovo;
    }
  }

  /// `true` se su questo dispositivo c'è almeno un portafoglio condiviso.
  Future<bool> presenti() async =>
      (await (_db.select(_db.portafogliCondivisi)
                ..where((c) => c.eliminato.equals(false))
                ..limit(1))
              .get())
          .isNotEmpty;

  /// Avvisa a ogni modifica di movimenti o portafogli in questo archivio:
  /// con [daInviare] si capisce se c'è qualcosa da mandare subito agli altri.
  Stream<void> get modificheLocali => _db
      .tableUpdates(
        TableUpdateQuery.onAllTables([_db.movimenti, _db.portafogli]),
      )
      .map((_) {});

  /// `true` se in un portafoglio condiviso c'è una modifica fatta qui e non
  /// ancora mandata agli altri (si confronta l'orologio delle righe).
  Future<bool> daInviare() async {
    final righe = await _db
        .customSelect(
          'SELECT 1 AS da_inviare_condivisi FROM portafogli_condivisi pc '
          'JOIN movimenti m ON m.portafoglio_id = pc.portafoglio_id '
          'OR m.portafoglio_destinazione_id = pc.portafoglio_id '
          "LEFT JOIN righe_condivise r ON r.id = pc.portafoglio_id || ':' || m.id "
          "WHERE pc.eliminato = 0 AND pc.chiave <> '' "
          'AND (r.id IS NULL OR r.riga_aggiornata_il <> m.aggiornato_il) '
          'UNION ALL '
          'SELECT 1 FROM portafogli_condivisi pc '
          'JOIN portafogli p ON p.id = pc.portafoglio_id '
          "LEFT JOIN righe_condivise r ON r.id = pc.portafoglio_id || ':' || p.id "
          "WHERE pc.eliminato = 0 AND pc.chiave <> '' "
          "AND (pc.ruolo = '${RuoloMembro.proprietario}' OR p.eliminato = 1) "
          'AND (r.id IS NULL OR r.riga_aggiornata_il <> p.aggiornato_il) '
          'LIMIT 1',
          readsFrom: {
            _db.portafogliCondivisi,
            _db.movimenti,
            _db.portafogli,
            _db.righeCondivise,
          },
        )
        .get();
    return righe.isNotEmpty;
  }

  /// Versione di ogni file già letto e unito: se Drive dice la stessa, il
  /// file non si scarica di nuovo.
  final _versioni = <String, String>{};

  /// Un file da unire è rimandato (es. firmato da una persona non ancora
  /// nota): va riletto al prossimo giro anche se non cambia.
  bool _rimandato = false;

  /// Il contenuto di un file, o `null` se non è cambiato dall'ultima volta.
  Future<String?> _leggiSeCambiato(DriveCondiviso drive, String fileId) async {
    final versione = await drive.versione(fileId);
    if (versione != null && _versioni[fileId] == versione) {
      return null;
    }
    final testo = await drive.leggi(fileId);
    if (versione != null) {
      // La versione letta PRIMA del contenuto: se nel frattempo il file è
      // cambiato, al prossimo giro si rilegge.
      _versioni[fileId] = versione;
    }
    return testo;
  }

  /// Un errore spiegato in breve.
  static String _leggibile(Object e) => switch (e) {
    SocketException() ||
    http.ClientException() => 'nessuna connessione a Internet',
    ErroreDriveCondiviso(stato: 408) => 'Google Drive non risponde',
    ErroreDriveCondiviso(stato: 401) => "serve di nuovo l'accesso a Google",
    ErroreDriveCondiviso(stato: 403 || 404) =>
      'un file del portafoglio non è raggiungibile su Google Drive',
    ErroreDriveCondiviso(:final stato) => 'Google Drive ha risposto $stato',
    CondivisoNonValido(:final motivo) => motivo,
    _ => '$e',
  };

  // ------------------------------------------------- fine della condivisione

  /// Fine della condivisione, scelta da qui. Il proprietario la chiude per
  /// tutti (registro "concluso", cartella nel cestino di Drive); un membro
  /// esce (lo scrive nel suo file). Il portafoglio resta qui come un
  /// portafoglio normale; le voci degli altri diventano "ex membro".
  Future<void> interrompi(String portafoglioId) async {
    final pc = await di(portafoglioId);
    if (pc == null) {
      return;
    }
    final client = await accesso.client();
    if (client == null) {
      throw const ErroreDriveCondiviso(401, 'Accesso a Google annullato.');
    }
    final drive = _creaDrive(client);
    try {
      await _chiudiSuDrive(drive, pc);
    } finally {
      drive.chiudi();
    }
    await _concludi(pc);
  }

  /// Su Drive: il proprietario chiude per tutti (registro "concluso",
  /// cartella nel cestino); un membro scrive nel suo file che è uscito.
  Future<void> _chiudiSuDrive(
    DriveCondiviso drive,
    PortafoglioCondiviso pc,
  ) async {
    if (pc.ruolo == RuoloMembro.proprietario) {
      if (pc.registroId.isNotEmpty) {
        await _scriviRegistro(drive, pc, concluso: true);
      }
      await drive.cestina(pc.cartellaId);
      return;
    }
    final mio = await io(pc);
    final fileId = pc.mioFileId;
    if (mio != null && fileId != null) {
      await drive.aggiorna(
        fileId,
        jsonEncode({
          ..._intestazioneFile(pc.portafoglioId, mio.id, _identita()),
          'uscito': true,
        }),
      );
    }
  }

  /// Da qui in poi è un portafoglio normale: le altre persone diventano
  /// "ex membro".
  Future<void> _concludi(PortafoglioCondiviso pc) => _db.transaction(() async {
    await (_db.update(
      _db.portafogliCondivisi,
    )..where((c) => c.id.equals(pc.id))).write(
      PortafogliCondivisiCompanion(
        eliminato: const Value(true),
        aggiornatoIl: Value(_orologio.adesso()),
      ),
    );
    for (final m in await membri(pc.portafoglioId)) {
      if (m.fileId != pc.mioFileId && m.stato != StatoMembro.uscito) {
        await (_db.update(_db.membri)..where((x) => x.id.equals(m.id))).write(
          MembriCompanion(
            stato: const Value(StatoMembro.uscito),
            aggiornatoIl: Value(_orologio.adesso()),
          ),
        );
      }
    }
  });

  Future<String> _nomePortafoglio(String portafoglioId) async =>
      (await (_db.select(
        _db.portafogli,
      )..where((p) => p.id.equals(portafoglioId))).getSingleOrNull())?.nome ??
      '';

  void _avvisa(String testo) {
    if (!_avvisi.isClosed) {
      _avvisi.add(testo);
    }
  }

  /// Il proprietario ha chiuso la condivisione (o non la si vede più).
  Future<void> _finita(PortafoglioCondiviso pc) async {
    await _concludi(pc);
    final nome = await _nomePortafoglio(pc.portafoglioId);
    _avvisa(
      'La condivisione di «${nome.isEmpty ? 'un portafoglio' : nome}» è '
      'finita: il proprietario l\'ha interrotta. Il portafoglio resta qui '
      'come un portafoglio normale; le voci degli altri sono segnate come '
      '«ex membro».',
    );
  }

  final Archivio _db;
  final Contabilita _contabilita;
  final Sodium _sodium;
  final IdentitaPersona Function() _identita;
  final DriveCondiviso Function(http.Client client) _creaDrive;
  final AccessoDriveFile accesso;

  static const formato = 1;
  static const nomeRegistro = 'wallecy_registro.json';
  static const _contestoRegistro = 'wallecy-registro-v1|';
  static const _contestoRiga = 'wallecy-riga-v1|';
  static const _contestoFile = 'wallecy-file-v1|';

  OrologioLogico get _orologio => _contabilita.orologio;

  /// Il file di una persona porta il nome del suo account Google
  /// (es. "wallecy_mario.rossi.json"): si capisce subito di chi è.
  static String nomeFilePersona(String email) {
    final nome = email
        .split('@')
        .first
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '_');
    return 'wallecy_${nome.isEmpty ? 'persona' : nome}.json';
  }

  static String nomeCartella(String nome, String id) {
    final pulito = nome
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final breve = pulito.length > 30 ? pulito.substring(0, 30) : pulito;
    return 'wallecy_share_${breve.isEmpty ? 'portafoglio' : breve}_'
        '${id.substring(0, 4)}';
  }

  // ------------------------------------------------------------ lettura

  /// I portafogli condivisi di questo archivio, con le persone.
  Stream<List<VistaCondiviso>> osserva() => _db
      .customSelect(
        'SELECT 1',
        readsFrom: {_db.portafogliCondivisi, _db.membri, _db.portafogli},
      )
      .watch()
      .asyncMap((_) async {
        final elenco = await (_db.select(
          _db.portafogliCondivisi,
        )..where((c) => c.eliminato.equals(false))).get();
        final membri = await (_db.select(
          _db.membri,
        )..where((m) => m.eliminato.equals(false))).get();
        final portafogli = {
          for (final p in await _db.select(_db.portafogli).get()) p.id: p,
        };
        return [
          for (final c in elenco)
            // Un portafoglio eliminato qui non è più nell'elenco (la sua
            // condivisione si chiude al prossimo giro).
            if (portafogli[c.portafoglioId]?.eliminato != true)
              (
                info: c,
                nome: portafogli[c.portafoglioId]?.nome ?? '',
                membri: [
                  for (final m in membri)
                    if (m.portafoglioId == c.portafoglioId) m,
                ],
              ),
        ];
      });

  Future<PortafoglioCondiviso?> di(String portafoglioId) async =>
      (await (_db.select(_db.portafogliCondivisi)..where(
                (c) =>
                    c.portafoglioId.equals(portafoglioId) &
                    c.eliminato.equals(false),
              ))
              .get())
          .firstOrNull;

  Future<List<Membro>> membri(String portafoglioId) =>
      (_db.select(_db.membri)..where(
            (m) =>
                m.portafoglioId.equals(portafoglioId) &
                m.eliminato.equals(false),
          ))
          .get();

  /// Io in quel portafoglio (la persona con il mio file).
  Future<Membro?> io(PortafoglioCondiviso pc) async =>
      (await membri(pc.portafoglioId))
          .where((m) => m.fileId == pc.mioFileId)
          .firstOrNull;

  /// Codice di sicurezza tra me e [altro] (vuoto se non ha ancora le chiavi).
  String? codiceSicurezza(Membro altro) {
    final scambio = altro.chiaveScambio;
    final firma = altro.chiaveFirma;
    if (scambio == null || firma == null) {
      return null;
    }
    final io = _identita();
    return IdentitaPersona.codiceSicurezza(
      _sodium,
      (scambio: io.pubblicaScambio, firma: io.pubblicaFirma),
      (scambio: base64.decode(scambio), firma: base64.decode(firma)),
    );
  }

  /// I codici coincidono sui due schermi.
  Future<void> segnaVerificato(String membroId) =>
      (_db.update(_db.membri)..where((m) => m.id.equals(membroId))).write(
        MembriCompanion(
          verificato: const Value(true),
          aggiornatoIl: Value(_orologio.adesso()),
        ),
      );

  // ------------------------------------------------------------- invito

  /// Invita [email] nel portafoglio: alla prima volta prepara cartella,
  /// registro e il file del proprietario; poi il file della persona e la
  /// condivisione della cartella (Google le manda un'email).
  Future<EsitoInvito> invita(String portafoglioId, String email) async {
    final indirizzo = email.trim().toLowerCase();
    final client = await accesso.client();
    if (client == null) {
      return EsitoInvito.annullato;
    }
    final drive = _creaDrive(client);
    try {
      final pc =
          await di(portafoglioId) ??
          await _primaCondivisione(drive, portafoglioId);
      _ciSono();
      final presenti = await membri(portafoglioId);
      final gia = presenti
          .where((m) => m.email == indirizzo && m.stato != StatoMembro.uscito)
          .firstOrNull;
      if (gia?.ruolo == RuoloMembro.proprietario) {
        return EsitoInvito.seiTu;
      }
      if (gia != null && gia.stato == StatoMembro.attivo) {
        return EsitoInvito.giaPresente;
      }
      if (gia != null) {
        // Già invitata ma non entrata (email persa, invito interrotto o
        // scaduto): la condivisione si rifà e ricomincia l'ora per accettare.
        final scadenza = _adesso().add(durataInvito);
        await drive.condividi(
          pc.cartellaId,
          indirizzo,
          messaggio: await _messaggioInvito(pc, gia.fileId, scadenza),
        );
        await (_db.update(_db.membri)..where((m) => m.id.equals(gia.id))).write(
          MembriCompanion(
            stato: const Value(StatoMembro.invitato),
            invitatoIl: Value(_adesso().toUtc().toIso8601String()),
            aggiornatoIl: Value(_orologio.adesso()),
          ),
        );
        await _scriviRegistro(drive, pc);
        return EsitoInvito.rimandato;
      }
      final id = nuovoId();
      final fileId = await drive.creaFile(
        pc.cartellaId,
        nomeFilePersona(indirizzo),
        jsonEncode({
          'formato': formato,
          'portafoglio': portafoglioId,
          'membro': id,
        }),
      );
      // Prima la condivisione su Drive, poi la persona qui: se l'invito si
      // interrompe, non resta una persona "da confermare" senza cartella.
      await drive.condividi(
        pc.cartellaId,
        indirizzo,
        messaggio: await _messaggioInvito(
          pc,
          fileId,
          _adesso().add(durataInvito),
        ),
      );
      await _db
          .into(_db.membri)
          .insert(
            MembriCompanion.insert(
              id: id,
              aggiornatoIl: _orologio.adesso(),
              portafoglioId: portafoglioId,
              email: indirizzo,
              ruolo: RuoloMembro.membro,
              stato: StatoMembro.invitato,
              fileId: Value(fileId),
              invitatoIl: Value(_adesso().toUtc().toIso8601String()),
            ),
          );
      await _scriviRegistro(drive, pc);
      return EsitoInvito.invitato;
    } finally {
      drive.chiudi();
    }
  }

  /// Il messaggio dell'email di Google: il link d'invito e, se non apre
  /// WalleCy, come entrare a mano.
  Future<String> _messaggioInvito(
    PortafoglioCondiviso pc,
    String? fileId,
    DateTime scadenza,
  ) async {
    final invito = await _invito(pc, fileId, scadenza);
    final ora = scadenza.toLocal();
    final hh = ora.hour.toString().padLeft(2, '0');
    final mm = ora.minute.toString().padLeft(2, '0');
    return 'Ti ho invitato al portafoglio condiviso «${invito.portafoglio}» '
        'di WalleCy. Hai tempo fino alle $hh:$mm. Dal telefono con WalleCy '
        'apri questo link: ${invito.link} . Se non funziona: apri WalleCy, '
        'Impostazioni, Portafogli condivisi, «Unisciti», poi in «Condivisi '
        'con me» apri questa cartella e scegli tutti i file.';
  }

  Future<InvitoCondiviso> _invito(
    PortafoglioCondiviso pc,
    String? fileId,
    DateTime? scadenza,
  ) async {
    final p = await (_db.select(
      _db.portafogli,
    )..where((x) => x.id.equals(pc.portafoglioId))).getSingleOrNull();
    final proprietario = (await membri(pc.portafoglioId))
        .where((m) => m.ruolo == RuoloMembro.proprietario)
        .firstOrNull;
    return InvitoCondiviso(
      cartellaId: pc.cartellaId,
      registroId: pc.registroId,
      fileId: fileId,
      fileProprietario: proprietario?.fileId,
      portafoglio: p?.nome ?? '',
      da: proprietario?.email ?? '',
      scadenza: scadenza,
    );
  }

  /// Il link d'invito per [m], da copiare in un messaggio (WhatsApp, SMS).
  Future<InvitoCondiviso?> invitoPer(String portafoglioId, Membro m) async {
    final pc = await di(portafoglioId);
    if (pc == null || pc.registroId.isEmpty) {
      return null;
    }
    return _invito(pc, m.fileId, scadenzaDi(m));
  }

  // ------------------------------------------------------ inviti ricevuti

  static const _chiaveInviti = 'condivisi.inviti';

  /// Gli inviti arrivati con un link e non ancora accettati ("Nuovi inviti").
  Stream<List<InvitoCondiviso>> osservaInviti() =>
      (_db.select(_db.impostazioni)
            ..where((i) => i.chiave.equals(_chiaveInviti)))
          .watch()
          .map((righe) => _leggiInviti(righe.firstOrNull?.valore));

  static List<InvitoCondiviso> _leggiInviti(String? json) {
    if (json == null) {
      return const [];
    }
    try {
      return [
        for (final v in (jsonDecode(json) as List).cast<Map<String, Object?>>())
          ?InvitoCondiviso.daMappa(v),
      ];
    } on Object {
      return const [];
    }
  }

  Future<List<InvitoCondiviso>> _inviti() async => _leggiInviti(
    (await (_db.select(
      _db.impostazioni,
    )..where((i) => i.chiave.equals(_chiaveInviti))).getSingleOrNull())?.valore,
  );

  Future<void> _salvaInviti(List<InvitoCondiviso> inviti) => _db
      .into(_db.impostazioni)
      .insertOnConflictUpdate(
        ImpostazioniCompanion.insert(
          chiave: _chiaveInviti,
          valore: jsonEncode([for (final i in inviti) i.toJson()]),
        ),
      );

  /// Un invito arrivato con un link. `false` se è di un portafoglio in cui
  /// si è già entrati.
  Future<bool> aggiungiInvito(InvitoCondiviso invito) async {
    final gia = await (_db.select(
      _db.portafogliCondivisi,
    )..where((c) => c.registroId.equals(invito.registroId))).get();
    if (gia.isNotEmpty) {
      return false;
    }
    await _salvaInviti([
      for (final i in await _inviti())
        if (i.registroId != invito.registroId) i,
      invito,
    ]);
    return true;
  }

  Future<void> togliInvito(String registroId) async => _salvaInviti([
    for (final i in await _inviti())
      if (i.registroId != registroId) i,
  ]);

  Future<PortafoglioCondiviso> _primaCondivisione(
    DriveCondiviso drive,
    String portafoglioId,
  ) async {
    final p = await (_db.select(
      _db.portafogli,
    )..where((p) => p.id.equals(portafoglioId))).getSingle();
    final cartella = await drive.cartellaDentroWalleCy(
      nomeCartella(p.nome, p.id),
    );
    final io = _identita();
    final mioId = nuovoId();
    final email = await drive.mioIndirizzo() ?? '';
    final mioFile = await drive.creaFile(
      cartella.id,
      nomeFilePersona(email),
      jsonEncode(_intestazioneFile(portafoglioId, mioId, io)),
    );
    final chiave = _sodium.randombytes.buf(Cifratore.lunghezzaChiave);
    await _db.transaction(() async {
      await _db
          .into(_db.portafogliCondivisi)
          .insert(
            PortafogliCondivisiCompanion.insert(
              id: nuovoId(),
              aggiornatoIl: _orologio.adesso(),
              portafoglioId: portafoglioId,
              ruolo: RuoloMembro.proprietario,
              cartellaId: cartella.id,
              registroId: '',
              mioFileId: Value(mioFile),
              chiave: base64.encode(chiave),
            ),
          );
      await _db
          .into(_db.membri)
          .insert(
            MembriCompanion.insert(
              id: mioId,
              aggiornatoIl: _orologio.adesso(),
              portafoglioId: portafoglioId,
              email: email,
              ruolo: RuoloMembro.proprietario,
              stato: StatoMembro.attivo,
              fileId: Value(mioFile),
              chiaveScambio: Value(base64.encode(io.pubblicaScambio)),
              chiaveFirma: Value(base64.encode(io.pubblicaFirma)),
              verificato: const Value(true),
            ),
          );
    });
    final pc = (await di(portafoglioId))!;
    await _scriviRegistro(drive, pc);
    return (await di(portafoglioId))!;
  }

  Map<String, Object?> _intestazioneFile(
    String portafoglioId,
    String membroId,
    IdentitaPersona io,
  ) => {
    'formato': formato,
    'portafoglio': portafoglioId,
    'membro': membroId,
    'scambio': base64.encode(io.pubblicaScambio),
    'firma': base64.encode(io.pubblicaFirma),
  };

  /// Il registro dalle persone locali, firmato dal proprietario. La chiave
  /// del portafoglio è sigillata per ogni persona che ha già le chiavi.
  Future<void> _scriviRegistro(
    DriveCondiviso drive,
    PortafoglioCondiviso pc, {
    bool concluso = false,
  }) async {
    final chiave = base64.decode(pc.chiave);
    var versione = 1;
    if (pc.registroId.isNotEmpty) {
      try {
        final vecchio = jsonDecode(await drive.leggi(pc.registroId));
        versione = ((vecchio as Map)['versione'] as int? ?? 0) + 1;
      } on Object {
        // Registro illeggibile: si riparte.
      }
    }
    final contenuto = {
      'formato': formato,
      'portafoglio': pc.portafoglioId,
      'versione': versione,
      if (concluso) 'concluso': true,
      'membri': [
        for (final m in await membri(pc.portafoglioId))
          {
            'id': m.id,
            'email': m.email,
            'ruolo': m.ruolo,
            'stato': m.stato,
            'file': m.fileId,
            'scambio': m.chiaveScambio,
            'firma': m.chiaveFirma,
            'chiave': m.chiaveScambio == null || m.stato != StatoMembro.attivo
                ? null
                : base64.encode(
                    IdentitaPersona.sigillaPer(
                      _sodium,
                      segreto: chiave,
                      pubblicaScambio: base64.decode(m.chiaveScambio!),
                    ),
                  ),
          },
      ],
    };
    final firma = _identita().firma(
      Uint8List.fromList(
        utf8.encode('$_contestoRegistro${canonico(contenuto)}'),
      ),
    );
    final testo = jsonEncode({
      ...contenuto,
      'firmaRegistro': base64.encode(firma),
    });
    if (pc.registroId.isEmpty) {
      final id = await drive.scrivi(pc.cartellaId, nomeRegistro, testo);
      await (_db.update(
        _db.portafogliCondivisi,
      )..where((c) => c.id.equals(pc.id))).write(
        PortafogliCondivisiCompanion(
          registroId: Value(id),
          aggiornatoIl: Value(_orologio.adesso()),
        ),
      );
    } else {
      await drive.aggiorna(pc.registroId, testo);
    }
  }

  /// Legge e verifica il registro: firmato dal proprietario, con la chiave
  /// del proprietario già nota (se c'è) uguale a quella del registro.
  Map<String, Object?> _verificaRegistro(String testo, {Membro? proprietario}) {
    final json = jsonDecode(testo) as Map<String, Object?>;
    final firma = json.remove('firmaRegistro');
    if (json['formato'] != formato || firma is! String) {
      throw const CondivisoNonValido('formato del registro');
    }
    final voci = (json['membri'] as List<Object?>? ?? const [])
        .cast<Map<String, Object?>>();
    final suo = voci
        .where((m) => m['ruolo'] == RuoloMembro.proprietario)
        .firstOrNull;
    final chiaveFirma = suo?['firma'];
    if (chiaveFirma is! String) {
      throw const CondivisoNonValido('registro senza proprietario');
    }
    if (proprietario?.chiaveFirma != null &&
        proprietario!.chiaveFirma != chiaveFirma) {
      throw const CondivisoNonValido(
        'la chiave del proprietario è cambiata: possibile intromissione',
      );
    }
    final valida = IdentitaPersona.firmaValida(
      _sodium,
      messaggio: Uint8List.fromList(
        utf8.encode('$_contestoRegistro${canonico(json)}'),
      ),
      firma: base64.decode(firma),
      pubblicaFirma: base64.decode(chiaveFirma),
    );
    if (!valida) {
      throw const CondivisoNonValido('firma del registro');
    }
    return json;
  }

  // ------------------------------------------------------------ ingresso

  /// Il membro sceglie i file della cartella condivisa (finestra di Google),
  /// pubblica le sue chiavi nel proprio file e aspetta la chiave del
  /// portafoglio dal proprietario.
  /// Con [invito] la finestra di Google prova a mostrare solo i file
  /// giusti (registro e il proprio file); se non ci riesce, si sceglie a
  /// mano come sempre.
  Future<EsitoIngresso> unisciti({InvitoCondiviso? invito}) async {
    final ElementiScelti scelta;
    try {
      scelta = await accesso.scegli(soloId: invito?.daScegliere ?? const []);
    } on SceltaAnnullata {
      return EsitoIngresso.annullato;
    }
    final drive = _creaDrive(scelta.client);
    try {
      String? registroId;
      String? cartellaId;
      for (final id in scelta.scelti) {
        final info = await drive.info(id);
        if (info.cartella) {
          cartellaId ??= id;
        } else {
          if (info.nome == nomeRegistro) {
            registroId = id;
          }
          cartellaId ??= info.padri.firstOrNull;
        }
      }
      if (registroId == null && cartellaId != null) {
        registroId = await drive.trovaFile(cartellaId, nomeRegistro);
      }
      if (registroId == null || cartellaId == null) {
        return EsitoIngresso.nessunRegistro;
      }
      final registro = _verificaRegistro(await drive.leggi(registroId));
      final portafoglioId = registro['portafoglio']! as String;
      final mia = await drive.mioIndirizzo();
      final voci = (registro['membri']! as List<Object?>)
          .cast<Map<String, Object?>>();
      final voce = voci
          .where((m) => m['email'] == mia && m['ruolo'] == RuoloMembro.membro)
          .firstOrNull;
      final mioFile = voce?['file'];
      if (voce == null || mioFile is! String) {
        return EsitoIngresso.nonInvitato;
      }
      if (voce['stato'] == StatoMembro.scaduto) {
        return EsitoIngresso.scaduto;
      }
      final io = _identita();
      try {
        await drive.aggiorna(
          mioFile,
          jsonEncode(
            _intestazioneFile(portafoglioId, voce['id']! as String, io),
          ),
        );
      } on ErroreDriveCondiviso {
        // L'app vede solo i file scelti: manca il proprio.
        return EsitoIngresso.fileMancanti;
      }
      if (await di(portafoglioId) == null) {
        await _db
            .into(_db.portafogliCondivisi)
            .insert(
              PortafogliCondivisiCompanion.insert(
                id: nuovoId(),
                aggiornatoIl: _orologio.adesso(),
                portafoglioId: portafoglioId,
                ruolo: RuoloMembro.membro,
                cartellaId: cartellaId,
                registroId: registroId,
                mioFileId: Value(mioFile),
                chiave: '',
              ),
            );
      }
      final pc = (await di(portafoglioId))!;
      _ciSono();
      await _aggiornaMembri(pc, registro, mieChiavi: io);
      await togliInvito(pc.registroId);
      await _sincronizzaUno(drive, pc);
      return (await di(portafoglioId))!.chiave.isEmpty
          ? EsitoIngresso.inAttesa
          : EsitoIngresso.entrato;
    } finally {
      drive.chiudi();
    }
  }

  /// Il portafoglio non arriva perché manca l'accesso a qualche file (es. il
  /// file del proprietario non scelto all'ingresso): la finestra di Google
  /// mostra i file del portafoglio, poi si sincronizza. `entrato` se ora il
  /// portafoglio c'è.
  Future<EsitoIngresso> completaIngresso(String portafoglioId) async {
    final pc = await di(portafoglioId);
    if (pc == null) {
      return EsitoIngresso.annullato;
    }
    final persone = await membri(portafoglioId);
    final ElementiScelti scelta;
    try {
      scelta = await accesso.scegli(
        soloId: [
          pc.registroId,
          ?pc.mioFileId,
          for (final m in persone)
            if (m.fileId != null &&
                m.fileId != pc.mioFileId &&
                m.stato == StatoMembro.attivo)
              m.fileId!,
        ],
      );
    } on SceltaAnnullata {
      return EsitoIngresso.annullato;
    }
    final drive = _creaDrive(scelta.client);
    try {
      await _sincronizzaUno(drive, pc);
    } finally {
      drive.chiudi();
    }
    final arrivato = await (_db.select(
      _db.portafogli,
    )..where((p) => p.id.equals(portafoglioId))).getSingleOrNull();
    return arrivato == null
        ? EsitoIngresso.fileMancanti
        : EsitoIngresso.entrato;
  }

  /// Le persone del registro, nell'archivio del membro.
  Future<void> _aggiornaMembri(
    PortafoglioCondiviso pc,
    Map<String, Object?> registro, {
    IdentitaPersona? mieChiavi,
  }) async {
    final locali = {for (final m in await membri(pc.portafoglioId)) m.id: m};
    for (final v
        in (registro['membri']! as List<Object?>)
            .cast<Map<String, Object?>>()) {
      final id = v['id']! as String;
      final mio = v['file'] == pc.mioFileId;
      final scambio = mio && mieChiavi != null
          ? base64.encode(mieChiavi.pubblicaScambio)
          : v['scambio'] as String?;
      final firma = mio && mieChiavi != null
          ? base64.encode(mieChiavi.pubblicaFirma)
          : v['firma'] as String?;
      final locale = locali[id];
      final dati = MembriCompanion(
        email: Value(v['email'] as String? ?? ''),
        ruolo: Value(v['ruolo'] as String? ?? RuoloMembro.membro),
        stato: Value(v['stato'] as String? ?? StatoMembro.invitato),
        fileId: Value(v['file'] as String?),
        chiaveScambio: Value(scambio ?? locale?.chiaveScambio),
        chiaveFirma: Value(firma ?? locale?.chiaveFirma),
      );
      if (locale == null) {
        await _db
            .into(_db.membri)
            .insert(
              dati.copyWith(
                id: Value(id),
                aggiornatoIl: Value(_orologio.adesso()),
                portafoglioId: Value(pc.portafoglioId),
                verificato: Value(mio),
              ),
            );
      } else if (locale.stato != dati.stato.value ||
          locale.chiaveScambio != dati.chiaveScambio.value ||
          locale.chiaveFirma != dati.chiaveFirma.value ||
          locale.fileId != dati.fileId.value) {
        await (_db.update(_db.membri)..where((m) => m.id.equals(id))).write(
          dati.copyWith(aggiornatoIl: Value(_orologio.adesso())),
        );
      }
    }
  }

  // ------------------------------------------------------ sincronizzazione

  Future<void>? _giro;
  Future<void>? _ancora;
  bool _ancoraInterattivo = false;

  /// Un giro su tutti i portafogli condivisi. Senza [interattivo] non chiede
  /// niente a Google: se manca il consenso, salta (e [stato] lo dice).
  ///
  /// Un giro alla volta: se ne arriva un altro mentre uno è in corso, si fa
  /// subito dopo (uno solo, anche se lo chiedono in tanti).
  Future<void> sincronizza({bool interattivo = false}) {
    final inCorso = _giro;
    if (inCorso != null) {
      _ancoraInterattivo |= interattivo;
      return _ancora ??= inCorso.then((_) {
        final i = _ancoraInterattivo;
        _ancora = null;
        _ancoraInterattivo = false;
        return sincronizza(interattivo: i);
      });
    }
    final giro = _sincronizzaTutti(interattivo: interattivo);
    _giro = giro;
    giro.whenComplete(() => _giro = null).ignore();
    return giro;
  }

  Future<void> _sincronizzaTutti({required bool interattivo}) async {
    try {
      final elenco = await (_db.select(
        _db.portafogliCondivisi,
      )..where((c) => c.eliminato.equals(false))).get();
      if (elenco.isEmpty) {
        _imposta(const StatoCondivisi(FaseCondivisi.nessuno));
        return;
      }
      final ultima = stato.value.ultima;
      final http.Client? client;
      try {
        client = await accesso.client(interattivo: interattivo);
      } on Object catch (e) {
        // Google non raggiungibile o consenso tolto: si riprova al prossimo
        // giro.
        debugPrint('Portafogli condivisi: accesso a Google non riuscito: $e');
        _imposta(
          StatoCondivisi(
            FaseCondivisi.errore,
            ultima: ultima,
            messaggio: _leggibile(e),
          ),
        );
        return;
      }
      if (client == null) {
        _imposta(
          StatoCondivisi(FaseCondivisi.accessoRichiesto, ultima: ultima),
        );
        return;
      }
      final drive = _creaDrive(client);
      final problemi = <String>[];
      try {
        for (final pc in elenco) {
          try {
            await _sincronizzaUno(drive, pc);
          } on Object catch (e) {
            // Un portafoglio con problemi non ferma gli altri; i suoi file si
            // rileggono tutti al prossimo giro.
            _versioni.clear();
            debugPrint('Portafoglio condiviso ${pc.portafoglioId}: $e');
            final nome = await _nomePortafoglio(pc.portafoglioId);
            problemi.add('«$nome»: ${_leggibile(e)}');
          }
        }
      } finally {
        drive.chiudi();
      }
      _imposta(
        problemi.isEmpty
            ? StatoCondivisi(FaseCondivisi.aggiornati, ultima: _adesso())
            : StatoCondivisi(
                FaseCondivisi.errore,
                ultima: ultima,
                messaggio: problemi.join('\n'),
              ),
      );
    } on Object catch (e) {
      // Archivio bloccato a metà giro: si riprende allo sblocco.
      debugPrint('Portafogli condivisi: giro interrotto: $e');
    }
  }

  Future<void> _sincronizzaUno(
    DriveCondiviso drive,
    PortafoglioCondiviso pc,
  ) async {
    final proprietario = pc.ruolo == RuoloMembro.proprietario;
    // 0. Portafoglio eliminato qui (anche con una versione precedente
    // dell'app): la condivisione finisce, come con "Interrompi".
    final locale = await (_db.select(
      _db.portafogli,
    )..where((p) => p.id.equals(pc.portafoglioId))).getSingleOrNull();
    if (locale != null && locale.eliminato) {
      await _chiudiSuDrive(drive, pc);
      await _concludi(pc);
      return;
    }
    var persone = await membri(pc.portafoglioId);
    // 1. Registro: il membro aggiorna le persone e prende la sua chiave.
    if (!proprietario && pc.registroId.isNotEmpty) {
      final String? testo;
      try {
        testo = await _leggiSeCambiato(drive, pc.registroId);
      } on ErroreDriveCondiviso catch (e) {
        if (e.stato == 403 || e.stato == 404) {
          // La cartella non è più condivisa (o è stata eliminata).
          await _finita(pc);
          return;
        }
        rethrow;
      }
      if (testo != null) {
        await _dalRegistro(pc, testo, persone);
        final aggiornato = await di(pc.portafoglioId);
        if (aggiornato == null) {
          return; // condivisione conclusa dal proprietario
        }
        pc = aggiornato;
        persone = await membri(pc.portafoglioId);
      }
    }
    await _passiSuccessivi(drive, pc, persone, proprietario: proprietario);
  }

  /// Il registro cambiato (membro): persone, fine della condivisione e la
  /// propria chiave del portafoglio.
  Future<void> _dalRegistro(
    PortafoglioCondiviso pc,
    String testo,
    List<Membro> persone,
  ) async {
    final registro = _verificaRegistro(
      testo,
      proprietario: persone
          .where((m) => m.ruolo == RuoloMembro.proprietario)
          .firstOrNull,
    );
    if (registro['concluso'] == true) {
      await _finita(pc);
      return;
    }
    await _aggiornaMembri(pc, registro);
    if (pc.chiave.isEmpty) {
      final mia = (registro['membri']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .where((m) => m['file'] == pc.mioFileId)
          .firstOrNull;
      final sigillata = mia?['chiave'];
      if (sigillata is String) {
        final chiave = _identita().apri(base64.decode(sigillata));
        await (_db.update(
          _db.portafogliCondivisi,
        )..where((c) => c.id.equals(pc.id))).write(
          PortafogliCondivisiCompanion(
            chiave: Value(base64.encode(chiave)),
            aggiornatoIl: Value(_orologio.adesso()),
          ),
        );
      }
    }
  }

  Future<void> _passiSuccessivi(
    DriveCondiviso drive,
    PortafoglioCondiviso pc,
    List<Membro> persone, {
    required bool proprietario,
  }) async {
    // 2. Proprietario: chi ha pubblicato le chiavi diventa attivo.
    if (proprietario) {
      var cambiato = false;
      for (final m in persone.where((m) => m.stato == StatoMembro.invitato)) {
        final fileId = m.fileId;
        if (fileId == null) {
          continue;
        }
        final Map<String, Object?> file;
        try {
          final testo = await _leggiSeCambiato(drive, fileId);
          if (testo == null) {
            continue;
          }
          file = jsonDecode(testo) as Map<String, Object?>;
        } on ErroreDriveCondiviso {
          continue;
        }
        final scambio = file['scambio'];
        final firma = file['firma'];
        if (scambio is String && firma is String) {
          await (_db.update(_db.membri)..where((x) => x.id.equals(m.id))).write(
            MembriCompanion(
              chiaveScambio: Value(scambio),
              chiaveFirma: Value(firma),
              stato: const Value(StatoMembro.attivo),
              aggiornatoIl: Value(_orologio.adesso()),
            ),
          );
          cambiato = true;
        }
      }
      // Chi non ha risposto entro un'ora: invito scaduto, cartella non più
      // condivisa, avviso al proprietario. Si può invitare di nuovo.
      final ora = _adesso();
      for (final m in await membri(pc.portafoglioId)) {
        final scadenza = scadenzaInvito(m);
        if (scadenza == null || ora.isBefore(scadenza)) {
          continue;
        }
        try {
          await drive.togliCondivisione(pc.cartellaId, m.email);
        } on ErroreDriveCondiviso catch (e) {
          debugPrint('Condivisione non tolta a ${m.email}: $e');
        }
        await (_db.update(_db.membri)..where((x) => x.id.equals(m.id))).write(
          MembriCompanion(
            stato: const Value(StatoMembro.scaduto),
            aggiornatoIl: Value(_orologio.adesso()),
          ),
        );
        cambiato = true;
        final nome =
            (await (_db.select(_db.portafogli)
                      ..where((p) => p.id.equals(pc.portafoglioId)))
                    .getSingleOrNull())
                ?.nome ??
            '';
        if (!_avvisi.isClosed) {
          _avvisi.add(
            'La condivisione di «$nome» con ${m.email} non è riuscita: '
            'nessuna risposta entro un\'ora. Il portafoglio funziona '
            'normalmente; puoi invitarla di nuovo quando vuoi con «Invita di '
            'nuovo», nella scheda del portafoglio.',
          );
        }
      }
      if (cambiato) {
        await _scriviRegistro(drive, pc);
        persone = await membri(pc.portafoglioId);
      }
    }
    if (pc.chiave.isEmpty) {
      return; // in attesa della chiave
    }
    final chiave = SecureKey.fromList(_sodium, base64.decode(pc.chiave));
    try {
      // 3. Le righe degli altri (e delle mie altre copie): prima il file del
      // proprietario, che porta anche il portafoglio.
      final ordinate = [
        ...persone.where((m) => m.ruolo == RuoloMembro.proprietario),
        ...persone.where((m) => m.ruolo != RuoloMembro.proprietario),
      ];
      for (final m in ordinate) {
        final fileId = m.fileId;
        if (fileId == null || m.stato == StatoMembro.invitato) {
          continue;
        }
        try {
          final testo = await _leggiSeCambiato(drive, fileId);
          if (testo == null) {
            continue; // non è cambiato dall'ultimo giro
          }
          final file = jsonDecode(testo) as Map<String, Object?>;
          // Un membro è uscito: resta "ex membro", la cartella non gli è
          // più condivisa.
          if (proprietario &&
              file['uscito'] == true &&
              m.stato == StatoMembro.attivo) {
            await (_db.update(
              _db.membri,
            )..where((x) => x.id.equals(m.id))).write(
              MembriCompanion(
                stato: const Value(StatoMembro.uscito),
                aggiornatoIl: Value(_orologio.adesso()),
              ),
            );
            try {
              await drive.togliCondivisione(pc.cartellaId, m.email);
            } on ErroreDriveCondiviso catch (e) {
              debugPrint('Condivisione non tolta a ${m.email}: $e');
            }
            await _scriviRegistro(drive, pc);
            final nome = await _nomePortafoglio(pc.portafoglioId);
            _avvisa(
              '${m.email} è uscito da «$nome». Le sue voci restano, segnate '
              'come «ex membro».',
            );
          }
          final dati = file['dati'];
          if (dati is! String) {
            continue;
          }
          final chiaro = Cifratore(_sodium).decifra(
            base64.decode(dati),
            chiave,
            aad: _aadFile(pc.portafoglioId, m.id),
          );
          final righe =
              ((jsonDecode(utf8.decode(chiaro)) as Map)['righe'] as List)
                  .cast<Map<String, Object?>>();
          _rimandato = false;
          await _unisci(pc, righe, persone);
          if (_rimandato) {
            _versioni.remove(fileId);
          }
        } on ErroreDriveCondiviso {
          // File non (ancora) accessibile: le sue righe arrivano dal
          // proprietario, che ricopia tutto.
        }
      }
      // 4. Le mie modifiche e il mio file.
      final mio = persone.where((m) => m.fileId == pc.mioFileId).firstOrNull;
      if (mio != null) {
        await _pubblica(pc, mio, persone);
        await _scriviMioFile(drive, pc, mio, chiave);
      }
    } finally {
      chiave.dispose();
    }
  }

  static Uint8List _aadFile(String portafoglioId, String membroId) =>
      Uint8List.fromList(utf8.encode('$_contestoFile$portafoglioId|$membroId'));

  Future<void> _scriviMioFile(
    DriveCondiviso drive,
    PortafoglioCondiviso pc,
    Membro mio,
    SecureKey chiave,
  ) async {
    final righe =
        await (_db.select(_db.righeCondivise)
              ..where((r) => r.portafoglioId.equals(pc.portafoglioId))
              ..orderBy([(r) => OrderingTerm(expression: r.id)]))
            .get();
    final elenco = [
      for (final r in righe)
        {
          'contenuto': r.contenuto,
          'firma': r.firma,
          'firmatario': r.firmatario,
        },
    ];
    final impronta = sha256.convert(utf8.encode(jsonEncode(elenco))).toString();
    final chiaveImpronta = 'condivisi.scritto.${pc.portafoglioId}';
    final scritta = await (_db.select(
      _db.impostazioni,
    )..where((i) => i.chiave.equals(chiaveImpronta))).getSingleOrNull();
    if (scritta?.valore == impronta) {
      return;
    }
    final cifrato = Cifratore(_sodium).cifra(
      Uint8List.fromList(utf8.encode(jsonEncode({'righe': elenco}))),
      chiave,
      aad: _aadFile(pc.portafoglioId, mio.id),
    );
    await drive.aggiorna(
      pc.mioFileId!,
      jsonEncode({
        ..._intestazioneFile(pc.portafoglioId, mio.id, _identita()),
        'dati': base64.encode(cifrato),
      }),
    );
    await _db
        .into(_db.impostazioni)
        .insertOnConflictUpdate(
          ImpostazioniCompanion.insert(
            chiave: chiaveImpronta,
            valore: impronta,
          ),
        );
  }

  // ----------------------------------------------------------- righe

  /// Le modifiche fatte qui (righe con un orologio diverso da quello
  /// registrato) diventano righe firmate da me.
  Future<void> _pubblica(
    PortafoglioCondiviso pc,
    Membro mio,
    List<Membro> persone,
  ) async {
    final w = pc.portafoglioId;
    final proprietario = pc.ruolo == RuoloMembro.proprietario;
    final registrate = {
      for (final r in await (_db.select(
        _db.righeCondivise,
      )..where((r) => r.portafoglioId.equals(w))).get())
        r.rigaId: r,
    };
    final albero = AlberoCategorie(await _db.select(_db.categorie).get());
    final tipi = {
      for (final t in await _db.select(_db.definizioniTipo).get()) t.id: t,
    };

    // Il portafoglio: solo il proprietario.
    final portafoglio = await (_db.select(
      _db.portafogli,
    )..where((p) => p.id.equals(w))).getSingleOrNull();
    if (proprietario && portafoglio != null) {
      final r = registrate[w];
      if (r == null || r.rigaAggiornataIl != portafoglio.aggiornatoIl) {
        await _firmaERegistra(pc, mio, w, 'portafoglio', {
          'tipo': 'portafoglio',
          'id': w,
          'portafoglio': w,
          'h': portafoglio.aggiornatoIl,
          'eliminato': portafoglio.eliminato,
          'nome': portafoglio.nome,
          'tipoNome': tipi[portafoglio.tipoId]?.nome,
          'valuta': portafoglio.valuta,
          'saldoIniziale': portafoglio.saldoInizialeMinimo,
          'modificatoDa': mio.id,
        }, portafoglio.aggiornatoIl);
      }
    }

    // I movimenti del portafoglio (anche i trasferimenti da o verso).
    final movimenti =
        await (_db.select(_db.movimenti)..where(
              (m) =>
                  m.portafoglioId.equals(w) |
                  m.portafoglioDestinazioneId.equals(w),
            ))
            .get();
    final presenti = <String>{};
    for (final m in movimenti) {
      presenti.add(m.id);
      final r = registrate[m.id];
      if (r != null && r.rigaAggiornataIl == m.aggiornatoIl) {
        continue;
      }
      final autore = r == null
          ? mio.id
          : (jsonDecode(r.contenuto) as Map)['inseritoDa'] as String? ?? mio.id;
      if (autore != mio.id && !proprietario) {
        continue; // non è mia: la cambia solo l'autore o il proprietario
      }
      final effetto = tipi[m.tipoId]?.effetto;
      final versoCondiviso = effetto == EffettoSaldo.trasferimento
          ? (m.portafoglioId == w ? EffettoSaldo.uscita : EffettoSaldo.entrata)
          : effetto ?? EffettoSaldo.uscita;
      await _firmaERegistra(pc, mio, m.id, 'movimento', {
        'tipo': 'movimento',
        'id': m.id,
        'portafoglio': w,
        'h': m.aggiornatoIl,
        'eliminato': m.eliminato,
        'data': m.data,
        'importo': m.importoMinimo,
        'valuta': m.valuta,
        'effetto': versoCondiviso,
        'categoria': m.categoriaId == null
            ? null
            : albero.percorso(m.categoriaId!),
        'descrizione': m.descrizione,
        'inseritoDa': autore,
        'modificatoDa': mio.id,
      }, m.aggiornatoIl);
      if (m.inseritoDa != autore || m.modificatoDa != mio.id) {
        // Senza cambiare l'orologio: non è una modifica dell'utente.
        await (_db.update(
          _db.movimenti,
        )..where((x) => x.id.equals(m.id))).write(
          MovimentiCompanion(
            inseritoDa: Value(autore),
            modificatoDa: Value(mio.id),
          ),
        );
      }
    }
    // Movimenti usciti dal portafoglio (spostati altrove): per gli altri
    // sono eliminati.
    for (final r in registrate.values) {
      if (r.tipo != 'movimento' || presenti.contains(r.rigaId)) {
        continue;
      }
      final contenuto = jsonDecode(r.contenuto) as Map<String, Object?>;
      if (contenuto['eliminato'] == true) {
        continue;
      }
      if (contenuto['inseritoDa'] != mio.id && !proprietario) {
        continue;
      }
      final h = _orologio.adesso();
      await _firmaERegistra(pc, mio, r.rigaId, 'movimento', {
        ...contenuto,
        'h': h,
        'eliminato': true,
        'modificatoDa': mio.id,
      }, r.rigaAggiornataIl);
    }
  }

  Future<void> _firmaERegistra(
    PortafoglioCondiviso pc,
    Membro mio,
    String rigaId,
    String tipo,
    Map<String, Object?> contenuto,
    String rigaAggiornataIl,
  ) async {
    final testo = canonico(contenuto);
    final firma = _identita().firma(
      Uint8List.fromList(utf8.encode('$_contestoRiga$testo')),
    );
    await _db
        .into(_db.righeCondivise)
        .insertOnConflictUpdate(
          RigheCondiviseCompanion.insert(
            id: '${pc.portafoglioId}:$rigaId',
            aggiornatoIl: contenuto['h']! as String,
            portafoglioId: pc.portafoglioId,
            rigaId: rigaId,
            tipo: tipo,
            firmatario: mio.id,
            contenuto: testo,
            firma: base64.encode(firma),
            rigaAggiornataIl: rigaAggiornataIl,
          ),
        );
  }

  /// Unisce le righe arrivate da un file: firma valida, permesso giusto,
  /// orologio più recente di quello che c'è qui.
  Future<int> _unisci(
    PortafoglioCondiviso pc,
    List<Map<String, Object?>> righe,
    List<Membro> persone,
  ) async {
    final perId = {for (final m in persone) m.id: m};
    final proprietario = persone
        .where((m) => m.ruolo == RuoloMembro.proprietario)
        .firstOrNull;
    final valide = <(Map<String, Object?>, Map<String, Object?>)>[];
    for (final riga in righe) {
      final testo = riga['contenuto'];
      final firma = riga['firma'];
      final firmatario = perId[riga['firmatario']];
      final chiaveFirma = firmatario?.chiaveFirma;
      if (testo is! String || firma is! String) {
        continue;
      }
      if (chiaveFirma == null) {
        // Persona non ancora nota qui: si riprova al prossimo giro.
        _rimandato = true;
        continue;
      }
      final valida = IdentitaPersona.firmaValida(
        _sodium,
        messaggio: Uint8List.fromList(utf8.encode('$_contestoRiga$testo')),
        firma: base64.decode(firma),
        pubblicaFirma: base64.decode(chiaveFirma),
      );
      final contenuto = jsonDecode(testo) as Map<String, Object?>;
      if (!valida ||
          contenuto['portafoglio'] != pc.portafoglioId ||
          contenuto['modificatoDa'] != firmatario!.id) {
        continue;
      }
      valide.add((riga, contenuto));
    }
    // Prima il portafoglio, poi i movimenti.
    valide.sort(
      (a, b) => (a.$2['tipo'] == 'portafoglio' ? 0 : 1).compareTo(
        b.$2['tipo'] == 'portafoglio' ? 0 : 1,
      ),
    );
    var cambiate = 0;
    await _db.transaction(() async {
      for (final (riga, contenuto) in valide) {
        final rigaId = contenuto['id']! as String;
        final h = contenuto['h']! as String;
        final firmatario = riga['firmatario']! as String;
        final esistente =
            await (_db.select(_db.righeCondivise)
                  ..where((r) => r.id.equals('${pc.portafoglioId}:$rigaId')))
                .getSingleOrNull();
        if (esistente != null && esistente.aggiornatoIl.compareTo(h) >= 0) {
          continue;
        }
        final eProprietario = firmatario == proprietario?.id;
        if (contenuto['tipo'] == 'portafoglio') {
          if (!eProprietario || rigaId != pc.portafoglioId) {
            continue;
          }
        } else {
          final autore = esistente == null
              ? contenuto['inseritoDa']
              : (jsonDecode(esistente.contenuto) as Map)['inseritoDa'];
          if (contenuto['inseritoDa'] != autore ||
              (firmatario != autore && !eProprietario)) {
            continue;
          }
        }
        _orologio.ricevi(h);
        final locale = _orologio.adesso();
        if (contenuto['tipo'] == 'portafoglio') {
          await _applicaPortafoglio(contenuto, locale);
        } else if (!await _applicaMovimento(pc, contenuto, locale)) {
          _rimandato = true;
          continue; // il portafoglio non è ancora qui: al prossimo giro
        }
        await _db
            .into(_db.righeCondivise)
            .insertOnConflictUpdate(
              RigheCondiviseCompanion.insert(
                id: '${pc.portafoglioId}:$rigaId',
                aggiornatoIl: h,
                portafoglioId: pc.portafoglioId,
                rigaId: rigaId,
                tipo: contenuto['tipo']! as String,
                firmatario: firmatario,
                contenuto: riga['contenuto']! as String,
                firma: riga['firma']! as String,
                rigaAggiornataIl: locale,
              ),
            );
        cambiate++;
      }
    });
    return cambiate;
  }

  Future<void> _applicaPortafoglio(
    Map<String, Object?> c,
    String locale,
  ) async {
    final id = c['id']! as String;
    final tipi = await _contabilita.tipi(AmbitoTipo.portafoglio);
    final tipo =
        tipi.where((t) => t.nome == c['tipoNome']).firstOrNull ??
        tipi.where((t) => t.nome != tipoCartaDiCredito).firstOrNull;
    final esistente = await (_db.select(
      _db.portafogli,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    if (esistente == null) {
      final ordine = (await _db.select(_db.portafogli).get()).length;
      await _db
          .into(_db.portafogli)
          .insert(
            PortafogliCompanion.insert(
              id: id,
              aggiornatoIl: locale,
              tipoId: tipo!.id,
              nome: c['nome']! as String,
              valuta: c['valuta']! as String,
              saldoInizialeMinimo: Value(c['saldoIniziale'] as int? ?? 0),
              ordine: Value(ordine),
              eliminato: Value(c['eliminato'] == true),
            ),
          );
      return;
    }
    await (_db.update(_db.portafogli)..where((p) => p.id.equals(id))).write(
      PortafogliCompanion(
        aggiornatoIl: Value(locale),
        nome: Value(c['nome']! as String),
        valuta: Value(c['valuta']! as String),
        saldoInizialeMinimo: Value(c['saldoIniziale'] as int? ?? 0),
        eliminato: Value(c['eliminato'] == true),
        tipoId: tipi.any((t) => t.nome == c['tipoNome'])
            ? Value(tipo!.id)
            : const Value.absent(),
      ),
    );
  }

  /// `false` se il portafoglio non è ancora arrivato.
  Future<bool> _applicaMovimento(
    PortafoglioCondiviso pc,
    Map<String, Object?> c,
    String locale,
  ) async {
    final c0 = await (_db.select(
      _db.portafogli,
    )..where((p) => p.id.equals(pc.portafoglioId))).getSingleOrNull();
    if (c0 == null) {
      return false;
    }
    final id = c['id']! as String;
    final esistente = await (_db.select(
      _db.movimenti,
    )..where((m) => m.id.equals(id))).getSingleOrNull();
    final comuni = MovimentiCompanion(
      aggiornatoIl: Value(locale),
      importoMinimo: Value(c['importo']! as int),
      data: Value(c['data']! as String),
      descrizione: Value(c['descrizione'] as String? ?? ''),
      eliminato: Value(c['eliminato'] == true),
      inseritoDa: Value(c['inseritoDa'] as String?),
      modificatoDa: Value(c['modificatoDa'] as String?),
    );
    if (esistente != null && esistente.portafoglioDestinazioneId != null) {
      // Qui è un trasferimento (da o verso un mio portafoglio): cambiano solo
      // importo, data, descrizione ed eliminazione.
      await (_db.update(
        _db.movimenti,
      )..where((m) => m.id.equals(id))).write(comuni);
      return true;
    }
    final tipo = await _tipoMovimento(c['effetto'] as String?);
    final categoria = await _categoriaDaPercorso(c['categoria'] as String?);
    final completi = comuni.copyWith(
      tipoId: Value(tipo),
      portafoglioId: Value(pc.portafoglioId),
      portafoglioDestinazioneId: const Value(null),
      categoriaId: Value(categoria),
      valuta: Value(c['valuta']! as String),
    );
    if (esistente == null) {
      await _db.into(_db.movimenti).insert(completi.copyWith(id: Value(id)));
    } else {
      await (_db.update(
        _db.movimenti,
      )..where((m) => m.id.equals(id))).write(completi);
    }
    return true;
  }

  Future<String> _tipoMovimento(String? effetto) async {
    final tipi =
        await (_db.select(_db.definizioniTipo)..where(
              (t) =>
                  t.ambito.equals(AmbitoTipo.movimento) &
                  t.effetto.equals(effetto ?? EffettoSaldo.uscita) &
                  t.eliminato.equals(false),
            ))
            .get();
    tipi.sort((a, b) => (b.diSistema ? 1 : 0).compareTo(a.diSistema ? 1 : 0));
    return tipi.first.id;
  }

  /// La categoria con lo stesso percorso ("Casa › Bollette"): se manca, si
  /// crea (anche i livelli sopra).
  Future<String?> _categoriaDaPercorso(String? percorso) async {
    if (percorso == null || percorso.isEmpty) {
      return null;
    }
    String? padre;
    for (final nome in percorso.split(' › ')) {
      final trovata =
          await (_db.select(_db.categorie)..where(
                (c) =>
                    c.nome.equals(nome) &
                    c.eliminato.equals(false) &
                    (padre == null
                        ? c.padreId.isNull()
                        : c.padreId.equals(padre)),
              ))
              .get();
      padre =
          trovata.firstOrNull?.id ??
          await _contabilita.creaCategoria(nome: nome, padreId: padre);
    }
    return padre;
  }
}

/// JSON con le chiavi in ordine: lo stesso testo su ogni dispositivo, da
/// firmare e verificare.
String canonico(Object? valore) => switch (valore) {
  final Map<Object?, Object?> m =>
    '{${(m.keys.map((k) => '$k').toList()..sort()).map((k) => '${jsonEncode(k)}:${canonico(m[k])}').join(',')}}',
  final List<Object?> l => '[${l.map(canonico).join(',')}]',
  _ => jsonEncode(valore),
};
