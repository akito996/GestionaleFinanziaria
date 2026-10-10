import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/importo.dart';
import '../../core/sessione.dart';

/// Tipi di grafico tra cui l'utente può scegliere.
enum TipoGrafico {
  barreImpilate('barre_impilate', 'Barre impilate', Icons.stacked_bar_chart),
  barre('barre', 'Barre', Icons.bar_chart),
  linee('linee', 'Linee', Icons.show_chart),
  ciambella('ciambella', 'Ciambella', Icons.donut_large),
  tabella('tabella', 'Tabella', Icons.table_rows_outlined);

  const TipoGrafico(this.codice, this.etichetta, this.icona);

  final String codice;
  final String etichetta;
  final IconData icona;

  static TipoGrafico? daCodice(String? codice) =>
      TipoGrafico.values.where((t) => t.codice == codice).firstOrNull;
}

/// Palette categoriale validata (stessa per tutti i grafici), passi per chiaro/scuro.
List<Color> paletteCategorie(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const [
        Color(0xFF3987E5),
        Color(0xFFD95926),
        Color(0xFF199E70),
        Color(0xFFC98500),
        Color(0xFFD55181),
        Color(0xFF008300),
        Color(0xFF9085E9),
      ]
    : const [
        Color(0xFF2A78D6),
        Color(0xFFEB6834),
        Color(0xFF1BAF7A),
        Color(0xFFEDA100),
        Color(0xFFE87BA4),
        Color(0xFF008300),
        Color(0xFF4A3AA7),
      ];

/// Colore di una serie unica (blu della palette).
Color coloreSerie(BuildContext context) => paletteCategorie(context).first;

/// Grigio per "Altre".
Color coloreAltre(BuildContext context) =>
    Theme.of(context).colorScheme.outline;

/// Scheda con titolo e scelta del tipo di grafico. Il tipo scelto viene
/// ricordato (per schermata) nelle impostazioni locali dell'archivio.
class SchedaGrafico extends StatefulWidget {
  const SchedaGrafico({
    super.key,
    required this.sessione,
    required this.chiave,
    required this.titolo,
    required this.tipi,
    required this.costruisci,
    this.sottotitolo,
    this.azione,
  });

  final Sessione sessione;

  /// Identifica la schermata (es. "panoramica.spese_categoria").
  final String chiave;
  final String titolo;
  final String? sottotitolo;

  /// Tipi ammessi; il primo è il predefinito (il più chiaro per questi dati).
  final List<TipoGrafico> tipi;
  final Widget Function(BuildContext context, TipoGrafico tipo) costruisci;
  final Widget? azione;

  @override
  State<SchedaGrafico> createState() => _SchedaGraficoState();
}

class _SchedaGraficoState extends State<SchedaGrafico> {
  late TipoGrafico _tipo = widget.tipi.first;

  @override
  void initState() {
    super.initState();
    widget.sessione.statistiche.preferenza('grafico.${widget.chiave}').then((
      v,
    ) {
      final tipo = TipoGrafico.daCodice(v);
      if (tipo != null && widget.tipi.contains(tipo) && mounted) {
        setState(() => _tipo = tipo);
      }
    });
  }

  void _scegli(TipoGrafico tipo) {
    setState(() => _tipo = tipo);
    widget.sessione.statistiche.salvaPreferenza(
      'grafico.${widget.chiave}',
      tipo.codice,
    );
  }

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.titolo, style: testo.titleMedium),
                      if (widget.sottotitolo != null)
                        Text(widget.sottotitolo!, style: testo.bodySmall),
                    ],
                  ),
                ),
                ?widget.azione,
                PopupMenuButton<TipoGrafico>(
                  tooltip: 'Tipo di grafico',
                  icon: Icon(_tipo.icona),
                  initialValue: _tipo,
                  onSelected: _scegli,
                  itemBuilder: (_) => [
                    for (final t in widget.tipi)
                      PopupMenuItem(
                        value: t,
                        child: ListTile(
                          leading: Icon(t.icona),
                          title: Text(
                            t == widget.tipi.first
                                ? '${t.etichetta} (consigliato)'
                                : t.etichetta,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: widget.costruisci(context, _tipo),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una voce con un valore (categoria → importo).
class VoceValore {
  const VoceValore(this.etichetta, this.valore);

  final String etichetta;
  final int valore;
}

/// Raggruppa le voci oltre [massimo] in "Altre" (mai più colori della palette).
List<VoceValore> conAltre(List<VoceValore> voci, {int massimo = 6}) {
  if (voci.length <= massimo) {
    return voci;
  }
  final altre = voci.skip(massimo - 1).fold<int>(0, (t, v) => t + v.valore);
  return [...voci.take(massimo - 1), VoceValore('Altre', altre)];
}

/// Barre orizzontali ordinate, un solo colore, valore scritto accanto.
class BarreOrizzontali extends StatelessWidget {
  const BarreOrizzontali({super.key, required this.voci, required this.valuta});

  final List<VoceValore> voci;
  final String valuta;

  @override
  Widget build(BuildContext context) {
    final massimo = voci.fold<int>(0, (m, v) => v.valore > m ? v.valore : m);
    final colore = coloreSerie(context);
    final schema = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final v in conAltre(voci, massimo: 8))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    v.etichetta,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, vincoli) => Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 14,
                        width: massimo == 0
                            ? 0
                            : vincoli.maxWidth * v.valore / massimo,
                        decoration: BoxDecoration(
                          color: v.etichetta == 'Altre'
                              ? coloreAltre(context)
                              : colore,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 96,
                  child: Text(
                    Importo.formatta(v.valore, valuta),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: schema.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Ciambella (massimo 6 fette + "Altre") con legenda e valori.
class Ciambella extends StatelessWidget {
  const Ciambella({super.key, required this.voci, required this.valuta});

  final List<VoceValore> voci;
  final String valuta;

  @override
  Widget build(BuildContext context) {
    final fette = conAltre(voci);
    final palette = paletteCategorie(context);
    final totale = fette.fold<int>(0, (t, v) => t + v.valore);
    final superficie = Theme.of(context).colorScheme.surfaceContainerLow;
    Color colore(int i, VoceValore v) => v.etichetta == 'Altre'
        ? coloreAltre(context)
        : palette[i % palette.length];
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 44,
              sectionsSpace: 2,
              sections: [
                for (final (i, v) in fette.indexed)
                  PieChartSectionData(
                    value: v.valore.toDouble(),
                    color: colore(i, v),
                    showTitle: false,
                    radius: 30,
                    borderSide: BorderSide(color: superficie, width: 2),
                  ),
              ],
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, v) in fette.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colore(i, v),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${v.etichetta}: ${Importo.formatta(v.valore, valuta)}'
                      '${totale == 0 ? '' : ' (${(v.valore * 100 / totale).round()}%)'}',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Una serie di valori nel tempo per [GraficoLinee].
class SerieTempo {
  const SerieTempo(this.nome, this.valori);

  final String nome;
  final List<int> valori;
}

/// Linee sottili con punti; una sola scala (euro). Legenda se più serie.
class GraficoLinee extends StatelessWidget {
  const GraficoLinee({
    super.key,
    required this.etichette,
    required this.serie,
    required this.valuta,
    this.altezza = 200,
  });

  final List<String> etichette;
  final List<SerieTempo> serie;
  final String valuta;
  final double altezza;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final palette = paletteCategorie(context);
    final tutti = [for (final s in serie) ...s.valori];
    final minimo = tutti.isEmpty ? 0 : tutti.reduce((a, b) => a < b ? a : b);
    final massimo = tutti.isEmpty ? 0 : tutti.reduce((a, b) => a > b ? a : b);
    final basso = (minimo < 0 ? minimo * 1.15 : 0) / 100;
    var alto = massimo / 100 * 1.15;
    if (alto <= basso) {
      alto = basso + 100;
    }
    final testoSecondario = tema.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: altezza,
          child: LineChart(
            LineChartData(
              minY: basso,
              maxY: alto,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
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
                    showTitles: true,
                    reservedSize: 52,
                    getTitlesWidget: (v, meta) => v == meta.max || v == meta.min
                        ? const SizedBox.shrink()
                        : Text(
                            '${v.round()}',
                            style: TextStyle(
                              color: testoSecondario,
                              fontSize: 11,
                            ),
                          ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 24,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= etichette.length || v != i.toDouble()) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          etichette[i],
                          style: TextStyle(
                            color: testoSecondario,
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => tema.colorScheme.inverseSurface,
                  getTooltipItems: (punti) => [
                    for (final p in punti)
                      LineTooltipItem(
                        '${serie.length > 1 ? '${serie[p.barIndex].nome}: ' : ''}'
                        '${Importo.formatta((p.y * 100).round(), valuta)}',
                        TextStyle(color: tema.colorScheme.onInverseSurface),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                for (final (i, s) in serie.indexed)
                  LineChartBarData(
                    spots: [
                      for (final (x, v) in s.valori.indexed)
                        FlSpot(x.toDouble(), v / 100),
                    ],
                    color: palette[i % palette.length],
                    barWidth: 2,
                    dotData: FlDotData(
                      getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                        radius: 4,
                        color: palette[i % palette.length],
                        strokeColor: tema.colorScheme.surfaceContainerLow,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (serie.length > 1) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: [
              for (final (i, s) in serie.indexed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 2,
                      color: palette[i % palette.length],
                    ),
                    const SizedBox(width: 6),
                    Text(s.nome, style: tema.textTheme.bodySmall),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Tabella semplice (alternativa sempre leggibile a ogni grafico).
class TabellaDati extends StatelessWidget {
  const TabellaDati({super.key, required this.colonne, required this.righe});

  final List<String> colonne;
  final List<List<String>> righe;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        headingRowHeight: 36,
        dataRowMinHeight: 32,
        dataRowMaxHeight: 40,
        columns: [
          for (final (i, c) in colonne.indexed)
            DataColumn(label: Text(c), numeric: i > 0),
        ],
        rows: [
          for (final r in righe)
            DataRow(cells: [for (final c in r) DataCell(Text(c))]),
        ],
      ),
    );
  }
}
