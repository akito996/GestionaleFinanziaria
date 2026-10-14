import 'package:flutter/material.dart';

import '../../core/sessione.dart';
import '../movimenti/riga_movimento.dart';
import 'avvisi.dart';
import 'campi.dart';

/// Campo "Conta dal" per un prestito o una voce già in corso quando la
/// inserisci: le scadenze prima di questa data sono già avvenute, quindi non si
/// registrano e non contano nel costo della vita.
class CampoContaDal extends StatelessWidget {
  const CampoContaDal({
    super.key,
    required this.valore,
    required this.inizio,
    required this.onChanged,
    required this.spiegazione,
  });

  final DateTime valore;

  /// Prima scadenza (la data più vecchia che ha senso scegliere).
  final DateTime inizio;
  final ValueChanged<DateTime> onChanged;

  /// Es. "le rate prima di questa data le consideri già pagate".
  final String spiegazione;

  @override
  Widget build(BuildContext context) {
    final oggi = DateUtils.dateOnly(DateTime.now());
    final schema = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoData(
          etichetta: 'Conta dal',
          valore: valore,
          primo: inizio.isBefore(oggi) ? inizio : oggi,
          ultimo: oggi,
          onChanged: onChanged,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.history_toggle_off, size: 16, color: schema.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Già in corso: $spiegazione. Non si registrano e non contano '
                  'nel costo della vita.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dopo il salvataggio: quanti movimenti sono stati tolti perché prima del
/// "Conta dal", con "Annulla" per rimetterli.
void avvisaMovimentiTolti(
  ScaffoldMessengerState messenger,
  Sessione sessione,
  List<String> tolti,
  DateTime dal,
) {
  if (tolti.isEmpty) {
    return;
  }
  // Il contesto dell'avviso: il modulo che l'ha chiesto è già chiuso.
  final giorno = dataLeggibile(messenger.context, dal);
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      avviso(
        content: Text(
          tolti.length == 1
              ? 'Tolto 1 movimento registrato prima del $giorno'
              : 'Tolti ${tolti.length} movimenti registrati prima del $giorno',
        ),
        action: SnackBarAction(
          label: 'Annulla',
          onPressed: () => sessione.pianificatore.ripristinaMovimenti(tolti),
        ),
      ),
    );
}
