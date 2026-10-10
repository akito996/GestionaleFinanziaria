import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/db/contabilita.dart';
import '../../core/db/costo_vita.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../comuni/icone.dart';
import '../comuni/in_arrivo.dart';
import '../comuni/navigazione.dart';
import '../costo_vita/costo_vita_pagina.dart';
import '../costo_vita/grafico_costo_vita.dart';
import '../movimenti/movimento_modulo.dart';
import '../movimenti/riga_movimento.dart';
import '../portafogli/portafoglio_modulo.dart';
import '../portafogli/portafoglio_pagina.dart';

/// Panoramica: totale, portafogli con saldo, ultimi movimenti e "+ Movimento".
/// Su Windows: Ctrl+N = nuovo movimento.
class HomePagina extends StatefulWidget {
  const HomePagina({super.key, required this.sessione, this.apriCostoVita});

  final Sessione sessione;

  /// Porta alla sezione Costo della vita (dalla scheda della Panoramica).
  final VoidCallback? apriCostoVita;

  @override
  State<HomePagina> createState() => _HomePaginaState();
}

class _HomePaginaState extends State<HomePagina> {
  late final Stream<List<PortafoglioConSaldo>> _portafogli;
  late final Stream<List<MovimentoDettaglio>> _movimenti;
  late final Stream<List<RiepilogoMese>> _costoVita;

  Sessione get _sessione => widget.sessione;

  @override
  void initState() {
    super.initState();
    _portafogli = _sessione.contabilita.osservaPortafogli();
    _movimenti = _sessione.contabilita.osservaMovimenti(limite: 30);
    final oggi = DateTime.now();
    _costoVita = _sessione.costoVita.osservaStorico(
      finoA: DateTime(oggi.year, oggi.month),
    );

    // Conferma visibile dell'apertura ("Archivio sbloccato", "Archivio creato", ...).
    final avviso = _sessione.avviso;
    _sessione.avviso = null;
    if (avviso != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const LucchettoAperto(colore: Colors.white),
                    const SizedBox(width: 12),
                    Text(avviso),
                  ],
                ),
                duration: const Duration(seconds: 2),
              ),
            );
        }
      });
    }
  }

  void _nuovoMovimento() => apriModuloMovimento(context, _sessione);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PortafoglioConSaldo>>(
      stream: _portafogli,
      builder: (context, snapshot) {
        final portafogli = snapshot.data;
        final vuoto = portafogli != null && portafogli.isEmpty;
        return CallbackShortcuts(
          bindings: {
            if (!vuoto)
              const SingleActivator(LogicalKeyboardKey.keyN, control: true):
                  _nuovoMovimento,
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('GestionaleFinanziaria'),
                actions: [PulsanteBlocca(sessione: _sessione)],
              ),
              floatingActionButton: portafogli == null || vuoto
                  ? null
                  : FloatingActionButton.extended(
                      onPressed: _nuovoMovimento,
                      tooltip: 'Nuovo movimento (Ctrl+N)',
                      icon: const Icon(Icons.add),
                      label: const Text('Movimento'),
                    ),
              body: portafogli == null
                  ? const Center(child: CircularProgressIndicator())
                  : vuoto
                  ? _PrimoPortafoglio(sessione: _sessione)
                  : _panoramica(context, portafogli),
            ),
          ),
        );
      },
    );
  }

  Widget _panoramica(
    BuildContext context,
    List<PortafoglioConSaldo> portafogli,
  ) {
    final totali = <String, int>{};
    for (final p in portafogli) {
      totali.update(
        p.portafoglio.valuta,
        (v) => v + p.saldo,
        ifAbsent: () => p.saldo,
      );
    }
    final testo = Theme.of(context).textTheme;

    final colonnaPortafogli = [
      SchedaInArrivo(sessione: _sessione),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Totale', style: testo.labelLarge),
              for (final MapEntry(key: valuta, value: totale) in totali.entries)
                Text(
                  Importo.formatta(totale, valuta),
                  style: testo.headlineMedium,
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      _Intestazione(
        titolo: 'Portafogli',
        azione: TextButton.icon(
          onPressed: () => apriModuloPortafoglio(context, _sessione),
          icon: const Icon(Icons.add),
          label: const Text('Nuovo'),
        ),
      ),
      for (final p in portafogli)
        Card(
          child: ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: Text(p.portafoglio.nome),
            subtitle: Text(p.tipo.nome),
            trailing: Text(
              Importo.formatta(p.saldo, p.portafoglio.valuta),
              style: testo.titleMedium?.copyWith(
                color: p.saldo < 0 ? Theme.of(context).colorScheme.error : null,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PortafoglioPagina(
                  sessione: _sessione,
                  portafoglioId: p.portafoglio.id,
                ),
              ),
            ),
          ),
        ),
    ];

    final schedaCostoVita = StreamBuilder<List<RiepilogoMese>>(
      stream: _costoVita,
      builder: (context, snapshot) {
        final storico = snapshot.data;
        final mese = storico?.last;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.apriCostoVita,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Costo della vita',
                          style: testo.labelLarge,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  if (storico == null)
                    const LinearProgressIndicator()
                  else if (storico.every((m) => m.voci.isEmpty))
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Configura le spese fisse e variabili per vedere quanto '
                        'ti costa vivere ogni mese.',
                      ),
                    )
                  else ...[
                    Text(
                      '${Importo.formatta(mese!.totalePrevisto, 'EUR')} al mese',
                      style: testo.headlineMedium,
                    ),
                    Text(
                      'Fisse ${Importo.formatta(mese.fisse, 'EUR')} · '
                      'variabili previste '
                      '${Importo.formatta(mese.variabiliPreviste, 'EUR')} · '
                      'spese finora ${Importo.formatta(mese.variabiliReali, 'EUR')}',
                      style: testo.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    GraficoCostoVita(
                      mesi: storico,
                      nomeMese: (m) => meseBreve(context, m),
                      altezza: 140,
                      compatto: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );

    final colonnaMovimenti = [
      schedaCostoVita,
      const SizedBox(height: 16),
      const _Intestazione(titolo: 'Ultimi movimenti'),
      StreamBuilder<List<MovimentoDettaglio>>(
        stream: _movimenti,
        builder: (context, snapshot) {
          final movimenti = snapshot.data ?? const [];
          if (snapshot.hasData && movimenti.isEmpty) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Ancora nessun movimento. Premi "+ Movimento" '
                  '(o Ctrl+N) per registrare una spesa, un\'entrata o un trasferimento.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return Card(
            child: Column(
              children: [
                for (final m in movimenti)
                  RigaMovimento(sessione: _sessione, dettaglio: m),
              ],
            ),
          );
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, vincoli) {
        const margine = EdgeInsets.fromLTRB(16, 16, 16, 96);
        if (vincoli.maxWidth >= 900) {
          return SingleChildScrollView(
            padding: margine,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: colonnaPortafogli,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: colonnaMovimenti,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView(
          padding: margine,
          children: [
            ...colonnaPortafogli,
            const SizedBox(height: 16),
            ...colonnaMovimenti,
          ],
        );
      },
    );
  }
}

class _Intestazione extends StatelessWidget {
  const _Intestazione({required this.titolo, this.azione});

  final String titolo;
  final Widget? azione;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(titolo, style: Theme.of(context).textTheme.titleMedium),
          ),
          ?azione,
        ],
      ),
    );
  }
}

/// Primo utilizzo: nessun portafoglio. Un tocco su un suggerimento apre il modulo
/// già compilato.
class _PrimoPortafoglio extends StatelessWidget {
  const _PrimoPortafoglio({required this.sessione});

  final Sessione sessione;

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                'Crea il tuo primo portafoglio',
                style: testo.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Un portafoglio è dove tieni i soldi: i contanti, un conto in banca, '
                'una carta. Scegline uno per iniziare:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final (nome, icona) in const [
                    ('Contanti', Icons.payments_outlined),
                    ('Conto corrente', Icons.account_balance_outlined),
                    ('Carta', Icons.credit_card),
                    ('Risparmi', Icons.savings_outlined),
                  ])
                    ActionChip(
                      avatar: Icon(icona),
                      label: Text(nome),
                      onPressed: () => apriModuloPortafoglio(
                        context,
                        sessione,
                        nomeSuggerito: nome,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => apriModuloPortafoglio(context, sessione),
                icon: const Icon(Icons.add),
                label: const Text('Altro portafoglio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
