import 'package:flutter/material.dart';

import '../../core/db/costo_vita.dart';
import '../../core/db/tabelle.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../categorie/scelta_categoria.dart';
import '../comuni/errori.dart';
import '../comuni/navigazione.dart';
import 'sezione_addebito.dart';

/// Nuova voce del costo della vita (fissa o variabile), con nome suggerito.
Future<void> apriNuovaVoce(
  BuildContext context,
  Sessione sessione, {
  required String tipo,
  String? nomeSuggerito,
  String? categoriaSuggerita,
}) => showDialog<void>(
  context: context,
  builder: (_) => _NuovaVoce(
    sessione: sessione,
    tipo: tipo,
    nomeSuggerito: nomeSuggerito,
    categoriaSuggerita: categoriaSuggerita,
  ),
);

class _NuovaVoce extends StatefulWidget {
  const _NuovaVoce({
    required this.sessione,
    required this.tipo,
    this.nomeSuggerito,
    this.categoriaSuggerita,
  });

  final Sessione sessione;
  final String tipo;
  final String? nomeSuggerito;
  final String? categoriaSuggerita;

  @override
  State<_NuovaVoce> createState() => _NuovaVoceState();
}

class _NuovaVoceState extends State<_NuovaVoce> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.nomeSuggerito ?? '');
  final _importo = TextEditingController();
  String? _categoria;
  late String _tipo = widget.tipo;
  final _addebito = ImpostazioneAddebito();
  bool _salvataggio = false;

  bool get _fissa => _tipo == TipoVoce.fissa;

  @override
  void initState() {
    super.initState();
    _categoria = widget.categoriaSuggerita;
  }

  @override
  void dispose() {
    _nome.dispose();
    _importo.dispose();
    super.dispose();
  }

  Future<void> _salva() async {
    if (_salvataggio || !_form.currentState!.validate()) {
      return;
    }
    setState(() => _salvataggio = true);
    try {
      final cv = widget.sessione.costoVita;
      final id = await cv.creaVoce(
        nome: _nome.text,
        tipo: _tipo,
        importo: Importo.leggi(_importo.text)!,
        categoriaId: _categoria,
      );
      if (_addebito.attivo) {
        await cv.impostaAddebito(
          id,
          ricorrenza: _addebito.ricorrenza,
          portafoglioId: _addebito.portafoglioId,
        );
        // Se il primo addebito è oggi o già passato, si registra subito.
        await widget.sessione.pianificatore.registraScadute();
      }
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
    return AlertDialog(
      title: Text(_fissa ? 'Nuova spesa fissa' : 'Nuova spesa variabile'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SceltaTipoVoce(
                  valore: _tipo,
                  onChanged: (t) => setState(() => _tipo = t),
                ),
                const SizedBox(height: 12),
                Text(
                  _fissa
                      ? 'Una spesa che si ripete uguale ogni mese.'
                      : 'Una spesa che cambia ogni mese: indica quanto prevedi di '
                            'spendere. Con una categoria l\'app confronta la stima '
                            'con quello che spendi davvero.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nome,
                  autofocus: widget.nomeSuggerito == null,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Dai un nome alla voce'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _importo,
                  autofocus: widget.nomeSuggerito != null,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _salva(),
                  decoration: InputDecoration(
                    labelText:
                        _addebito.attivo &&
                            _addebito.frequenza.codice != 'mensile'
                        ? (_fissa
                              ? 'Importo per addebito'
                              : 'Stima per addebito')
                        : (_fissa ? 'Importo al mese' : 'Stima al mese'),
                    hintText: '0,00',
                    suffixText: '€',
                  ),
                  validator: (v) {
                    final importo = Importo.leggi(v ?? '');
                    return importo == null || importo <= 0
                        ? 'Scrivi un importo, per esempio 80,00'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                CampoCategoria(
                  sessione: widget.sessione,
                  valore: _categoria,
                  onChanged: (v) => setState(() => _categoria = v),
                  etichetta: _fissa
                      ? 'Categoria (facoltativa)'
                      : 'Categoria delle spese reali',
                ),
                const SizedBox(height: 8),
                SezioneAddebito(
                  sessione: widget.sessione,
                  valore: _addebito,
                  onChanged: () => setState(() {}),
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
          child: const Text('Aggiungi'),
        ),
      ],
    );
  }
}

/// Come applicare un nuovo importo.
enum _Ambito { soloMese, domani, meseProssimo }

/// Modifica di una voce: nuovo importo (solo per questo mese / da domani / dal mese
/// prossimo), ripristino del predefinito, nome e categoria, archiviazione.
Future<void> apriModificaVoce(
  BuildContext context,
  Sessione sessione,
  VoceDelMese voce,
  DateTime mese,
) => showDialog<void>(
  context: context,
  builder: (_) => _ModificaVoce(sessione: sessione, voce: voce, mese: mese),
);

class _ModificaVoce extends StatefulWidget {
  const _ModificaVoce({
    required this.sessione,
    required this.voce,
    required this.mese,
  });

  final Sessione sessione;
  final VoceDelMese voce;
  final DateTime mese;

  @override
  State<_ModificaVoce> createState() => _ModificaVoceState();
}

class _ModificaVoceState extends State<_ModificaVoce> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.voce.voce.nome);
  late final int _importoMostrato = widget.voce.variato
      ? widget.voce.previsto
      : widget.voce.importoUnitario;
  late final _importo = TextEditingController(
    text: Importo.perModifica(_importoMostrato),
  );
  late String? _categoria = widget.voce.voce.categoriaId;
  late String _tipo = widget.voce.voce.tipo;
  late final _addebito = ImpostazioneAddebito.da(widget.voce.addebito);
  _Ambito _ambito = _Ambito.soloMese;
  bool _salvataggio = false;

  @override
  void dispose() {
    _nome.dispose();
    _importo.dispose();
    super.dispose();
  }

  Future<void> _esegui(Future<void> Function() azione) async {
    setState(() => _salvataggio = true);
    try {
      await azione();
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

  Future<void> _salva() async {
    if (_salvataggio || !_form.currentState!.validate()) {
      return;
    }
    final cv = widget.sessione.costoVita;
    final v = widget.voce;
    final importo = Importo.leggi(_importo.text)!;
    await _esegui(() async {
      if (_nome.text.trim() != v.voce.nome ||
          _categoria != v.voce.categoriaId ||
          _tipo != v.voce.tipo) {
        await cv.modificaVoce(
          v.voce.id,
          nome: _nome.text,
          categoriaId: _categoria,
          tipo: _tipo,
        );
      }
      await cv.impostaAddebito(
        v.voce.id,
        ricorrenza: _addebito.ricorrenza,
        portafoglioId: _addebito.portafoglioId,
      );
      if (importo != _importoMostrato) {
        switch (_ambito) {
          case _Ambito.soloMese:
            await cv.variaMese(v.voce.id, widget.mese, importo);
          case _Ambito.domani:
            await cv.cambiaImportoPredefinito(
              v.voce.id,
              importo,
              Decorrenza.domani,
            );
          case _Ambito.meseProssimo:
            await cv.cambiaImportoPredefinito(
              v.voce.id,
              importo,
              Decorrenza.meseProssimo,
            );
        }
      }
      await widget.sessione.pianificatore.registraScadute();
    });
  }

  Future<void> _archivia() async {
    final cv = widget.sessione.costoVita;
    final messenger = ScaffoldMessenger.of(context);
    final v = widget.voce.voce;
    await _esegui(() => cv.archiviaVoce(v.id));
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('"${v.nome}" tolta dal costo della vita'),
          action: SnackBarAction(
            label: 'Annulla',
            onPressed: () => cv.archiviaVoce(v.id, archiviata: false),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.voce;
    final nomeMese = meseLeggibile(context, widget.mese);
    final schema = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(v.voce.nome),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SceltaTipoVoce(
                  valore: _tipo,
                  onChanged: (t) => setState(() => _tipo = t),
                ),
                const SizedBox(height: 12),
                Text(
                  'Importo predefinito: '
                  '${Importo.formatta(v.importoUnitario, 'EUR')} '
                  '${_addebito.attivo && _addebito.frequenza.codice != 'mensile' ? 'per addebito' : 'al mese'}',
                  style: TextStyle(color: schema.onSurfaceVariant),
                ),
                if (v.variato)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Per $nomeMese hai impostato '
                          '${Importo.formatta(v.previsto, 'EUR')}.',
                        ),
                      ),
                      TextButton(
                        onPressed: _salvataggio
                            ? null
                            : () => _esegui(
                                () => widget.sessione.costoVita
                                    .annullaVariazione(v.voce.id, widget.mese),
                              ),
                        child: const Text('Torna al predefinito'),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _importo,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: v.fissa ? 'Importo' : 'Stima',
                    suffixText: '€',
                  ),
                  validator: (t) {
                    final importo = Importo.leggi(t ?? '');
                    return importo == null || importo < 0
                        ? 'Scrivi un importo, per esempio 80,00'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Se cambi l\'importo, vale:',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                RadioGroup<_Ambito>(
                  groupValue: _ambito,
                  onChanged: (a) => setState(() => _ambito = a ?? _ambito),
                  child: Column(
                    children: [
                      RadioListTile(
                        value: _Ambito.soloMese,
                        title: Text('Solo per $nomeMese'),
                        subtitle: const Text('Gli altri mesi non cambiano'),
                      ),
                      const RadioListTile(
                        value: _Ambito.domani,
                        title: Text('Da domani in poi'),
                        subtitle: Text(
                          'Nuovo importo predefinito dal giorno dopo',
                        ),
                      ),
                      const RadioListTile(
                        value: _Ambito.meseProssimo,
                        title: Text('Dal mese prossimo in poi'),
                        subtitle: Text('Il mese in corso resta com\'è'),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                TextFormField(
                  controller: _nome,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (t) => (t == null || t.trim().isEmpty)
                      ? 'Dai un nome alla voce'
                      : null,
                ),
                const SizedBox(height: 16),
                CampoCategoria(
                  sessione: widget.sessione,
                  valore: _categoria,
                  onChanged: (c) => setState(() => _categoria = c),
                ),
                const SizedBox(height: 8),
                SezioneAddebito(
                  sessione: widget.sessione,
                  valore: _addebito,
                  onChanged: () => setState(() {}),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _salvataggio ? null : _archivia,
          icon: const Icon(Icons.archive_outlined),
          label: const Text('Togli'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _salvataggio ? null : _salva,
          child: const Text('Salva'),
        ),
      ],
    );
  }
}
