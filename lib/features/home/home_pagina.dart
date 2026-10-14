import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/db/contabilita.dart';
import '../../core/db/costo_vita.dart';
import '../../core/db/statistiche.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../comuni/icone.dart';
import '../comuni/layout.dart';
import '../comuni/navigazione.dart';
import '../costo_vita/costo_vita_pagina.dart';
import '../export/export_dialogo.dart';
import '../costo_vita/grafico_costo_vita.dart';
import '../grafici/grafici.dart';
import '../grafici/grafici_avanzati.dart';
import '../movimenti/movimento_modulo.dart';
import '../movimenti/riga_movimento.dart';
import '../portafogli/portafoglio_modulo.dart';
import '../portafogli/elenco_portafogli.dart';
import 'entrate_previste.dart';
import 'entrate_uscite.dart';
import 'schede_panoramica.dart';

/// Panoramica: totale e portafogli (sempre), poi le schede scelte dall'utente
/// nell'ordine che preferisce, e "+ Movimento". Su Windows: Ctrl+N = nuovo
/// movimento.
class HomePagina extends StatefulWidget {
  const HomePagina({
    super.key,
    required this.sessione,
    this.apriMovimenti,
    this.apriCostoVita,
    this.apriEntrate,
  });

  final Sessione sessione;

  /// Porta alla sezione Movimenti (tutti, con i filtri).
  final VoidCallback? apriMovimenti;

  /// Porta alla sezione Costo della vita (dalla scheda della Panoramica).
  final VoidCallback? apriCostoVita;

  /// Porta alla sezione Entrate previste.
  final VoidCallback? apriEntrate;

  @override
  State<HomePagina> createState() => _HomePaginaState();
}

class _HomePaginaState extends State<HomePagina> {
  late final Stream<List<PortafoglioConSaldo>> _portafogli;
  late final Stream<List<MovimentoDettaglio>> _movimenti;
  late final Stream<List<RiepilogoMese>> _costoVita;
  late final Stream<List<SpesaCategoria>> _spese;
  late final Stream<Patrimonio> _patrimonio;
  late final Stream<List<PassoCascata>> _cascata;
  ConfigurazionePanoramica _configurazione =
      ConfigurazionePanoramica.predefinita;

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
    _patrimonio = _sessione.statistiche.osservaPatrimonio(
      _sessione.carte,
      _sessione.prestiti,
    );
    _cascata = _sessione.statistiche.osservaCascataMese(
      DateTime(oggi.year, oggi.month),
    );
    _spese = _sessione.statistiche.osservaSpesePerCategoria(
      DateTime(oggi.year, oggi.month),
      DateTime(oggi.year, oggi.month + 1, 0),
    );

    _sessione.statistiche.preferenza(ConfigurazionePanoramica.chiave).then((v) {
      if (mounted) {
        setState(() => _configurazione = ConfigurazionePanoramica.leggi(v));
      }
    });

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
                    // Sul telefono il testo va a capo invece di uscire dal bordo.
                    Expanded(child: Text(avviso)),
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

  Future<void> _personalizza() async {
    final nuova = await personalizzaPanoramica(
      context,
      _sessione,
      _configurazione,
    );
    if (nuova != null && mounted) {
      setState(() => _configurazione = nuova);
    }
  }

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
                actions: [
                  if (portafogli != null && !vuoto)
                    IconButton(
                      tooltip: 'Personalizza la Panoramica',
                      icon: const Icon(Icons.dashboard_customize_outlined),
                      onPressed: _personalizza,
                    ),
                  IconButton(
                    tooltip: 'Esporta (PDF o Excel)',
                    icon: const IconaEsporta(),
                    onPressed: () => apriExport(context, _sessione),
                  ),
                  PulsanteBlocca(sessione: _sessione),
                ],
              ),
              floatingActionButton: portafogli == null || vuoto
                  ? null
                  : FloatingActionButton.extended(
                      heroTag: 'fab-panoramica',
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

    // Sempre visibili: totale e portafogli.
    final colonnaPortafogli = [
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
      ElencoPortafogli(sessione: _sessione, portafogli: portafogli),
    ];

    final schedaCostoVita = StreamBuilder<List<RiepilogoMese>>(
      stream: _costoVita,
      builder: (context, snapshot) {
        final storico = snapshot.data;
        final mese = storico?.last;
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
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
                  else if (storico.every((m) => m.vuoto))
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
                      'Fisse ${Importo.formatta(mese.fisse, 'EUR')}'
                      '${mese.ratePrestiti > 0 ? ' (di cui rate ${Importo.formatta(mese.ratePrestiti, 'EUR')})' : ''} · '
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

    final schedaSpese = StreamBuilder<List<SpesaCategoria>>(
      stream: _spese,
      builder: (context, snapshot) {
        final spese = snapshot.data ?? const [];
        if (spese.isEmpty) {
          return const SizedBox.shrink();
        }
        final voci = [
          for (final s in spese)
            VoceValore(s.categoria ?? 'Senza categoria', s.totale),
        ];
        final totale = voci.fold<int>(0, (t, v) => t + v.valore);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SchedaGrafico(
            sessione: _sessione,
            chiave: 'panoramica.spese_categoria',
            titolo:
                'Spese di ${meseLeggibile(context, DateTime.now()).toLowerCase()}',
            sottotitolo:
                'Per categoria · totale ${Importo.formatta(totale, 'EUR')}',
            tipi: const [
              TipoGrafico.barre,
              TipoGrafico.colonne,
              TipoGrafico.torta,
              TipoGrafico.ciambella,
              TipoGrafico.tabella,
            ],
            costruisci: (context, tipo) => switch (tipo) {
              TipoGrafico.ciambella => Ciambella(voci: voci, valuta: 'EUR'),
              TipoGrafico.torta => Ciambella(
                voci: voci,
                valuta: 'EUR',
                torta: true,
              ),
              TipoGrafico.colonne => Colonne(voci: voci, valuta: 'EUR'),
              TipoGrafico.tabella => TabellaDati(
                colonne: const ['Categoria', 'Speso'],
                righe: [
                  for (final v in voci)
                    [v.etichetta, Importo.formatta(v.valore, 'EUR')],
                ],
              ),
              _ => BarreOrizzontali(voci: voci, valuta: 'EUR'),
            },
          ),
        );
      },
    );

    final schedaPatrimonio = StreamBuilder<Patrimonio>(
      stream: _patrimonio,
      builder: (context, snapshot) {
        final p = snapshot.data;
        if (p == null || (p.attivita.isEmpty && p.passivita.isEmpty)) {
          return const SizedBox.shrink();
        }
        final voci = [
          for (final v in p.attivita) VoceValore(v.nome, v.importo),
          for (final v in p.passivita)
            VoceValore('${v.nome} (debito)', v.importo),
        ];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SchedaGrafico(
            sessione: _sessione,
            chiave: 'panoramica.patrimonio',
            titolo: 'Patrimonio',
            sottotitolo: 'Cosa possiedi e cosa devi, oggi',
            tipi: const [
              TipoGrafico.statoPatrimoniale,
              TipoGrafico.colonne,
              TipoGrafico.tabella,
            ],
            costruisci: (context, tipo) => switch (tipo) {
              TipoGrafico.colonne => Colonne(voci: voci, valuta: 'EUR'),
              TipoGrafico.tabella => TabellaDati(
                colonne: const ['Voce', 'Importo'],
                righe: [
                  for (final v in p.attivita)
                    [v.nome, Importo.formatta(v.importo, 'EUR')],
                  for (final v in p.passivita)
                    ['${v.nome} (debito)', Importo.formatta(-v.importo, 'EUR')],
                  ['Patrimonio netto', Importo.formatta(p.netto, 'EUR')],
                ],
              ),
              _ => StatoPatrimonialeGrafico(patrimonio: p, valuta: 'EUR'),
            },
          ),
        );
      },
    );

    final schedaCascata = StreamBuilder<List<PassoCascata>>(
      stream: _cascata,
      builder: (context, snapshot) {
        final passi = snapshot.data;
        if (passi == null || passi.where((p) => !p.totale).isEmpty) {
          return const SizedBox.shrink();
        }
        final variazioni = passi.where((p) => !p.totale).toList();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SchedaGrafico(
            sessione: _sessione,
            chiave: 'panoramica.flusso',
            titolo: 'Flusso del mese',
            sottotitolo: 'Da inizio a fine mese: entrate e spese per categoria',
            tipi: const [
              TipoGrafico.cascata,
              TipoGrafico.colonne,
              TipoGrafico.tabella,
            ],
            costruisci: (context, tipo) => switch (tipo) {
              TipoGrafico.colonne => Colonne(
                voci: [
                  for (final p in variazioni)
                    VoceValore(p.etichetta, p.valore.abs()),
                ],
                valuta: 'EUR',
              ),
              TipoGrafico.tabella => TabellaDati(
                colonne: const ['Voce', 'Importo'],
                righe: [
                  for (final p in passi)
                    [
                      p.etichetta,
                      Importo.formatta(p.valore, 'EUR', conSegno: !p.totale),
                    ],
                ],
              ),
              _ => Cascata(passi: passi, valuta: 'EUR'),
            },
          ),
        );
      },
    );

    final schedaMovimenti = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Intestazione(
          titolo: 'Ultimi movimenti',
          azione: widget.apriMovimenti == null
              ? null
              : TextButton.icon(
                  onPressed: widget.apriMovimenti,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Tutti i movimenti'),
                ),
        ),
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
        const SizedBox(height: 16),
      ],
    );

    // Le schede scelte, nell'ordine scelto (Personalizza la Panoramica).
    final colonnaMovimenti = [
      for (final scheda in _configurazione.visibili)
        KeyedSubtree(
          key: ValueKey(scheda),
          child: switch (scheda) {
            SchedaPanoramica.costoVita => schedaCostoVita,
            SchedaPanoramica.entratePreviste => SchedaEntratePreviste(
              sessione: _sessione,
              onApri: widget.apriEntrate,
            ),
            SchedaPanoramica.entrateUscite => SchedaEntrateUscite(
              sessione: _sessione,
            ),
            SchedaPanoramica.spese => schedaSpese,
            SchedaPanoramica.flusso => schedaCascata,
            SchedaPanoramica.patrimonio => schedaPatrimonio,
            SchedaPanoramica.movimenti => schedaMovimenti,
          },
        ),
      Align(
        child: TextButton.icon(
          onPressed: _personalizza,
          icon: const Icon(Icons.dashboard_customize_outlined),
          label: const Text('Personalizza la Panoramica'),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, vincoli) {
        const margine = EdgeInsets.fromLTRB(16, 16, 16, 96);
        if (vincoli.maxWidth >= Larghezze.ampia) {
          return SingleChildScrollView(
            padding: margine,
            child: ContenutoCentrato(
              larghezzaMassima: Larghezze.dueColonne,
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
            ),
          );
        }
        return ListView(
          padding: marginiPagina(vincoli),
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
