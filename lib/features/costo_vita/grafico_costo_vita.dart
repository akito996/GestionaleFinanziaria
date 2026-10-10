import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/db/costo_vita.dart';
import '../../core/importo.dart';

/// Colori delle tre serie (palette validata, passi diversi per chiaro e scuro).
class ColoriCostoVita {
  const ColoriCostoVita._(this.fisse, this.variabili, this.reali);

  factory ColoriCostoVita.di(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const ColoriCostoVita._(
          Color(0xFF3987E5),
          Color(0xFFD95926),
          Color(0xFF199E70),
        )
      : const ColoriCostoVita._(
          Color(0xFF2A78D6),
          Color(0xFFEB6834),
          Color(0xFF1BAF7A),
        );

  final Color fisse;
  final Color variabili;
  final Color reali;
}

/// Barre impilate per mese: spese fisse + variabili previste. Il punto verde è
/// quanto hai speso davvero (fisse + variabili reali). Tocca una barra per i valori.
class GraficoCostoVita extends StatelessWidget {
  const GraficoCostoVita({
    super.key,
    required this.mesi,
    required this.nomeMese,
    this.altezza = 220,
    this.compatto = false,
  });

  final List<RiepilogoMese> mesi;

  /// Etichetta breve dell'asse (es. "ott").
  final String Function(DateTime mese) nomeMese;
  final double altezza;
  final bool compatto;

  @override
  Widget build(BuildContext context) {
    final colori = ColoriCostoVita.di(context);
    final tema = Theme.of(context);
    final superficie = tema.colorScheme.surfaceContainerLow;
    final testoSecondario = tema.colorScheme.onSurfaceVariant;

    double euro(int minimo) => minimo / 100;
    final massimo = mesi.fold<int>(0, (m, r) {
      final realeTotale = r.fisse + r.variabiliReali;
      final valore = r.totalePrevisto > realeTotale
          ? r.totalePrevisto
          : realeTotale;
      return valore > m ? valore : m;
    });
    final tetto = massimo == 0 ? 100.0 : euro(massimo) * 1.15;
    final larghezzaBarra = compatto ? 14.0 : 22.0;

    final barre = BarChartData(
      maxY: tetto,
      alignment: BarChartAlignment.spaceAround,
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: tetto / 4,
        getDrawingHorizontalLine: (_) => FlLine(
          color: tema.colorScheme.outlineVariant.withValues(alpha: 0.5),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: !compatto,
            reservedSize: 48,
            interval: tetto / 4,
            getTitlesWidget: (valore, meta) => valore == meta.max
                ? const SizedBox.shrink()
                : Text(
                    '${valore.round()}',
                    style: TextStyle(color: testoSecondario, fontSize: 11),
                  ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (valore, _) {
              final i = valore.toInt();
              if (i < 0 || i >= mesi.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  nomeMese(mesi[i].mese),
                  style: TextStyle(color: testoSecondario, fontSize: 11),
                ),
              );
            },
          ),
        ),
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => tema.colorScheme.inverseSurface,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItem: (gruppo, _, _, _) {
            final r = mesi[gruppo.x];
            final stile = TextStyle(
              color: tema.colorScheme.onInverseSurface,
              fontSize: 12,
            );
            return BarTooltipItem(
              '${nomeMese(r.mese)}\n',
              stile.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.left,
              children: [
                TextSpan(
                  text:
                      'Fisse: ${Importo.formatta(r.fisse, 'EUR')}\n'
                      'Variabili previste: '
                      '${Importo.formatta(r.variabiliPreviste, 'EUR')}\n'
                      'Variabili reali: '
                      '${Importo.formatta(r.variabiliReali, 'EUR')}',
                  style: stile,
                ),
              ],
            );
          },
        ),
      ),
      barGroups: [
        for (final (i, r) in mesi.indexed)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: euro(r.totalePrevisto),
                width: larghezzaBarra,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                rodStackItems: [
                  BarChartRodStackItem(0, euro(r.fisse), colori.fisse),
                  // 2px di separazione tra i segmenti, col colore della superficie.
                  if (r.variabiliPreviste > 0)
                    BarChartRodStackItem(
                      euro(r.fisse),
                      euro(r.totalePrevisto),
                      colori.variabili,
                      borderSide: BorderSide(color: superficie, width: 2),
                    ),
                ],
                color: Colors.transparent,
              ),
            ],
          ),
      ],
    );

    // Punti "speso davvero" sopra le barre (stessa scala, un solo asse).
    final punti = ScatterChartData(
      minX: -0.5,
      maxX: mesi.length - 0.5,
      minY: 0,
      maxY: tetto,
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      scatterTouchData: ScatterTouchData(enabled: false),
      scatterSpots: [
        for (final (i, r) in mesi.indexed)
          if (r.voci.any((v) => !v.fissa && v.reale != null))
            ScatterSpot(
              i.toDouble(),
              euro(r.fisse + r.variabiliReali),
              dotPainter: FlDotCirclePainter(
                radius: compatto ? 4 : 5,
                color: colori.reali,
                strokeColor: superficie,
                strokeWidth: 2,
              ),
            ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: altezza,
          child: Stack(
            children: [
              BarChart(barre),
              // Il livello dei punti non intercetta i tocchi delle barre.
              IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.only(left: compatto ? 0 : 48, bottom: 24),
                  child: ScatterChart(punti),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            _Legenda(colore: colori.fisse, testo: 'Fisse'),
            _Legenda(colore: colori.variabili, testo: 'Variabili previste'),
            _Legenda(colore: colori.reali, testo: 'Speso davvero', tondo: true),
          ],
        ),
      ],
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({
    required this.colore,
    required this.testo,
    this.tondo = false,
  });

  final Color colore;
  final String testo;
  final bool tondo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: colore,
            shape: tondo ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: tondo ? null : BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(testo, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
