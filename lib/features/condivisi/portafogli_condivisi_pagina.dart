import 'package:flutter/material.dart';

import '../../core/condivisi/drive_condiviso.dart';
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

  /// Preparato una volta sola (vedi SchedaPersone).
  late final Stream<List<VistaCondiviso>> _flusso = widget.sessione.condivisi
      .osserva();

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

  Future<void> _unisciti() async {
    final procedi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.group_add_outlined),
        title: const Text('Unisciti a un portafoglio condiviso'),
        content: const Text(
          'Nella finestra di Google apri «Condivisi con me», poi la cartella '
          '«wallecy_share_…» che ti hanno condiviso, e scegli TUTTI i file '
          'che ci sono dentro: il registro e un file per ogni persona, con '
          'il nome del suo account. Tocca ognuno, poi «Seleziona».',
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
      final esito = await widget.sessione.condivisi.unisciti();
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
