import 'package:flutter/material.dart';

import '../../core/db/archivio.dart';
import '../../core/sessione.dart';
import '../comuni/dialogo_testo.dart';
import '../comuni/layout.dart';
import '../comuni/navigazione.dart';
import 'albero_vista.dart';

/// Gestione delle categorie: albero senza limiti, aggiungi sottocategoria,
/// rinomina, archivia (con Annulla).
class CategoriePagina extends StatelessWidget {
  const CategoriePagina({super.key, required this.sessione});

  final Sessione sessione;

  Future<String?> _chiediNome(
    BuildContext context, {
    required String titolo,
    String iniziale = '',
  }) => chiediTesto(
    context,
    titolo: titolo,
    etichetta: 'Nome',
    iniziale: iniziale,
  );

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
      body: ContenutoCentrato(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Le categorie servono a capire dove vanno i soldi. Puoi creare '
                'sottocategorie a qualsiasi livello (es. Casa › Bollette › Luce).',
              ),
            ),
            Expanded(
              child: AlberoCategorieVista(
                sessione: sessione,
                chiave: 'pagina',
                apertePredefinite: true,
                onTocca: (c) => _rinomina(context, c),
                azioni: (categoria) => Row(
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
            ),
          ],
        ),
      ),
    );
  }
}
