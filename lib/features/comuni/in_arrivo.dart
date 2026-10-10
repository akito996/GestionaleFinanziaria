import 'package:flutter/material.dart';

import '../../core/db/pianificatore.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../movimenti/riga_movimento.dart';

/// "Oggi", "Domani", "Tra 3 giorni".
String quando(int giorni) => switch (giorni) {
  0 => 'Oggi',
  1 => 'Domani',
  _ => 'Tra $giorni giorni',
};

/// Scadenze in arrivo (bollette, rate, addebiti carta). Quelle entro la finestra
/// di avviso (3 giorni) sono evidenziate. Non mostra nulla se non ce ne sono.
class SchedaInArrivo extends StatefulWidget {
  const SchedaInArrivo({
    super.key,
    required this.sessione,
    this.portafoglioId,
    this.giorni = 7,
    this.titolo = 'In arrivo',
  });

  final Sessione sessione;

  /// Solo le scadenze che toccano questo portafoglio.
  final String? portafoglioId;
  final int giorni;
  final String titolo;

  @override
  State<SchedaInArrivo> createState() => _SchedaInArrivoState();
}

class _SchedaInArrivoState extends State<SchedaInArrivo> {
  // Creato una volta sola: dopo il blocco la scheda non tocca più l'archivio.
  late final Stream<List<ScadenzaInArrivo>> _scadenze = widget
      .sessione
      .pianificatore
      .osservaInArrivo(
        giorni: widget.giorni,
        portafoglioId: widget.portafoglioId,
      );

  @override
  Widget build(BuildContext context) {
    final giorni = widget.giorni;
    final titolo = widget.titolo;
    return StreamBuilder<List<ScadenzaInArrivo>>(
      stream: _scadenze,
      builder: (context, snapshot) {
        final scadenze = snapshot.data ?? const [];
        if (scadenze.isEmpty) {
          return const SizedBox.shrink();
        }
        final schema = Theme.of(context).colorScheme;
        final urgenti = scadenze.where((s) => s.daAvvisare).length;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            color: urgenti > 0 ? schema.tertiaryContainer : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    leading: Icon(
                      urgenti > 0
                          ? Icons.notifications_active
                          : Icons.event_note,
                      color: urgenti > 0 ? schema.onTertiaryContainer : null,
                    ),
                    title: Text(titolo),
                    subtitle: Text(
                      urgenti > 0
                          ? '$urgenti nei prossimi 3 giorni: verranno registrati '
                                'da soli nel giorno previsto'
                          : 'Nei prossimi $giorni giorni',
                    ),
                  ),
                  for (final s in scadenze.take(6))
                    ListTile(
                      dense: true,
                      leading: Icon(
                        s.daAvvisare ? Icons.priority_high : Icons.schedule,
                        size: 20,
                        color: s.daAvvisare ? schema.error : schema.outline,
                      ),
                      title: Text(
                        s.pianificazione.descrizione.isEmpty
                            ? 'Pagamento programmato'
                            : s.pianificazione.descrizione,
                      ),
                      subtitle: Text(
                        '${quando(s.giorniMancanti)} · '
                        '${dataLeggibile(context, s.data)}'
                        '${s.pianificazione.portafoglioId == null ? ' · promemoria' : ''}',
                      ),
                      trailing: Text(
                        Importo.formatta(s.importo, s.pianificazione.valuta),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
