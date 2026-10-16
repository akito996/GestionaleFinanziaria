import 'package:flutter/material.dart';

import 'layout.dart';

/// Modulo in una finestra che si adatta allo schermo:
/// - telefono (sotto [Larghezze.media]): a tutto schermo, con "Chiudi" a
///   sinistra e l'azione principale in alto a destra, come le app Android;
/// - tablet e PC: finestra al centro, con le azioni in basso.
///
/// [contenuto] è la colonna dei campi (scorre da sola).
class ModuloAdattivo extends StatelessWidget {
  const ModuloAdattivo({
    super.key,
    required this.titolo,
    required this.contenuto,
    required this.azione,
    required this.onAzione,
    this.onElimina,
    this.larghezza = 440,
  });

  final String titolo;
  final Widget contenuto;

  /// Testo dell'azione principale (es. "Aggiungi", "Salva").
  final String azione;

  /// `null` = azione momentaneamente non disponibile (es. salvataggio in corso).
  final VoidCallback? onAzione;

  /// Se presente, compare "Elimina".
  final VoidCallback? onElimina;

  /// Larghezza della finestra su tablet e PC.
  final double larghezza;

  @override
  Widget build(BuildContext context) {
    final telefono = MediaQuery.sizeOf(context).width < Larghezze.media;
    if (telefono) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            leading: const CloseButton(),
            title: Text(titolo, overflow: TextOverflow.ellipsis),
            actions: [
              if (onElimina != null)
                IconButton(
                  tooltip: 'Elimina',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onElimina,
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton(onPressed: onAzione, child: Text(azione)),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: contenuto,
            ),
          ),
        ),
      );
    }
    return AlertDialog(
      title: Text(titolo),
      content: SizedBox(
        width: larghezza,
        child: SingleChildScrollView(child: contenuto),
      ),
      actions: [
        if (onElimina != null)
          TextButton.icon(
            onPressed: onElimina,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Elimina'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(onPressed: onAzione, child: Text(azione)),
      ],
    );
  }
}
