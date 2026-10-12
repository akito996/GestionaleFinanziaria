import 'package:drift/drift.dart';

import '../prestiti/ammortamento.dart';
import '../ricorrenza.dart';
import 'archivio.dart';
import 'contabilita.dart';
import 'id.dart';
import 'orologio.dart';
import 'osservazione.dart';
import 'pianificatore.dart';
import 'tabelle.dart';

/// Dati del modulo di un prestito.
class DatiPrestito {
  const DatiPrestito({
    required this.nome,
    required this.tipo,
    required this.capitale,
    required this.numeroRate,
    required this.importoRata,
    required this.primaRata,
    this.frequenza = Frequenza.mensile,
    this.finanziatore = '',
    this.tanPuntiBase,
    this.taegPuntiBase,
    this.maxiRata,
    this.speseRata,
    this.portafoglioId,
    this.categoriaId,
    this.note = '',
  });

  final String nome;
  final String tipo;
  final int capitale;
  final int numeroRate;
  final int importoRata;
  final DateTime primaRata;
  final Frequenza frequenza;
  final String finanziatore;
  final int? tanPuntiBase;
  final int? taegPuntiBase;

  /// Maxi rata finale: l'ultima delle [numeroRate] rate vale questa cifra.
  final int? maxiRata;

  /// Spese di incasso per ogni rata: si aggiungono al movimento registrato.
  final int? speseRata;
  final String? portafoglioId;
  final String? categoriaId;
  final String note;
}

/// Una rata con la sua data e se è già stata pagata (registrata).
class RataDatata {
  const RataDatata(this.piano, this.data, {required this.pagata});

  final RataPiano piano;
  final DateTime data;
  final bool pagata;
}

/// Maxi rata in arrivo su cui l'utente deve decidere (rifinanziare o pagare).
class AvvisoMaxi {
  const AvvisoMaxi({
    required this.stato,
    required this.scadenza,
    required this.importo,
    required this.giorniMancanti,
    required this.daChiedere,
  });

  final PrestitoConStato stato;
  final DateTime scadenza;

  /// Maxi rata + spese di incasso (quanto uscirebbe dal conto).
  final int importo;
  final int giorniMancanti;

  /// `true` = va chiesto adesso (mai chiesto, o il rimando è scaduto).
  final bool daChiedere;
}

class PrestitoConStato {
  const PrestitoConStato({
    required this.prestito,
    required this.rate,
    required this.ratePagate,
  });

  final Prestito prestito;
  final List<RataDatata> rate;
  final int ratePagate;

  int get rateRimanenti => prestito.numeroRate - ratePagate;

  RataDatata? get prossima => rate.where((r) => !r.pagata).firstOrNull;

  DateTime? get fine => rate.isEmpty ? null : rate.last.data;

  /// Debito residuo dopo l'ultima rata pagata (dal piano di ammortamento).
  int get debitoResiduo => ratePagate == 0
      ? prestito.capitaleMinimo
      : rate[ratePagate - 1].piano.debitoResiduo;

  /// Spese di incasso di ogni rata (0 se non ce ne sono).
  int get speseRata => prestito.speseRataMinimo ?? 0;

  /// Quanto resta da pagare (capitale + interessi futuri + spese di incasso).
  int get daPagare => rate
      .where((r) => !r.pagata)
      .fold(0, (totale, r) => totale + r.piano.rata + speseRata);

  double get avanzamento =>
      prestito.numeroRate == 0 ? 0 : ratePagate / prestito.numeroRate;
}

/// Prestiti e rate: ogni rata è un pagamento programmato a importo fisso che si
/// registra da solo nel giorno previsto, nella categoria scelta.
class PrestitiServizio {
  PrestitiServizio(
    this._db,
    this._orologio,
    this._pianificatore, {
    DateTime Function()? adesso,
  }) : _adesso = adesso ?? DateTime.now {
    _pianificatore.registraCalcolo(OriginePianificazione.prestito, (
      pianificazione,
      data,
    ) async {
      final id = pianificazione.origineId;
      final p = id == null
          ? null
          : await (_db.select(
              _db.prestiti,
            )..where((x) => x.id.equals(id))).getSingleOrNull();
      return p == null ? null : importoRataAl(p, data);
    });
  }

  final Archivio _db;
  final OrologioLogico _orologio;
  final Pianificatore _pianificatore;
  final DateTime Function() _adesso;

  /// Importo addebitato il giorno [data]: la rata (la maxi rata se è
  /// l'ultima) più le spese di incasso.
  /// Con la maxi rata rifinanziata l'ultima rata non esce dal conto (0).
  static int importoRataAl(Prestito p, DateTime data) {
    final spese = p.speseRataMinimo ?? 0;
    final maxi = p.maxiRataMinimo;
    if (maxi == null) {
      return p.importoRataMinimo + spese;
    }
    if (!_ultima(p, data)) {
      return p.importoRataMinimo + spese;
    }
    return p.decisioneMaxi == DecisioneMaxi.rifinanzia ? 0 : maxi + spese;
  }

  static bool _ultima(Prestito p, DateTime data) {
    final date = _ricorrenza(p).tra(Contabilita.daGiorno(p.primaRata), data);
    return date.length == p.numeroRate &&
        Contabilita.giorno(date.last) == Contabilita.giorno(data);
  }

  // --------------------------------------------------------- maxi rata

  /// Da quando si chiede cosa fare della maxi rata: 6 mesi prima.
  static DateTime inizioAvvisiMaxi(DateTime scadenza) =>
      DateTime(scadenza.year, scadenza.month - 6, scadenza.day);

  /// Prossima volta in cui chiedere, dopo un rimando del giorno [rimandataIl]:
  /// ogni 15 giorni (2 volte al mese); negli ultimi 2 mesi ogni settimana;
  /// nell'ultimo mese ogni 3 giorni. Senza rimandi: dall'inizio degli avvisi.
  static DateTime prossimoAvvisoMaxi(DateTime scadenza, DateTime? rimandataIl) {
    if (rimandataIl == null) {
      return inizioAvvisiMaxi(scadenza);
    }
    final r = DateTime(rimandataIl.year, rimandataIl.month, rimandataIl.day);
    final mancano = _giorniTra(r, scadenza);
    final dueMesiPrima = DateTime(
      scadenza.year,
      scadenza.month,
      scadenza.day - 60,
    );
    final unMesePrima = DateTime(
      scadenza.year,
      scadenza.month,
      scadenza.day - 30,
    );
    if (mancano > 60) {
      final p = DateTime(r.year, r.month, r.day + 15);
      return p.isAfter(dueMesiPrima) ? dueMesiPrima : p;
    }
    if (mancano > 30) {
      final p = DateTime(r.year, r.month, r.day + 7);
      return p.isAfter(unMesePrima) ? unMesePrima : p;
    }
    return DateTime(r.year, r.month, r.day + 3);
  }

  /// Maxi rate senza decisione, dai 6 mesi prima fino alla scadenza.
  static List<AvvisoMaxi> avvisiMaxi(
    List<PrestitoConStato> stati,
    DateTime adesso,
  ) {
    final oggi = DateTime(adesso.year, adesso.month, adesso.day);
    final risultato = [
      for (final s in stati)
        if (avvisoMaxi(s, oggi) case final a?)
          if (s.prestito.decisioneMaxi == null &&
              !oggi.isBefore(inizioAvvisiMaxi(a.scadenza)))
            a,
    ]..sort((a, b) => a.scadenza.compareTo(b.scadenza));
    return risultato;
  }

  /// La maxi rata di [s] non ancora pagata (anche già decisa o lontana),
  /// oppure `null` se il prestito non ne ha o è già passata.
  static AvvisoMaxi? avvisoMaxi(PrestitoConStato s, DateTime adesso) {
    final p = s.prestito;
    final oggi = DateTime(adesso.year, adesso.month, adesso.day);
    if (p.maxiRataMinimo == null ||
        s.rate.length != p.numeroRate ||
        s.rate.last.pagata) {
      return null;
    }
    final scadenza = s.rate.last.data;
    if (oggi.isAfter(scadenza)) {
      return null;
    }
    final rimandata = p.maxiRimandataIl == null
        ? null
        : Contabilita.daGiorno(p.maxiRimandataIl!);
    return AvvisoMaxi(
      stato: s,
      scadenza: scadenza,
      importo: p.maxiRataMinimo! + (p.speseRataMinimo ?? 0),
      giorniMancanti: _giorniTra(oggi, scadenza),
      daChiedere:
          p.decisioneMaxi == null &&
          !oggi.isBefore(prossimoAvvisoMaxi(scadenza, rimandata)),
    );
  }

  static int _giorniTra(DateTime da, DateTime a) => DateTime.utc(
    a.year,
    a.month,
    a.day,
  ).difference(DateTime.utc(da.year, da.month, da.day)).inDays;

  /// Avvisi sulle maxi rate, aggiornati quando cambiano prestiti o movimenti.
  Stream<List<AvvisoMaxi>> osservaAvvisiMaxi() =>
      osserva().map((stati) => avvisiMaxi(stati, _adesso()));

  /// Decisione sulla maxi rata ([DecisioneMaxi]); `null` = di nuovo da decidere.
  Future<void> decidiMaxi(String id, String? decisione) =>
      (_db.update(_db.prestiti)..where((p) => p.id.equals(id))).write(
        PrestitiCompanion(
          aggiornatoIl: Value(_orologio.adesso()),
          decisioneMaxi: Value(decisione),
          maxiRimandataIl: const Value(null),
        ),
      );

  /// "Ricordamelo più tardi": la prossima richiesta segue [prossimoAvvisoMaxi].
  Future<void> rimandaMaxi(String id) =>
      (_db.update(_db.prestiti)..where((p) => p.id.equals(id))).write(
        PrestitiCompanion(
          aggiornatoIl: Value(_orologio.adesso()),
          maxiRimandataIl: Value(Contabilita.giorno(_oggi())),
        ),
      );

  static Ricorrenza _ricorrenza(Prestito p) => Ricorrenza(
    inizio: Contabilita.daGiorno(p.primaRata),
    frequenza: Frequenza.daCodice(p.frequenza),
    occorrenze: p.numeroRate,
  );

  Future<String> crea(DatiPrestito d) async {
    final id = nuovoId();
    await _db
        .into(_db.prestiti)
        .insert(
          PrestitiCompanion.insert(
            id: id,
            aggiornatoIl: _orologio.adesso(),
            nome: d.nome.trim(),
            tipo: d.tipo,
            finanziatore: Value(d.finanziatore.trim()),
            capitaleMinimo: d.capitale,
            numeroRate: d.numeroRate,
            importoRataMinimo: d.importoRata,
            tanPuntiBase: Value(d.tanPuntiBase),
            taegPuntiBase: Value(d.taegPuntiBase),
            maxiRataMinimo: Value(d.maxiRata),
            speseRataMinimo: Value(_spese(d.speseRata)),
            primaRata: Contabilita.giorno(d.primaRata),
            frequenza: Value(d.frequenza.codice),
            portafoglioId: Value(d.portafoglioId),
            categoriaId: Value(
              d.categoriaId ?? await categoriaPredefinita(d.tipo),
            ),
            note: Value(d.note),
          ),
        );
    await _aggiornaRate(id);
    return id;
  }

  Future<void> modifica(String id, DatiPrestito d) async {
    await (_db.update(_db.prestiti)..where((p) => p.id.equals(id))).write(
      PrestitiCompanion(
        aggiornatoIl: Value(_orologio.adesso()),
        nome: Value(d.nome.trim()),
        tipo: Value(d.tipo),
        finanziatore: Value(d.finanziatore.trim()),
        capitaleMinimo: Value(d.capitale),
        numeroRate: Value(d.numeroRate),
        importoRataMinimo: Value(d.importoRata),
        tanPuntiBase: Value(d.tanPuntiBase),
        taegPuntiBase: Value(d.taegPuntiBase),
        maxiRataMinimo: Value(d.maxiRata),
        speseRataMinimo: Value(_spese(d.speseRata)),
        primaRata: Value(Contabilita.giorno(d.primaRata)),
        frequenza: Value(d.frequenza.codice),
        portafoglioId: Value(d.portafoglioId),
        categoriaId: Value(d.categoriaId),
        note: Value(d.note),
      ),
    );
    await _aggiornaRate(id);
  }

  /// Archivia (es. estinto in anticipo): le rate future non si registrano più.
  Future<void> archivia(String id, {bool archiviato = true}) async {
    await (_db.update(_db.prestiti)..where((p) => p.id.equals(id))).write(
      PrestitiCompanion(
        aggiornatoIl: Value(_orologio.adesso()),
        archiviato: Value(archiviato),
      ),
    );
    await (_db.update(_db.pianificazioni)..where(
          (p) =>
              p.origine.equals(OriginePianificazione.prestito) &
              p.origineId.equals(id),
        ))
        .write(
          PianificazioniCompanion(
            aggiornatoIl: Value(_orologio.adesso()),
            attiva: Value(!archiviato),
          ),
        );
  }

  Stream<List<PrestitoConStato>> osserva() => _db
      .customSelect(
        'SELECT 1 AS osserva_prestiti', // testo univoco: drift condivide le query uguali
        readsFrom: {_db.prestiti, _db.movimenti, _db.pianificazioni},
      )
      .watch()
      .ricalcola((_) => stati());

  Future<List<PrestitoConStato>> stati() async {
    final prestiti =
        await (_db.select(_db.prestiti)
              ..where(
                (p) => p.eliminato.equals(false) & p.archiviato.equals(false),
              )
              ..orderBy([(p) => OrderingTerm(expression: p.primaRata)]))
            .get();
    final risultato = <PrestitoConStato>[];
    for (final p in prestiti) {
      risultato.add(await stato(p));
    }
    return risultato;
  }

  Future<PrestitoConStato> stato(Prestito p) async {
    final frequenza = Frequenza.daCodice(p.frequenza);
    final piano = Ammortamento.piano(
      capitale: p.capitaleMinimo,
      numeroRate: p.numeroRate,
      tanPuntiBase:
          p.tanPuntiBase ??
          Ammortamento.tanDaRata(
            capitale: p.capitaleMinimo,
            numeroRate: p.numeroRate,
            rata: p.importoRataMinimo,
            rateAllAnno: _rateAllAnno(frequenza),
            rataFinale: p.maxiRataMinimo,
          ) ??
          0,
      rataFissa: p.importoRataMinimo,
      rateAllAnno: _rateAllAnno(frequenza),
      rataFinale: p.maxiRataMinimo,
    );
    final date = _ricorrenza(p)
        .tra(Contabilita.daGiorno(p.primaRata), DateTime(9999));
    final pagate = await _dateRegistrate(p.id);
    final oggi = _oggi();
    final rate = <RataDatata>[];
    for (var i = 0; i < piano.length && i < date.length; i++) {
      final data = date[i];
      // Senza conto le rate non si registrano: si considerano pagate alla
      // scadenza. Lo stesso per la maxi rata rifinanziata (la paga il nuovo
      // prestito, dal conto non esce).
      final rifinanziata =
          i == p.numeroRate - 1 &&
          p.maxiRataMinimo != null &&
          p.decisioneMaxi == DecisioneMaxi.rifinanzia;
      final pagata = p.portafoglioId == null || rifinanziata
          ? !data.isAfter(oggi)
          : pagate.contains(Contabilita.giorno(data));
      rate.add(RataDatata(piano[i], data, pagata: pagata));
    }
    return PrestitoConStato(
      prestito: p,
      rate: rate,
      ratePagate: rate.where((r) => r.pagata).length,
    );
  }

  /// Sottocategoria di "Finanziamenti" adatta al tipo di prestito.
  Future<String?> categoriaPredefinita(String tipo) async {
    final nome = switch (tipo) {
      TipoPrestito.mutuo => 'Mutuo',
      TipoPrestito.rate => 'Pagamenti a rate',
      _ => 'Prestiti',
    };
    final padre =
        await (_db.select(_db.categorie)..where(
              (c) => c.nome.equals(categoriaFinanziamenti) & c.padreId.isNull(),
            ))
            .getSingleOrNull();
    if (padre == null) {
      return null;
    }
    final figlia =
        await (_db.select(_db.categorie)
              ..where((c) => c.nome.equals(nome) & c.padreId.equals(padre.id)))
            .getSingleOrNull();
    return (figlia ?? padre).id;
  }

  // ------------------------------------------------------------- interni

  DateTime _oggi() {
    final a = _adesso();
    return DateTime(a.year, a.month, a.day);
  }

  static int? _spese(int? spese) => spese == null || spese <= 0 ? null : spese;

  static int _rateAllAnno(Frequenza f) => switch (f) {
    Frequenza.settimanale => 52,
    _ => 12 ~/ f.mesi,
  };

  Future<Set<String>> _dateRegistrate(String prestitoId) async {
    final p = await _pianificatore.perOrigine(
      OriginePianificazione.prestito,
      prestitoId,
    );
    if (p == null) {
      return {};
    }
    final righe =
        await (_db.selectOnly(_db.movimenti)
              ..addColumns([_db.movimenti.dataPrevista])
              ..where(
                _db.movimenti.pianificazioneId.equals(p.id) &
                    _db.movimenti.eliminato.equals(false),
              ))
            .get();
    return {
      for (final r in righe)
        if (r.read(_db.movimenti.dataPrevista) case final String d) d,
    };
  }

  Future<void> _aggiornaRate(String id) async {
    final p = await (_db.select(
      _db.prestiti,
    )..where((x) => x.id.equals(id))).getSingle();
    await _pianificatore.salva(
      DatiPianificazione(
        origine: OriginePianificazione.prestito,
        origineId: id,
        ricorrenza: _ricorrenza(p),
        portafoglioId: p.portafoglioId,
        categoriaId: p.categoriaId,
        descrizione: 'Rata ${p.nome}',
        // Con la maxi rata l'importo cambia all'ultima: lo calcola [importoRataAl].
        importo: p.maxiRataMinimo == null
            ? p.importoRataMinimo + (p.speseRataMinimo ?? 0)
            : null,
        valuta: p.valuta,
      ),
    );
  }
}
