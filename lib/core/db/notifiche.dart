import 'package:drift/drift.dart';

import 'archivio.dart';
import 'contabilita.dart';
import 'orologio.dart';
import 'osservazione.dart';
import 'pianificatore.dart';
import 'prestiti.dart';
import 'tabelle.dart';

/// Che tipo di notifica è (decide le azioni possibili).
enum TipoNotifica {
  /// Voce "Chiedi conferma" arrivata al suo giorno: resta finché non decidi.
  daConfermare('Da confermare'),

  /// Maxi rata: scegliere se rifinanziare o pagare (resta finché non decidi).
  decisione('Da decidere'),

  /// Scadenza dei prossimi giorni (si registra da sola o chiederà conferma).
  inArrivo('In arrivo'),

  /// Registrata da sola nel giorno previsto.
  registrata('Registrata'),

  /// Promemoria senza portafoglio (niente da registrare).
  promemoria('Promemoria');

  const TipoNotifica(this.etichetta);

  final String etichetta;
}

/// Una notifica: scadenza (entrata, spesa, rata, addebito carta) o decisione.
class Notifica {
  const Notifica({
    required this.chiave,
    required this.tipo,
    required this.titolo,
    required this.data,
    required this.letta,
    this.importo,
    this.valuta = 'EUR',
    this.entrata = false,
    this.scadenza,
    this.maxi,
  });

  /// Identifica la notifica (stato "letta"): `scadenza:<id>:<giorno>`,
  /// `maxi:<id>:<giorno>`.
  final String chiave;
  final TipoNotifica tipo;
  final String titolo;

  /// Il giorno della scadenza.
  final DateTime data;
  final bool letta;
  final int? importo;
  final String valuta;

  /// Soldi in arrivo (entrata) invece che in uscita.
  final bool entrata;

  /// Per le scadenze: cosa confermare, spostare o annullare.
  final SituazioneScadenza? scadenza;

  /// Per le decisioni sulla maxi rata.
  final AvvisoMaxi? maxi;

  /// Resta visibile finché l'utente non decide.
  bool get richiedeAzione =>
      tipo == TipoNotifica.daConfermare || tipo == TipoNotifica.decisione;

  /// Nella campanella: da decidere, oppure non ancora letta.
  bool get attiva => richiedeAzione || !letta;

  /// Si può confermare (registrare il movimento, o segnare fatto il promemoria).
  bool get confermabile =>
      scadenza != null &&
      scadenza!.movimento == null &&
      tipo != TipoNotifica.registrata;

  /// Si può spostare o annullare.
  bool get modificabile => confermabile;
}

/// Come tornare indietro dopo un'azione ("Annulla" nell'avviso in basso).
typedef Ripristino = Future<void> Function();

/// Notifiche dell'app: scadenze (da confermare, in arrivo, registrate,
/// promemoria) e decisioni sulle maxi rate, con lo stato "letta".
///
/// - Le voci "Chiedi conferma" compaiono nel giorno previsto e restano finché
///   l'utente conferma, sposta o annulla.
/// - Le uscite automatiche avvisano qualche giorno prima (vedi
///   [Pianificazioni.avvisoGiorni]); le entrate nel giorno previsto.
/// - Gli avvisi letti spariscono dalla campanella e restano nell'elenco.
class NotificheServizio {
  NotificheServizio(
    this._db,
    this._orologio,
    this._pianificatore,
    this._prestiti, {
    DateTime Function()? adesso,
  }) : _adesso = adesso ?? DateTime.now;

  final Archivio _db;
  final OrologioLogico _orologio;
  final Pianificatore _pianificatore;
  final PrestitiServizio _prestiti;
  final DateTime Function() _adesso;

  /// Quanto indietro guarda l'elenco (scadenze non confermate più vecchie non
  /// vengono più chieste).
  static const giorniIndietro = 30;

  /// Per quanti giorni resta l'avviso "registrata da sola" non letta.
  static const giorniRegistrate = 7;

  /// Chiavi delle notifiche già lette o gestite (confermate, spostate,
  /// annullate), aggiornate quando cambiano.
  Stream<Set<String>> osservaLette() =>
      (_db.select(_db.notificheLette)..where((l) => l.eliminato.equals(false)))
          .watch()
          .map((righe) => {for (final l in righe) l.id});

  static String chiaveScadenza(
    String pianificazioneId,
    DateTime dataPrevista,
  ) => 'scadenza:$pianificazioneId:${Contabilita.giorno(dataPrevista)}';

  Future<List<Notifica>> elenco() async {
    final a = _adesso();
    final oggi = DateTime(a.year, a.month, a.day);
    final lette = {
      for (final l in await (_db.select(
        _db.notificheLette,
      )..where((l) => l.eliminato.equals(false))).get())
        l.id,
    };
    final effetti = {
      for (final t in await _db.select(_db.definizioniTipo).get())
        t.id: t.effetto,
    };
    final massimoAvviso = await _massimoAvviso();
    final notifiche = <Notifica>[];
    for (final s in await _pianificatore.situazione(
      oggi.subtract(const Duration(days: giorniIndietro)),
      oggi.add(Duration(days: massimoAvviso)),
    )) {
      final p = s.pianificazione;
      final entrata = effetti[p.tipoId] == EffettoSaldo.entrata;
      // Le entrate si annunciano nel giorno previsto, le uscite prima.
      final avviso = entrata ? 0 : p.avvisoGiorni;
      if (s.data.isAfter(oggi.add(Duration(days: avviso)))) {
        continue;
      }
      final TipoNotifica tipo;
      final m = s.movimento;
      if (m != null) {
        if (m.eliminato ||
            p.richiedeConferma ||
            s.data.isBefore(
              oggi.subtract(const Duration(days: giorniRegistrate)),
            )) {
          continue; // eliminata apposta, confermata dall'utente o vecchia
        }
        tipo = TipoNotifica.registrata;
      } else if (s.importo == null || s.importo! <= 0) {
        continue; // niente da registrare (es. voce variabile senza stima)
      } else if (p.portafoglioId == null) {
        tipo = TipoNotifica.promemoria;
      } else if (p.richiedeConferma && !s.data.isAfter(oggi)) {
        tipo = TipoNotifica.daConfermare;
      } else {
        tipo = TipoNotifica.inArrivo;
      }
      final chiave = chiaveScadenza(p.id, s.dataPrevista);
      notifiche.add(
        Notifica(
          chiave: chiave,
          tipo: tipo,
          titolo: p.descrizione.isEmpty
              ? 'Pagamento programmato'
              : p.descrizione,
          data: s.data,
          letta: lette.contains(chiave),
          importo: m?.importoMinimo ?? s.importo,
          valuta: p.valuta,
          entrata: entrata,
          scadenza: s,
        ),
      );
    }
    for (final avviso in PrestitiServizio.avvisiMaxi(
      await _prestiti.stati(),
      a,
    )) {
      final prestito = avviso.stato.prestito;
      final chiave =
          'maxi:${prestito.id}:${Contabilita.giorno(avviso.scadenza)}';
      notifiche.add(
        Notifica(
          chiave: chiave,
          tipo: TipoNotifica.decisione,
          titolo: 'Maxi rata di "${prestito.nome}": scegli cosa fare',
          data: avviso.scadenza,
          letta: lette.contains(chiave),
          importo: avviso.importo,
          valuta: prestito.valuta,
          maxi: avviso,
        ),
      );
    }
    // Prima quelle da decidere (la più vecchia in cima), poi le non lette.
    notifiche.sort((x, y) {
      final azione = (x.richiedeAzione ? 0 : 1) - (y.richiedeAzione ? 0 : 1);
      if (azione != 0) {
        return azione;
      }
      final lettura = (x.letta ? 1 : 0) - (y.letta ? 1 : 0);
      return lettura != 0 ? lettura : x.data.compareTo(y.data);
    });
    return notifiche;
  }

  /// Come [elenco], aggiornato quando cambiano scadenze, movimenti o letture.
  Stream<List<Notifica>> osserva() => _db
      .customSelect(
        'SELECT 1 AS osserva_notifiche', // testo univoco: drift condivide le query uguali
        readsFrom: {
          ..._pianificatore.tabelleOsservate,
          _db.notificheLette,
          _db.prestiti,
          _db.carteCredito,
        },
      )
      .watch()
      .ricalcola((_) => elenco());

  // ---------------------------------------------------------------- azioni

  /// Segna come lette (o da leggere) le [notifiche].
  Future<Ripristino> segnaLette(
    Iterable<Notifica> notifiche, {
    bool lette = true,
  }) async {
    final cambiate = [
      for (final n in notifiche)
        if (n.letta != lette) n.chiave,
    ];
    await _scriviLette(cambiate, lette);
    return () => _scriviLette(cambiate, !lette);
  }

  /// Conferma le scadenze: registra i movimenti (o segna fatti i promemoria).
  /// Le altre notifiche vengono ignorate.
  Future<Ripristino> conferma(Iterable<Notifica> notifiche) async {
    final daConfermare = notifiche.where((n) => n.confermabile).toList();
    final movimenti = <String>[];
    final promemoria = <SituazioneScadenza>[];
    await _db.transaction(() async {
      for (final n in daConfermare) {
        final s = n.scadenza!;
        final id = await _pianificatore.conferma(
          s.pianificazione,
          s.dataPrevista,
        );
        if (id != null) {
          movimenti.add(id);
        } else if (s.pianificazione.portafoglioId == null) {
          promemoria.add(s);
        }
      }
    });
    final lette = await segnaLette(daConfermare);
    return () async {
      await _db.transaction(() async {
        for (final id in movimenti) {
          await _pianificatore.annullaConferma(id);
        }
        for (final s in promemoria) {
          await _ripristinaScelta(s);
        }
      });
      await lette();
    };
  }

  /// Sposta la scadenza a [giorno] (solo questa volta).
  Future<Ripristino> sposta(Notifica notifica, DateTime giorno) =>
      _scegli(notifica, StatoOccorrenza.spostata, giorno);

  /// Annulla la scadenza (solo questa volta): non si registra.
  Future<Ripristino> annulla(Notifica notifica) =>
      _scegli(notifica, StatoOccorrenza.annullata, null);

  // ------------------------------------------------------------- interni

  Future<Ripristino> _scegli(
    Notifica notifica,
    String stato,
    DateTime? nuovaData,
  ) async {
    final s = notifica.scadenza!;
    await _pianificatore.scegli(
      s.pianificazione.id,
      s.dataPrevista,
      stato: stato,
      nuovaData: nuovaData,
    );
    final lette = await segnaLette([notifica]);
    return () async {
      await _ripristinaScelta(s);
      await lette();
    };
  }

  /// Rimette la scelta com'era prima ([SituazioneScadenza.scelta]).
  Future<void> _ripristinaScelta(SituazioneScadenza s) => _pianificatore.scegli(
    s.pianificazione.id,
    s.dataPrevista,
    stato: s.scelta?.stato,
    nuovaData: s.scelta?.nuovaData == null
        ? null
        : Contabilita.daGiorno(s.scelta!.nuovaData!),
  );

  Future<void> _scriviLette(List<String> chiavi, bool lette) async {
    if (chiavi.isEmpty) {
      return;
    }
    final quando = _adesso().toIso8601String();
    await _db.batch((b) {
      for (final chiave in chiavi) {
        b.insert(
          _db.notificheLette,
          NotificheLetteCompanion.insert(
            id: chiave,
            aggiornatoIl: _orologio.adesso(),
            lettaIl: quando,
            eliminato: Value(!lette),
          ),
          onConflict: DoUpdate(
            (_) => NotificheLetteCompanion(
              aggiornatoIl: Value(_orologio.adesso()),
              lettaIl: Value(quando),
              eliminato: Value(!lette),
            ),
          ),
        );
      }
    });
  }

  Future<int> _massimoAvviso() async {
    final massimo = _db.pianificazioni.avvisoGiorni.max();
    final riga = await (_db.selectOnly(
      _db.pianificazioni,
    )..addColumns([massimo])).getSingle();
    return riga.read(massimo) ?? 3;
  }
}
