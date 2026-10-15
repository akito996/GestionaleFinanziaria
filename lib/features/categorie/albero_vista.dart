import 'package:flutter/material.dart';

import '../comuni/sezioni.dart';
import '../../core/db/archivio.dart';
import '../../core/db/contabilita.dart';
import '../../core/sessione.dart';
import 'scelta_categoria.dart' show iconaCategoria;

/// Albero delle categorie con ricerca, rami apribili/richiudibili e
/// "come mostrarle all'apertura" (aperte o chiuse) ricordato per [chiave].
class AlberoCategorieVista extends StatefulWidget {
  const AlberoCategorieVista({
    super.key,
    required this.sessione,
    required this.chiave,
    required this.apertePredefinite,
    required this.onTocca,
    this.selezionata,
    this.azioni,
    this.intestazione,
    this.scorrimentoInterno = true,
  });

  final Sessione sessione;

  /// Dove viene usata (es. "pagina", "scelta"): preferenza separata.
  final String chiave;

  /// Predefinito se l'utente non ha ancora scelto (pagina: aperte; scelta: chiuse).
  final bool apertePredefinite;
  final ValueChanged<Categoria> onTocca;
  final String? selezionata;

  /// Pulsanti in fondo a ogni riga (es. aggiungi sottocategoria, menu).
  final Widget Function(Categoria categoria)? azioni;

  /// Righe extra in cima all'elenco (es. "Nessuna categoria").
  final List<Widget>? intestazione;
  final bool scorrimentoInterno;

  @override
  State<AlberoCategorieVista> createState() => _AlberoCategorieVistaState();
}

class _AlberoCategorieVistaState extends State<AlberoCategorieVista> {
  late final Stream<List<Categoria>> _categorie = widget.sessione.contabilita
      .osservaCategorie();
  final _cerca = TextEditingController();
  String _filtro = '';
  late bool _aperteAllAvvio = widget.apertePredefinite;
  final Set<String> _aperte = {};
  final Set<String> _chiuse = {};

  String get _chiavePreferenza => 'categorie.${widget.chiave}.aperte';

  @override
  void initState() {
    super.initState();
    widget.sessione.statistiche.preferenza(_chiavePreferenza).then((v) {
      if (v != null && mounted) {
        setState(() => _aperteAllAvvio = v == '1');
      }
    });
  }

  @override
  void dispose() {
    _cerca.dispose();
    super.dispose();
  }

  bool _aperta(String id) =>
      _aperte.contains(id) || (_aperteAllAvvio && !_chiuse.contains(id));

  /// [riga]: il punto toccato, che resta in vista se il ramo si chiude.
  void _alterna(String id, BuildContext riga) {
    final chiudo = _aperta(id);
    setState(() {
      if (chiudo) {
        _aperte.remove(id);
        _chiuse.add(id);
      } else {
        _chiuse.remove(id);
        _aperte.add(id);
      }
    });
    if (chiudo) {
      mantieniInVista(() => riga);
    }
  }

  void _tutte(bool aperte) => setState(() {
    _aperte.clear();
    _chiuse.clear();
    _aperteAllAvvio = aperte;
  });

  void _predefinito(bool aperte) {
    _tutte(aperte);
    widget.sessione.statistiche.salvaPreferenza(
      _chiavePreferenza,
      aperte ? '1' : '0',
    );
  }

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    return StreamBuilder<List<Categoria>>(
      stream: _categorie,
      builder: (context, snapshot) {
        final albero = AlberoCategorie(snapshot.data ?? const []);
        final filtro = _filtro.trim().toLowerCase();
        final righe = <Widget>[...?widget.intestazione];

        if (filtro.isNotEmpty) {
          // Ricerca: risultati in elenco piatto con il percorso completo.
          for (final (c, _) in albero.inOrdine()) {
            final percorso = albero.percorso(c.id);
            if (percorso.toLowerCase().contains(filtro)) {
              righe.add(_riga(c, 0, percorso, haFigli: false, aperta: false));
            }
          }
          if (righe.length == (widget.intestazione?.length ?? 0) &&
              snapshot.hasData) {
            righe.add(
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nessuna categoria trovata.'),
              ),
            );
          }
        } else {
          void visita(String? padre, int livello) {
            for (final c in albero.figli(padre)) {
              final haFigli = albero.figli(c.id).isNotEmpty;
              final aperta = _aperta(c.id);
              righe.add(
                _riga(c, livello, c.nome, haFigli: haFigli, aperta: aperta),
              );
              if (haFigli && aperta) {
                visita(c.id, livello + 1);
              }
            }
          }

          visita(null, 0);
        }

        final barra = Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cerca,
                onChanged: (v) => setState(() => _filtro = v),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Cerca (es. luce, spesa, auto)',
                  suffixIcon: _filtro.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Cancella ricerca',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            _cerca.clear();
                            _filtro = '';
                          }),
                        ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Apri tutto',
              icon: const Icon(Icons.unfold_more),
              onPressed: () => _tutte(true),
            ),
            IconButton(
              tooltip: 'Chiudi tutto',
              icon: const Icon(Icons.unfold_less),
              onPressed: () => _tutte(false),
            ),
            PopupMenuButton<bool>(
              tooltip: 'Come mostrarle all\'apertura',
              icon: const Icon(Icons.tune),
              onSelected: _predefinito,
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: true,
                  checked: _aperteAllAvvio,
                  child: const Text('All\'apertura: tutte aperte'),
                ),
                CheckedPopupMenuItem(
                  value: false,
                  checked: !_aperteAllAvvio,
                  child: const Text('All\'apertura: raggruppate (chiuse)'),
                ),
              ],
            ),
          ],
        );

        final elenco = widget.scorrimentoInterno
            ? Expanded(child: ListView(children: righe))
            : Column(children: righe);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: widget.scorrimentoInterno
              ? MainAxisSize.max
              : MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: barra,
            ),
            const SizedBox(height: 4),
            elenco,
            if (!snapshot.hasData)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            Divider(
              height: 1,
              color: schema.outlineVariant.withValues(alpha: 0),
            ),
          ],
        );
      },
    );
  }

  Widget _riga(
    Categoria c,
    int livello,
    String testo, {
    required bool haFigli,
    required bool aperta,
  }) {
    final schema = Theme.of(context).colorScheme;
    return ListTile(
      key: ValueKey('cat-${c.id}'),
      dense: livello > 0,
      selected: c.id == widget.selezionata,
      contentPadding: EdgeInsets.only(left: 8.0 + livello * 24, right: 4),
      leading: SizedBox(
        width: 72,
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: haFigli
                  ? Builder(
                      builder: (riga) => IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: aperta ? 'Chiudi' : 'Apri',
                        icon: Icon(
                          aperta ? Icons.expand_more : Icons.chevron_right,
                        ),
                        onPressed: () => _alterna(c.id, riga),
                      ),
                    )
                  : null,
            ),
            Icon(
              livello == 0
                  ? iconaCategoria(c.icona)
                  : Icons.subdirectory_arrow_right,
              color: livello == 0 ? null : schema.outline,
            ),
          ],
        ),
      ),
      title: Text(testo),
      trailing: widget.azioni?.call(c),
      onTap: () => widget.onTocca(c),
    );
  }
}
