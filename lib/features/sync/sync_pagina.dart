import 'package:flutter/material.dart';

import '../../core/condivisi/portafogli_condivisi.dart';
import '../../core/sessione.dart';
import '../../core/sync/sincronizzazione.dart';
import '../comuni/avvisi.dart';
import '../comuni/blocco_automatico.dart';
import '../comuni/layout.dart';
import '../comuni/navigazione.dart';
import '../movimenti/riga_movimento.dart';
import 'archivio_remoto.dart';

/// "oggi alle 14:32", "ieri alle 9:05", "lun 12 ott alle 18:00".
String quandoSincronizzato(BuildContext context, DateTime quando) {
  final locale = quando.toLocal();
  final ora = MaterialLocalizations.of(context)
      .formatTimeOfDay(TimeOfDay.fromDateTime(locale));
  return '${dataLeggibile(context, locale).toLowerCase()} alle $ora';
}

/// Icona e testo dello stato (icona in alto, pagina).
(IconData, String) _descrizione(BuildContext context, StatoSync s) {
  final ultima = s.ultima == null
      ? ''
      : ': ultima ${quandoSincronizzato(context, s.ultima!)}';
  return switch (s.fase) {
    FaseSync.spenta => (Icons.cloud_off_outlined, 'Sincronizzazione spenta'),
    FaseSync.nonDisponibile => (
      Icons.cloud_off_outlined,
      'Sincronizzazione non disponibile in questa versione',
    ),
    FaseSync.inCorso => (
      Icons.cloud_sync_outlined,
      'Sincronizzazione in corso',
    ),
    FaseSync.aggiornata => (Icons.cloud_done_outlined, 'Sincronizzato$ultima'),
    FaseSync.accessoRichiesto => (
      Icons.key_outlined,
      'Serve di nuovo l\'accesso a Google',
    ),
    FaseSync.archivioDiverso => (
      Icons.warning_amber,
      'Su Google Drive c\'è un altro archivio',
    ),
    FaseSync.errore => (
      Icons.sync_problem_outlined,
      s.messaggio ?? 'Sincronizzazione non riuscita',
    ),
  };
}

/// Stato dei portafogli condivisi in una riga (`null` se va tutto bene o non
/// ce ne sono).
String? _problemaCondivisi(StatoCondivisi? c) => switch (c?.fase) {
  FaseCondivisi.accessoRichiesto =>
    'Portafogli condivisi: serve l\'accesso a Google, tocca ⟳',
  FaseCondivisi.errore => 'Portafogli condivisi: ${c?.messaggio}',
  _ => null,
};

bool _daSistemare(StatoSync s) =>
    s.fase == FaseSync.errore ||
    s.fase == FaseSync.accessoRichiesto ||
    s.fase == FaseSync.archivioDiverso;

/// La voce "Sincronizzazione" del menu ☰: la nuvola con lo stato.
(Widget, String) voceSincronizzazione(BuildContext context, Sessione sessione) {
  final stato = sessione.sync.stato.value;
  final (icona, testo) = _descrizione(context, stato);
  final condivisi = _problemaCondivisi(sessione.condivisiSeAperto?.stato.value);
  final attenzione = _daSistemare(stato) || condivisi != null;
  return (
    Icon(icona, color: attenzione ? Theme.of(context).colorScheme.error : null),
    condivisi == null ? testo : '$testo\n$condivisi',
  );
}

void apriSincronizzazione(BuildContext context, Sessione sessione) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SincronizzazionePagina(sessione: sessione),
      ),
    );

/// Sincronizza subito l'archivio (Google Drive) e i portafogli condivisi:
/// dal pulsante ⟳, trascinando verso il basso o con F5. Avvisa solo se c'è
/// qualcosa da sapere; con [conferma] anche quando è andato tutto bene.
Future<void> sincronizzaOra(
  BuildContext context,
  Sessione sessione, {
  bool conferma = false,
}) async {
  final condivisi = sessione.condivisiSeAperto;
  if (condivisi == null || sessione.fase != FaseSessione.sbloccata) {
    return;
  }
  final sync = sessione.sync;
  final messaggi = ScaffoldMessenger.of(context);
  final fase = sync.stato.value.fase;
  final archivio = fase != FaseSync.spenta && fase != FaseSync.nonDisponibile;
  final bool conCondivisi;
  try {
    conCondivisi = await condivisi.presenti();
  } on Object {
    return; // archivio bloccato nel frattempo
  }
  void mostra(String testo) => messaggi
    ..clearSnackBars()
    ..showSnackBar(
      avviso(
        content: Text(testo),
        action: context.mounted
            ? SnackBarAction(
                label: 'Dettagli',
                onPressed: () => apriSincronizzazione(context, sessione),
              )
            : null,
      ),
    );
  if (!archivio && !conCondivisi) {
    mostra(
      fase == FaseSync.spenta
          ? 'La sincronizzazione con Google Drive è spenta.'
          : 'Sincronizzazione non disponibile in questa versione.',
    );
    return;
  }
  await senzaBloccoAutomatico(
    () => Future.wait([
      if (archivio) sync.sincronizza(interattivo: true),
      if (conCondivisi) condivisi.sincronizza(interattivo: true),
    ]),
  );
  if (sessione.fase != FaseSessione.sbloccata || !context.mounted) {
    return;
  }
  final problemi = [
    if (archivio && sync.stato.value.fase != FaseSync.aggiornata)
      _descrizione(context, sync.stato.value).$2,
    if (conCondivisi) ?_problemaCondivisi(condivisi.stato.value),
  ];
  if (problemi.isNotEmpty) {
    mostra(problemi.join('\n'));
  } else if (conferma) {
    messaggi
      ..clearSnackBars()
      ..showSnackBar(avviso(content: const Text('Tutto aggiornato')));
  }
}

/// In alto a destra: ⟳ sincronizza subito (archivio e portafogli condivisi).
/// Gira mentre lavora, diventa rosso se c'è qualcosa da sistemare; se la
/// sincronizzazione è spenta apre la pagina per accenderla.
class PulsanteSincronizza extends StatefulWidget {
  const PulsanteSincronizza({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<PulsanteSincronizza> createState() => _PulsanteSincronizzaState();
}

class _PulsanteSincronizzaState extends State<PulsanteSincronizza> {
  // Presi una volta: dopo il blocco la sessione non li ha più.
  late final _sync = widget.sessione.sync;
  late final _condivisi = widget.sessione.condivisiSeAperto;
  bool _inCorso = false;

  Future<void> _tocca(bool soloPagina) async {
    if (soloPagina) {
      apriSincronizzazione(context, widget.sessione);
      return;
    }
    setState(() => _inCorso = true);
    try {
      await sincronizzaOra(context, widget.sessione, conferma: true);
    } finally {
      if (mounted) {
        setState(() => _inCorso = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_sync.stato, ?_condivisi?.stato]),
      builder: (context, _) {
        final stato = _sync.stato.value;
        final condivisi = _condivisi?.stato.value;
        final conCondivisi =
            condivisi != null && condivisi.fase != FaseCondivisi.nessuno;
        final spenta =
            (stato.fase == FaseSync.spenta ||
                stato.fase == FaseSync.nonDisponibile) &&
            !conCondivisi;
        final problema = _problemaCondivisi(condivisi);
        final attenzione = _daSistemare(stato) || problema != null;
        final inCorso = _inCorso || stato.fase == FaseSync.inCorso;
        final schema = Theme.of(context).colorScheme;
        final String testo;
        if (inCorso) {
          testo = 'Sincronizzazione in corso';
        } else if (spenta || _daSistemare(stato)) {
          testo = _descrizione(context, stato).$2;
        } else {
          testo = problema ?? 'Sincronizza ora';
        }
        return IconButton(
          tooltip: testo,
          onPressed: inCorso
              ? null
              : () => _tocca(spenta || stato.fase == FaseSync.archivioDiverso),
          icon: inCorso
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  attenzione
                      ? Icons.sync_problem
                      : spenta
                      ? Icons.sync_disabled
                      : Icons.sync,
                  color: attenzione ? schema.error : null,
                ),
        );
      },
    );
  }
}

/// Trascina verso il basso per sincronizzare subito (telefono e tablet).
/// Anche le pagine corte si possono trascinare.
class AggiornaTrascinando extends StatelessWidget {
  const AggiornaTrascinando({
    super.key,
    required this.sessione,
    required this.child,
    this.sottoBarra = false,
  });

  final Sessione sessione;
  final Widget child;

  /// Le pagine dentro hanno la loro barra in alto: il cerchio compare sotto.
  final bool sottoBarra;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      edgeOffset: sottoBarra
          ? MediaQuery.paddingOf(context).top + kToolbarHeight
          : 0,
      notificationPredicate: (n) =>
          n.depth == 0 && n.metrics.axis == Axis.vertical,
      onRefresh: () => sincronizzaOra(context, sessione),
      child: ScrollConfiguration(
        behavior: const _SempreTrascinabile(),
        child: child,
      ),
    );
  }
}

/// Come quello dell'app, ma anche una pagina corta si può trascinare (per
/// "trascina per aggiornare"). Sempre lo stesso: le pagine non ricreano lo
/// scorrimento a ogni aggiornamento.
class _SempreTrascinabile extends MaterialScrollBehavior {
  const _SempreTrascinabile();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      AlwaysScrollableScrollPhysics(parent: super.getScrollPhysics(context));
}

/// Accendere, spegnere e controllare la sincronizzazione con Google Drive.
class SincronizzazionePagina extends StatelessWidget {
  const SincronizzazionePagina({super.key, required this.sessione});

  final Sessione sessione;

  Sincronizzazione get _sync => sessione.sync;

  Future<void> _spegni(BuildContext context) async {
    final si = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Spegnere la sincronizzazione?'),
        content: const Text(
          'Questo dispositivo smette di inviare e ricevere le modifiche. I dati '
          'restano qui e su Google Drive: puoi riaccenderla quando vuoi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Spegni'),
          ),
        ],
      ),
    );
    if (si == true) {
      await _sync.spegni();
    }
  }

  Future<void> _sostituisciRemoto(BuildContext context, String idRemoto) async {
    final si = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber),
        title: const Text('Mettere questo archivio su Drive?'),
        content: Text(
          'L\'archivio $idRemoto su Google Drive viene messo da parte (non '
          'cancellato) e al suo posto va quello di questo dispositivo '
          '(${sessione.idArchivio}). Gli altri dispositivi dovranno scaricare '
          'questo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Metti questo su Drive'),
          ),
        ],
      ),
    );
    if (si == true) {
      await senzaBloccoAutomatico(_sync.sostituisciRemoto);
    }
  }

  Future<void> _usaRemoto(BuildContext context, String idRemoto) async {
    final remoto = await senzaBloccoAutomatico(sessione.spazioRemoto);
    if (remoto == null || !context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Usa l\'archivio di Drive')),
          body: LayoutBuilder(
            builder: (context, vincoli) => ListView(
              padding: marginiPagina(vincoli),
              children: [
                ModuloArchivioRemoto(
                  sessione: sessione,
                  remoto: remoto,
                  idRemoto: idRemoto,
                  avvertenza:
                      'I dati di questo dispositivo (${sessione.idArchivio}) '
                      'vengono messi da parte, non cancellati, e sostituiti '
                      'da quelli di Google Drive.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronizzazione'),
        actions: [PulsanteBlocca(sessione: sessione, sincronizzazione: false)],
      ),
      body: ValueListenableBuilder<StatoSync>(
        valueListenable: _sync.stato,
        builder: (context, stato, _) {
          final (icona, testo) = _descrizione(context, stato);
          final schema = Theme.of(context).colorScheme;
          final inCorso = stato.fase == FaseSync.inCorso;
          return LayoutBuilder(
            builder: (context, vincoli) => ListView(
              padding: marginiPagina(vincoli),
              children: [
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.devices_outlined),
                    title: Text('PC, telefono e tablet sempre allineati'),
                    subtitle: Text(
                      'Le modifiche viaggiano cifrate nella cartella nascosta '
                      'dell\'app su Google Drive: Google non può leggerle e '
                      'l\'app non vede gli altri tuoi file. Sull\'altro '
                      'dispositivo scegli "Ho già un archivio" e usa la stessa '
                      'password.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: inCorso
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(icona),
                    title: Text(testo),
                    subtitle: Text(
                      'Archivio ${sessione.idArchivio}. Si sincronizza '
                      'all\'apertura e ogni 5 minuti; per farlo subito tocca '
                      '⟳ o trascina la pagina verso il basso.',
                    ),
                  ),
                ),
                _SchedaCondivisi(sessione: sessione),
                const SizedBox(height: 16),
                ..._azioni(context, stato, schema),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _azioni(
    BuildContext context,
    StatoSync stato,
    ColorScheme schema,
  ) {
    switch (stato.fase) {
      case FaseSync.nonDisponibile:
        return const [
          Text(
            'Questa versione dell\'app non ha la configurazione di Google: '
            'usa quella scaricata dalla build ufficiale.',
          ),
        ];
      case FaseSync.spenta:
        return [
          FilledButton.icon(
            onPressed: () => senzaBloccoAutomatico(_sync.accendi),
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Accendi con Google Drive'),
          ),
        ];
      case FaseSync.archivioDiverso:
        final idRemoto = stato.idRemoto ?? '';
        return [
          Card(
            color: schema.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Su Google Drive c\'è già l\'archivio $idRemoto, creato su un '
                'altro dispositivo. Questo è ${sessione.idArchivio}: non si '
                'possono mescolare. Scegli quale tenere.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _usaRemoto(context, idRemoto),
            icon: const Icon(Icons.cloud_download_outlined),
            label: const Text('Usa quello di Drive su questo dispositivo'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _sostituisciRemoto(context, idRemoto),
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Metti questo su Drive al suo posto'),
          ),
        ];
      case FaseSync.accessoRichiesto:
        return [
          FilledButton.icon(
            onPressed: () => senzaBloccoAutomatico(
              () => _sync.sincronizza(interattivo: true),
            ),
            icon: const Icon(Icons.login),
            label: const Text('Riaccedi a Google'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Finché l\'app è in prova presso Google, l\'accesso scade ogni 7 '
            'giorni.',
          ),
        ];
      case FaseSync.inCorso || FaseSync.aggiornata || FaseSync.errore:
        return [
          FilledButton.icon(
            onPressed: stato.fase == FaseSync.inCorso
                ? null
                : () => sincronizzaOra(context, sessione),
            icon: const Icon(Icons.sync),
            label: const Text('Sincronizza ora'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _spegni(context),
            child: const Text('Spegni su questo dispositivo'),
          ),
        ];
    }
  }
}

/// Nella pagina: com'è andato l'ultimo giro dei portafogli condivisi.
class _SchedaCondivisi extends StatelessWidget {
  const _SchedaCondivisi({required this.sessione});

  final Sessione sessione;

  @override
  Widget build(BuildContext context) {
    final condivisi = sessione.condivisiSeAperto;
    if (condivisi == null) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<StatoCondivisi>(
      valueListenable: condivisi.stato,
      builder: (context, stato, _) {
        if (stato.fase == FaseCondivisi.nessuno) {
          return const SizedBox.shrink();
        }
        final problema = _problemaCondivisi(stato);
        final ultima = stato.ultima;
        return Card(
          child: ListTile(
            leading: Icon(
              problema == null ? Icons.group_outlined : Icons.sync_problem,
              color: problema == null
                  ? null
                  : Theme.of(context).colorScheme.error,
            ),
            title: Text(
              problema ??
                  (ultima == null
                      ? 'Portafogli condivisi'
                      : 'Portafogli condivisi: aggiornati '
                            '${quandoSincronizzato(context, ultima)}'),
            ),
            subtitle: const Text(
              'Le tue modifiche partono dopo pochi secondi; quelle degli '
              'altri si controllano ogni minuto con l\'app aperta.',
            ),
          ),
        );
      },
    );
  }
}
