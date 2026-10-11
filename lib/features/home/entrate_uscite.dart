import 'package:flutter/material.dart';

import '../../core/db/statistiche.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../comuni/navigazione.dart';
import '../costo_vita/costo_vita_pagina.dart' show meseBreve;
import '../grafici/grafici.dart';
import '../grafici/grafici_avanzati.dart';

typedef DatiEntrateUscite = ({
  List<EntrateUscite> mesi,
  List<EntrateUscite> anni,
  ConfrontoPeriodo confrontoMese,
  ConfrontoPeriodo confrontoAnno,
});

/// Confronto tra entrate e uscite, mese per mese o anno per anno, con
/// l'andamento e il confronto con lo stesso tratto del periodo prima.
class SchedaEntrateUscite extends StatefulWidget {
  const SchedaEntrateUscite({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<SchedaEntrateUscite> createState() => _SchedaEntrateUsciteState();
}

class _SchedaEntrateUsciteState extends State<SchedaEntrateUscite> {
  static const _preferenzaAnni = 'panoramica.entrate_uscite.anni';

  late final Stream<DatiEntrateUscite> _dati = widget.sessione.statistiche
      .osservaEntrateUscite(DateTime.now());
  bool _anni = false;

  @override
  void initState() {
    super.initState();
    widget.sessione.statistiche.preferenza(_preferenzaAnni).then((v) {
      if (mounted && v == 'si') {
        setState(() => _anni = true);
      }
    });
  }

  void _scegli(bool anni) {
    setState(() => _anni = anni);
    widget.sessione.statistiche.salvaPreferenza(
      _preferenzaAnni,
      anni ? 'si' : 'no',
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatiEntrateUscite>(
      stream: _dati,
      builder: (context, snapshot) {
        final dati = snapshot.data;
        if (dati == null) {
          return const SizedBox.shrink();
        }
        final periodi = _anni ? dati.anni : dati.mesi;
        final etichette = [
          for (final p in periodi)
            _anni ? '${p.periodo.year}' : meseBreve(context, p.periodo),
        ];
        final colori = coloriVariazione(context);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SchedaGrafico(
            sessione: widget.sessione,
            chiave: 'panoramica.entrate_uscite',
            titolo: 'Entrate e uscite',
            sottotitolo: _anni ? 'Anno per anno' : 'Ultimi 12 mesi',
            azione: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Mesi')),
                ButtonSegment(value: true, label: Text('Anni')),
              ],
              selected: {_anni},
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              onSelectionChanged: (s) => _scegli(s.first),
            ),
            tipi: const [
              TipoGrafico.colonne,
              TipoGrafico.linee,
              TipoGrafico.tabella,
            ],
            costruisci: (context, tipo) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Riepilogo(
                  confronto: _anni ? dati.confrontoAnno : dati.confrontoMese,
                  anni: _anni,
                ),
                const SizedBox(height: 16),
                switch (tipo) {
                  TipoGrafico.linee => GraficoLinee(
                    etichette: etichette,
                    valuta: 'EUR',
                    serie: [
                      SerieTempo('Entrate', [
                        for (final p in periodi) p.entrate,
                      ], colore: colori.su),
                      SerieTempo('Uscite', [
                        for (final p in periodi) p.uscite,
                      ], colore: colori.giu),
                      SerieTempo('Risparmio', [
                        for (final p in periodi) p.differenza,
                      ], colore: colori.totale),
                    ],
                  ),
                  TipoGrafico.tabella => TabellaDati(
                    colonne: const [
                      'Periodo',
                      'Entrate',
                      'Uscite',
                      'Differenza',
                      'Risparmio',
                    ],
                    righe: [
                      for (final p in periodi.reversed)
                        [
                          _anni
                              ? '${p.periodo.year}'
                              : meseLeggibile(context, p.periodo),
                          Importo.formatta(p.entrate, 'EUR'),
                          Importo.formatta(p.uscite, 'EUR'),
                          Importo.formatta(p.differenza, 'EUR', conSegno: true),
                          _percentuale(p.risparmio),
                        ],
                    ],
                  ),
                  _ => ColonneRaggruppate(
                    etichette: etichette,
                    valuta: 'EUR',
                    serie: [
                      SerieTempo('Entrate', [
                        for (final p in periodi) p.entrate,
                      ], colore: colori.su),
                      SerieTempo('Uscite', [
                        for (final p in periodi) p.uscite,
                      ], colore: colori.giu),
                    ],
                  ),
                },
              ],
            ),
          ),
        );
      },
    );
  }
}

String _percentuale(double? quota, {bool conSegno = false}) {
  if (quota == null) {
    return '—';
  }
  final valore = (quota * 100).round();
  final segno = valore > 0 && conSegno ? '+' : (valore < 0 ? '−' : '');
  return '$segno${valore.abs()}%';
}

/// Il periodo in corso (dall'inizio a oggi) in tre numeri, più il confronto
/// con lo stesso tratto del periodo prima.
class _Riepilogo extends StatelessWidget {
  const _Riepilogo({required this.confronto, required this.anni});

  final ConfrontoPeriodo confronto;
  final bool anni;

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    final schema = Theme.of(context).colorScheme;
    final colori = coloriVariazione(context);
    final a = confronto.attuale;
    final p = confronto.precedente;
    final oggi = DateTime.now();
    final prima = anni
        ? 'allo stesso periodo del ${oggi.year - 1}'
        : 'agli stessi giorni di '
              '${meseLeggibile(context, DateTime(oggi.year, oggi.month - 1)).toLowerCase()}';

    Widget numero(String etichetta, int valore, Color colore, IconData icona) =>
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icona, size: 16, color: colore),
                  const SizedBox(width: 4),
                  Flexible(child: Text(etichetta, style: testo.labelMedium)),
                ],
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  Importo.formatta(
                    valore,
                    'EUR',
                    conSegno: etichetta == 'Differenza',
                  ),
                  style: testo.titleMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        );

    String variazione(String nome, int adesso, int primaValore) {
      final v = ConfrontoPeriodo.variazione(adesso, primaValore);
      return v == null
          ? '$nome ${Importo.formatta(adesso, 'EUR')}'
          : '$nome ${_percentuale(v, conSegno: true)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          anni ? 'Quest\'anno, fino a oggi' : 'Questo mese, fino a oggi',
          style: testo.labelLarge,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            numero('Entrate', a.entrate, colori.su, Icons.south_west),
            numero('Uscite', a.uscite, colori.giu, Icons.north_east),
            numero(
              'Differenza',
              a.differenza,
              colori.totale,
              Icons.savings_outlined,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          [
            if (a.risparmio != null)
              a.differenza >= 0
                  ? 'Hai messo da parte il ${_percentuale(a.risparmio)} delle entrate.'
                  : 'Hai speso più di quanto è entrato.',
            if (p.entrate > 0 || p.uscite > 0)
              'Rispetto $prima: '
                  '${variazione('entrate', a.entrate, p.entrate)}, '
                  '${variazione('uscite', a.uscite, p.uscite)}.',
          ].join(' '),
          style: testo.bodySmall?.copyWith(color: schema.onSurfaceVariant),
        ),
      ],
    );
  }
}
