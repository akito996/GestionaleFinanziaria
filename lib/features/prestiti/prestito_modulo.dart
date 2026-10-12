import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../core/db/contabilita.dart';
import '../../core/db/prestiti.dart';
import '../../core/db/tabelle.dart';
import '../../core/importo.dart';
import '../../core/prestiti/ammortamento.dart';
import '../../core/prestiti/estrazione_pdf.dart';
import '../../core/prestiti/lettore_contratto.dart';
import '../../core/ricorrenza.dart';
import '../../core/sessione.dart';
import '../categorie/scelta_categoria.dart';
import '../comuni/campi.dart';
import '../comuni/dialogo_testo.dart';
import '../comuni/errori.dart';

/// Scelta iniziale: leggere il contratto (PDF o testo) o compilare a mano.
Future<void> apriNuovoPrestito(BuildContext context, Sessione sessione) async {
  final modo = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text('Nuovo prestito o pagamento a rate'),
            subtitle: Text(
              'Il contratto viene letto solo su questo dispositivo: non viene '
              'inviato a nessuno.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Leggi dal contratto (PDF)'),
            subtitle: const Text(
              'Ideale con il modulo SECCI (prestiti) o PIES (mutui)',
            ),
            onTap: () => Navigator.of(context).pop('pdf'),
          ),
          ListTile(
            leading: const Icon(Icons.content_paste),
            title: const Text('Incolla il testo del contratto'),
            onTap: () => Navigator.of(context).pop('testo'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('Inserisci a mano'),
            onTap: () => Navigator.of(context).pop('mano'),
          ),
        ],
      ),
    ),
  );
  if (modo == null || !context.mounted) {
    return;
  }
  ProposteContratto? proposte;
  try {
    if (modo == 'pdf') {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(label: 'Contratto (PDF)', extensions: ['pdf']),
        ],
      );
      if (file == null) {
        return;
      }
      proposte = LettoreContratto.leggi(await testoDaPdf(file.path));
    } else if (modo == 'testo') {
      if (!context.mounted) {
        return;
      }
      final testo = await chiediTesto(
        context,
        titolo: 'Incolla il testo del contratto',
        suggerimento:
            'Copia dal PDF le pagine con importo, rate, TAN e TAEG e '
            'incollale qui.',
        conferma: 'Leggi',
        righe: 8,
      );
      if (testo == null) {
        return;
      }
      proposte = LettoreContratto.leggi(testo);
    }
  } catch (e, stack) {
    if (context.mounted) {
      await mostraErroreImprevisto(context, e, stack);
    }
    return;
  }
  if (context.mounted) {
    await apriModuloPrestito(context, sessione, proposte: proposte);
  }
}

/// Modulo del prestito (nuovo, da proposte del contratto, o modifica).
Future<void> apriModuloPrestito(
  BuildContext context,
  Sessione sessione, {
  ProposteContratto? proposte,
  PrestitoConStato? esistente,
  String? introduzione,
}) => showDialog<void>(
  context: context,
  builder: (_) => _ModuloPrestito(
    sessione: sessione,
    proposte: proposte,
    esistente: esistente,
    introduzione: introduzione,
  ),
);

const _tipi = [
  (TipoPrestito.mutuo, 'Mutuo'),
  (TipoPrestito.prestito, 'Prestito'),
  (TipoPrestito.rate, 'A rate'),
  (TipoPrestito.privato, 'Tra privati'),
];

class _ModuloPrestito extends StatefulWidget {
  const _ModuloPrestito({
    required this.sessione,
    this.proposte,
    this.esistente,
    this.introduzione,
  });

  final Sessione sessione;
  final ProposteContratto? proposte;
  final PrestitoConStato? esistente;

  /// Testo in cima al modulo al posto dei "dati trovati nel contratto".
  final String? introduzione;

  @override
  State<_ModuloPrestito> createState() => _ModuloPrestitoState();
}

class _ModuloPrestitoState extends State<_ModuloPrestito> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _finanziatore = TextEditingController();
  final _capitale = TextEditingController();
  final _numeroRate = TextEditingController();
  final _rata = TextEditingController();
  final _maxi = TextEditingController();
  bool _conMaxi = false;
  final _spese = TextEditingController();
  final _tan = TextEditingController();
  final _taeg = TextEditingController();
  String _tipo = TipoPrestito.prestito;
  Frequenza _frequenza = Frequenza.mensile;
  DateTime _primaRata = DateUtils.dateOnly(
    DateTime(DateTime.now().year, DateTime.now().month + 1, 1),
  );
  String? _conto;
  String? _categoria;
  bool _categoriaScelta = false;
  List<PortafoglioConSaldo> _portafogli = const [];
  bool _salvataggio = false;

  @override
  void initState() {
    super.initState();
    final e = widget.esistente?.prestito;
    final p = widget.proposte;
    if (e != null) {
      _nome.text = e.nome;
      _finanziatore.text = e.finanziatore;
      _capitale.text = Importo.perModifica(e.capitaleMinimo);
      _numeroRate.text = '${e.numeroRate}';
      _rata.text = Importo.perModifica(e.importoRataMinimo);
      if (e.maxiRataMinimo != null) {
        _conMaxi = true;
        _maxi.text = Importo.perModifica(e.maxiRataMinimo!);
      }
      if (e.speseRataMinimo != null) {
        _spese.text = Importo.perModifica(e.speseRataMinimo!);
      }
      _tan.text = _percentuale(e.tanPuntiBase);
      _taeg.text = _percentuale(e.taegPuntiBase);
      _tipo = e.tipo;
      _frequenza = Frequenza.daCodice(e.frequenza);
      _primaRata = Contabilita.daGiorno(e.primaRata);
      _conto = e.portafoglioId;
      _categoria = e.categoriaId;
      _categoriaScelta = true;
    } else if (p != null) {
      _tipo = p.mutuo ? TipoPrestito.mutuo : TipoPrestito.prestito;
      _nome.text = p.nome ?? (p.mutuo ? 'Mutuo' : '');
      _finanziatore.text = p.finanziatore ?? '';
      if (p.capitale != null) {
        _capitale.text = Importo.perModifica(p.capitale!);
      }
      if (p.numeroRate != null) {
        _numeroRate.text = '${p.numeroRate}';
      }
      if (p.importoRata != null) {
        _rata.text = Importo.perModifica(p.importoRata!);
      }
      if (p.maxiRata != null) {
        _conMaxi = true;
        _maxi.text = Importo.perModifica(p.maxiRata!);
      }
      if (p.speseRata != null) {
        _spese.text = Importo.perModifica(p.speseRata!);
      }
      _tan.text = _percentuale(p.tanPuntiBase);
      _taeg.text = _percentuale(p.taegPuntiBase);
      if (p.primaRata != null) {
        _primaRata = p.primaRata!;
      }
    }
    _carica();
    // Il totale addebitato segue rata, maxi rata e spese mentre si scrive.
    for (final c in [_rata, _maxi, _spese]) {
      c.addListener(_aggiornaTotale);
    }
  }

  void _aggiornaTotale() => setState(() {});

  /// Rata + spese di incasso, formattato ("—" se la rata non è scritta).
  String _totale(int? rata) => rata == null
      ? '—'
      : Importo.formatta(rata + (Importo.leggi(_spese.text) ?? 0), 'EUR');

  static String _percentuale(int? puntiBase) => puntiBase == null
      ? ''
      : (puntiBase / 100).toStringAsFixed(2).replaceAll('.', ',');

  static int? _leggiPercentuale(String testo) {
    final v = double.tryParse(testo.trim().replaceAll(',', '.'));
    return v == null ? null : (v * 100).round();
  }

  Future<void> _carica() async {
    final portafogli = await widget.sessione.contabilita
        .osservaPortafogli()
        .first;
    final categoria = _categoriaScelta
        ? _categoria
        : await widget.sessione.prestiti.categoriaPredefinita(_tipo);
    if (mounted) {
      setState(() {
        _portafogli = portafogli;
        _categoria = categoria;
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nome,
      _finanziatore,
      _capitale,
      _numeroRate,
      _rata,
      _maxi,
      _spese,
      _tan,
      _taeg,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _calcolaRata() {
    final capitale = Importo.leggi(_capitale.text);
    final n = int.tryParse(_numeroRate.text);
    final tan = _leggiPercentuale(_tan.text) ?? 0;
    final maxi = _conMaxi ? Importo.leggi(_maxi.text) : null;
    if (capitale == null || n == null || n <= 0 || (_conMaxi && n < 2)) {
      return;
    }
    setState(
      () => _rata.text = Importo.perModifica(
        Ammortamento.rata(
          capitale: capitale,
          numeroRate: n,
          tanPuntiBase: tan,
          rateAllAnno: _frequenza.mesi == 0 ? 52 : 12 ~/ _frequenza.mesi,
          rataFinale: maxi,
        ),
      ),
    );
  }

  Future<void> _salva() async {
    if (_salvataggio || !_form.currentState!.validate()) {
      return;
    }
    final dati = DatiPrestito(
      nome: _nome.text,
      tipo: _tipo,
      finanziatore: _finanziatore.text,
      capitale: Importo.leggi(_capitale.text)!,
      numeroRate: int.parse(_numeroRate.text.trim()),
      importoRata: Importo.leggi(_rata.text)!,
      maxiRata: _conMaxi ? Importo.leggi(_maxi.text) : null,
      speseRata: Importo.leggi(_spese.text),
      tanPuntiBase: _leggiPercentuale(_tan.text),
      taegPuntiBase: _leggiPercentuale(_taeg.text),
      primaRata: _primaRata,
      frequenza: _frequenza,
      portafoglioId: _conto,
      categoriaId: _categoria,
    );
    setState(() => _salvataggio = true);
    try {
      final servizio = widget.sessione.prestiti;
      if (widget.esistente == null) {
        await servizio.crea(dati);
      } else {
        await servizio.modifica(widget.esistente!.prestito.id, dati);
      }
      await widget.sessione.pianificatore.registraScadute();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, stack) {
      if (mounted) {
        setState(() => _salvataggio = false);
        await mostraErroreImprevisto(context, e, stack);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    final p = widget.proposte;
    final modifica = widget.esistente != null;
    String? obbligatorioImporto(String? v) {
      final x = Importo.leggi(v ?? '');
      return x == null || x <= 0 ? 'Scrivi un importo' : null;
    }

    return AlertDialog(
      title: Text(modifica ? 'Modifica prestito' : 'Nuovo prestito'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.introduzione case final testo?)
                  Card(
                    color: schema.secondaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.autorenew),
                      title: Text(testo),
                    ),
                  )
                else if (p != null)
                  Card(
                    color: p.campiTrovati > 0
                        ? schema.secondaryContainer
                        : schema.errorContainer,
                    child: ListTile(
                      leading: Icon(
                        p.campiTrovati > 0
                            ? Icons.auto_awesome
                            : Icons.info_outline,
                      ),
                      title: Text(
                        p.campiTrovati > 0
                            ? 'Ho trovato ${p.campiTrovati} dati nel contratto'
                            : 'Non ho trovato dati nel contratto',
                      ),
                      subtitle: Text(
                        [
                          p.campiTrovati > 0
                              ? 'Controllali e completa quelli mancanti.'
                              : 'Forse è una scansione: compila i campi a mano.',
                          if (p.speseRata case final spese?)
                            'Ho inserito anche le spese di incasso '
                                '(${Importo.formatta(spese, 'EUR')} per rata).',
                        ].join(' '),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    for (final (valore, etichetta) in _tipi)
                      ButtonSegment(value: valore, label: Text(etichetta)),
                  ],
                  selected: {_tipo},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) async {
                    setState(() => _tipo = s.first);
                    if (!_categoriaScelta) {
                      final c = await widget.sessione.prestiti
                          .categoriaPredefinita(_tipo);
                      if (mounted) {
                        setState(() => _categoria = c);
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nome,
                  autofocus: !modifica,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    hintText: 'Es. Mutuo casa, Prestito auto, Lavatrice',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Dai un nome' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _finanziatore,
                  decoration: const InputDecoration(
                    labelText: 'Banca o finanziaria (facoltativo)',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _capitale,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Importo finanziato',
                          suffixText: '€',
                        ),
                        validator: obbligatorioImporto,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _numeroRate,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Numero di rate',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '') ?? 0;
                          if (n <= 0) {
                            return 'Quante rate?';
                          }
                          return _conMaxi && n < 2
                              ? 'Con la maxi rata servono almeno 2 rate'
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tan,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'TAN (facoltativo)',
                          suffixText: '%',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _taeg,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'TAEG (facoltativo)',
                          suffixText: '%',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _conMaxi,
                  onChanged: (v) => setState(() => _conMaxi = v),
                  title: const Text("C'è una maxi rata finale"),
                  subtitle: const Text(
                    "L'ultima rata è più alta delle altre (tipico dei "
                    'finanziamenti auto).',
                  ),
                ),
                if (_conMaxi)
                  TextFormField(
                    controller: _maxi,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Maxi rata finale',
                      suffixText: '€',
                      helperText:
                          "È l'ultima rata: è già compresa nel numero di rate.",
                    ),
                    validator: obbligatorioImporto,
                  ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _rata,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: _conMaxi
                              ? "Rata (tutte tranne l'ultima)"
                              : 'Importo della rata',
                          suffixText: '€',
                        ),
                        validator: obbligatorioImporto,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        onPressed: _calcolaRata,
                        icon: const Icon(Icons.calculate_outlined),
                        label: const Text('Calcola'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _spese,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Spese per rata (facoltative)',
                          hintText: 'Es. 3,50',
                          suffixText: '€',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return null;
                          }
                          final x = Importo.leggi(v);
                          return x == null || x < 0
                              ? 'Scrivi un importo'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: _conMaxi
                              ? "Totale rata (tranne l'ultima)"
                              : 'Totale addebitato per rata',
                          border: InputBorder.none,
                          filled: true,
                        ),
                        child: Text(
                          _totale(Importo.leggi(_rata.text)),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    [
                      'Le spese di incasso si addebitano insieme alla rata: il '
                          'movimento registrato è rata + spese, come '
                          "sull'estratto conto.",
                      if (_conMaxi)
                        'Ultima rata (maxi rata + spese): '
                            '${_totale(Importo.leggi(_maxi.text))}.',
                    ].join(' '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Frequenza>(
                  initialValue: _frequenza,
                  decoration: const InputDecoration(labelText: 'Ogni quanto'),
                  items: [
                    for (final f in Frequenza.values)
                      DropdownMenuItem(value: f, child: Text(f.etichetta)),
                  ],
                  onChanged: (f) =>
                      setState(() => _frequenza = f ?? _frequenza),
                ),
                const SizedBox(height: 12),
                CampoData(
                  etichetta: 'Data della prima rata',
                  valore: _primaRata,
                  onChanged: (d) => setState(() => _primaRata = d),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue:
                      _portafogli.any((x) => x.portafoglio.id == _conto)
                      ? _conto
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Da quale conto escono le rate',
                    helperText:
                        'Con un conto ogni rata si registra da sola nel giorno '
                        'previsto (avviso 3 giorni prima).',
                    helperMaxLines: 2,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      child: Text('Nessuno: solo promemoria'),
                    ),
                    for (final x in _portafogli)
                      DropdownMenuItem<String?>(
                        value: x.portafoglio.id,
                        child: Text(x.portafoglio.nome),
                      ),
                  ],
                  onChanged: (v) => setState(() => _conto = v),
                ),
                const SizedBox(height: 12),
                CampoCategoria(
                  sessione: widget.sessione,
                  valore: _categoria,
                  etichetta: 'Categoria delle rate',
                  onChanged: (c) => setState(() {
                    _categoria = c;
                    _categoriaScelta = true;
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _salvataggio ? null : _salva,
          child: Text(modifica ? 'Salva' : 'Aggiungi'),
        ),
      ],
    );
  }
}
