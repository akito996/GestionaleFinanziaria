import 'package:flutter/material.dart';

import '../../core/db/archivio.dart';
import '../../core/db/contabilita.dart';
import '../../core/sessione.dart';
import '../comuni/navigazione.dart';
import 'scelta_categoria.dart';

/// Gestione delle categorie: albero senza limiti, aggiungi sottocategoria,
/// rinomina, archivia (con Annulla).
class CategoriePagina extends StatelessWidget {
  const CategoriePagina({super.key, required this.sessione});

  final Sessione sessione;

  Future<String?> _chiediNome(
    BuildContext context, {
    required String titolo,
    String iniziale = '',
  }) {
    final testo = TextEditingController(text: iniziale);
    return showDialog<String>(
      context: context,
      builder: (context) {
        void conferma() {
          if (testo.text.trim().isNotEmpty) {
            Navigator.of(context).pop(testo.text.trim());
          }
        }

        return AlertDialog(
          title: Text(titolo),
          content: TextField(
            controller: testo,
            autofocus: true,
            onSubmitted: (_) => conferma(),
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            FilledButton(onPressed: conferma, child: const Text('Salva')),
          ],
        );
      },
    ).whenComplete(testo.dispose);
  }

  Future<void> _nuova(BuildContext context, {Categoria? padre}) async {
    final nome = await _chiediNome(
      context,
      titolo: padre == null
          ? 'Nuova categoria'
          : 'Nuova sottocategoria di "${padre.nome}"',
    );
    if (nome != null) {
      await sessione.contabilita.creaCategoria(nome: nome, padreId: padre?.id);
    }
  }

  Future<void> _rinomina(BuildContext context, Categoria categoria) async {
    final nome = await _chiediNome(
      context,
      titolo: 'Rinomina categoria',
      iniziale: categoria.nome,
    );
    if (nome != null) {
      await sessione.contabilita.rinominaCategoria(categoria.id, nome);
    }
  }

  Future<void> _archivia(BuildContext context, Categoria categoria) async {
    final contabilita = sessione.contabilita;
    await contabilita.archiviaCategoria(categoria.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('"${categoria.nome}" archiviata'),
          action: SnackBarAction(
            label: 'Annulla',
            onPressed: () =>
                contabilita.archiviaCategoria(categoria.id, archiviata: false),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorie'),
        actions: [PulsanteBlocca(sessione: sessione)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-categorie',
        onPressed: () => _nuova(context),
        icon: const Icon(Icons.add),
        label: const Text('Categoria'),
      ),
      body: StreamBuilder(
        stream: sessione.contabilita.osservaCategorie(),
        builder: (context, snapshot) {
          final albero = AlberoCategorie(snapshot.data ?? const []);
          final schema = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Le categorie servono a capire dove vanno i soldi. Puoi creare '
                  'sottocategorie a qualsiasi livello (es. Casa › Bollette › Luce).',
                ),
              ),
              for (final (categoria, livello) in albero.inOrdine())
                ListTile(
                  contentPadding: EdgeInsets.only(
                    left: 16.0 + livello * 28,
                    right: 8,
                  ),
                  leading: livello == 0
                      ? Icon(iconaCategoria(categoria.icona))
                      : Icon(
                          Icons.subdirectory_arrow_right,
                          color: schema.outline,
                        ),
                  title: Text(categoria.nome),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Aggiungi sottocategoria',
                        icon: const Icon(Icons.add),
                        onPressed: () => _nuova(context, padre: categoria),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Altre azioni',
                        onSelected: (azione) => azione == 'rinomina'
                            ? _rinomina(context, categoria)
                            : _archivia(context, categoria),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'rinomina',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Rinomina'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'archivia',
                            child: ListTile(
                              leading: Icon(Icons.archive_outlined),
                              title: Text('Archivia'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
