import 'package:flutter/material.dart';

import '../../core/db/archivio.dart';
import '../../core/db/contabilita.dart';
import '../../core/db/pianificatore.dart';
import '../../core/db/tabelle.dart';
import '../../core/importo.dart';
import '../../core/ricorrenza.dart';
import '../../core/sessione.dart';
import '../movimenti/riga_movimento.dart';

enum TipoFine { mai, data, occorrenze }

/// Impostazioni della data di addebito scelte nel modulo.
class ImpostazioneAddebito {
  ImpostazioneAddebito({
    this.attivo = false,
    DateTime? inizio,
    this.frequenza = Frequenza.mensile,
    this.tipoFine = TipoFine.mai,
    this.fine,
    this.occorrenze = 12,
    this.portafoglioId,
  }) : inizio = inizio ?? DateUtils.dateOnly(DateTime.now());

  factory ImpostazioneAddebito.da(Pianificazione? p) {
    if (p == null) {
      return ImpostazioneAddebito();
    }
    final r = Pianificatore.ricorrenzaDi(p);
    return ImpostazioneAddebito(
      attivo: true,
      inizio: r.inizio,
      frequenza: r.frequenza,
      tipoFine: r.occorrenze != null
          ? TipoFine.occorrenze
          : r.fine != null
          ? TipoFine.data
          : TipoFine.mai,
      fine: r.fine,
      occorrenze: r.occorrenze ?? 12,
      portafoglioId: p.portafoglioId,
    );
  }

  bool attivo;
  DateTime inizio;
  Frequenza frequenza;
  TipoFine tipoFine;
  DateTime? fine;
  int occorrenze;
  String? portafoglioId;

  Ricorrenza? get ricorrenza => attivo
      ? Ricorrenza(
          inizio: inizio,
          frequenza: frequenza,
          fine: tipoFine == TipoFine.data ? fine : null,
          occorrenze: tipoFine == TipoFine.occorrenze ? occorrenze : null,
        )
      : null;
}

/// Sezione "Quando scalano i soldi": data, frequenza, fine, conto di pagamento.
/// Con un conto il movimento si registra da solo (avviso 3 giorni prima).
class SezioneAddebito extends StatefulWidget {
  const SezioneAddebito({
    super.key,
    required this.sessione,
    required this.valore,
    required this.onChanged,
  });

  final Sessione sessione;
  final ImpostazioneAddebito valore;
  final VoidCallback onChanged;

  @override
  State<SezioneAddebito> createState() => _SezioneAddebitoState();
}

class _SezioneAddebitoState extends State<SezioneAddebito> {
  late final Future<List<PortafoglioConSaldo>> _portafogli = widget
      .sessione
      .contabilita
      .osservaPortafogli()
      .first;
  late final _occorrenze = TextEditingController(
    text: '${widget.valore.occorrenze}',
  );

  ImpostazioneAddebito get v => widget.valore;

  void _aggiorna(VoidCallback modifica) {
    setState(modifica);
    widget.onChanged();
  }

  @override
  void dispose() {
    _occorrenze.dispose();
    super.dispose();
  }

  Future<DateTime?> _data(DateTime iniziale, String titolo) => showDatePicker(
    context: context,
    initialDate: iniziale,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    helpText: titolo,
  );

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    final ricorrenza = v.ricorrenza;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: v.attivo,
          onChanged: (a) => _aggiorna(() => v.attivo = a),
          title: const Text('Data di addebito'),
          subtitle: const Text('Quando scalano i soldi dal conto'),
        ),
        if (v.attivo) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text(
                    'Primo addebito: ${dataLeggibile(context, v.inizio)}',
                  ),
                  onPressed: () async {
                    final d = await _data(v.inizio, 'Primo addebito');
                    if (d != null) {
                      _aggiorna(() => v.inizio = d);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Frequenza>(
            initialValue: v.frequenza,
            decoration: const InputDecoration(labelText: 'Ogni quanto'),
            items: [
              for (final f in Frequenza.values)
                DropdownMenuItem(value: f, child: Text(f.etichetta)),
            ],
            onChanged: (f) => _aggiorna(() => v.frequenza = f ?? v.frequenza),
          ),
          const SizedBox(height: 12),
          Text('Fino a quando', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          SegmentedButton<TipoFine>(
            segments: const [
              ButtonSegment(value: TipoFine.mai, label: Text('Sempre')),
              ButtonSegment(
                value: TipoFine.data,
                label: Text('Fino a una data'),
              ),
              ButtonSegment(value: TipoFine.occorrenze, label: Text('N volte')),
            ],
            selected: {v.tipoFine},
            showSelectedIcon: false,
            onSelectionChanged: (s) => _aggiorna(() {
              v.tipoFine = s.first;
              if (v.tipoFine == TipoFine.data && v.fine == null) {
                v.fine = DateTime(
                  v.inizio.year + 1,
                  v.inizio.month,
                  v.inizio.day,
                );
              }
            }),
          ),
          if (v.tipoFine == TipoFine.data)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.event_busy),
                label: Text(
                  'Ultimo addebito entro: ${dataLeggibile(context, v.fine!)}',
                ),
                onPressed: () async {
                  final d = await _data(v.fine!, 'Data di fine');
                  if (d != null) {
                    _aggiorna(() => v.fine = d);
                  }
                },
              ),
            ),
          if (v.tipoFine == TipoFine.occorrenze)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextFormField(
                controller: _occorrenze,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dopo quanti addebiti finisce',
                ),
                onChanged: (t) => _aggiorna(
                  () => v.occorrenze = int.tryParse(t) ?? v.occorrenze,
                ),
                validator: (t) => (int.tryParse(t ?? '') ?? 0) < 1
                    ? 'Scrivi un numero, per esempio 12'
                    : null,
              ),
            ),
          const SizedBox(height: 12),
          FutureBuilder<List<PortafoglioConSaldo>>(
            future: _portafogli,
            builder: (context, snapshot) {
              final portafogli = snapshot.data ?? const [];
              final ids = portafogli.map((p) => p.portafoglio.id).toSet();
              return DropdownButtonFormField<String?>(
                initialValue: ids.contains(v.portafoglioId)
                    ? v.portafoglioId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Da quale portafoglio',
                  helperText:
                      'Con un portafoglio la spesa si registra da sola nel giorno '
                      'previsto (ti avviso 3 giorni prima).',
                  helperMaxLines: 2,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    child: Text('Nessuno: solo promemoria'),
                  ),
                  for (final p in portafogli)
                    DropdownMenuItem<String?>(
                      value: p.portafoglio.id,
                      child: Text(
                        '${p.portafoglio.nome} · '
                        '${Importo.formatta(p.saldo, p.portafoglio.valuta)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) => _aggiorna(() => v.portafoglioId = id),
              );
            },
          ),
          if (ricorrenza != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.repeat, size: 16, color: schema.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ricorrenza.descrizione(),
                      style: TextStyle(color: schema.primary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// Testo breve per una riga: "Ogni mese il giorno 5 · Conto".
String testoAddebito(Pianificazione p, Map<String, String> nomiPortafogli) {
  final regola = Pianificatore.ricorrenzaDi(p).descrizione();
  final conto = p.portafoglioId == null
      ? 'solo promemoria'
      : nomiPortafogli[p.portafoglioId] ?? '';
  return '$regola · $conto';
}

/// Il tipo di voce (fissa/variabile) sotto forma di scelta a due bottoni.
class SceltaTipoVoce extends StatelessWidget {
  const SceltaTipoVoce({
    super.key,
    required this.valore,
    required this.onChanged,
  });

  final String valore;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: TipoVoce.fissa, label: Text('Fissa')),
        ButtonSegment(value: TipoVoce.variabile, label: Text('Variabile')),
      ],
      selected: {valore},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
