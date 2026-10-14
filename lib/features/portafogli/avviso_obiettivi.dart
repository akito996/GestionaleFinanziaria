import 'package:flutter/material.dart';

import '../../core/db/obiettivi.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';

/// Nel portafoglio: quanta parte dei soldi è messa da parte per gli obiettivi
/// che li tengono qui, e quanto resta libero. Non mostra nulla se non ce ne
/// sono.
class AvvisoObiettivi extends StatefulWidget {
  const AvvisoObiettivi({
    super.key,
    required this.sessione,
    required this.portafoglioId,
    required this.saldo,
    required this.valuta,
  });

  final Sessione sessione;
  final String portafoglioId;
  final int saldo;
  final String valuta;

  @override
  State<AvvisoObiettivi> createState() => _AvvisoObiettiviState();
}

class _AvvisoObiettiviState extends State<AvvisoObiettivi> {
  // Creato una volta sola: dopo il blocco non tocca più l'archivio.
  late final Stream<List<ObiettivoConStato>> _obiettivi = widget
      .sessione
      .obiettivi
      .osserva();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ObiettivoConStato>>(
      stream: _obiettivi,
      builder: (context, snapshot) {
        final qui = [
          for (final o in snapshot.data ?? const <ObiettivoConStato>[])
            if (o.obiettivo.portafoglioId == widget.portafoglioId &&
                o.riservato > 0)
              o,
        ];
        if (qui.isEmpty) {
          return const SizedBox.shrink();
        }
        String euro(int v) => Importo.formatta(v, widget.valuta);
        final riservato = qui.fold(0, (somma, o) => somma + o.riservato);
        final libero = widget.saldo - riservato;
        final schema = Theme.of(context).colorScheme;
        final testo = Theme.of(context).textTheme;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            color: schema.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.savings_outlined,
                        color: schema.onSecondaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          qui.length == 1
                              ? 'Di questi soldi, ${euro(riservato)} sono per '
                                    'l\'obiettivo "${qui.single.obiettivo.nome}"'
                              : 'Di questi soldi, ${euro(riservato)} sono per '
                                    '${qui.length} obiettivi',
                          style: testo.titleSmall?.copyWith(
                            color: schema.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final o in qui)
                    Padding(
                      padding: const EdgeInsets.only(left: 36, bottom: 2),
                      child: Text(
                        '${o.obiettivo.nome}: ${euro(o.riservato)}'
                        '${o.raggiunto ? ' (obiettivo raggiunto)' : ' (tutto il versato, obiettivo non ancora raggiunto)'}',
                        style: testo.bodySmall?.copyWith(
                          color: schema.onSecondaryContainer,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: Text(
                      libero >= 0
                          ? 'Liberi da usare: ${euro(libero)}'
                          : 'Attenzione: nel portafoglio mancano ${euro(-libero)} '
                                'rispetto ai soldi messi da parte',
                      style: testo.bodyMedium?.copyWith(
                        color: libero >= 0
                            ? schema.onSecondaryContainer
                            : schema.error,
                        fontWeight: FontWeight.w600,
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
