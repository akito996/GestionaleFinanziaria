import 'package:flutter/material.dart';

import '../../core/sessione.dart';
import '../../core/sync/sincronizzazione.dart';
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

/// Icona a forma di nuvola accanto alla campanella: com'è la sincronizzazione.
/// Un tocco apre la pagina.
class IconaSync extends StatelessWidget {
  const IconaSync({super.key, required this.sessione});

  final Sessione sessione;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StatoSync>(
      valueListenable: sessione.sync.stato,
      builder: (context, stato, _) {
        final (icona, testo) = _descrizione(context, stato);
        final schema = Theme.of(context).colorScheme;
        final attenzione =
            stato.fase == FaseSync.errore ||
            stato.fase == FaseSync.accessoRichiesto ||
            stato.fase == FaseSync.archivioDiverso;
        return IconButton(
          tooltip: testo,
          icon: Icon(icona, color: attenzione ? schema.error : null),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SincronizzazionePagina(sessione: sessione),
            ),
          ),
        );
      },
    );
  }
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
                      'all\'apertura e ogni 5 minuti.',
                    ),
                  ),
                ),
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
                : () => senzaBloccoAutomatico(
                    () => _sync.sincronizza(interattivo: true),
                  ),
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
