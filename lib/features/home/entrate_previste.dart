import 'package:flutter/material.dart';

import '../../core/db/costo_vita.dart';
import '../../core/db/tabelle.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../grafici/grafici_avanzati.dart';

/// Scheda della Panoramica: entrate previste del mese e margine previsto
/// (entrate previste − costo della vita), cioè quanto dovrebbe restarti.
class SchedaEntratePreviste extends StatefulWidget {
  const SchedaEntratePreviste({super.key, required this.sessione, this.onApri});

  final Sessione sessione;
  final VoidCallback? onApri;

  @override
  State<SchedaEntratePreviste> createState() => _SchedaEntratePrevisteState();
}

class _SchedaEntratePrevisteState extends State<SchedaEntratePreviste> {
  late final _mese = DateTime(DateTime.now().year, DateTime.now().month);
  late final Stream<RiepilogoMese> _entrate = widget.sessione.costoVita
      .osservaMese(_mese, natura: NaturaVoce.entrata);
  late final Stream<RiepilogoMese> _spese = widget.sessione.costoVita
      .osservaMese(_mese);

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    final colori = coloriVariazione(context);
    return StreamBuilder<RiepilogoMese>(
      stream: _entrate,
      builder: (context, entrate) => StreamBuilder<RiepilogoMese>(
        stream: _spese,
        builder: (context, spese) {
          final e = entrate.data;
          final s = spese.data;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onApri,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Entrate previste',
                            style: testo.labelLarge,
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    if (e == null || s == null)
                      const LinearProgressIndicator()
                    else if (e.vuoto)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Aggiungi lo stipendio e le altre entrate per vedere '
                          'quanto ti resta ogni mese.',
                        ),
                      )
                    else ...[
                      Text(
                        '${Importo.formatta(e.totalePrevisto, 'EUR')} al mese',
                        style: testo.headlineMedium,
                      ),
                      Text(
                        'Fisse ${Importo.formatta(e.fisse, 'EUR')} · '
                        'variabili previste '
                        '${Importo.formatta(e.variabiliPreviste, 'EUR')} · '
                        'ricevute finora '
                        '${Importo.formatta(e.variabiliReali, 'EUR')}',
                        style: testo.bodySmall,
                      ),
                      if (!s.vuoto) ...[
                        const SizedBox(height: 12),
                        _Margine(
                          entrate: e.totalePrevisto,
                          spese: s.totalePrevisto,
                          su: colori.su,
                          giu: colori.giu,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// "Ti restano 700 € al mese" (o "mancano"), con segno e icona: mai solo colore.
class _Margine extends StatelessWidget {
  const _Margine({
    required this.entrate,
    required this.spese,
    required this.su,
    required this.giu,
  });

  final int entrate;
  final int spese;
  final Color su;
  final Color giu;

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    final margine = entrate - spese;
    final positivo = margine >= 0;
    return Row(
      children: [
        Icon(
          positivo ? Icons.savings_outlined : Icons.warning_amber_outlined,
          color: positivo ? su : giu,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: positivo ? 'Margine previsto: ' : 'Mancano ogni mese: ',
                ),
                TextSpan(
                  text: Importo.formatta(margine, 'EUR', conSegno: true),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text:
                      ' (entrate ${Importo.formatta(entrate, 'EUR')} − '
                      'costo della vita ${Importo.formatta(spese, 'EUR')})',
                ),
              ],
            ),
            style: testo.bodyMedium,
          ),
        ),
      ],
    );
  }
}
