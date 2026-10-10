import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/db/statistiche.dart';
import '../../core/importo.dart';
import 'grafici.dart';

/// Colori "su/giù" leggibili anche con daltonismo (verde acqua / arancio),
/// totali in blu. Sempre accompagnati da segno e legenda, mai solo colore.
({Color su, Color giu, Color totale}) coloriVariazione(BuildContext context) {
  final p = paletteCategorie(context);
  return (su: p[2], giu: p[1], totale: p[0]);
}

Widget _legenda(BuildContext context, List<(Color, String)> voci) => Wrap(
  spacing: 16,
  runSpacing: 4,
  children: [
    for (final (colore, testo) in voci)
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: colore,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(testo, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
  ],
);

FlTitlesData _titoli(
  BuildContext context, {
  required List<String> etichette,
  bool asseY = true,
}) {
  final colore = Theme.of(context).colorScheme.onSurfaceVariant;
  return FlTitlesData(
    topTitles: const AxisTitles(),
    rightTitles: const AxisTitles(),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: asseY,
        reservedSize: 52,
        getTitlesWidget: (v, meta) => v == meta.max || v == meta.min
            ? const SizedBox.shrink()
            : Text(
                '${v.round()}',
                style: TextStyle(color: colore, fontSize: 11),
              ),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 36,
        getTitlesWidget: (v, _) {
          final i = v.toInt();
          if (i < 0 || i >= etichette.length) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              etichette[i],
              style: TextStyle(color: colore, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    ),
  );
}

FlGridData _griglia(BuildContext context) => FlGridData(
  drawVerticalLine: false,
  getDrawingHorizontalLine: (_) => FlLine(
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
    strokeWidth: 1,
  ),
);

BarTouchData _suggerimento(
  BuildContext context,
  String Function(int gruppo, int asta) testo,
) => BarTouchData(
  touchTooltipData: BarTouchTooltipData(
    getTooltipColor: (_) => Theme.of(context).colorScheme.inverseSurface,
    fitInsideHorizontally: true,
    fitInsideVertically: true,
    getTooltipItem: (g, _, _, asta) => BarTooltipItem(
      testo(g.x, asta),
      TextStyle(
        color: Theme.of(context).colorScheme.onInverseSurface,
        fontSize: 12,
      ),
    ),
  ),
);

/// Colonne verticali di una serie (es. spese per categoria).
class Colonne extends StatelessWidget {
  const Colonne({
    super.key,
    required this.voci,
    required this.valuta,
    this.altezza = 220,
  });

  final List<VoceValore> voci;
  final String valuta;
  final double altezza;

  @override
  Widget build(BuildContext context) {
    final dati = conAltre(voci, massimo: 8);
    final massimo = dati.fold<int>(0, (m, v) => v.valore > m ? v.valore : m);
    final colore = coloreSerie(context);
    return SizedBox(
      height: altezza,
      child: BarChart(
        BarChartData(
          maxY: massimo == 0 ? 1 : massimo / 100 * 1.15,
          borderData: FlBorderData(show: false),
          gridData: _griglia(context),
          titlesData: _titoli(
            context,
            etichette: [for (final v in dati) v.etichetta],
          ),
          barTouchData: _suggerimento(
            context,
            (g, _) =>
                '${dati[g].etichetta}\n${Importo.formatta(dati[g].valore, valuta)}',
          ),
          barGroups: [
            for (final (i, v) in dati.indexed)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: v.valore / 100,
                    width: 20,
                    color: v.etichetta == 'Altre'
                        ? coloreAltre(context)
                        : colore,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Colonne raggruppate nel tempo (più serie per periodo), un solo asse.
class ColonneRaggruppate extends StatelessWidget {
  const ColonneRaggruppate({
    super.key,
    required this.etichette,
    required this.serie,
    required this.valuta,
    this.altezza = 220,
  });

  final List<String> etichette;
  final List<SerieTempo> serie;
  final String valuta;
  final double altezza;

  @override
  Widget build(BuildContext context) {
    final palette = paletteCategorie(context);
    final tutti = [for (final s in serie) ...s.valori];
    final massimo = tutti.isEmpty ? 0 : tutti.reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: altezza,
          child: BarChart(
            BarChartData(
              maxY: massimo == 0 ? 1 : massimo / 100 * 1.15,
              borderData: FlBorderData(show: false),
              gridData: _griglia(context),
              titlesData: _titoli(context, etichette: etichette),
              barTouchData: _suggerimento(
                context,
                (g, a) =>
                    '${serie[a].nome}\n${Importo.formatta(serie[a].valori[g], valuta)}',
              ),
              barGroups: [
                for (var i = 0; i < etichette.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 2,
                    barRods: [
                      for (final (k, s) in serie.indexed)
                        BarChartRodData(
                          toY: s.valori[i] / 100,
                          width: 8,
                          color: palette[k % palette.length],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _legenda(context, [
          for (final (k, s) in serie.indexed)
            (palette[k % palette.length], s.nome),
        ]),
      ],
    );
  }
}

/// Grafico a cascata (waterfall): dal valore iniziale al finale, passando per
/// aumenti (verde acqua, "+") e diminuzioni (arancio, "−").
class Cascata extends StatelessWidget {
  const Cascata({
    super.key,
    required this.passi,
    required this.valuta,
    this.altezza = 240,
  });

  final List<PassoCascata> passi;
  final String valuta;
  final double altezza;

  @override
  Widget build(BuildContext context) {
    final colori = coloriVariazione(context);
    final barre = <({double da, double a, Color colore})>[];
    var livello = 0;
    for (final p in passi) {
      if (p.totale) {
        livello = p.valore;
        barre.add((da: 0, a: p.valore / 100, colore: colori.totale));
      } else {
        final prima = livello;
        livello += p.valore;
        barre.add((
          da: prima / 100,
          a: livello / 100,
          colore: p.valore >= 0 ? colori.su : colori.giu,
        ));
      }
    }
    final valori = [
      for (final b in barre) ...[b.da, b.a],
    ];
    final alto = valori.isEmpty ? 1.0 : valori.reduce((a, b) => a > b ? a : b);
    final basso = valori.isEmpty ? 0.0 : valori.reduce((a, b) => a < b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: altezza,
          child: BarChart(
            BarChartData(
              maxY: alto <= 0 ? 1 : alto * 1.1,
              minY: basso < 0 ? basso * 1.1 : 0,
              borderData: FlBorderData(show: false),
              gridData: _griglia(context),
              titlesData: _titoli(
                context,
                etichette: [for (final p in passi) p.etichetta],
              ),
              barTouchData: _suggerimento(context, (g, _) {
                final p = passi[g];
                return '${p.etichetta}\n'
                    '${Importo.formatta(p.valore, valuta, conSegno: !p.totale)}';
              }),
              barGroups: [
                for (final (i, b) in barre.indexed)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        fromY: b.da < b.a ? b.da : b.a,
                        toY: b.da < b.a ? b.a : b.da,
                        width: 22,
                        color: b.colore,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _legenda(context, [
          (colori.totale, 'Saldo'),
          (colori.su, '+ Entrate'),
          (colori.giu, '− Spese'),
        ]),
      ],
    );
  }
}

/// Stato patrimoniale: colonna delle attività e colonna delle passività,
/// impilate per voce, con il patrimonio netto.
class StatoPatrimonialeGrafico extends StatelessWidget {
  const StatoPatrimonialeGrafico({
    super.key,
    required this.patrimonio,
    required this.valuta,
    this.altezza = 200,
  });

  final Patrimonio patrimonio;
  final String valuta;
  final double altezza;

  @override
  Widget build(BuildContext context) {
    final palette = paletteCategorie(context);
    final schema = Theme.of(context).colorScheme;
    final testo = Theme.of(context).textTheme;
    final p = patrimonio;
    final massimo = [
      p.totaleAttivita,
      p.totalePassivita,
      1,
    ].reduce((a, b) => a > b ? a : b);
    // Attività in blu/verde acqua/viola…, passività in arancio/giallo/rosa.
    final coloriAttivita = [palette[0], palette[2], palette[6], palette[5]];
    final coloriPassivita = [palette[1], palette[3], palette[4]];

    Widget colonna(
      String titolo,
      List<VocePatrimonio> voci,
      List<Color> colori,
      int totale,
    ) => Expanded(
      child: Column(
        children: [
          SizedBox(
            height: altezza,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 64,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (final (i, v) in voci.indexed.toList().reversed)
                      Tooltip(
                        message:
                            '${v.nome}: ${Importo.formatta(v.importo, valuta)}',
                        child: Container(
                          height:
                              (altezza - 2 * voci.length) *
                              v.importo /
                              massimo, // meno gli spazi tra i segmenti
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: colori[i % colori.length],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(titolo, style: testo.labelLarge),
          Text(Importo.formatta(totale, valuta), style: testo.titleMedium),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            colonna('Attività', p.attivita, coloriAttivita, p.totaleAttivita),
            colonna(
              'Passività',
              p.passivita,
              coloriPassivita,
              p.totalePassivita,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Patrimonio netto: ${Importo.formatta(p.netto, valuta)}',
            style: testo.titleMedium?.copyWith(
              color: p.netto < 0 ? schema.error : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _legenda(context, [
          for (final (i, v) in p.attivita.indexed)
            (coloriAttivita[i % coloriAttivita.length], v.nome),
          for (final (i, v) in p.passivita.indexed)
            (coloriPassivita[i % coloriPassivita.length], v.nome),
        ]),
      ],
    );
  }
}

/// Candele mensili del saldo: corpo da apertura a chiusura (verde acqua se è
/// cresciuto, arancio se è sceso), stoppino dal minimo al massimo del mese.
class CandeleGrafico extends StatelessWidget {
  const CandeleGrafico({
    super.key,
    required this.candele,
    required this.etichette,
    required this.valuta,
    this.altezza = 220,
  });

  final List<CandelaSaldo> candele;
  final List<String> etichette;
  final String valuta;
  final double altezza;

  @override
  Widget build(BuildContext context) {
    final colori = coloriVariazione(context);
    final schema = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: altezza,
          child: CustomPaint(
            size: Size.infinite,
            painter: _PittoreCandele(
              candele: candele,
              etichette: etichette,
              su: colori.su,
              giu: colori.giu,
              griglia: schema.outlineVariant.withValues(alpha: 0.5),
              testo: schema.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _legenda(context, [
          (colori.su, 'Mese chiuso in crescita'),
          (colori.giu, 'Mese chiuso in calo'),
        ]),
        Text(
          'Linea sottile: minimo e massimo del mese · corpo: inizio e fine mese',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PittoreCandele extends CustomPainter {
  _PittoreCandele({
    required this.candele,
    required this.etichette,
    required this.su,
    required this.giu,
    required this.griglia,
    required this.testo,
  });

  final List<CandelaSaldo> candele;
  final List<String> etichette;
  final Color su;
  final Color giu;
  final Color griglia;
  final Color testo;

  @override
  void paint(Canvas canvas, Size size) {
    if (candele.isEmpty) {
      return;
    }
    const sinistra = 52.0;
    const basso = 22.0;
    final area = Rect.fromLTRB(sinistra, 8, size.width, size.height - basso);
    var minimo = candele.map((c) => c.minimo).reduce((a, b) => a < b ? a : b);
    var massimo = candele.map((c) => c.massimo).reduce((a, b) => a > b ? a : b);
    if (massimo == minimo) {
      massimo += 100;
      minimo -= 100;
    }
    final margine = (massimo - minimo) * 0.08;
    final alto = massimo + margine;
    final giuY = minimo - margine;
    double y(num v) => area.bottom - (v - giuY) / (alto - giuY) * area.height;

    final lineaGriglia = Paint()
      ..color = griglia
      ..strokeWidth = 1;
    final stile = TextStyle(color: testo, fontSize: 10);
    for (var k = 0; k <= 4; k++) {
      final valore = giuY + (alto - giuY) * k / 4;
      final yy = y(valore);
      canvas.drawLine(
        Offset(area.left, yy),
        Offset(area.right, yy),
        lineaGriglia,
      );
      if (k > 0 && k < 4) {
        final tp = TextPainter(
          text: TextSpan(text: '${(valore / 100).round()}', style: stile),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(0, yy - tp.height / 2));
      }
    }

    final passo = area.width / candele.length;
    final larghezza = (passo * 0.5).clamp(4.0, 18.0);
    for (final (i, c) in candele.indexed) {
      final x = area.left + passo * (i + 0.5);
      final colore = c.crescita ? su : giu;
      final pennello = Paint()..color = colore;
      canvas.drawLine(
        Offset(x, y(c.massimo)),
        Offset(x, y(c.minimo)),
        pennello..strokeWidth = 2,
      );
      final top = y(c.apertura > c.chiusura ? c.apertura : c.chiusura);
      final bottom = y(c.apertura > c.chiusura ? c.chiusura : c.apertura);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            x - larghezza / 2,
            top,
            x + larghezza / 2,
            bottom < top + 2 ? top + 2 : bottom,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = colore,
      );
      if (i < etichette.length) {
        final tp = TextPainter(
          text: TextSpan(text: etichette[i], style: stile),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, area.bottom + 6));
      }
    }
  }

  @override
  bool shouldRepaint(_PittoreCandele vecchio) =>
      vecchio.candele != candele || vecchio.su != su;
}
