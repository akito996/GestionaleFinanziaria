import 'package:flutter/material.dart';

import '../../core/sessione.dart';

/// Schede della Panoramica che si possono riordinare o nascondere. Totale e
/// portafogli restano sempre visibili e non sono in questo elenco.
///
/// Il [codice] è salvato nelle preferenze: non cambiarlo per le schede esistenti.
enum SchedaPanoramica {
  inArrivo('in_arrivo', 'In arrivo', 'Scadenze dei prossimi giorni'),
  costoVita('costo_vita', 'Costo della vita', 'Spese fisse e variabili'),
  entrateUscite('entrate_uscite', 'Entrate e uscite', 'Confronto e andamento'),
  spese('spese', 'Spese del mese', 'Per categoria'),
  flusso('flusso', 'Flusso del mese', 'Da inizio a fine mese'),
  patrimonio('patrimonio', 'Patrimonio', 'Cosa possiedi e cosa devi'),
  movimenti('movimenti', 'Ultimi movimenti', 'Gli ultimi 30');

  const SchedaPanoramica(this.codice, this.titolo, this.descrizione);

  final String codice;
  final String titolo;
  final String descrizione;
}

/// Ordine e visibilità delle schede, salvati come testo:
/// `costo_vita,entrate_uscite,-flusso,...` (il "-" = nascosta).
class ConfigurazionePanoramica {
  const ConfigurazionePanoramica(this.ordine, this.nascoste);

  static const chiave = 'panoramica.schede';

  static final predefinita = ConfigurazionePanoramica(
    SchedaPanoramica.values,
    const {},
  );

  final List<SchedaPanoramica> ordine;
  final Set<SchedaPanoramica> nascoste;

  /// Le schede visibili, nell'ordine scelto.
  List<SchedaPanoramica> get visibili => [
    for (final s in ordine)
      if (!nascoste.contains(s)) s,
  ];

  /// Legge il testo salvato. Le schede sconosciute si ignorano; quelle nuove
  /// (aggiunte da versioni successive dell'app) vanno in fondo, visibili.
  factory ConfigurazionePanoramica.leggi(String? testo) {
    if (testo == null || testo.trim().isEmpty) {
      return predefinita;
    }
    final ordine = <SchedaPanoramica>[];
    final nascoste = <SchedaPanoramica>{};
    for (final parte in testo.split(',')) {
      final nascosta = parte.startsWith('-');
      final codice = nascosta ? parte.substring(1) : parte;
      final scheda = SchedaPanoramica.values
          .where((s) => s.codice == codice)
          .firstOrNull;
      if (scheda == null || ordine.contains(scheda)) {
        continue;
      }
      ordine.add(scheda);
      if (nascosta) {
        nascoste.add(scheda);
      }
    }
    for (final s in SchedaPanoramica.values) {
      if (!ordine.contains(s)) {
        ordine.add(s);
      }
    }
    return ConfigurazionePanoramica(ordine, nascoste);
  }

  String scrivi() =>
      [for (final s in ordine) nascoste.contains(s) ? '-${s.codice}' : s.codice]
          .join(',');
}

/// Finestra "Personalizza la Panoramica": trascina per l'ordine, spunta per
/// mostrare o nascondere. Restituisce la nuova configurazione (già salvata).
Future<ConfigurazionePanoramica?> personalizzaPanoramica(
  BuildContext context,
  Sessione sessione,
  ConfigurazionePanoramica attuale,
) async {
  final scelta = await showDialog<ConfigurazionePanoramica>(
    context: context,
    builder: (_) => _DialogoPersonalizza(attuale: attuale),
  );
  if (scelta != null) {
    await sessione.statistiche.salvaPreferenza(
      ConfigurazionePanoramica.chiave,
      scelta.scrivi(),
    );
  }
  return scelta;
}

class _DialogoPersonalizza extends StatefulWidget {
  const _DialogoPersonalizza({required this.attuale});

  final ConfigurazionePanoramica attuale;

  @override
  State<_DialogoPersonalizza> createState() => _DialogoPersonalizzaState();
}

class _DialogoPersonalizzaState extends State<_DialogoPersonalizza> {
  late final _ordine = [...widget.attuale.ordine];
  late final _nascoste = {...widget.attuale.nascoste};

  void _sposta(int da, int a) =>
      setState(() => _ordine.insert(a, _ordine.removeAt(da)));

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Personalizza la Panoramica'),
      contentPadding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Totale e portafogli restano sempre visibili. Spunta le schede '
                'da mostrare e trascinale (≡) per cambiare l\'ordine.',
                style: TextStyle(color: schema.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ReorderableListView(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                onReorderItem: _sposta,
                children: [
                  for (final (i, s) in _ordine.indexed)
                    CheckboxListTile(
                      key: ValueKey(s),
                      controlAffinity: ListTileControlAffinity.leading,
                      value: !_nascoste.contains(s),
                      onChanged: (v) => setState(
                        () =>
                            v == true ? _nascoste.remove(s) : _nascoste.add(s),
                      ),
                      title: Text(s.titolo),
                      subtitle: Text(s.descrizione),
                      secondary: ReorderableDragStartListener(
                        index: i,
                        child: Tooltip(
                          message: 'Trascina per spostare',
                          child: const Icon(Icons.drag_handle),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() {
            _ordine
              ..clear()
              ..addAll(SchedaPanoramica.values);
            _nascoste.clear();
          }),
          child: const Text('Ripristina'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context)
                  .pop(ConfigurazionePanoramica(_ordine, _nascoste)),
          child: const Text('Salva'),
        ),
      ],
    );
  }
}
