import 'package:flutter/material.dart';

import '../../core/db/contabilita.dart';
import '../../core/sessione.dart';

/// Icona di una categoria principale (chiave salvata nella colonna `icona`).
IconData iconaCategoria(String? chiave) => switch (chiave) {
  'casa' => Icons.home_outlined,
  'alimentari' => Icons.shopping_cart_outlined,
  'trasporti' => Icons.directions_car_outlined,
  'salute' => Icons.favorite_outline,
  'abbonamenti' => Icons.subscriptions_outlined,
  'svago' => Icons.celebration_outlined,
  'persona' => Icons.person_outline,
  'tasse' => Icons.account_balance_outlined,
  'entrate' => Icons.savings_outlined,
  _ => Icons.label_outline,
};

/// Risultato della scelta: [annullata] se l'utente chiude senza scegliere.
typedef SceltaCategoria = ({bool annullata, String? id});

/// Elenco ad albero con ricerca. "Nessuna categoria" è sempre possibile.
Future<SceltaCategoria> scegliCategoria(
  BuildContext context,
  Sessione sessione, {
  String? selezionata,
  String titolo = 'Categoria',
}) async {
  final scelta = await showDialog<SceltaCategoria>(
    context: context,
    builder: (_) => _SceltaCategoriaDialogo(
      sessione: sessione,
      selezionata: selezionata,
      titolo: titolo,
    ),
  );
  return scelta ?? (annullata: true, id: selezionata);
}

class _SceltaCategoriaDialogo extends StatefulWidget {
  const _SceltaCategoriaDialogo({
    required this.sessione,
    required this.selezionata,
    required this.titolo,
  });

  final Sessione sessione;
  final String? selezionata;
  final String titolo;

  @override
  State<_SceltaCategoriaDialogo> createState() =>
      _SceltaCategoriaDialogoState();
}

class _SceltaCategoriaDialogoState extends State<_SceltaCategoriaDialogo> {
  final _cerca = TextEditingController();
  String _filtro = '';

  @override
  void dispose() {
    _cerca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.titolo),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SizedBox(
        width: 420,
        height: 480,
        child: StreamBuilder(
          stream: widget.sessione.contabilita.osservaCategorie(),
          builder: (context, snapshot) {
            final albero = AlberoCategorie(snapshot.data ?? const []);
            final filtro = _filtro.trim().toLowerCase();
            final righe = albero
                .inOrdine()
                .where(
                  (r) =>
                      filtro.isEmpty ||
                      albero.percorso(r.$1.id).toLowerCase().contains(filtro),
                )
                .toList();
            return Column(
              children: [
                TextField(
                  controller: _cerca,
                  autofocus: true,
                  onChanged: (v) => setState(() => _filtro = v),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Cerca (es. luce, spesa, auto)',
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.block),
                        title: const Text('Nessuna categoria'),
                        selected: widget.selezionata == null,
                        onTap: () =>
                            Navigator.of(context)
                                .pop((annullata: false, id: null)),
                      ),
                      for (final (categoria, livello) in righe)
                        ListTile(
                          contentPadding: EdgeInsets.only(
                            left: 16.0 + (filtro.isEmpty ? livello * 24 : 0),
                            right: 16,
                          ),
                          leading: livello == 0
                              ? Icon(iconaCategoria(categoria.icona))
                              : Icon(
                                  Icons.subdirectory_arrow_right,
                                  color: schema.outline,
                                ),
                          title: Text(
                            filtro.isEmpty
                                ? categoria.nome
                                : albero.percorso(categoria.id),
                          ),
                          selected: categoria.id == widget.selezionata,
                          onTap: () =>
                              Navigator.of(context)
                                  .pop((annullata: false, id: categoria.id)),
                        ),
                      if (righe.isEmpty && snapshot.hasData)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Nessuna categoria trovata. Puoi crearla nella '
                            'sezione Categorie.',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
      ],
    );
  }
}

/// Campo "Categoria" per i moduli: mostra il percorso e apre la scelta.
class CampoCategoria extends StatelessWidget {
  const CampoCategoria({
    super.key,
    required this.sessione,
    required this.valore,
    required this.onChanged,
    this.etichetta = 'Categoria (facoltativa)',
  });

  final Sessione sessione;
  final String? valore;
  final ValueChanged<String?> onChanged;
  final String etichetta;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: sessione.contabilita.osservaCategorie(),
      builder: (context, snapshot) {
        final albero = AlberoCategorie(snapshot.data ?? const []);
        final testo = valore == null ? null : albero.percorso(valore!);
        return InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () async {
            final scelta = await scegliCategoria(
              context,
              sessione,
              selezionata: valore,
            );
            if (!scelta.annullata) {
              onChanged(scelta.id);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: etichetta,
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            isEmpty: testo == null || testo.isEmpty,
            child: Text(testo ?? '', overflow: TextOverflow.ellipsis),
          ),
        );
      },
    );
  }
}
