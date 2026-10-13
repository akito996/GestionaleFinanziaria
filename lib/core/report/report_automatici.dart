import 'package:drift/drift.dart';

import '../db/archivio.dart';
import '../db/contabilita.dart';
import '../db/costo_vita.dart';
import '../db/id.dart';
import '../db/orologio.dart';
import '../db/statistiche.dart';
import '../db/tabelle.dart';
import 'documento.dart';

/// Nomi dei mesi per i titoli dei report (senza dipendere dalla lingua del
/// sistema: l'app è in italiano).
const nomiMesi = [
  'gennaio',
  'febbraio',
  'marzo',
  'aprile',
  'maggio',
  'giugno',
  'luglio',
  'agosto',
  'settembre',
  'ottobre',
  'novembre',
  'dicembre',
];

String meseEsteso(DateTime m) => '${nomiMesi[m.month - 1]} ${m.year}';

String meseCorto(DateTime m) => nomiMesi[m.month - 1].substring(0, 3);

/// Report automatici sull'andamento delle entrate previste e del costo della
/// vita: uno per ogni mese concluso e uno per ogni anno concluso. Dopo 12 mesi
/// i report mensili si cancellano e restano solo quelli annuali.
class ReportAutomatici {
  ReportAutomatici(
    this._db,
    this._orologio,
    this._costoVita,
    this._statistiche, {
    DateTime Function()? adesso,
  }) : _adesso = adesso ?? DateTime.now;

  /// Quanti mesi si conservano i report mensili.
  static const mesiConservati = 12;

  final Archivio _db;
  final OrologioLogico _orologio;
  final CostoVita _costoVita;
  final StatisticheServizio _statistiche;
  final DateTime Function() _adesso;

  /// Report salvati (non eliminati), dal più recente.
  Stream<List<ReportSalvato>> osserva() =>
      (_db.select(_db.report)
            ..where((r) => r.eliminato.equals(false))
            ..orderBy([
              (r) => OrderingTerm.desc(r.periodo),
              (r) => OrderingTerm(expression: r.periodicita),
            ]))
          .watch();

  /// Crea i report mancanti dei periodi conclusi e toglie i mensili più
  /// vecchi di [mesiConservati] mesi (se c'è già l'annuale del loro anno).
  /// Restituisce quanti report ha creato.
  Future<int> aggiorna() async {
    final primo = await _primoMese();
    if (primo == null) {
      return 0; // archivio ancora vuoto
    }
    final oggi = _adesso();
    final meseCorrente = DateTime(oggi.year, oggi.month);
    final salvati = await (_db.select(
      _db.report,
    )..where((r) => r.eliminato.equals(false))).get();
    final presenti = {for (final r in salvati) '${r.periodicita}|${r.periodo}'};
    var creati = 0;

    for (var i = mesiConservati; i >= 1; i--) {
      final mese = DateTime(meseCorrente.year, meseCorrente.month - i);
      final periodo = _chiaveMese(mese);
      if (mese.isBefore(primo) ||
          presenti.contains('${PeriodicitaReport.mensile}|$periodo')) {
        continue;
      }
      await _salva(PeriodicitaReport.mensile, periodo, await this.mese(mese));
      creati++;
    }
    for (var anno = primo.year; anno < oggi.year; anno++) {
      if (presenti.contains('${PeriodicitaReport.annuale}|$anno')) {
        continue;
      }
      await _salva(PeriodicitaReport.annuale, '$anno', await this.anno(anno));
      presenti.add('${PeriodicitaReport.annuale}|$anno');
      creati++;
    }

    final limite = _chiaveMese(
      DateTime(meseCorrente.year, meseCorrente.month - mesiConservati),
    );
    for (final r in salvati) {
      if (r.periodicita == PeriodicitaReport.mensile &&
          r.periodo.compareTo(limite) < 0 &&
          presenti.contains(
            '${PeriodicitaReport.annuale}|${r.periodo.substring(0, 4)}',
          )) {
        await (_db.update(_db.report)..where((x) => x.id.equals(r.id))).write(
          ReportCompanion(
            aggiornatoIl: Value(_orologio.adesso()),
            eliminato: const Value(true),
          ),
        );
      }
    }
    return creati;
  }

  // ------------------------------------------------------------- calcoli

  /// Report di un mese: cifre del mese, andamento degli ultimi 12 mesi,
  /// dettaglio per voce.
  Future<DocumentoReport> mese(DateTime mese) async {
    final m = DateTime(mese.year, mese.month);
    final mesi = [for (var i = 11; i >= 0; i--) DateTime(m.year, m.month - i)];
    final spese = await _costoVita.riepiloghi(mesi);
    final entrate = await _costoVita.riepiloghi(
      mesi,
      natura: NaturaVoce.entrata,
    );
    final effettivi = await _statistiche.entrateUscitePerMese(
      finoA: m,
      mesi: 12,
    );
    final s = spese.last;
    final e = entrate.last;
    final x = effettivi.last;
    final prima = (
      s: spese[spese.length - 2],
      e: entrate[entrate.length - 2],
      x: effettivi[effettivi.length - 2],
    );
    String? rispetto(int adesso, int primaValore) =>
        _variazione(adesso, primaValore, 'al mese prima');

    return DocumentoReport(
      titolo: 'Report di ${meseEsteso(m)}',
      sottotitolo:
          'Entrate previste e costo della vita · creato il ${_data(_adesso())}',
      blocchi: [
        CifreChiave('Il mese in sintesi', [
          Cifra(
            'Entrate previste',
            e.totalePrevisto,
            nota: rispetto(e.totalePrevisto, prima.e.totalePrevisto),
          ),
          Cifra(
            'Entrate effettive',
            x.entrate,
            nota: rispetto(x.entrate, prima.x.entrate),
          ),
          Cifra(
            'Costo della vita previsto',
            s.totalePrevisto,
            nota: rispetto(s.totalePrevisto, prima.s.totalePrevisto),
          ),
          Cifra(
            'Uscite effettive',
            x.uscite,
            nota: rispetto(x.uscite, prima.x.uscite),
          ),
          Cifra('Margine previsto', e.totalePrevisto - s.totalePrevisto),
          Cifra('Margine effettivo', x.entrate - x.uscite),
        ]),
        _andamento(
          'Andamento degli ultimi 12 mesi',
          mesi,
          entrate,
          spese,
          effettivi,
        ),
        _perVoce('Costo della vita per voce', [s], 'Speso'),
        _perVoce('Entrate previste per voce', [e], 'Ricevuto'),
      ],
    );
  }

  /// Report di un anno: cifre dell'anno (con il confronto con l'anno prima),
  /// mese per mese, dettaglio per voce.
  Future<DocumentoReport> anno(int anno) async {
    final mesi = [for (var i = 1; i <= 12; i++) DateTime(anno, i)];
    final spese = await _costoVita.riepiloghi(mesi);
    final entrate = await _costoVita.riepiloghi(
      mesi,
      natura: NaturaVoce.entrata,
    );
    final effettivi = await _statistiche.entrateUscitePerMese(
      finoA: DateTime(anno, 12),
      mesi: 12,
    );
    final precedenti = await _statistiche.entrateUscitePerMese(
      finoA: DateTime(anno - 1, 12),
      mesi: 12,
    );
    int somma(Iterable<int> v) => v.fold(0, (a, b) => a + b);
    final entratePreviste = somma(entrate.map((m) => m.totalePrevisto));
    final costoPrevisto = somma(spese.map((m) => m.totalePrevisto));
    final entrateEffettive = somma(effettivi.map((m) => m.entrate));
    final usciteEffettive = somma(effettivi.map((m) => m.uscite));
    String? rispetto(int adesso, int prima) =>
        _variazione(adesso, prima, "all'anno prima");

    return DocumentoReport(
      titolo: 'Report del $anno',
      sottotitolo:
          'Entrate previste e costo della vita · creato il ${_data(_adesso())}',
      blocchi: [
        CifreChiave("L'anno in sintesi", [
          Cifra('Entrate previste', entratePreviste),
          Cifra(
            'Entrate effettive',
            entrateEffettive,
            nota: rispetto(
              entrateEffettive,
              somma(precedenti.map((m) => m.entrate)),
            ),
          ),
          Cifra('Costo della vita previsto', costoPrevisto),
          Cifra(
            'Uscite effettive',
            usciteEffettive,
            nota: rispetto(
              usciteEffettive,
              somma(precedenti.map((m) => m.uscite)),
            ),
          ),
          Cifra('Margine previsto', entratePreviste - costoPrevisto),
          Cifra('Margine effettivo', entrateEffettive - usciteEffettive),
        ]),
        _andamento('Mese per mese', mesi, entrate, spese, effettivi),
        TabellaReport(
          'Mese per mese',
          colonne: const [
            'Mese',
            'Entrate previste',
            'Entrate effettive',
            'Costo previsto',
            'Uscite effettive',
            'Margine effettivo',
          ],
          righe: [
            for (var i = 0; i < 12; i++)
              [
                ValoreTesto(meseEsteso(mesi[i])),
                ValoreImporto(entrate[i].totalePrevisto),
                ValoreImporto(effettivi[i].entrate),
                ValoreImporto(spese[i].totalePrevisto),
                ValoreImporto(effettivi[i].uscite),
                ValoreImporto(effettivi[i].differenza),
              ],
          ],
        ),
        _perVoce("Costo della vita per voce (tutto l'anno)", spese, 'Speso'),
        _perVoce(
          "Entrate previste per voce (tutto l'anno)",
          entrate,
          'Ricevuto',
        ),
      ],
    );
  }

  SerieReport _andamento(
    String titolo,
    List<DateTime> mesi,
    List<RiepilogoMese> entrate,
    List<RiepilogoMese> spese,
    List<EntrateUscite> effettivi,
  ) => SerieReport(
    titolo,
    etichette: [for (final m in mesi) meseCorto(m)],
    serie: [
      (
        nome: 'Entrate previste',
        valori: [for (final m in entrate) m.totalePrevisto],
      ),
      (
        nome: 'Entrate effettive',
        valori: [for (final m in effettivi) m.entrate],
      ),
      (
        nome: 'Costo della vita previsto',
        valori: [for (final m in spese) m.totalePrevisto],
      ),
      (nome: 'Uscite effettive', valori: [for (final m in effettivi) m.uscite]),
    ],
  );

  /// Una riga per voce, sommando i [mesi] (uno solo nel report mensile).
  TabellaReport _perVoce(
    String titolo,
    List<RiepilogoMese> mesi,
    String reale,
  ) {
    final righe =
        <String, ({String nome, String tipo, int previsto, int? reale})>{};
    for (final m in mesi) {
      for (final v in m.voci) {
        final prima = righe[v.voce.id];
        righe[v.voce.id] = (
          nome: v.voce.nome,
          tipo: v.fissa ? 'Fissa' : 'Variabile',
          previsto: (prima?.previsto ?? 0) + v.previsto,
          reale: v.reale == null
              ? prima?.reale
              : (prima?.reale ?? 0) + v.reale!,
        );
      }
      for (final r in m.rate) {
        final chiave = 'prestito:${r.prestito.id}';
        final prima = righe[chiave];
        righe[chiave] = (
          nome: r.prestito.nome,
          tipo: 'Rata',
          previsto: (prima?.previsto ?? 0) + r.importo,
          reale: null,
        );
      }
    }
    final ordinate = righe.values.toList()
      ..sort((a, b) => b.previsto.compareTo(a.previsto));
    return TabellaReport(
      titolo,
      colonne: ['Voce', 'Tipo', 'Previsto', reale],
      righe: [
        for (final r in ordinate)
          [
            ValoreTesto(r.nome),
            ValoreTesto(r.tipo),
            ValoreImporto(r.previsto),
            if (r.reale == null)
              const ValoreTesto('')
            else
              ValoreImporto(r.reale!),
          ],
      ],
    );
  }

  // ------------------------------------------------------------- interni

  /// Il primo mese con dati: movimenti o voci di costo/entrata.
  Future<DateTime?> _primoMese() async {
    final riga = await _db.customSelect('''
          SELECT MIN(primo) AS primo FROM (
            SELECT MIN(data) AS primo FROM movimenti WHERE eliminato = 0
            UNION ALL
            SELECT MIN(valido_dal) AS primo FROM importi_voce WHERE eliminato = 0
          )
          ''').getSingle();
    final testo = riga.readNullable<String>('primo');
    if (testo == null) {
      return null;
    }
    final d = Contabilita.daGiorno(testo);
    return DateTime(d.year, d.month);
  }

  Future<void> _salva(
    String periodicita,
    String periodo,
    DocumentoReport documento,
  ) => _db
      .into(_db.report)
      .insert(
        ReportCompanion.insert(
          id: nuovoId(),
          aggiornatoIl: _orologio.adesso(),
          periodicita: periodicita,
          periodo: periodo,
          contenuto: documento.codifica(),
        ),
      );

  static String? _variazione(int adesso, int prima, String rispetto) {
    if (prima == 0) {
      return null;
    }
    final v = ((adesso - prima) / prima * 100).round();
    final segno = v > 0 ? '+' : (v < 0 ? '−' : '');
    return '$segno${v.abs()}% rispetto $rispetto';
  }

  static String _chiaveMese(DateTime m) =>
      '${m.year}-${m.month.toString().padLeft(2, '0')}';

  static String _data(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
