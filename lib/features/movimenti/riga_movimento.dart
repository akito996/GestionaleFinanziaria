import 'package:flutter/material.dart';

import '../../core/db/contabilita.dart';
import '../../core/db/tabelle.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import 'movimento_modulo.dart';
import '../comuni/avvisi.dart';

/// Colore delle entrate (verde leggibile sia in chiaro sia in scuro).
Color coloreEntrata(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF81C784)
    : const Color(0xFF2E7D32);

Color coloreEffetto(BuildContext context, String? effetto) => switch (effetto) {
  EffettoSaldo.entrata => coloreEntrata(context),
  EffettoSaldo.uscita => Theme.of(context).colorScheme.error,
  _ => Theme.of(context).colorScheme.primary,
};

IconData iconaEffetto(String? effetto) => switch (effetto) {
  EffettoSaldo.entrata => Icons.south_west,
  EffettoSaldo.uscita => Icons.north_east,
  _ => Icons.swap_horiz,
};

/// "Oggi", "Ieri" oppure la data breve in italiano (con l'anno se diverso).
String dataLeggibile(BuildContext context, DateTime data) {
  final oggi = DateUtils.dateOnly(DateTime.now());
  final giorno = DateUtils.dateOnly(data);
  if (giorno == oggi) {
    return 'Oggi';
  }
  if (giorno == oggi.subtract(const Duration(days: 1))) {
    return 'Ieri';
  }
  final breve = MaterialLocalizations.of(context).formatMediumDate(giorno);
  // L'anno si mostra solo se non è quello in corso ("sab 5 dic 2030").
  return giorno.year == oggi.year ? breve : '$breve ${giorno.year}';
}

/// Una riga dell'elenco movimenti. Tocco = modifica; menu = modifica / elimina
/// (con "Annulla" subito disponibile).
class RigaMovimento extends StatelessWidget {
  const RigaMovimento({
    super.key,
    required this.sessione,
    required this.dettaglio,
    this.portafoglioId,
  });

  final Sessione sessione;
  final MovimentoDettaglio dettaglio;

  /// Se l'elenco è di un solo portafoglio, il segno si riferisce a quello.
  final String? portafoglioId;

  Future<void> _elimina(BuildContext context) async {
    final contabilita = sessione.contabilita;
    final id = dettaglio.movimento.id;
    await contabilita.eliminaMovimento(id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        avviso(
          content: const Text('Movimento eliminato'),
          action: SnackBarAction(
            label: 'Annulla',
            onPressed: () => contabilita.ripristinaMovimento(id),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final m = dettaglio.movimento;
    final effetto = dettaglio.tipo.effetto;
    final colore = coloreEffetto(context, effetto);

    final int importoMostrato;
    final bool conSegno;
    if (portafoglioId != null) {
      importoMostrato = dettaglio.effettoSu(portafoglioId!);
      conSegno = true;
    } else {
      importoMostrato = switch (effetto) {
        EffettoSaldo.uscita => -m.importoMinimo,
        _ => m.importoMinimo,
      };
      conSegno = effetto == EffettoSaldo.entrata;
    }

    final portafogli = dettaglio.destinazione == null
        ? dettaglio.portafoglio.nome
        : '${dettaglio.portafoglio.nome} → ${dettaglio.destinazione!.nome}';
    final titolo = m.descrizione.isEmpty ? dettaglio.tipo.nome : m.descrizione;

    return ListTile(
      onTap: () => apriModuloMovimento(context, sessione, esistente: dettaglio),
      leading: CircleAvatar(
        backgroundColor: colore.withValues(alpha: 0.15),
        foregroundColor: colore,
        child: Icon(iconaEffetto(effetto)),
      ),
      title: Text(titolo, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${dettaglio.categoria == null ? '' : '${dettaglio.categoria!.nome} · '}'
        '$portafogli · '
        '${dataLeggibile(context, Contabilita.daGiorno(m.data))}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Importo.formatta(importoMostrato, m.valuta, conSegno: conSegno),
            style: TextStyle(
              color:
                  effetto == EffettoSaldo.trasferimento && portafoglioId == null
                  ? null
                  : colore,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Altre azioni',
            onSelected: (azione) => switch (azione) {
              'modifica' => apriModuloMovimento(
                context,
                sessione,
                esistente: dettaglio,
              ),
              _ => _elimina(context),
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'modifica',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Modifica'),
                ),
              ),
              PopupMenuItem(
                value: 'elimina',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Elimina'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
