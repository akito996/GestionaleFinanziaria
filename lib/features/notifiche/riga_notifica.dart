import 'package:flutter/material.dart';

import '../../core/db/notifiche.dart';
import '../../core/db/tabelle.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../comuni/campi.dart';
import '../comuni/errori.dart';
import '../movimenti/riga_movimento.dart';
import '../prestiti/avviso_maxi.dart';

/// "oggi", "domani", "ieri" oppure la data breve ("gio 15 ott").
String giornoNotifica(BuildContext context, DateTime data) {
  final oggi = DateUtils.dateOnly(DateTime.now());
  final giorno = DateUtils.dateOnly(data);
  // Arrotondato: il cambio dell'ora legale non sposta il giorno.
  return switch ((giorno.difference(oggi).inHours / 24).round()) {
    0 => 'oggi',
    1 => 'domani',
    -1 => 'ieri',
    _ => dataLeggibile(context, giorno),
  };
}

/// Cosa dice la seconda riga della notifica.
String sottotitoloNotifica(BuildContext context, Notifica n) {
  final giorno = giornoNotifica(context, n.data);
  final testo = switch (n.tipo) {
    TipoNotifica.daConfermare => 'Da confermare · $giorno',
    TipoNotifica.decisione => 'Maxi rata · scade $giorno',
    TipoNotifica.inArrivo =>
      n.scadenza!.pianificazione.richiedeConferma
          ? 'Ti chiederò conferma $giorno'
          : 'Si registra da sola $giorno',
    TipoNotifica.registrata => 'Registrata da sola $giorno',
    TipoNotifica.promemoria => 'Promemoria · $giorno',
  };
  final s = n.scadenza;
  final spostata = s != null && s.scelta?.stato == StatoOccorrenza.spostata
      ? ' · spostata dal ${dataLeggibile(context, s.dataPrevista)}'
      : '';
  return '$testo$spostata';
}

IconData _icona(TipoNotifica tipo) => switch (tipo) {
  TipoNotifica.daConfermare => Icons.pending_actions,
  TipoNotifica.decisione => Icons.flag_outlined,
  TipoNotifica.inArrivo => Icons.schedule,
  TipoNotifica.registrata => Icons.task_alt,
  TipoNotifica.promemoria => Icons.sticky_note_2_outlined,
};

// --------------------------------------------------------------- azioni

void _avviso(
  ScaffoldMessengerState messenger,
  String testo, {
  Ripristino? indietro,
  String etichetta = 'Annulla',
}) {
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(testo),
        action: indietro == null
            ? null
            : SnackBarAction(label: etichetta, onPressed: () => indietro()),
      ),
    );
}

Future<void> _esegui(
  BuildContext context,
  Future<void> Function(ScaffoldMessengerState messenger) azione,
) async {
  // Preso prima: dopo l'azione la riga sparisce dall'elenco.
  final messenger = ScaffoldMessenger.of(context);
  try {
    await azione(messenger);
  } catch (e, stack) {
    if (context.mounted) {
      await mostraErroreImprevisto(context, e, stack);
    }
  }
}

/// Conferma le scadenze (registra i movimenti, o segna fatti i promemoria),
/// con "Annulla" nell'avviso.
Future<void> confermaNotifiche(
  BuildContext context,
  Sessione sessione,
  List<Notifica> notifiche,
) async {
  final valide = [
    for (final n in notifiche)
      if (n.confermabile) n,
  ];
  if (valide.isEmpty) {
    return;
  }
  await _esegui(context, (messenger) async {
    final indietro = await sessione.notifiche.conferma(valide);
    final n = valide.first;
    _avviso(
      messenger,
      valide.length > 1
          ? 'Confermate ${valide.length} scadenze'
          : n.scadenza!.pianificazione.portafoglioId == null
          ? 'Fatto: "${n.titolo}"'
          : 'Registrato: "${n.titolo}" '
                '${Importo.formatta(n.importo ?? 0, n.valuta)}',
      indietro: indietro,
    );
  });
}

/// Sposta la scadenza a un altro giorno (solo questa volta).
Future<void> riprogrammaNotifica(
  BuildContext context,
  Sessione sessione,
  Notifica n,
) async {
  final oggi = DateUtils.dateOnly(DateTime.now());
  final giorno = await scegliData(
    context,
    iniziale: n.data.isBefore(oggi) ? oggi : n.data,
    titolo: 'Nuovo giorno per "${n.titolo}"',
    primo: oggi.subtract(
      const Duration(days: NotificheServizio.giorniIndietro),
    ),
    ultimo: DateTime(oggi.year + 2, oggi.month, oggi.day),
  );
  if (giorno == null || !context.mounted) {
    return;
  }
  final testoGiorno = giornoNotifica(context, giorno);
  await _esegui(context, (messenger) async {
    final indietro = await sessione.notifiche.sposta(n, giorno);
    _avviso(
      messenger,
      '"${n.titolo}" spostata a $testoGiorno',
      indietro: indietro,
    );
  });
}

/// Annulla la scadenza (solo questa volta), con "Ripristina".
Future<void> annullaNotifica(
  BuildContext context,
  Sessione sessione,
  Notifica n,
) => _esegui(context, (messenger) async {
  final indietro = await sessione.notifiche.annulla(n);
  _avviso(
    messenger,
    '"${n.titolo}" annullata per questa volta',
    indietro: indietro,
    etichetta: 'Ripristina',
  );
});

/// Segna come lette; con più notifiche l'avviso permette di tornare indietro.
Future<void> segnaNotificheLette(
  BuildContext context,
  Sessione sessione,
  List<Notifica> notifiche,
) => _esegui(context, (messenger) async {
  final daSegnare = [
    for (final n in notifiche)
      if (!n.letta) n,
  ];
  if (daSegnare.isEmpty) {
    return;
  }
  final indietro = await sessione.notifiche.segnaLette(daSegnare);
  if (daSegnare.length > 1) {
    _avviso(
      messenger,
      '${daSegnare.length} notifiche segnate come lette',
      indietro: indietro,
    );
  }
});

// ----------------------------------------------------------------- riga

/// Una notifica con le sue azioni (icone con la descrizione al passaggio del
/// mouse). Con [selezionata] mostra la casella per la selezione multipla.
class RigaNotifica extends StatelessWidget {
  const RigaNotifica({
    super.key,
    required this.sessione,
    required this.notifica,
    this.selezionata,
    this.onSeleziona,
  });

  final Sessione sessione;
  final Notifica notifica;
  final bool? selezionata;
  final ValueChanged<bool>? onSeleziona;

  List<Widget> _azioni(BuildContext context) {
    final n = notifica;
    IconButton azione(IconData icona, String descrizione, VoidCallback fai) =>
        IconButton(
          icon: Icon(icona),
          tooltip: descrizione,
          visualDensity: VisualDensity.compact,
          onPressed: fai,
        );
    final futura = n.data.isAfter(DateUtils.dateOnly(DateTime.now()));
    return [
      if (n.tipo == TipoNotifica.decisione)
        azione(
          Icons.rule,
          'Scegli: apri un altro prestito o paghi tutto',
          () => chiediDecisioneMaxi(context, sessione, n.maxi!),
        ),
      if (n.confermabile)
        azione(
          Icons.check_circle_outline,
          n.tipo == TipoNotifica.promemoria
              ? 'Fatto: segna come fatto'
              : futura
              ? 'Conferma adesso: registra il movimento oggi'
              : 'Conferma: registra il movimento',
          () => confermaNotifiche(context, sessione, [n]),
        ),
      if (n.modificabile) ...[
        azione(
          Icons.edit_calendar_outlined,
          'Riprogramma: scegli un altro giorno',
          () => riprogrammaNotifica(context, sessione, n),
        ),
        azione(
          Icons.event_busy_outlined,
          'Annulla: per questa volta non c\'è',
          () => annullaNotifica(context, sessione, n),
        ),
      ],
      if (!n.letta && !n.richiedeAzione && n.tipo != TipoNotifica.promemoria)
        azione(
          Icons.mark_email_read_outlined,
          'Segna come letta',
          () => segnaNotificheLette(context, sessione, [n]),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final n = notifica;
    final schema = Theme.of(context).colorScheme;
    final testo = Theme.of(context).textTheme;
    final evidenza = n.richiedeAzione
        ? schema.tertiary
        : n.tipo == TipoNotifica.registrata
        ? coloreEntrata(context)
        : schema.primary;
    final importo = n.importo;
    return Opacity(
      opacity: n.attiva ? 1 : 0.65,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 4, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selezionata != null)
              Checkbox(
                value: selezionata,
                onChanged: (v) => onSeleziona?.call(v ?? false),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: evidenza.withValues(alpha: 0.15),
                foregroundColor: evidenza,
                child: Icon(_icona(n.tipo), size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          n.titolo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: testo.bodyLarge?.copyWith(
                            fontWeight: n.letta
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (importo != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          Importo.formatta(
                            n.tipo == TipoNotifica.decisione || n.entrata
                                ? importo
                                : -importo,
                            n.valuta,
                            conSegno: n.entrata,
                          ),
                          style: TextStyle(
                            color: n.tipo == TipoNotifica.decisione
                                ? null
                                : coloreEffetto(
                                    context,
                                    n.entrata
                                        ? EffettoSaldo.entrata
                                        : EffettoSaldo.uscita,
                                  ),
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sottotitoloNotifica(context, n),
                    style: testo.bodySmall?.copyWith(
                      color: n.tipo == TipoNotifica.daConfermare
                          ? schema.tertiary
                          : schema.onSurfaceVariant,
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Wrap(children: _azioni(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
