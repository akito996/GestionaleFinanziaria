import 'package:flutter/material.dart';

/// Finestra con un campo di testo; restituisce il testo confermato o `null`.
///
/// Il campo appartiene alla finestra stessa: viene liberato solo quando la
/// finestra è davvero chiusa (anche dopo l'animazione di chiusura).
Future<String?> chiediTesto(
  BuildContext context, {
  required String titolo,
  String etichetta = '',
  String suggerimento = '',
  String iniziale = '',
  String conferma = 'Salva',
  int righe = 1,
  bool obbligatorio = true,
}) => showDialog<String>(
  context: context,
  builder: (_) => _DialogoTesto(
    titolo: titolo,
    etichetta: etichetta,
    suggerimento: suggerimento,
    iniziale: iniziale,
    conferma: conferma,
    righe: righe,
    obbligatorio: obbligatorio,
  ),
);

class _DialogoTesto extends StatefulWidget {
  const _DialogoTesto({
    required this.titolo,
    required this.etichetta,
    required this.suggerimento,
    required this.iniziale,
    required this.conferma,
    required this.righe,
    required this.obbligatorio,
  });

  final String titolo;
  final String etichetta;
  final String suggerimento;
  final String iniziale;
  final String conferma;
  final int righe;
  final bool obbligatorio;

  @override
  State<_DialogoTesto> createState() => _DialogoTestoState();
}

class _DialogoTestoState extends State<_DialogoTesto> {
  late final _testo = TextEditingController(text: widget.iniziale);

  @override
  void dispose() {
    _testo.dispose();
    super.dispose();
  }

  void _conferma() {
    final valore = widget.righe == 1 ? _testo.text.trim() : _testo.text;
    if (widget.obbligatorio && valore.trim().isEmpty) {
      return;
    }
    Navigator.of(context).pop(valore);
  }

  @override
  Widget build(BuildContext context) {
    final multiriga = widget.righe > 1;
    return AlertDialog(
      title: Text(widget.titolo),
      content: SizedBox(
        width: multiriga ? 520 : 400,
        child: TextField(
          controller: _testo,
          autofocus: true,
          minLines: multiriga ? widget.righe : 1,
          maxLines: multiriga ? widget.righe * 2 : 1,
          onSubmitted: multiriga ? null : (_) => _conferma(),
          decoration: InputDecoration(
            labelText: widget.etichetta.isEmpty ? null : widget.etichetta,
            hintText: widget.suggerimento.isEmpty ? null : widget.suggerimento,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(onPressed: _conferma, child: Text(widget.conferma)),
      ],
    );
  }
}
