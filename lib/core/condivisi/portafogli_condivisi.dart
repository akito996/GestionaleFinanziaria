import 'dart:async';
import 'dart:convert';

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

  void chiudi() => _avvisi.close();

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
        final nomi = {
          for (final p in await _db.select(_db.portafogli).get()) p.id: p.nome,
        };
        return [
          for (final c in elenco)
            (
              info: c,
              nome: nomi[c.portafoglioId] ?? '',
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
    PortafoglioCondiviso pc,
  ) async {
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
      scelta = await accesso.scegli(
        soloId: [if (invito != null) invito.registroId, ?invito?.fileId],
      );
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

  /// Un giro su tutti i portafogli condivisi. Senza [interattivo] non chiede
  /// niente a Google: se manca il consenso, salta.
  Future<void> sincronizza({bool interattivo = false}) async {
    final elenco = await (_db.select(
      _db.portafogliCondivisi,
    )..where((c) => c.eliminato.equals(false))).get();
    if (elenco.isEmpty) {
      return;
    }
    final http.Client? client;
    try {
      client = await accesso.client(interattivo: interattivo);
    } on Object catch (e) {
      // Google non raggiungibile o consenso tolto: si riprova al prossimo giro.
      debugPrint('Portafogli condivisi: accesso a Google non riuscito: $e');
      return;
    }
    if (client == null) {
      return;
    }
    final drive = _creaDrive(client);
    try {
      for (final pc in elenco) {
        try {
          await _sincronizzaUno(drive, pc);
        } on Object catch (e) {
          // Un portafoglio con problemi non ferma gli altri.
          debugPrint('Portafoglio condiviso ${pc.portafoglioId}: $e');
        }
      }
    } finally {
      drive.chiudi();
    }
  }

  Future<void> _sincronizzaUno(
    DriveCondiviso drive,
    PortafoglioCondiviso pc,
  ) async {
    final proprietario = pc.ruolo == RuoloMembro.proprietario;
    var persone = await membri(pc.portafoglioId);
    // 1. Registro: il membro aggiorna le persone e prende la sua chiave.
    if (!proprietario && pc.registroId.isNotEmpty) {
      final registro = _verificaRegistro(
        await drive.leggi(pc.registroId),
        proprietario: persone
            .where((m) => m.ruolo == RuoloMembro.proprietario)
            .firstOrNull,
      );
      await _aggiornaMembri(pc, registro);
      persone = await membri(pc.portafoglioId);
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
          pc = (await di(pc.portafoglioId))!;
        }
      }
    }
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
          file = jsonDecode(await drive.leggi(fileId)) as Map<String, Object?>;
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
            'normalmente; puoi invitarla di nuovo quando vuoi dall\'icona '
            'delle persone.',
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
          final file =
              jsonDecode(await drive.leggi(fileId)) as Map<String, Object?>;
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
          await _unisci(pc, righe, persone);
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
      if (testo is! String || firma is! String || chiaveFirma == null) {
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
