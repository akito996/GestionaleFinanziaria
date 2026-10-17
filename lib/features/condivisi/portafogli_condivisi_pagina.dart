import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/condivisi/drive_condiviso.dart';
import '../../core/condivisi/invito.dart';
import '../../core/condivisi/portafogli_condivisi.dart';
import '../../core/db/tabelle.dart';
import '../../core/sessione.dart';
import '../comuni/avvisi.dart';
import '../comuni/blocco_automatico.dart';
import '../comuni/errori.dart';
import '../comuni/layout.dart';
import '../portafogli/portafoglio_pagina.dart';

/// Impostazioni › Portafogli condivisi (ADR-019): quelli di cui fai parte e
/// "Unisciti" per entrare in un portafoglio a cui sei stato invitato.
class PortafogliCondivisiPagina extends StatefulWidget {
  const PortafogliCondivisiPagina({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<PortafogliCondivisiPagina> createState() =>
      _PortafogliCondivisiPaginaState();
}

class _PortafogliCondivisiPaginaState extends State<PortafogliCondivisiPagina> {
  bool _occupato = false;

  /// Preparati una volta sola (vedi SchedaPersone).
  late final Stream<List<VistaCondiviso>> _flusso = widget.sessione.condivisi
      .osserva();
  late final Stream<List<InvitoCondiviso>> _inviti = widget.sessione.condivisi
      .osservaInviti();

  Future<void> _lavoro(Future<void> Function() lavoro) async {
    setState(() => _occupato = true);
    try {
      // La finestra di Google porta l'app in secondo piano.
      await senzaBloccoAutomatico(lavoro);
    } on ErroreDriveCondiviso catch (e) {
      _avvisa('Google Drive ha risposto ${e.stato}. Riprova tra poco.');
    } on CondivisoNonValido catch (e) {
      _avvisa('Portafoglio condiviso non valido: ${e.motivo}.');
    } catch (e, stack) {
      if (mounted) {
        await mostraErroreImprevisto(context, e, stack);
      }
    } finally {
      if (mounted) {
        setState(() => _occupato = false);
      }
    }
  }

  void _avvisa(String testo) {
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(avviso(content: Text(testo)));
    }
  }

  Future<void> _unisciti({InvitoCondiviso? invito}) async {
    final procedi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.group_add_outlined),
        title: Text(
          invito == null
              ? 'Unisciti a un portafoglio condiviso'
              : 'Accetta l\'invito a «${invito.portafoglio}»',
        ),
        content: const Text(
          'Nella finestra di Google scegli i file del portafoglio. Se li '
          'vedi già (il registro e il tuo file), sceglili tutti. Altrimenti '
          'apri «Condivisi con me», poi la cartella «wallecy_share_…», e '
          'scegli TUTTI i file che ci sono dentro: il registro e un file per '
          'ogni persona, con il nome del suo account. Tocca ognuno, poi '
          '«Seleziona».',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apri la finestra di Google'),
          ),
        ],
      ),
    );
    if (procedi != true || !mounted) {
      return;
    }
    await _lavoro(() async {
      final esito = await widget.sessione.condivisi.unisciti(invito: invito);
      _avvisa(switch (esito) {
        EsitoIngresso.entrato =>
          'Sei entrato: il portafoglio è nella '
              'Panoramica.',
        EsitoIngresso.inAttesa =>
          'Fatto. Il portafoglio compare appena l\'app del proprietario si '
              'sincronizza (di solito entro qualche minuto, con la sua app '
              'aperta).',
        EsitoIngresso.nessunRegistro =>
          'Tra i file scelti non c\'è «wallecy_registro.json»: riprova e '
              'scegli tutti i file della cartella.',
        EsitoIngresso.fileMancanti =>
          'Manca il tuo file: riprova e scegli TUTTI i file della cartella.',
        EsitoIngresso.nonInvitato =>
          'Questo account Google non è stato invitato in quel portafoglio. '
              'Controlla di usare l\'account giusto.',
        EsitoIngresso.annullato => 'Scelta annullata.',
        EsitoIngresso.scaduto =>
          'L\'invito è scaduto (nessuna risposta entro un\'ora): chiedi '
              'al proprietario di invitarti di nuovo.',
      });
    });
  }

  /// "Ho un link d'invito": per Windows o se il link non ha aperto l'app.
  Future<void> _incollaLink() async {
    final invito = await showDialog<InvitoCondiviso>(
      context: context,
      builder: (_) => const _ModuloLink(),
    );
    if (invito == null || !mounted) {
      return;
    }
    if (!await widget.sessione.condivisi.aggiungiInvito(invito)) {
      _avvisa('Fai già parte del portafoglio «${invito.portafoglio}».');
    }
  }

  Future<void> _aggiorna() => _lavoro(() async {
    await widget.sessione.condivisi.sincronizza(interattivo: true);
    _avvisa('Portafogli condivisi aggiornati.');
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Portafogli condivisi'),
      actions: [
        IconButton(
          tooltip: 'Ho un link d\'invito',
          icon: const Icon(Icons.add_link),
          onPressed: _occupato ? null : _incollaLink,
        ),
        IconButton(
          tooltip: 'Aggiorna ora',
          icon: const Icon(Icons.sync),
          onPressed: _occupato ? null : _aggiorna,
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      heroTag: 'fab-condivisi',
      onPressed: _occupato ? null : _unisciti,
      icon: const Icon(Icons.group_add_outlined),
      label: const Text('Unisciti'),
    ),
    body: StreamBuilder<List<VistaCondiviso>>(
      stream: _flusso,
      builder: (context, snapshot) {
        final elenco = snapshot.data ?? const [];
        return LayoutBuilder(
          builder: (context, vincoli) => ListView(
            padding: marginiPagina(vincoli),
            children: [
              if (_occupato) const LinearProgressIndicator(),
              const Text(
                'Un portafoglio condiviso lo vedono e lo usano più persone, '
                'ognuna con il proprio WalleCy e il proprio account Google. '
                'Per condividerne uno, aprilo e tocca l\'icona delle persone. '
                'Se ti hanno invitato, premi «Unisciti».',
              ),
              const SizedBox(height: 16),
              _NuoviInviti(
                inviti: _inviti,
                occupato: _occupato,
                onAccetta: (i) => _unisciti(invito: i),
                onIgnora: (i) =>
                    widget.sessione.condivisi.togliInvito(i.registroId),
              ),
              if (elenco.isEmpty && snapshot.hasData)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Ancora nessun portafoglio condiviso.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final v in elenco)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.group_outlined),
                    title: Text(
                      v.nome.isEmpty ? 'Portafoglio in arrivo' : v.nome,
                    ),
                    subtitle: Text(
                      [
                        v.info.ruolo == RuoloMembro.proprietario
                            ? 'Sei il proprietario'
                            : 'Sei un membro',
                        '${v.membri.length} persone',
                        if (v.info.chiave.isEmpty)
                          'in attesa della chiave dal proprietario',
                      ].join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: v.nome.isEmpty
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PortafoglioPagina(
                                sessione: widget.sessione,
                                portafoglioId: v.info.portafoglioId,
                              ),
                            ),
                          ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

/// "Nuovi inviti": arrivati con un link e non ancora accettati.
class _NuoviInviti extends StatelessWidget {
  const _NuoviInviti({
    required this.inviti,
    required this.occupato,
    required this.onAccetta,
    required this.onIgnora,
  });

  final Stream<List<InvitoCondiviso>> inviti;
  final bool occupato;
  final void Function(InvitoCondiviso invito) onAccetta;
  final void Function(InvitoCondiviso invito) onIgnora;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<InvitoCondiviso>>(
    stream: inviti,
    builder: (context, snapshot) {
      final elenco = snapshot.data ?? const [];
      if (elenco.isEmpty) {
        return const SizedBox.shrink();
      }
      final schema = Theme.of(context).colorScheme;
      final ora = DateTime.now();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nuovi inviti', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final i in elenco)
            Card(
              color: schema.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '«${i.portafoglio.isEmpty ? 'Portafoglio' : i.portafoglio}»',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      [
                        if (i.da.isNotEmpty) 'Da ${i.da}',
                        if (i.scadutoAlle(ora))
                          'invito scaduto: chiedi di invitarti di nuovo'
                        else if (i.scadenza != null)
                          'accetta entro le '
                              '${TimeOfDay.fromDateTime(i.scadenza!.toLocal()).format(context)}',
                      ].join(' · '),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: occupato ? null : () => onIgnora(i),
                          child: const Text('Ignora'),
                        ),
                        FilledButton(
                          onPressed: occupato ? null : () => onAccetta(i),
                          child: const Text('Accetta'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      );
    },
  );
}

/// "Ho un link d'invito": il campo appartiene alla finestra e si chiude con
/// lei (anche durante l'animazione di chiusura).
class _ModuloLink extends StatefulWidget {
  const _ModuloLink();

  @override
  State<_ModuloLink> createState() => _ModuloLinkState();
}

class _ModuloLinkState extends State<_ModuloLink> {
  final _campo = TextEditingController();
  String? _errore;

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  void _aggiungi() {
    final invito = InvitoCondiviso.daLink(_campo.text);
    if (invito == null) {
      setState(() => _errore = 'Non è un link d\'invito di WalleCy.');
    } else {
      Navigator.of(context).pop(invito);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const Icon(Icons.add_link),
    title: const Text('Ho un link d\'invito'),
    content: SizedBox(
      width: 420,
      child: TextField(
        controller: _campo,
        autofocus: true,
        maxLines: 3,
        minLines: 1,
        decoration: InputDecoration(
          labelText: 'Incolla il link dell\'email o del messaggio',
          errorText: _errore,
          suffixIcon: IconButton(
            tooltip: 'Incolla',
            icon: const Icon(Icons.content_paste),
            onPressed: () async {
              final dati = await Clipboard.getData('text/plain');
              _campo.text = dati?.text ?? '';
            },
          ),
        ),
        onSubmitted: (_) => _aggiungi(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Annulla'),
      ),
      FilledButton(onPressed: _aggiungi, child: const Text('Aggiungi')),
    ],
  );
}
