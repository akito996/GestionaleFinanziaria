import 'package:drift/drift.dart';

import '../db/archivio.dart';
import '../db/carte_credito.dart';
import '../db/contabilita.dart';
import '../db/costo_vita.dart';
import '../db/obiettivi.dart';
import '../db/prestiti.dart';
import '../db/statistiche.dart';
import '../db/tabelle.dart';
import 'documento.dart';
import 'report_automatici.dart' show meseCorto, meseEsteso;

/// Strumenti di cui si può creare un report.
enum StrumentoReport {
  entrateUscite('Entrate e uscite'),
  spese('Spese per categoria'),
  saldo('Saldo dei portafogli'),
  costoVita('Costo della vita'),
  entratePreviste('Entrate previste'),
  carte('Carte di credito'),
  prestiti('Prestiti e rate'),
  obiettivi('Obiettivi e collette');

  const StrumentoReport(this.etichetta);

  final String etichetta;
}

/// Dettaglio del report: ogni quanto si raggruppano i dati.
enum Dettaglio {
  giorno('Giornaliero'),
  settimana('Settimanale'),
  mese('Mensile'),
  anno('Annuale');

  const Dettaglio(this.etichetta);

  final String etichetta;
}

/// Un intervallo del report (un giorno, una settimana, un mese, un anno).
class Intervallo {
  const Intervallo(this.da, this.a, this.etichetta);

  final DateTime da;

  /// Ultimo giorno compreso.
  final DateTime a;
  final String etichetta;
}

/// Report creati dall'utente: uno o più strumenti, con il dettaglio scelto.
class ReportPersonalizzati {
  ReportPersonalizzati(
    this._db,
    this._costoVita,
    this._statistiche,
    this._carte,
    this._prestiti,
    this._obiettivi,
  );

  /// Oltre questo numero di intervalli il report diventa illeggibile.
  static const massimoIntervalli = 400;

  final Archivio _db;
  final CostoVita _costoVita;
  final StatisticheServizio _statistiche;
  final CarteCreditoServizio _carte;
  final PrestitiServizio _prestiti;
  final ObiettiviServizio _obiettivi;

  /// Gli intervalli tra [da] e [a] (inclusi) con il [dettaglio] scelto.
  /// Settimane da lunedì a domenica; il primo e l'ultimo intervallo sono
  /// tagliati sul periodo scelto.
  static List<Intervallo> intervalli(
    DateTime da,
    DateTime a,
    Dettaglio dettaglio,
  ) {
    final inizio = DateTime(da.year, da.month, da.day);
    final fine = DateTime(a.year, a.month, a.day);
    final risultato = <Intervallo>[];
    var corrente = inizio;
    while (!corrente.isAfter(fine)) {
      final DateTime ultimo;
      final String etichetta;
      switch (dettaglio) {
        case Dettaglio.giorno:
          ultimo = corrente;
          etichetta = '${corrente.day} ${meseCorto(corrente)}';
        case Dettaglio.settimana:
          final domenica = DateTime(
            corrente.year,
            corrente.month,
            corrente.day + (7 - corrente.weekday),
          );
          ultimo = domenica.isAfter(fine) ? fine : domenica;
          etichetta = '${corrente.day}/${corrente.month}';
        case Dettaglio.mese:
          final fineMese = DateTime(corrente.year, corrente.month + 1, 0);
          ultimo = fineMese.isAfter(fine) ? fine : fineMese;
          etichetta = '${meseCorto(corrente)} ${corrente.year % 100}';
        case Dettaglio.anno:
          final fineAnno = DateTime(corrente.year, 12, 31);
          ultimo = fineAnno.isAfter(fine) ? fine : fineAnno;
          etichetta = '${corrente.year}';
      }
      risultato.add(Intervallo(corrente, ultimo, etichetta));
      if (risultato.length > massimoIntervalli) {
        throw ArgumentError(
          'Troppi intervalli: scegli un periodo più breve o un dettaglio meno '
          'fine.',
        );
      }
      corrente = DateTime(ultimo.year, ultimo.month, ultimo.day + 1);
    }
    return risultato;
  }

  Future<DocumentoReport> crea({
    required Set<StrumentoReport> strumenti,
    required Dettaglio dettaglio,
    required DateTime da,
    required DateTime a,
    DateTime? creatoIl,
  }) async {
    final iv = intervalli(da, a, dettaglio);
    final blocchi = <BloccoReport>[];
    for (final s in StrumentoReport.values.where(strumenti.contains)) {
      blocchi.addAll(switch (s) {
        StrumentoReport.entrateUscite => await _entrateUscite(iv),
        StrumentoReport.spese => await _spese(iv, da, a),
        StrumentoReport.saldo => await _saldo(iv),
        StrumentoReport.costoVita => await _previsto(iv, NaturaVoce.spesa),
        StrumentoReport.entratePreviste => await _previsto(
          iv,
          NaturaVoce.entrata,
        ),
        StrumentoReport.carte => await _carteDiCredito(iv),
        StrumentoReport.prestiti => await _rate(iv),
        StrumentoReport.obiettivi => await _versamenti(iv),
      });
    }
    final oggi = creatoIl ?? DateTime.now();
    return DocumentoReport(
      titolo: strumenti.length == 1
          ? 'Report: ${strumenti.single.etichetta.toLowerCase()}'
          : 'Report del gestionale',
      sottotitolo:
          'Dal ${_data(da)} al ${_data(a)} · dettaglio '
          '${dettaglio.etichetta.toLowerCase()} · creato il ${_data(oggi)}',
      blocchi: blocchi,
    );
  }

  // ------------------------------------------------------------- strumenti

  Future<List<BloccoReport>> _entrateUscite(List<Intervallo> iv) async {
    final valori = [
      for (final i in iv) await _statistiche.entrateUsciteTra(i.da, i.a),
    ];
    final entrate = valori.fold<int>(0, (t, v) => t + v.entrate);
    final uscite = valori.fold<int>(0, (t, v) => t + v.uscite);
    return [
      CifreChiave('Entrate e uscite', [
        Cifra('Entrate', entrate),
        Cifra('Uscite', uscite),
        Cifra(
          'Differenza',
          entrate - uscite,
          nota: entrate == 0
              ? null
              : 'Messo da parte: ${((entrate - uscite) / entrate * 100).round()}% delle entrate',
        ),
      ]),
      SerieReport(
        'Entrate e uscite nel periodo',
        etichette: [for (final i in iv) i.etichetta],
        serie: [
          (nome: 'Entrate', valori: [for (final v in valori) v.entrate]),
          (nome: 'Uscite', valori: [for (final v in valori) v.uscite]),
        ],
        aColonne: true,
      ),
      TabellaReport(
        'Entrate e uscite per periodo',
        colonne: const ['Periodo', 'Entrate', 'Uscite', 'Differenza'],
        righe: [
          for (final (k, i) in iv.indexed)
            [
              ValoreTesto(_periodo(i)),
              ValoreImporto(valori[k].entrate),
              ValoreImporto(valori[k].uscite),
              ValoreImporto(valori[k].differenza),
            ],
        ],
      ),
    ];
  }

  Future<List<BloccoReport>> _spese(
    List<Intervallo> iv,
    DateTime da,
    DateTime a,
  ) async {
    final perCategoria = await _statistiche.spesePerCategoria(da, a);
    final totale = perCategoria.fold<int>(0, (t, s) => t + s.totale);
    final andamento = [
      for (final i in iv)
        (await _statistiche.entrateUsciteTra(i.da, i.a)).uscite,
    ];
    return [
      SerieReport(
        'Spese nel periodo',
        etichette: [for (final i in iv) i.etichetta],
        serie: [(nome: 'Spese', valori: andamento)],
        aColonne: true,
      ),
      TabellaReport(
        'Spese per categoria · totale',
        colonne: const ['Categoria', 'Speso', 'Quota'],
        righe: [
          for (final s in perCategoria)
            [
              ValoreTesto(s.categoria ?? 'Senza categoria'),
              ValoreImporto(s.totale),
              ValoreTesto(
                totale == 0 ? '' : '${(s.totale / totale * 100).round()}%',
              ),
            ],
        ],
      ),
    ];
  }

  Future<List<BloccoReport>> _saldo(List<Intervallo> iv) async {
    final portafogli =
        await (_db.select(_db.portafogli)..where(
              (p) => p.eliminato.equals(false) & p.archiviato.equals(false),
            ))
            .get();
    final idCarte = {for (final c in await _carte.stati()) c.portafoglio.id};
    final conti = [
      for (final p in portafogli)
        if (!idCarte.contains(p.id)) p,
    ];
    final totali = <int>[];
    for (final i in iv) {
      var t = 0;
      for (final p in conti) {
        t += await _statistiche.saldoAl(p.id, i.a);
      }
      totali.add(t);
    }
    final fine = iv.last.a;
    return [
      SerieReport(
        'Saldo totale a fine periodo',
        etichette: [for (final i in iv) i.etichetta],
        serie: [(nome: 'Saldo totale', valori: totali)],
      ),
      TabellaReport(
        'Saldo dei portafogli al ${_data(fine)}',
        colonne: const ['Portafoglio', 'Saldo'],
        righe: [
          for (final p in conti)
            [
              ValoreTesto(p.nome),
              ValoreImporto(await _statistiche.saldoAl(p.id, fine)),
            ],
        ],
      ),
    ];
  }

  /// Costo della vita o entrate previste: previsto (in proporzione ai giorni
  /// dell'intervallo) contro uscite o entrate effettive.
  Future<List<BloccoReport>> _previsto(
    List<Intervallo> iv,
    String natura,
  ) async {
    final entrate = natura == NaturaVoce.entrata;
    final mesi = <DateTime>{};
    for (final i in iv) {
      for (
        var m = DateTime(i.da.year, i.da.month);
        !m.isAfter(i.a);
        m = DateTime(m.year, m.month + 1)
      ) {
        mesi.add(m);
      }
    }
    final riepiloghi = {
      for (final r in await _costoVita.riepiloghi(
        mesi.toList()..sort(),
        natura: natura,
      ))
        r.mese: r,
    };
    final previsti = <int>[];
    final effettivi = <int>[];
    for (final i in iv) {
      var previsto = 0.0;
      for (
        var g = i.da;
        !g.isAfter(i.a);
        g = DateTime(g.year, g.month, g.day + 1)
      ) {
        final r = riepiloghi[DateTime(g.year, g.month)];
        if (r != null) {
          previsto += r.totalePrevisto / DateTime(g.year, g.month + 1, 0).day;
        }
      }
      previsti.add(previsto.round());
      final x = await _statistiche.entrateUsciteTra(i.da, i.a);
      effettivi.add(entrate ? x.entrate : x.uscite);
    }
    final nome = entrate ? 'Entrate previste' : 'Costo della vita';
    final effettivo = entrate ? 'Entrate effettive' : 'Uscite effettive';
    final totPrevisto = previsti.fold<int>(0, (t, v) => t + v);
    final totEffettivo = effettivi.fold<int>(0, (t, v) => t + v);
    final ultimo =
        riepiloghi[riepiloghi.keys.reduce((a, b) => a.isAfter(b) ? a : b)];
    return [
      CifreChiave(nome, [
        Cifra('Previsto nel periodo', totPrevisto),
        Cifra(effettivo, totEffettivo),
        Cifra(
          'Differenza',
          totEffettivo - totPrevisto,
          nota: entrate
              ? 'Positiva: è entrato più del previsto'
              : 'Positiva: hai speso più del previsto',
        ),
      ]),
      SerieReport(
        '$nome: previsto ed effettivo',
        etichette: [for (final i in iv) i.etichetta],
        serie: [
          (nome: 'Previsto', valori: previsti),
          (nome: effettivo, valori: effettivi),
        ],
        aColonne: true,
      ),
      if (ultimo != null)
        TabellaReport(
          '$nome di ${meseEsteso(ultimo.mese)} per voce',
          colonne: const ['Voce', 'Tipo', 'Previsto'],
          righe: [
            for (final v in ultimo.voci)
              [
                ValoreTesto(v.voce.nome),
                ValoreTesto(v.fissa ? 'Fissa' : 'Variabile'),
                ValoreImporto(v.previsto),
              ],
            for (final r in ultimo.rate)
              [
                ValoreTesto(r.prestito.nome),
                const ValoreTesto('Rata'),
                ValoreImporto(r.importo),
              ],
          ],
        ),
    ];
  }

  Future<List<BloccoReport>> _carteDiCredito(List<Intervallo> iv) async {
    final carte = await _carte.stati();
    final perCarta = <String, List<int>>{};
    for (final c in carte) {
      perCarta[c.portafoglio.nome] = [
        for (final i in iv) await _uscitePortafoglio(c.portafoglio.id, i),
      ];
    }
    return [
      SerieReport(
        'Spese con le carte',
        etichette: [for (final i in iv) i.etichetta],
        serie: [
          for (final MapEntry(:key, :value) in perCarta.entries)
            (nome: key, valori: value),
        ],
        aColonne: true,
      ),
      TabellaReport(
        'Carte di credito',
        colonne: const ['Carta', 'Speso nel periodo', 'Debito di oggi'],
        righe: [
          for (final c in carte)
            [
              ValoreTesto(c.portafoglio.nome),
              ValoreImporto(
                perCarta[c.portafoglio.nome]!.fold<int>(0, (t, v) => t + v),
              ),
              ValoreImporto(c.debitoTotale),
            ],
        ],
      ),
    ];
  }

  Future<List<BloccoReport>> _rate(List<Intervallo> iv) async {
    final prestiti = await _prestiti.stati();
    final perIntervallo = [
      for (final i in iv)
        prestiti.fold<int>(0, (t, s) {
          var somma = t;
          for (final r in s.rate) {
            if (!r.data.isBefore(i.da) && !r.data.isAfter(i.a)) {
              somma += r.piano.rata + s.speseRata;
            }
          }
          return somma;
        }),
    ];
    return [
      SerieReport(
        'Rate nel periodo',
        etichette: [for (final i in iv) i.etichetta],
        serie: [(nome: 'Rate (con le spese)', valori: perIntervallo)],
        aColonne: true,
      ),
      TabellaReport(
        'Prestiti e rate',
        colonne: const [
          'Prestito',
          'Rate pagate',
          'Debito residuo',
          'Ancora da pagare',
        ],
        righe: [
          for (final s in prestiti)
            [
              ValoreTesto(s.prestito.nome),
              ValoreTesto('${s.ratePagate} / ${s.prestito.numeroRate}'),
              ValoreImporto(s.debitoResiduo),
              ValoreImporto(s.daPagare),
            ],
        ],
      ),
    ];
  }

  Future<List<BloccoReport>> _versamenti(List<Intervallo> iv) async {
    final obiettivi = await _obiettivi.stati();
    final versamenti = await (_db.select(
      _db.versamenti,
    )..where((v) => v.eliminato.equals(false))).get();
    final perIntervallo = [
      for (final i in iv)
        versamenti
            .where((v) {
              final d = Contabilita.daGiorno(v.data);
              return !d.isBefore(i.da) && !d.isAfter(i.a);
            })
            .fold<int>(0, (t, v) => t + v.importoMinimo),
    ];
    return [
      SerieReport(
        'Versamenti negli obiettivi',
        etichette: [for (final i in iv) i.etichetta],
        serie: [(nome: 'Versato', valori: perIntervallo)],
        aColonne: true,
      ),
      TabellaReport(
        'Obiettivi e collette',
        colonne: const ['Obiettivo', 'Versato', 'Obiettivo da raggiungere'],
        righe: [
          for (final o in obiettivi)
            [
              ValoreTesto(o.obiettivo.nome),
              ValoreImporto(o.versato),
              ValoreImporto(o.obiettivo.importoObiettivoMinimo),
            ],
        ],
      ),
    ];
  }

  // ------------------------------------------------------------- interni

  Future<int> _uscitePortafoglio(String portafoglioId, Intervallo i) async {
    final riga = await _db
        .customSelect(
          '''
          SELECT COALESCE(SUM(m.importo_minimo), 0) AS totale
          FROM movimenti m JOIN definizioni_tipo t ON t.id = m.tipo_id
          WHERE m.eliminato = 0 AND t.effetto = 'uscita'
            AND m.portafoglio_id = ? AND m.data BETWEEN ? AND ?
          ''',
          variables: [
            Variable.withString(portafoglioId),
            Variable.withString(Contabilita.giorno(i.da)),
            Variable.withString(Contabilita.giorno(i.a)),
          ],
        )
        .getSingle();
    return riga.read<int>('totale');
  }

  static String _periodo(Intervallo i) =>
      i.da == i.a ? _data(i.da) : '${_data(i.da)} - ${_data(i.a)}';

  static String _data(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
