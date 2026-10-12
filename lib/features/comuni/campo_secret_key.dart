import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/crypto/eccezioni.dart';
import '../../core/crypto/secret_key.dart';

/// Inserimento della Secret Key senza digitare: "Scegli il file" o "Incolla".
/// Si può anche scrivere a mano. Il controllo del formato è immediato.
class CampoSecretKey extends StatefulWidget {
  const CampoSecretKey({
    super.key,
    required this.controller,
    required this.onValidita,
    this.errore,
  });

  final TextEditingController controller;

  /// Chiamato a ogni modifica: `true` se il testo contiene una Secret Key ben formata.
  final ValueChanged<bool> onValidita;

  /// Errore dall'esterno (es. "non è di questo archivio").
  final String? errore;

  @override
  State<CampoSecretKey> createState() => _CampoSecretKeyState();
}

class _CampoSecretKeyState extends State<CampoSecretKey> {
  /// Un file con la Secret Key pesa poche centinaia di byte.
  static const _dimensioneMassimaFile = 64 * 1024;

  String? _stato;
  bool _valida = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_controlla);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controlla);
    super.dispose();
  }

  void _controlla() {
    final testo = widget.controller.text;
    String? stato;
    var valida = false;
    if (testo.trim().isNotEmpty) {
      try {
        SecretKey.daTesto(testo).cancella();
        valida = true;
      } on SecretKeyNonValidaException catch (e) {
        stato = e.messaggio;
      }
    }
    if (valida != _valida || stato != _stato) {
      setState(() {
        _valida = valida;
        _stato = stato;
      });
      widget.onValidita(valida);
    }
  }

  Future<void> _scegliFile() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Secret Key (.txt)',
          extensions: ['txt'],
          mimeTypes: ['text/plain'],
        ),
      ],
      confirmButtonText: 'Usa questo file',
    );
    if (file == null) {
      return;
    }
    if (await file.length() > _dimensioneMassimaFile) {
      setState(() => _stato = 'Questo file non contiene una Secret Key.');
      return;
    }
    widget.controller.text = await file.readAsString();
  }

  Future<void> _incolla() async {
    final dati = await Clipboard.getData(Clipboard.kTextPlain);
    widget.controller.text = dati?.text ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    final errore = widget.errore ?? _stato;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: _scegliFile,
              icon: const Icon(Icons.file_open_outlined),
              label: const Text('Scegli il file'),
            ),
            OutlinedButton.icon(
              onPressed: _incolla,
              icon: const Icon(Icons.content_paste),
              label: const Text('Incolla'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.controller,
          minLines: 2,
          maxLines: 4,
          autocorrect: false,
          enableSuggestions: false,
          style: const TextStyle(fontFamily: 'monospace'),
          decoration: InputDecoration(
            labelText: 'Secret Key',
            hintText: 'GF1-XXXXX-XXXXX-…',
            errorText: errore,
            errorMaxLines: 3,
            helperText: _valida ? 'Secret Key valida' : null,
            helperStyle: TextStyle(color: schema.primary),
            suffixIcon: _valida
                ? Icon(Icons.check_circle, color: schema.primary)
                : null,
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
