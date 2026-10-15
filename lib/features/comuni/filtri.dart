import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Larghezza della pagina (accanto alla barra laterale) da cui i filtri
/// stanno comodi nella pagina.
const larghezzaFiltriInPagina = 720.0;

/// Su telefono e tablet (e nelle finestre strette) ricerca e opzioni stanno
/// in un pannello "Filtri" con "Applica"; sul PC largo restano nella pagina.
/// [vincoli]: lo spazio della pagina (da un `LayoutBuilder`).
bool filtriCompatti(BoxConstraints vincoli) =>
    (!kIsWeb && Platform.isAndroid) ||
    vincoli.maxWidth < larghezzaFiltriInPagina;

/// Pannello dal basso con le opzioni: le scelte valgono solo con [conferma]
/// ("Applica"). Restituisce `true` se l'utente ha confermato.
///
/// [campi] costruisce le opzioni su una copia di lavoro; [aggiorna] ridisegna
/// il pannello dopo ogni scelta. [azzera] rimette la copia com'era all'inizio.
Future<bool> apriPannelloFiltri(
  BuildContext context, {
  required String titolo,
  required List<Widget> Function(BuildContext context, StateSetter aggiorna)
  campi,
  required VoidCallback azzera,
  String conferma = 'Applica',
}) async {
  final esito = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, aggiorna) => Padding(
        // La tastiera (ricerca) non copre i pulsanti.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        titolo,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => aggiorna(azzera),
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text('Azzera'),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: campi(context, aggiorna),
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Annulla'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.check),
                      label: Text(conferma),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return esito ?? false;
}

/// Riga in cima alla pagina compatta: "Filtri (2)", cosa è filtrato e
/// "Togli i filtri".
class BarraFiltri extends StatelessWidget {
  const BarraFiltri({
    super.key,
    required this.attivi,
    required this.descrizione,
    required this.onApri,
    this.onTogli,
    this.etichetta = 'Filtri',
  });

  /// Quanti filtri sono attivi (0 = nessuno).
  final int attivi;

  /// Es. "Ottobre · Uscite · «lidl»" (vuoto = "Tutti i movimenti").
  final String descrizione;
  final VoidCallback onApri;
  final VoidCallback? onTogli;
  final String etichetta;

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    return Row(
      children: [
        FilledButton.tonalIcon(
          onPressed: onApri,
          icon: const Icon(Icons.tune),
          label: Text(attivi == 0 ? etichetta : '$etichetta ($attivi)'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            descrizione,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: testo.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (attivi > 0 && onTogli != null)
          IconButton(
            tooltip: 'Togli i filtri',
            icon: const Icon(Icons.filter_alt_off_outlined),
            onPressed: onTogli,
          ),
      ],
    );
  }
}
