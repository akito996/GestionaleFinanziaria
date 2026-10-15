import 'package:flutter/material.dart';

import '../../core/db/notifiche.dart';
import '../../core/sessione.dart';
import '../comuni/layout.dart';
import '../comuni/navigazione.dart';
import 'riga_notifica.dart';

/// Scorciatoie dei filtri.
enum _Vista { tutte, daLeggere, daConfermare }

/// Entrate, uscite o tutte.
enum _Verso { entrate, uscite }

/// Tutte le notifiche (anche quelle lette degli ultimi giorni): filtri,
/// ricerca e selezione multipla per segnarle lette o confermarle insieme.
class NotifichePagina extends StatefulWidget {
  const NotifichePagina({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<NotifichePagina> createState() => _NotifichePaginaState();
}

class _NotifichePaginaState extends State<NotifichePagina> {
  late final Stream<List<Notifica>> _notifiche = widget.sessione.notifiche
      .osserva();
  final _ricerca = TextEditingController();
  _Vista _vista = _Vista.tutte;
  _Verso? _verso;
  final Set<String> _selezionate = {};

  @override
  void dispose() {
    _ricerca.dispose();
    super.dispose();
  }

  bool _passa(Notifica n) {
    final vista = switch (_vista) {
      _Vista.tutte => true,
      _Vista.daLeggere => !n.letta,
      _Vista.daConfermare => n.richiedeAzione,
    };
    final verso = switch (_verso) {
      null => true,
      _Verso.entrate => n.entrata,
      _Verso.uscite => !n.entrata && n.tipo != TipoNotifica.decisione,
    };
    final testo = _ricerca.text.trim().toLowerCase();
    return vista &&
        verso &&
        (testo.isEmpty || n.titolo.toLowerCase().contains(testo));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifiche'),
        actions: [PulsanteBlocca(sessione: widget.sessione, campanella: false)],
      ),
      body: StreamBuilder<List<Notifica>>(
        stream: _notifiche,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tutte = snapshot.data!;
          final visibili = tutte.where(_passa).toList();
          // Si tengono selezionate solo quelle ancora visibili.
          _selezionate.retainWhere((c) => visibili.any((n) => n.chiave == c));
          final scelte = [
            for (final n in visibili)
              if (_selezionate.contains(n.chiave)) n,
          ];
          return LayoutBuilder(
            builder: (context, vincoli) => ListView(
              padding: marginiPagina(vincoli, sotto: 32),
              children: [
                _filtri(context, tutte),
                const SizedBox(height: 8),
                _barraSelezione(context, visibili, scelte),
                if (visibili.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(switch (_vista) {
                      _Vista.daLeggere => 'Nessuna notifica da leggere.',
                      _Vista.daConfermare => 'Niente da confermare.',
                      _Vista.tutte => 'Nessuna notifica.',
                    }, textAlign: TextAlign.center),
                  )
                else
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final (i, n) in visibili.indexed) ...[
                          if (i > 0) const Divider(height: 1),
                          RigaNotifica(
                            key: ValueKey(n.chiave),
                            sessione: widget.sessione,
                            notifica: n,
                            selezionata: _selezionate.contains(n.chiave),
                            onSeleziona: (si) => setState(
                              () => si
                                  ? _selezionate.add(n.chiave)
                                  : _selezionate.remove(n.chiave),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filtri(BuildContext context, List<Notifica> tutte) {
    final daLeggere = tutte.where((n) => !n.letta).length;
    final daConfermare = tutte.where((n) => n.richiedeAzione).length;
    ChoiceChip scorciatoia(_Vista vista, String etichetta, IconData icona) =>
        ChoiceChip(
          avatar: Icon(icona, size: 18),
          label: Text(etichetta),
          selected: _vista == vista,
          onSelected: (_) => setState(() => _vista = vista),
        );
    FilterChip verso(_Verso valore, String etichetta) => FilterChip(
      label: Text(etichetta),
      selected: _verso == valore,
      onSelected: (si) => setState(() => _verso = si ? valore : null),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            scorciatoia(_Vista.tutte, 'Tutte', Icons.inbox_outlined),
            scorciatoia(
              _Vista.daLeggere,
              'Da leggere ($daLeggere)',
              Icons.mark_email_unread_outlined,
            ),
            scorciatoia(
              _Vista.daConfermare,
              'Da confermare ($daConfermare)',
              Icons.pending_actions,
            ),
            verso(_Verso.entrate, 'Entrate'),
            verso(_Verso.uscite, 'Uscite'),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ricerca,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Cerca per nome',
            suffixIcon: _ricerca.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Cancella la ricerca',
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(_ricerca.clear),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _barraSelezione(
    BuildContext context,
    List<Notifica> visibili,
    List<Notifica> scelte,
  ) {
    final tutteScelte = visibili.isNotEmpty && scelte.length == visibili.length;
    final confermabili = scelte.where((n) => n.confermabile).toList();
    final daLeggere = scelte.where((n) => !n.letta).toList();
    void inverti() => setState(() {
      if (tutteScelte) {
        _selezionate.clear();
      } else {
        _selezionate.addAll(visibili.map((n) => n.chiave));
      }
    });
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        // Si può toccare anche la scritta, non solo la casella.
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: visibili.isEmpty ? null : inverti,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  tristate: true,
                  value: scelte.isEmpty ? false : (tutteScelte ? true : null),
                  onChanged: visibili.isEmpty ? null : (_) => inverti(),
                ),
                Text(
                  scelte.isEmpty
                      ? 'Seleziona tutte'
                      : '${scelte.length} selezionate',
                ),
              ],
            ),
          ),
        ),
        if (scelte.isNotEmpty) ...[
          TextButton.icon(
            onPressed: daLeggere.isEmpty
                ? null
                : () async {
                    await segnaNotificheLette(
                      context,
                      widget.sessione,
                      daLeggere,
                    );
                    setState(_selezionate.clear);
                  },
            icon: const Icon(Icons.mark_email_read_outlined),
            label: const Text('Segna come lette'),
          ),
          FilledButton.tonalIcon(
            onPressed: confermabili.isEmpty
                ? null
                : () async {
                    await confermaNotifiche(
                      context,
                      widget.sessione,
                      confermabili,
                    );
                    setState(_selezionate.clear);
                  },
            icon: const Icon(Icons.check_circle_outline),
            label: Text('Conferma (${confermabili.length})'),
          ),
        ],
      ],
    );
  }
}
