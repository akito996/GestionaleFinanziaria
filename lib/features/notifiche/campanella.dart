import 'package:flutter/material.dart';

import '../../core/db/notifiche.dart';
import '../../core/sessione.dart';
import '../comuni/layout.dart';
import 'notifiche_pagina.dart';
import 'riga_notifica.dart';

/// Campanella vicino al lucchetto, come le notifiche del telefono: compare
/// solo se c'è qualcosa da vedere (da decidere o non letto) e il numero dice
/// quante sono. Un tocco apre il pannello. Senza notifiche resta nel menu ☰.
class CampanellaNotifiche extends StatefulWidget {
  const CampanellaNotifiche({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<CampanellaNotifiche> createState() => _CampanellaNotificheState();
}

class _CampanellaNotificheState extends State<CampanellaNotifiche> {
  // Creato una volta sola: dopo il blocco non tocca più l'archivio.
  late final Stream<List<Notifica>> _notifiche = widget.sessione.notifiche
      .osserva();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Notifica>>(
      stream: _notifiche,
      builder: (context, snapshot) {
        final attive = (snapshot.data ?? const <Notifica>[])
            .where((n) => n.attiva)
            .length;
        if (attive == 0) {
          return const SizedBox.shrink();
        }
        return IconButton(
          tooltip: attive == 0
              ? 'Notifiche'
              : attive == 1
              ? 'Notifiche: 1 da vedere'
              : 'Notifiche: $attive da vedere',
          icon: Badge(
            isLabelVisible: attive > 0,
            label: Text('$attive'),
            child: Icon(
              attive > 0
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none,
            ),
          ),
          onPressed: () => apriPannelloNotifiche(context, widget.sessione),
        );
      },
    );
  }
}

/// Pannello delle notifiche: da destra sugli schermi larghi (come il centro
/// notifiche di Windows), dal basso sul telefono. Si chiude toccando fuori.
Future<void> apriPannelloNotifiche(BuildContext context, Sessione sessione) {
  final schermo = MediaQuery.sizeOf(context);
  if (schermo.width >= Larghezze.media) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Chiudi le notifiche',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, animazione, _, figlio) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: animazione, curve: Curves.easeOutCubic),
        ),
        child: figlio,
      ),
      pageBuilder: (context, _, _) => Align(
        alignment: AlignmentDirectional.centerEnd,
        child: SizedBox(
          width: schermo.width < 480 ? schermo.width : 420,
          height: double.infinity,
          child: Material(
            elevation: 8,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: SafeArea(child: PannelloNotifiche(sessione: sessione)),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SizedBox(
      height: schermo.height * 0.85,
      child: PannelloNotifiche(sessione: sessione),
    ),
  );
}

/// Le notifiche da vedere, con le azioni, "Segna tutte come lette" e il
/// collegamento all'elenco completo.
class PannelloNotifiche extends StatefulWidget {
  const PannelloNotifiche({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<PannelloNotifiche> createState() => _PannelloNotificheState();
}

class _PannelloNotificheState extends State<PannelloNotifiche> {
  late final Stream<List<Notifica>> _notifiche = widget.sessione.notifiche
      .osserva();

  void _apriTutte() {
    final navigatore = Navigator.of(context);
    navigatore.pop();
    navigatore.push(
      MaterialPageRoute<void>(
        builder: (_) => NotifichePagina(sessione: widget.sessione),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Avvisi in basso ("Annulla") dentro il pannello, non dietro.
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StreamBuilder<List<Notifica>>(
          stream: _notifiche,
          builder: (context, snapshot) {
            final attive = (snapshot.data ?? const <Notifica>[])
                .where((n) => n.attiva)
                .toList();
            final daLeggere = attive.where((n) => !n.letta).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Notifiche',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Segna tutte come lette',
                        icon: const Icon(Icons.done_all),
                        onPressed: daLeggere.isEmpty
                            ? null
                            : () => segnaNotificheLette(
                                context,
                                widget.sessione,
                                daLeggere,
                              ),
                      ),
                      IconButton(
                        tooltip: 'Chiudi',
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                if (!snapshot.hasData)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (attive.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 40),
                          SizedBox(height: 8),
                          Text(
                            'Nessuna notifica da vedere',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: attive.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) => RigaNotifica(
                        key: ValueKey(attive[i].chiave),
                        sessione: widget.sessione,
                        notifica: attive[i],
                      ),
                    ),
                  ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton.icon(
                    onPressed: _apriTutte,
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Tutte le notifiche'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
