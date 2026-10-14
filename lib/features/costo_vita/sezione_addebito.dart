import 'package:flutter/material.dart';

import '../../core/db/archivio.dart';
import '../../core/db/contabilita.dart';
import '../../core/db/costo_vita.dart';
import '../../core/db/pianificatore.dart';
import '../../core/db/tabelle.dart';
import '../../core/importo.dart';
import '../../core/ricorrenza.dart';
import '../../core/sessione.dart';
import '../comuni/campi.dart';
import '../comuni/conta_dal.dart';
import 'testi_voci.dart';

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
    this.ripartita = false,
    this.conferma = false,
    DateTime? contaDal,
    this.contaDalIniziale,
  }) : inizio = inizio ?? DateUtils.dateOnly(DateTime.now()),
       contaDal = contaDal ?? DateUtils.dateOnly(DateTime.now());

  /// Dal pagamento programmato salvato; senza, [conferma] è la scelta
  /// predefinita (entrate: chiedi conferma; spese: da sola).
  factory ImpostazioneAddebito.da(
    Pianificazione? p, {
    bool ripartita = false,
    bool conferma = false,
  }) {
    if (p == null) {
      return ImpostazioneAddebito(ripartita: ripartita, conferma: conferma);
    }
    final r = Pianificatore.ricorrenzaDi(p);
    // Senza "Conta dal" (archivi di prima) contano tutte, dal primo addebito.
    final dal = p.registraDal == null
        ? r.inizio
        : Contabilita.daGiorno(p.registraDal!);
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
      ripartita: ripartita,
      conferma: p.richiedeConferma,
      contaDal: dal,
      contaDalIniziale: dal,
    );
  }

  bool attivo;
  DateTime inizio;
  Frequenza frequenza;
  TipoFine tipoFine;
  DateTime? fine;
  int occorrenze;
  String? portafoglioId;

  /// Solo per addebiti non mensili: suddividi la spesa nei mesi.
  bool ripartita;

  /// Con un portafoglio: `true` = nel giorno previsto chiede conferma nelle
  /// notifiche, `false` = si registra da solo.
  bool conferma;

  /// "Conta dal": le scadenze prima sono già avvenute (voce già in corso).
  DateTime contaDal;

  /// "Conta dal" salvato (`null` = voce nuova).
  final DateTime? contaDalIniziale;

  /// Già in corso: la prima data è passata.
  bool get giaInCorso =>
      attivo && inizio.isBefore(DateUtils.dateOnly(DateTime.now()));

  /// Da passare a [CostoVita.impostaAddebito]: `null` = nuova voce che inizia
  /// oggi o dopo, oppure nessun cambiamento.
  DateTime? get contaDalDaSalvare {
    if (!attivo) {
      return null;
    }
    if (contaDalIniziale == null) {
      return giaInCorso ? contaDal : null;
    }
    return contaDal == contaDalIniziale ? null : contaDal;
  }

  /// La casella "Suddividi nei mesi" ha senso solo per addebiti non mensili.
  bool get nonMensile => attivo && frequenza != Frequenza.mensile;

  /// Valore da salvare nella voce.
  bool get ripartitaEffettiva => nonMensile && ripartita;

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
    this.importo,
    this.testi = TestiVoci.costoVita,
  });

  final Sessione sessione;

  /// Testi per spese (addebito) o entrate (accredito).
  final TestiVoci testi;
  final ImpostazioneAddebito valore;
  final VoidCallback onChanged;

  /// Importo di un addebito (se già scritto), per l'esempio della suddivisione.
  final int? importo;

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

  /// Esempio concreto con l'importo scritto (o 1.200 € se manca).
  String _spiegazioneRipartizione() {
    final importo = widget.importo ?? 120000;
    final quota = CostoVita.quotaMensile(importo, v.frequenza);
    final ogni = v.frequenza.etichetta.toLowerCase();
    return v.ripartita
        ? '${Importo.formatta(importo, 'EUR')} $ogni → '
              '${Importo.formatta(quota, 'EUR')} al mese '
              '${widget.testi.entrate ? 'nelle entrate previste' : 'nel costo della vita'}.'
        : 'Spenta: ${Importo.formatta(importo, 'EUR')} contano solo nel mese '
              'del pagamento.';
  }

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
          title: Text(widget.testi.data),
          subtitle: Text(widget.testi.dataSpiegazione),
        ),
        if (v.attivo) ...[
          CampoData(
            etichetta: widget.testi.primaData,
            valore: v.inizio,
            primo: DateTime(2000),
            onChanged: (d) => _aggiorna(() => v.inizio = d),
          ),
          if (v.giaInCorso) ...[
            const SizedBox(height: 12),
            CampoContaDal(
              valore: v.contaDal,
              inizio: v.inizio,
              onChanged: (d) => _aggiorna(() => v.contaDal = d),
              spiegazione: widget.testi.entrate
                  ? 'gli accrediti prima di questa data sono già arrivati'
                  : 'gli addebiti prima di questa data sono già usciti',
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<Frequenza>(
            isExpanded: true,
            initialValue: v.frequenza,
            decoration: const InputDecoration(labelText: 'Ogni quanto'),
            items: [
              for (final f in Frequenza.values)
                DropdownMenuItem(value: f, child: Text(f.etichetta)),
            ],
            onChanged: (f) => _aggiorna(() => v.frequenza = f ?? v.frequenza),
          ),
          if (v.nonMensile)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: v.ripartita,
              onChanged: (r) => _aggiorna(() => v.ripartita = r ?? false),
              title: Text(widget.testi.suddividi),
              subtitle: Text(_spiegazioneRipartizione()),
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
              child: CampoData(
                etichetta: widget.testi.ultimaData,
                valore: v.fine,
                primo: v.inizio,
                onChanged: (d) => _aggiorna(() => v.fine = d),
              ),
            ),
          if (v.tipoFine == TipoFine.occorrenze)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextFormField(
                controller: _occorrenze,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: widget.testi.quanteVolte,
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
                decoration: InputDecoration(
                  labelText: widget.testi.portafoglio,
                  helperText: widget.testi.portafoglioSpiegazione,
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
          if (v.portafoglioId != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: v.conferma,
              onChanged: (c) => _aggiorna(() => v.conferma = c),
              title: const Text('Chiedi conferma prima di registrare'),
              subtitle: Text(
                v.conferma
                    ? 'Nel giorno previsto la trovi nelle notifiche: confermi, '
                          'sposti o annulli. Finché non decidi non si registra.'
                    : 'Si registra da sola nel giorno previsto. Ti arriva un '
                          'avviso che sparisce quando lo leggi.',
              ),
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
