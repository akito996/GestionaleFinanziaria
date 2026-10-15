import 'package:flutter/material.dart';

import '../../core/sessione.dart';
import '../../core/sicurezza/sicurezza_dispositivo.dart';
import '../comuni/firma_versione.dart';
import '../comuni/layout.dart';
import '../comuni/navigazione.dart';
import '../movimenti/riga_movimento.dart';
import '../sblocco/sblocco_rapido.dart';
import '../sync/sync_pagina.dart';

/// "Subito", "Dopo 1 minuto", "Dopo 1 ora", "Mai".
String testoBloccoAutomatico(Duration? durata) => switch (durata) {
  null => 'Mai',
  Duration.zero => 'Subito',
  final d when d.inMinutes < 60 =>
    'Dopo ${d.inMinutes} ${d.inMinutes == 1 ? 'minuto' : 'minuti'}',
  final d => 'Dopo ${d.inHours} ${d.inHours == 1 ? 'ora' : 'ore'}',
};

/// Impostazioni di questo dispositivo: sicurezza (sblocco rapido, blocco
/// automatico), sincronizzazione e informazioni sull'app.
class ImpostazioniPagina extends StatefulWidget {
  const ImpostazioniPagina({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<ImpostazioniPagina> createState() => _ImpostazioniPaginaState();
}

class _ImpostazioniPaginaState extends State<ImpostazioniPagina> {
  bool _occupato = false;

  SicurezzaDispositivo get _sicurezza => widget.sessione.sicurezza;

  @override
  void initState() {
    super.initState();
    // Nel frattempo può essere stata aggiunta un'impronta o un PIN.
    _sicurezza.aggiornaDisponibilita().ignore();
  }

  Future<void> _cambiaRapido(bool attiva) async {
    setState(() => _occupato = true);
    try {
      if (attiva) {
        await attivaSbloccoRapido(context, widget.sessione);
      } else {
        await _sicurezza.disattivaRapido();
      }
    } finally {
      if (mounted) {
        setState(() => _occupato = false);
      }
    }
  }

  Future<void> _scegliBlocco() async {
    final attuale = _sicurezza.bloccoAutomatico;
    final scelta = await showDialog<({Duration? durata})>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Blocco automatico'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Quando l\'app resta in secondo piano (o la finestra ridotta a '
              'icona), l\'archivio si blocca:',
            ),
          ),
          for (final durata in SicurezzaDispositivo.scelteBlocco)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Icon(
                durata == attuale
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(testoBloccoAutomatico(durata)),
              onTap: () => Navigator.of(context).pop((durata: durata)),
            ),
        ],
      ),
    );
    if (scelta != null) {
      await _sicurezza.impostaBloccoAutomatico(scelta.durata);
    }
  }

  String _statoRapido() {
    final manca = mancaPerSbloccoRapido(_sicurezza);
    if (_sicurezza.rapidoAttivo) {
      final prossima = _sicurezza.prossimaPassword;
      if (_sicurezza.passwordDaChiedere || prossima == null) {
        return 'Attivo: al prossimo sblocco serve la password.';
      }
      return 'Attivo. La password ti verrà chiesta di nuovo da '
          '${dataLeggibile(context, prossima.toLocal()).toLowerCase()}.';
    }
    return manca ?? 'Apri l\'archivio senza scrivere la password.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        actions: [PulsanteBlocca(sessione: widget.sessione)],
      ),
      body: ListenableBuilder(
        listenable: _sicurezza,
        builder: (context, _) {
          final pronta = mancaPerSbloccoRapido(_sicurezza) == null;
          return LayoutBuilder(
            builder: (context, vincoli) => ListView(
              padding: marginiPagina(vincoli),
              children: [
                Text(
                  'Sicurezza di questo dispositivo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: Icon(iconaSbloccoRapido),
                        title: Text(
                          'Sblocco con ${nomeSbloccoRapido(_sicurezza)}',
                        ),
                        subtitle: Text(_statoRapido()),
                        value: _sicurezza.rapidoAttivo,
                        onChanged:
                            _occupato || (!pronta && !_sicurezza.rapidoAttivo)
                            ? null
                            : _cambiaRapido,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_clock_outlined),
                        title: const Text('Blocco automatico'),
                        subtitle: Text(
                          'In secondo piano: '
                          '${testoBloccoAutomatico(_sicurezza.bloccoAutomatico).toLowerCase()}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _scegliBlocco,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'La password principale resta sempre valida e la Secret Key '
                  'serve se la dimentichi. Queste scelte valgono solo per '
                  'questo dispositivo.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                Text('App', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.cloud_outlined),
                        title: const Text('Sincronizzazione'),
                        subtitle: const Text(
                          'PC, telefono e tablet allineati con Google Drive',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SincronizzazionePagina(
                              sessione: widget.sessione,
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Informazioni'),
                        subtitle: const Text(
                          'Versione, licenza e codice sorgente',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => apriInformazioni(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
