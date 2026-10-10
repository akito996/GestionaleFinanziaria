import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../db/carte_credito.dart';
import '../db/contabilita.dart';
import '../db/costo_vita.dart';
import '../db/obiettivi.dart';
import '../db/prestiti.dart';
import '../db/statistiche.dart';
import '../db/tabelle.dart';
import '../importo.dart';
import '../sessione.dart';
import 'xlsx.dart';

/// Cosa si può esportare.
enum SezioneExport {
  portafogli('Portafogli e saldi'),
  movimenti('Movimenti del periodo'),
  spese('Spese per categoria (con grafico)'),
  costoVita('Costo della vita (con grafico)'),
  carte('Carte di credito'),
  prestiti('Prestiti e rate'),
  obiettivi('Obiettivi e collette');

  const SezioneExport(this.etichetta);

  final String etichetta;
}

class OpzioniExport {
  const OpzioniExport({
    required this.da,
    required this.a,
    required this.sezioni,
  });

  final DateTime da;
  final DateTime a;
  final Set<SezioneExport> sezioni;
}

/// Dati raccolti dall'archivio per l'export (una sola lettura, poi PDF ed Excel).
class DatiExport {
  DatiExport(this.opzioni, this.idArchivio, this.creatoIl);

  final OpzioniExport opzioni;
  final String idArchivio;
  final DateTime creatoIl;
  List<PortafoglioConSaldo> portafogli = const [];
  List<MovimentoDettaglio> movimenti = const [];
  List<SpesaCategoria> spese = const [];
  List<RiepilogoMese> costoVita = const [];
  List<CartaConStato> carte = const [];
  List<PrestitoConStato> prestiti = const [];
  List<ObiettivoConStato> obiettivi = const [];

  bool ha(SezioneExport s) => opzioni.sezioni.contains(s);
}

abstract final class Esportazione {
  /// Legge dall'archivio aperto tutto quello che serve per le sezioni scelte.
  static Future<DatiExport> raccogli(Sessione s, OpzioniExport o) async {
    final d = DatiExport(o, s.idArchivio ?? '', DateTime.now());
    if (d.ha(SezioneExport.portafogli)) {
      d.portafogli = await s.contabilita.osservaPortafogli().first;
    }
    if (d.ha(SezioneExport.movimenti)) {
      d.movimenti = await s.contabilita.movimentiTra(o.da, o.a);
    }
    if (d.ha(SezioneExport.spese)) {
      d.spese = await s.statistiche.spesePerCategoria(o.da, o.a);
    }
    if (d.ha(SezioneExport.costoVita)) {
      final mesi = <DateTime>[];
      var m = DateTime(o.da.year, o.da.month);
      final ultimo = DateTime(o.a.year, o.a.month);
      while (!m.isAfter(ultimo) && mesi.length < 24) {
        mesi.add(m);
        m = DateTime(m.year, m.month + 1);
      }
      d.costoVita = await s.costoVita.riepiloghi(mesi);
    }
    if (d.ha(SezioneExport.carte)) {
      d.carte = await s.carte.stati();
    }
    if (d.ha(SezioneExport.prestiti)) {
      d.prestiti = await s.prestiti.stati();
    }
    if (d.ha(SezioneExport.obiettivi)) {
      d.obiettivi = await s.obiettivi.stati();
    }
    return d;
  }

  // ===================================================================== PDF

  /// Report PDF leggibile con tabelle e grafici. [normale] e [grassetto] sono i
  /// file TTF del carattere da incorporare (Roboto): senza, si usa Helvetica,
  /// che non ha il simbolo dell'euro (sostituito da "EUR").
  static Future<Uint8List> pdf(
    DatiExport d, {
    ByteData? normale,
    ByteData? grassetto,
  }) async {
    final conCarattere = normale != null;
    final doc = pw.Document(
      title: 'GestionaleFinanziaria - Report',
      creator: 'GestionaleFinanziaria',
      theme: conCarattere
          ? pw.ThemeData.withFont(
              base: pw.Font.ttf(normale),
              bold: pw.Font.ttf(grassetto ?? normale),
            )
          : null,
    );
    String t(String testo) => _t(testo, carattereCompleto: conCarattere);
    const blu = PdfColor.fromInt(0xFF2A78D6);
    const arancio = PdfColor.fromInt(0xFFEB6834);
    const verde = PdfColor.fromInt(0xFF1BAF7A);
    const grigio = PdfColor.fromInt(0xFF6B6B66);

    String euro(int v) => t(Importo.formatta(v, 'EUR'));
    pw.Widget titolo(String testo) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
      child: pw.Text(
        t(testo),
        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
      ),
    );
    pw.Widget tabella(List<String> intestazione, List<List<String>> righe) =>
        pw.TableHelper.fromTextArray(
          headers: [for (final h in intestazione) t(h)],
          data: [
            for (final r in righe) [for (final c in r) t(c)],
          ],
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          // A destra solo le colonne di importi e numeri; il testo resta a sinistra.
          cellAlignments: {
            for (var i = 1; i < intestazione.length; i++)
              if (righe.isNotEmpty &&
                  righe.every(
                    (r) =>
                        i >= r.length ||
                        r[i].isEmpty ||
                        RegExp(r'^[-+−]?[\d.,]+( ?€)?$|^\d+ / \d+$')
                            .hasMatch(r[i]),
                  ))
                i: pw.Alignment.centerRight,
          },
          cellAlignment: pw.Alignment.centerLeft,
        );

    final contenuto = <pw.Widget>[
      pw.Text(
        'GestionaleFinanziaria - Report',
        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
      ),
      pw.Text(
        t(
          'Periodo: ${_data(d.opzioni.da)} - ${_data(d.opzioni.a)} · '
          'creato il ${_data(d.creatoIl)} · archivio ${d.idArchivio}',
        ),
        style: const pw.TextStyle(fontSize: 9, color: grigio),
      ),
    ];

    if (d.ha(SezioneExport.portafogli)) {
      final totale = d.portafogli.fold<int>(0, (t, p) => t + p.saldo);
      contenuto
        ..add(titolo('Portafogli e saldi'))
        ..add(
          tabella(
            ['Portafoglio', 'Tipo', 'Saldo'],
            [
              for (final p in d.portafogli)
                [p.portafoglio.nome, p.tipo.nome, euro(p.saldo)],
              ['Totale', '', euro(totale)],
            ],
          ),
        );
    }

    if (d.ha(SezioneExport.spese)) {
      final totale = d.spese.fold<int>(0, (t, s) => t + s.totale);
      final massimo = d.spese.fold<int>(
        0,
        (m, s) => s.totale > m ? s.totale : m,
      );
      contenuto
        ..add(titolo('Spese per categoria · totale ${euro(totale)}'))
        ..add(
          pw.Column(
            children: [
              for (final s in d.spese.take(12))
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 120,
                        child: pw.Text(
                          t(s.categoria ?? 'Senza categoria'),
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Align(
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Container(
                            height: 10,
                            width: massimo == 0 ? 0 : 280 * s.totale / massimo,
                            color: blu,
                          ),
                        ),
                      ),
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text(
                          euro(s.totale),
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
    }

    if (d.ha(SezioneExport.costoVita) && d.costoVita.isNotEmpty) {
      final massimo = d.costoVita.fold<int>(0, (m, r) {
        final v = r.totalePrevisto > r.fisse + r.variabiliReali
            ? r.totalePrevisto
            : r.fisse + r.variabiliReali;
        return v > m ? v : m;
      });
      const altezza = 120.0;
      double h(int v) => massimo == 0 ? 0 : altezza * v / massimo;
      pw.Widget legenda(PdfColor c, String testo) => pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(width: 8, height: 8, color: c),
          pw.SizedBox(width: 4),
          pw.Text(t(testo), style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(width: 12),
        ],
      );
      contenuto
        ..add(titolo('Costo della vita'))
        ..add(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              for (final r in d.costoVita)
                pw.Expanded(
                  child: pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Column(
                            children: [
                              pw.Container(
                                width: 12,
                                height: h(r.variabiliPreviste),
                                color: arancio,
                              ),
                              pw.Container(
                                width: 12,
                                height: h(r.fisse),
                                color: blu,
                              ),
                            ],
                          ),
                          pw.SizedBox(width: 2),
                          pw.Container(
                            width: 5,
                            height: h(r.fisse + r.variabiliReali),
                            color: verde,
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '${r.mese.month.toString().padLeft(2, '0')}/${r.mese.year % 100}',
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        )
        ..add(pw.SizedBox(height: 6))
        ..add(
          pw.Row(
            children: [
              legenda(blu, 'Fisse'),
              legenda(arancio, 'Variabili previste'),
              legenda(verde, 'Speso davvero (fisse + variabili)'),
            ],
          ),
        )
        ..add(pw.SizedBox(height: 8))
        ..add(
          tabella(
            [
              'Mese',
              'Fisse',
              'Variabili previste',
              'Variabili reali',
              'Totale previsto',
            ],
            [
              for (final r in d.costoVita)
                [
                  _mese(r.mese),
                  euro(r.fisse),
                  euro(r.variabiliPreviste),
                  euro(r.variabiliReali),
                  euro(r.totalePrevisto),
                ],
            ],
          ),
        );
      final ultimo = d.costoVita.last;
      if (ultimo.voci.isNotEmpty) {
        contenuto
          ..add(pw.SizedBox(height: 8))
          ..add(
            tabella(
              ['Voce (${_mese(ultimo.mese)})', 'Tipo', 'Previsto', 'Speso'],
              [
                for (final v in ultimo.voci)
                  [
                    v.voce.nome,
                    v.fissa ? 'Fissa' : 'Variabile',
                    euro(v.previsto),
                    v.reale == null ? '' : euro(v.reale!),
                  ],
              ],
            ),
          );
      }
    }

    if (d.ha(SezioneExport.carte) && d.carte.isNotEmpty) {
      contenuto
        ..add(titolo('Carte di credito'))
        ..add(
          tabella(
            ['Carta', 'Conto', 'Prossimo addebito', 'Importo', 'Debito totale'],
            [
              for (final c in d.carte)
                [
                  c.portafoglio.nome,
                  c.conto.nome,
                  _data(c.prossimoAddebito),
                  euro(c.daAddebitare),
                  euro(c.debitoTotale),
                ],
            ],
          ),
        );
    }

    if (d.ha(SezioneExport.prestiti) && d.prestiti.isNotEmpty) {
      contenuto
        ..add(titolo('Prestiti e rate'))
        ..add(
          tabella(
            [
              'Prestito',
              'Rata',
              'Rate pagate',
              'Prossima rata',
              'Debito residuo',
            ],
            [
              for (final p in d.prestiti)
                [
                  p.prestito.nome,
                  euro(p.prestito.importoRataMinimo),
                  '${p.ratePagate} / ${p.prestito.numeroRate}',
                  p.prossima == null ? '-' : _data(p.prossima!.data),
                  euro(p.debitoResiduo),
                ],
            ],
          ),
        );
    }

    if (d.ha(SezioneExport.obiettivi) && d.obiettivi.isNotEmpty) {
      contenuto
        ..add(titolo('Obiettivi e collette'))
        ..add(
          tabella(
            ['Obiettivo', 'Tipo', 'Versato', 'Obiettivo', 'Mancano'],
            [
              for (final o in d.obiettivi)
                [
                  o.obiettivo.nome,
                  o.colletta ? 'Colletta' : 'Personale',
                  euro(o.versato),
                  euro(o.obiettivo.importoObiettivoMinimo),
                  euro(o.mancante),
                ],
            ],
          ),
        );
      for (final o in d.obiettivi.where(
        (o) => o.colletta && o.quote.isNotEmpty,
      )) {
        contenuto
          ..add(pw.SizedBox(height: 6))
          ..add(
            tabella(
              [
                '${o.obiettivo.nome}: partecipante',
                'Quota',
                'Versato',
                'Mancano',
              ],
              [
                for (final q in o.quote)
                  [
                    q.partecipante.nome,
                    euro(q.quota),
                    euro(q.versato),
                    euro(q.mancante),
                  ],
              ],
            ),
          );
      }
    }

    if (d.ha(SezioneExport.movimenti)) {
      contenuto
        ..add(titolo('Movimenti del periodo (${d.movimenti.length})'))
        ..add(
          tabella(
            ['Data', 'Descrizione', 'Categoria', 'Portafoglio', 'Importo'],
            [
              for (final m in d.movimenti)
                [
                  _data(Contabilita.daGiorno(m.movimento.data)),
                  m.movimento.descrizione.isEmpty
                      ? m.tipo.nome
                      : m.movimento.descrizione,
                  m.categoria?.nome ?? '',
                  m.destinazione == null
                      ? m.portafoglio.nome
                      : '${m.portafoglio.nome} > ${m.destinazione!.nome}',
                  t(
                    Importo.formatta(
                      _importoConSegno(m),
                      m.movimento.valuta,
                      conSegno: m.tipo.effetto == EffettoSaldo.entrata,
                    ),
                  ),
                ],
            ],
          ),
        );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Pagina ${context.pageNumber} di ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: grigio),
          ),
        ),
        build: (_) => contenuto,
      ),
    );
    return doc.save();
  }

  // =================================================================== Excel

  /// File Excel con un foglio per sezione (dati completi, anche i piani rate).
  static Uint8List excel(DatiExport d) {
    final fogli = <Foglio>[];
    if (d.ha(SezioneExport.portafogli)) {
      final f = Foglio('Portafogli', [
        'Portafoglio',
        'Tipo',
        'Valuta',
        'Saldo',
      ]);
      for (final p in d.portafogli) {
        f.aggiungi([
          Testo(p.portafoglio.nome),
          Testo(p.tipo.nome),
          Testo(p.portafoglio.valuta),
          Euro(p.saldo),
        ]);
      }
      fogli.add(f);
    }
    if (d.ha(SezioneExport.movimenti)) {
      final f = Foglio('Movimenti', [
        'Data',
        'Tipo',
        'Descrizione',
        'Categoria',
        'Portafoglio',
        'Verso portafoglio',
        'Importo',
        'Valuta',
      ]);
      for (final m in d.movimenti) {
        f.aggiungi([
          Testo(_data(Contabilita.daGiorno(m.movimento.data))),
          Testo(m.tipo.nome),
          Testo(m.movimento.descrizione),
          Testo(m.categoria?.nome ?? ''),
          Testo(m.portafoglio.nome),
          Testo(m.destinazione?.nome ?? ''),
          Euro(_importoConSegno(m)),
          Testo(m.movimento.valuta),
        ]);
      }
      fogli.add(f);
    }
    if (d.ha(SezioneExport.spese)) {
      final f = Foglio('Spese per categoria', ['Categoria', 'Speso']);
      for (final s in d.spese) {
        f.aggiungi([Testo(s.categoria ?? 'Senza categoria'), Euro(s.totale)]);
      }
      fogli.add(f);
    }
    if (d.ha(SezioneExport.costoVita)) {
      final f = Foglio('Costo della vita', [
        'Mese',
        'Voce',
        'Tipo',
        'Previsto',
        'Speso',
        'Variato nel mese',
      ]);
      for (final r in d.costoVita) {
        for (final v in r.voci) {
          f.aggiungi([
            Testo(_mese(r.mese)),
            Testo(v.voce.nome),
            Testo(v.fissa ? 'Fissa' : 'Variabile'),
            Euro(v.previsto),
            if (v.reale == null) const Testo('') else Euro(v.reale!),
            Testo(v.variato ? 'Sì' : ''),
          ]);
        }
      }
      fogli.add(f);
    }
    if (d.ha(SezioneExport.carte)) {
      final f = Foglio('Carte di credito', [
        'Carta',
        'Conto di addebito',
        'Giorno addebito',
        'Prossimo addebito',
        'Importo',
        'Debito totale',
      ]);
      for (final c in d.carte) {
        f.aggiungi([
          Testo(c.portafoglio.nome),
          Testo(c.conto.nome),
          Numero(c.carta.giornoAddebito),
          Testo(_data(c.prossimoAddebito)),
          Euro(c.daAddebitare),
          Euro(c.debitoTotale),
        ]);
      }
      fogli.add(f);
    }
    if (d.ha(SezioneExport.prestiti)) {
      final f = Foglio('Piani delle rate', [
        'Prestito',
        'N.',
        'Data',
        'Rata',
        'Quota capitale',
        'Quota interessi',
        'Debito residuo',
        'Stato',
      ]);
      for (final p in d.prestiti) {
        for (final r in p.rate) {
          f.aggiungi([
            Testo(p.prestito.nome),
            Numero(r.piano.numero),
            Testo(_data(r.data)),
            Euro(r.piano.rata),
            Euro(r.piano.quotaCapitale),
            Euro(r.piano.quotaInteressi),
            Euro(r.piano.debitoResiduo),
            Testo(r.pagata ? 'Pagata' : 'Da pagare'),
          ]);
        }
      }
      fogli.add(f);
    }
    if (d.ha(SezioneExport.obiettivi)) {
      final f = Foglio('Obiettivi e collette', [
        'Obiettivo',
        'Tipo',
        'Partecipante',
        'Quota',
        'Versato',
        'Mancano',
      ]);
      for (final o in d.obiettivi) {
        f.aggiungi([
          Testo(o.obiettivo.nome),
          Testo(o.colletta ? 'Colletta' : 'Personale'),
          const Testo('Totale'),
          Euro(o.obiettivo.importoObiettivoMinimo),
          Euro(o.versato),
          Euro(o.mancante),
        ]);
        for (final q in o.quote) {
          f.aggiungi([
            Testo(o.obiettivo.nome),
            const Testo(''),
            Testo(q.partecipante.nome),
            Euro(q.quota),
            Euro(q.versato),
            Euro(q.mancante),
          ]);
        }
      }
      fogli.add(f);
    }
    if (fogli.isEmpty) {
      fogli.add(Foglio('Report', ['Nessuna sezione scelta']));
    }
    return Xlsx.crea(fogli);
  }

  // ------------------------------------------------------------------ utilità

  static int _importoConSegno(MovimentoDettaglio m) => switch (m.tipo.effetto) {
    EffettoSaldo.uscita => -m.movimento.importoMinimo,
    _ => m.movimento.importoMinimo,
  };

  static String _data(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _mese(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Con Roboto incorporato si tolgono solo le emoji; con Helvetica (latino
  /// occidentale) si sostituiscono anche i simboli fuori set, euro compreso.
  static String _t(String testo, {required bool carattereCompleto}) {
    final out = StringBuffer();
    for (final r in testo.runes) {
      if (carattereCompleto) {
        if (r < 0x2600) {
          out.writeCharCode(r);
        }
        continue;
      }
      out.write(switch (r) {
        0x2212 => '-',
        0x203A || 0x2192 => '>',
        0x2026 => '...',
        0x20AC => 'EUR',
        _ when r < 0x100 => String.fromCharCode(r),
        _ => '',
      });
    }
    return out.toString();
  }
}
