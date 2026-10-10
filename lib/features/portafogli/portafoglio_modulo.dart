import 'package:flutter/material.dart';

import '../../core/db/archivio.dart';
import '../../core/db/tabelle.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../comuni/errori.dart';

/// Nuovo portafoglio (o modifica di uno [esistente]). [nomeSuggerito] e [tipoSuggerito]
/// precompilano il modulo (es. dalle scorciatoie "Contanti", "Conto corrente").
Future<bool> apriModuloPortafoglio(
  BuildContext context,
  Sessione sessione, {
  Portafoglio? esistente,
  String? nomeSuggerito,
}) async {
  final salvato = await showDialog<bool>(
    context: context,
    builder: (_) => _PortafoglioModulo(
      sessione: sessione,
      esistente: esistente,
      nomeSuggerito: nomeSuggerito,
    ),
  );
  return salvato ?? false;
}

class _PortafoglioModulo extends StatefulWidget {
  const _PortafoglioModulo({
    required this.sessione,
    this.esistente,
    this.nomeSuggerito,
  });

  final Sessione sessione;
  final Portafoglio? esistente;
  final String? nomeSuggerito;

  @override
  State<_PortafoglioModulo> createState() => _PortafoglioModuloState();
}

class _PortafoglioModuloState extends State<_PortafoglioModulo> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _saldo = TextEditingController();
  final _gruppo = TextEditingController();

  List<DefinizioneTipo> _tipi = const [];
  List<String> _gruppi = const [];
  bool _preferito = false;
  bool _gruppoCollegato = false;
  String? _tipo;
  String _valuta = 'EUR';
  bool _salvataggio = false;

  @override
  void initState() {
    super.initState();
    final p = widget.esistente;
    _nome.text = p?.nome ?? widget.nomeSuggerito ?? '';
    if (p != null) {
      _valuta = p.valuta;
      _gruppo.text = p.gruppo ?? '';
      _preferito = p.preferito;
      _saldo.text = p.saldoInizialeMinimo == 0
          ? ''
          : Importo.perModifica(p.saldoInizialeMinimo);
    }
    _carica();
  }

  Future<void> _carica() async {
    final tipi = (await widget.sessione.contabilita.tipi(
      AmbitoTipo.portafoglio,
    )).where((t) => t.nome != tipoCartaDiCredito).toList();
    final gruppi = await widget.sessione.contabilita.gruppiPortafogli();
    if (!mounted) {
      return;
    }
    final suggerito = tipi
        .where((t) => t.nome == widget.nomeSuggerito)
        .firstOrNull;
    setState(() {
      _tipi = tipi;
      _gruppi = gruppi;
      _tipo = widget.esistente?.tipoId ?? suggerito?.id ?? tipi.firstOrNull?.id;
    });
  }

  @override
  void dispose() {
    _nome.dispose();
    _saldo.dispose();
    _gruppo.dispose();
    super.dispose();
  }

  Future<void> _salva() async {
    if (_salvataggio || !_form.currentState!.validate()) {
      return;
    }
    final saldo = _saldo.text.trim().isEmpty ? 0 : Importo.leggi(_saldo.text)!;
    final contabilita = widget.sessione.contabilita;
    setState(() => _salvataggio = true);
    try {
      if (widget.esistente == null) {
        await contabilita.creaPortafoglio(
          nome: _nome.text,
          tipoId: _tipo!,
          valuta: _valuta,
          saldoIniziale: saldo,
          gruppo: _gruppo.text,
        );
      } else {
        await contabilita.modificaPortafoglio(
          widget.esistente!.id,
          nome: _nome.text,
          tipoId: _tipo!,
          valuta: _valuta,
          saldoIniziale: saldo,
          gruppo: _gruppo.text,
        );
      }
      final id = widget.esistente?.id;
      if (id != null && _preferito != widget.esistente!.preferito) {
        await contabilita.impostaPreferito(id, _preferito);
      }
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
    return AlertDialog(
      title: Text(modifica ? 'Modifica portafoglio' : 'Nuovo portafoglio'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nome,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    hintText: 'Es. Contanti, Conto BancaX, Carta Visa',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Dai un nome al portafoglio'
                      : null,
                ),
                const SizedBox(height: 16),
                if (_tipi.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _tipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: [
                      for (final t in _tipi)
                        DropdownMenuItem(value: t.id, child: Text(t.nome)),
                    ],
                    onChanged: (v) => setState(() => _tipo = v),
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _valuta,
                  decoration: const InputDecoration(labelText: 'Valuta'),
                  items: [
                    for (final v in {...valuteComuni, _valuta})
                      DropdownMenuItem(
                        value: v,
                        child: Text('$v (${Importo.simbolo(v)})'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _valuta = v ?? 'EUR'),
                ),
                const SizedBox(height: 16),
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _gruppo.text),
                  optionsBuilder: (v) => _gruppi.where(
                    (g) => g.toLowerCase().contains(v.text.toLowerCase()),
                  ),
                  onSelected: (g) => _gruppo.text = g,
                  fieldViewBuilder: (context, controllo, fuoco, invio) {
                    if (!_gruppoCollegato) {
                      _gruppoCollegato = true;
                      controllo.addListener(
                        () => _gruppo.text = controllo.text,
                      );
                    }
                    return TextField(
                      controller: controllo,
                      focusNode: fuoco,
                      decoration: const InputDecoration(
                        labelText: 'Gruppo (facoltativo)',
                        hintText: 'Es. Conti, Risparmi, Investimenti',
                        helperText:
                            'I portafogli dello stesso gruppo stanno insieme '
                            'nella Panoramica e si possono richiudere.',
                        helperMaxLines: 2,
                      ),
                    );
                  },
                ),
                if (widget.esistente != null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _preferito,
                    onChanged: (v) => setState(() => _preferito = v),
                    secondary: Icon(
                      _preferito ? Icons.star : Icons.star_border,
                    ),
                    title: const Text('Preferito'),
                    subtitle: const Text(
                      'Sempre in evidenza in cima alla Panoramica',
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _saldo,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _salva(),
                  decoration: InputDecoration(
                    labelText: 'Quanto c\'è adesso? (facoltativo)',
                    hintText: '0,00',
                    helperText: 'Il saldo di partenza: da qui in poi conta i movimenti.',
                    helperMaxLines: 2,
                    suffixText: Importo.simbolo(_valuta),
                  ),
                  validator: (v) =>
                      (v != null &&
                          v.trim().isNotEmpty &&
                          Importo.leggi(v) == null)
                      ? 'Scrivi un importo, per esempio 150,00'
                      : null,
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
          child: Text(modifica ? 'Salva modifiche' : 'Crea'),
        ),
      ],
    );
  }
}
