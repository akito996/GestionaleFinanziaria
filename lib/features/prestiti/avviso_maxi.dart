import 'package:flutter/material.dart';

import '../../core/db/prestiti.dart';
import '../../core/db/tabelle.dart';
import '../../core/importo.dart';
import '../../core/prestiti/lettore_contratto.dart';
import '../../core/sessione.dart';
import '../comuni/errori.dart';
import '../movimenti/riga_movimento.dart';
import 'prestito_modulo.dart';

/// "tra 3 giorni", "tra circa 4 mesi".
String _traQuanto(int giorni) => switch (giorni) {
  0 => 'oggi',
  1 => 'domani',
  <= 60 => 'tra $giorni giorni',
  _ => 'tra circa ${(giorni / 30).round()} mesi',
};

/// Chiede cosa fare della maxi rata: aprire un altro prestito (rifinanziare),
/// pagarla in un'unica soluzione, oppure rimandare la decisione.
Future<void> chiediDecisioneMaxi(
  BuildContext context,
  Sessione sessione,
  AvvisoMaxi avviso,
) async {
  final p = avviso.stato.prestito;
  final prossimo = PrestitiServizio.prossimoAvvisoMaxi(
    avviso.scadenza,
    DateTime.now(),
  );
  final scelta = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final testo = Theme.of(context).textTheme;
      return AlertDialog(
        // Sul telefono piccolo il contenuto scorre invece di uscire dal bordo.
        scrollable: true,
        icon: const Icon(Icons.flag_outlined),
        title: const Text('Maxi rata in arrivo'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '"${p.nome}": la maxi rata finale di '
                '${Importo.formatta(avviso.importo, p.valuta)} scade il '
                '${dataLeggibile(context, avviso.scadenza)}, '
                '${_traQuanto(avviso.giorniMancanti)}.',
              ),
              const SizedBox(height: 8),
              Text('Cosa vuoi fare?', style: testo.titleSmall),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.autorenew),
                  title: const Text('Apro un altro prestito'),
                  subtitle: const Text(
                    'Rifinanzio la maxi rata con un nuovo finanziamento: '
                    'dal conto non esce.',
                  ),
                  onTap: () =>
                      Navigator.of(context).pop(DecisioneMaxi.rifinanzia),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text("Pago tutto in un'unica soluzione"),
                  subtitle: const Text(
                    'La maxi rata esce dal conto alla scadenza.',
                  ),
                  onTap: () =>
                      Navigator.of(context).pop(DecisioneMaxi.estingui),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Ricordamelo più tardi (${dataLeggibile(context, prossimo)})',
            ),
          ),
        ],
      );
    },
  );
  final servizio = sessione.prestiti;
  try {
    if (scelta == null) {
      await servizio.rimandaMaxi(p.id);
      return;
    }
    await servizio.decidiMaxi(p.id, scelta);
    if (scelta == DecisioneMaxi.rifinanzia && context.mounted) {
      // Il nuovo prestito parte il mese dopo la maxi rata, per quell'importo.
      await apriModuloPrestito(
        context,
        sessione,
        introduzione:
            'Nuovo prestito per la maxi rata di "${p.nome}": completa con i '
            'dati del nuovo finanziamento (puoi farlo anche più avanti).',
        proposte: ProposteContratto(
          nome: 'Rifinanziamento ${p.nome}',
          capitale: p.maxiRataMinimo,
          primaRata: DateTime(
            avviso.scadenza.year,
            avviso.scadenza.month + 1,
            avviso.scadenza.day,
          ),
        ),
      );
    }
  } catch (e, stack) {
    if (context.mounted) {
      await mostraErroreImprevisto(context, e, stack);
    }
  }
}

/// Chiede, una dopo l'altra, le decisioni sulle maxi rate dovute adesso
/// (all'apertura dell'app e poi periodicamente). Non fa nulla se è già aperta
/// una richiesta.
Future<void> controllaAvvisiMaxi(
  BuildContext context,
  Sessione sessione,
) async {
  if (_inCorso) {
    return;
  }
  _inCorso = true;
  try {
    final avvisi = PrestitiServizio.avvisiMaxi(
      await sessione.prestiti.stati(),
      DateTime.now(),
    ).where((a) => a.daChiedere);
    for (final a in avvisi) {
      if (!context.mounted) {
        return;
      }
      await chiediDecisioneMaxi(context, sessione, a);
    }
  } finally {
    _inCorso = false;
  }
}

bool _inCorso = false;
