import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/db/archivio.dart';
import '../../core/db/contabilita.dart';
import '../../core/db/tabelle.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../categorie/scelta_categoria.dart';
import '../comuni/campi.dart';
import '../comuni/errori.dart';
import 'riga_movimento.dart';

/// Apre il modulo per un nuovo movimento (o per modificarne uno [esistente]).
/// Restituisce `true` se è stato salvato.
Future<bool> apriModuloMovimento(
  BuildContext context,
  Sessione sessione, {
  MovimentoDettaglio? esistente,
  String? portafoglioId,
}) async {
  final salvato = await showDialog<bool>(
    context: context,
    builder: (_) => _MovimentoModulo(
      sessione: sessione,
      esistente: esistente,
      portafoglioIniziale: portafoglioId,
    ),
  );
  return salvato ?? false;
}

/// Ultimo portafoglio usato (in questa sessione): proposto al movimento successivo.
String? _ultimoPortafoglio;

class _MovimentoModulo extends StatefulWidget {
  const _MovimentoModulo({
    required this.sessione,
    this.esistente,
    this.portafoglioIniziale,
  });

  final Sessione sessione;
  final MovimentoDettaglio? esistente;
  final String? portafoglioIniziale;

  @override
  State<_MovimentoModulo> createState() => _MovimentoModuloState();
}

class _MovimentoModuloState extends State<_MovimentoModulo> {
  final _form = GlobalKey<FormState>();
  final _importo = TextEditingController();
  final _descrizione = TextEditingController();

  List<DefinizioneTipo> _tipi = const [];
  List<PortafoglioConSaldo> _portafogli = const [];
  DefinizioneTipo? _tipo;
  String? _portafoglio;
  String? _destinazione;
  String? _categoria;
  DateTime _data = DateTime.now();
  bool _salvataggio = false;

  bool get _trasferimento => _tipo?.effetto == EffettoSaldo.trasferimento;

  @override
  void initState() {
    super.initState();
    _carica();
  }

  Future<void> _carica() async {
    final contabilita = widget.sessione.contabilita;
    final tipi = await contabilita.tipi(AmbitoTipo.movimento);
    final portafogli = await contabilita.osservaPortafogli().first;
    final esistente = widget.esistente;
    if (!mounted) {
      return;
    }
    setState(() {
      _tipi = tipi;
      _portafogli = portafogli;
      final ids = portafogli.map((p) => p.portafoglio.id).toSet();
      if (esistente != null) {
        final m = esistente.movimento;
        _tipo = tipi.where((t) => t.id == m.tipoId).firstOrNull ?? tipi.first;
        _portafoglio = m.portafoglioId;
        _destinazione = m.portafoglioDestinazioneId;
        _categoria = m.categoriaId;
        _data = Contabilita.daGiorno(m.data);
        _importo.text = Importo.perModifica(m.importoMinimo);
        _descrizione.text = m.descrizione;
      } else {
        _tipo = tipi.firstOrNull;
        _portafoglio =
            [
              widget.portafoglioIniziale,
              _ultimoPortafoglio,
              portafogli.firstOrNull?.portafoglio.id,
            ].firstWhere(
              (id) => id != null && ids.contains(id),
              orElse: () => null,
            );
      }
    });
  }

  @override
  void dispose() {
    _importo.dispose();
    _descrizione.dispose();
    super.dispose();
  }

  Portafoglio? _portafoglioDa(String? id) =>
      _portafogli.where((p) => p.portafoglio.id == id).firstOrNull?.portafoglio;

  Future<void> _salva() async {
    if (_salvataggio || !_form.currentState!.validate()) {
      return;
    }
    final portafoglio = _portafoglioDa(_portafoglio)!;
    final importo = Importo.leggi(_importo.text)!;
    final contabilita = widget.sessione.contabilita;
    setState(() => _salvataggio = true);
    try {
      final destinazione = _trasferimento ? _destinazione : null;
      if (_trasferimento) {
        _categoria = null;
      }
      if (widget.esistente == null) {
        await contabilita.registraMovimento(
          tipoId: _tipo!.id,
          portafoglioId: portafoglio.id,
          destinazioneId: destinazione,
          categoriaId: _categoria,
          importo: importo,
          valuta: portafoglio.valuta,
          data: _data,
          descrizione: _descrizione.text,
        );
      } else {
        await contabilita.modificaMovimento(
          widget.esistente!.movimento.id,
          tipoId: _tipo!.id,
          portafoglioId: portafoglio.id,
          destinazioneId: destinazione,
          categoriaId: _categoria,
          importo: importo,
          valuta: portafoglio.valuta,
          data: _data,
          descrizione: _descrizione.text,
        );
      }
      _ultimoPortafoglio = portafoglio.id;
      if (mounted) {
        Navigator.of(context).pop(true);
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
    final modifica = widget.esistente != null;
    final valuta = _portafoglioDa(_portafoglio)?.valuta ?? 'EUR';
    final colore = coloreEffetto(context, _tipo?.effetto);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _salva,
      },
      child: AlertDialog(
        title: Text(modifica ? 'Modifica movimento' : 'Nuovo movimento'),
        content: _tipo == null
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : SizedBox(
                width: 460,
                child: Form(
                  key: _form,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<String>(
                          segments: [
                            for (final t in _tipi)
                              ButtonSegment(
                                value: t.id,
                                label: Text(t.nome),
                                icon: Icon(iconaEffetto(t.effetto)),
                              ),
                          ],
                          selected: {_tipo!.id},
                          showSelectedIcon: false,
                          onSelectionChanged: (s) => setState(
                            () => _tipo = _tipi.firstWhere(
                              (t) => t.id == s.first,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        CampoImporto(
                          controller: _importo,
                          autofocus: true,
                          valuta: valuta,
                          colore: colore,
                        ),
                        const SizedBox(height: 16),
                        _sceltaPortafoglio(
                          etichetta: _trasferimento ? 'Da' : 'Portafoglio',
                          valore: _portafoglio,
                          onChanged: (v) => setState(() => _portafoglio = v),
                        ),
                        if (_trasferimento) ...[
                          const SizedBox(height: 16),
                          _sceltaPortafoglio(
                            etichetta: 'A',
                            valore: _destinazione,
                            onChanged: (v) => setState(() => _destinazione = v),
                            escludi: _portafoglio,
                            // Per ora i trasferimenti sono tra portafogli con la
                            // stessa valuta (il cambio arriverà con i tassi BCE).
                            soloValuta: valuta,
                          ),
                        ],
                        if (!_trasferimento) ...[
                          const SizedBox(height: 16),
                          CampoCategoria(
                            sessione: widget.sessione,
                            valore: _categoria,
                            onChanged: (c) => setState(() => _categoria = c),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descrizione,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _salva(),
                          decoration: const InputDecoration(
                            labelText: 'Descrizione (facoltativa)',
                            hintText: 'Es. Pizzeria, Stipendio, Bolletta luce',
                          ),
                        ),
                        const SizedBox(height: 16),
                        CampoData(
                          etichetta: 'Data del movimento',
                          valore: _data,
                          primo: DateTime(1970),
                          ultimo: DateTime.now().add(
                            const Duration(days: 365 * 5),
                          ),
                          onChanged: (d) => setState(() => _data = d),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: _tipo == null || _salvataggio ? null : _salva,
            child: Text(modifica ? 'Salva modifiche' : 'Salva'),
          ),
        ],
      ),
    );
  }

  Widget _sceltaPortafoglio({
    required String etichetta,
    required String? valore,
    required ValueChanged<String?> onChanged,
    String? escludi,
    String? soloValuta,
  }) {
    final scelte = _portafogli.where(
      (p) =>
          p.portafoglio.id != escludi &&
          (soloValuta == null || p.portafoglio.valuta == soloValuta),
    );
    return DropdownButtonFormField<String>(
      initialValue: scelte.any((p) => p.portafoglio.id == valore)
          ? valore
          : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: etichetta),
      items: [
        for (final p in scelte)
          DropdownMenuItem(
            value: p.portafoglio.id,
            child: Text(
              '${p.portafoglio.nome} · '
              '${Importo.formatta(p.saldo, p.portafoglio.valuta)}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
      validator: (v) => v == null ? 'Scegli un portafoglio' : null,
    );
  }
}
