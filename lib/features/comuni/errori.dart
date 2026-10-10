import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Errore non previsto: mai silenzio. Spiega che i dati sono al sicuro e permette
/// di copiare i dettagli tecnici (tipo ed elenco delle chiamate: niente password né dati).
Future<void> mostraErroreImprevisto(
  BuildContext context,
  Object errore,
  StackTrace stack,
) {
  final dettagli =
      '${errore.runtimeType}: $errore\n\n'
      '${stack.toString().split('\n').take(15).join('\n')}';
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.error_outline),
      title: const Text('Qualcosa è andato storto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Non è colpa tua e i tuoi dati sono al sicuro. Riprova; se il problema '
              'si ripete, copia i dettagli e inviali a chi ti assiste.',
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Dettagli tecnici'),
              children: [
                SelectableText(
                  dettagli,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: dettagli)),
          child: const Text('Copia dettagli'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Chiudi'),
        ),
      ],
    ),
  );
}

/// Riga "in corso": cerchio di caricamento + testo che dice cosa sta succedendo.
class InCorso extends StatelessWidget {
  const InCorso({super.key, required this.testo});

  final String testo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(testo)),
        ],
      ),
    );
  }
}
