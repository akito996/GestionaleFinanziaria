import 'package:flutter/material.dart';

import '../../core/db/costo_vita.dart';
import '../../core/db/pianificatore.dart';
import '../../core/db/tabelle.dart';
import '../../core/importo.dart';
import '../../core/ricorrenza.dart';
import '../../core/sessione.dart';
import '../comuni/layout.dart';
import '../comuni/navigazione.dart';
import '../grafici/grafici.dart';
import '../grafici/grafici_avanzati.dart';
import '../movimenti/riga_movimento.dart';
import '../prestiti/prestiti_pagina.dart';
import 'grafico_costo_vita.dart';
import 'testi_voci.dart';
import 'voce_modulo.dart';

/// Abbreviazione del mese per l'asse del grafico ("ott").
String meseBreve(BuildContext context, DateTime mese) {
  const nomi = [
    'gen',
    'feb',
    'mar',
    'apr',
    'mag',
    'giu',
    'lug',
    'ago',
    'set',
    'ott',
    'nov',
    'dic',
  ];
  return nomi[mese.month - 1];
}

/// Costo della vita: quanto costa vivere ogni mese, tra spese fisse e
/// variabili. Con [natura] = [NaturaVoce.entrata] è la sezione gemella
/// "Entrate previste" (stipendio, pensione...).
class CostoVitaPagina extends StatefulWidget {
  const CostoVitaPagina({
    super.key,
    required this.sessione,
    this.natura = NaturaVoce.spesa,
  });

  final Sessione sessione;
  final String natura;

  @override
  State<CostoVitaPagina> createState() => _CostoVitaPaginaState();
}

class _CostoVitaPaginaState extends State<CostoVitaPagina> {
  late DateTime _mese;

  TestiVoci get _t => TestiVoci.per(widget.natura);

  @override
  void initState() {
    super.initState();
    final oggi = DateTime.now();
    _mese = DateTime(oggi.year, oggi.month);
  }

  void _spostaMese(int delta) =>
      setState(() => _mese = DateTime(_mese.year, _mese.month + delta));

  Future<void> _suggerita(String tipo, String nome, String categoria) async {
    final categorie = await widget.sessione.contabilita
        .osservaCategorie()
        .first;
    final id = categorie.where((c) => c.nome == categoria).firstOrNull?.id;
    if (mounted) {
      await apriNuovaVoce(
        context,
        widget.sessione,
        tipo: tipo,
        natura: widget.natura,
        nomeSuggerito: nome,
        categoriaSuggerita: id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cv = widget.sessione.costoVita;
    return Scaffold(
      appBar: AppBar(
        title: Text(_t.sezione),
        actions: [PulsanteBlocca(sessione: widget.sessione)],
      ),
      body: StreamBuilder<List<RiepilogoMese>>(
        // La chiave fa ripartire il flusso quando cambi mese.
        key: ValueKey(_mese),
        stream: cv.osservaStorico(finoA: _mese, natura: widget.natura),
        builder: (context, snapshot) {
          final storico = snapshot.data;
          if (storico == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final mese = storico.last;
          final senzaVoci = storico.every((m) => m.vuoto);
          return LayoutBuilder(
            builder: (context, vincoli) => ListView(
              padding: marginiPagina(vincoli, sopra: 8, sotto: 32),
              children: [
                _SceltaMese(
                  mese: _mese,
                  onPrecedente: () => _spostaMese(-1),
                  onSuccessivo: () => _spostaMese(1),
                ),
                if (senzaVoci)
                  _PrimaConfigurazione(
                    onSuggerita: _suggerita,
                    sessione: widget.sessione,
                    testi: _t,
                  )
                else ...[
                  _Riepilogo(mese: mese, testi: _t),
                  const SizedBox(height: 16),
                  SchedaGrafico(
                    sessione: widget.sessione,
                    chiave: _t.entrate
                        ? 'entrate.storico'
                        : 'costo_vita.storico',
                    titolo: 'Ultimi 6 mesi',
                    tipi: const [
                      TipoGrafico.barreImpilate,
                      TipoGrafico.colonne,
                      TipoGrafico.linee,
                      TipoGrafico.tabella,
                    ],
                    costruisci: (context, tipo) => switch (tipo) {
                      TipoGrafico.colonne => ColonneRaggruppate(
                        etichette: [
                          for (final m in storico) meseBreve(context, m.mese),
                        ],
                        valuta: 'EUR',
                        serie: [
                          SerieTempo('Fisse', [
                            for (final m in storico) m.fisse,
                          ]),
                          SerieTempo('Variabili previste', [
                            for (final m in storico) m.variabiliPreviste,
                          ]),
                          SerieTempo('Variabili reali', [
                            for (final m in storico) m.variabiliReali,
                          ]),
                        ],
                      ),
                      TipoGrafico.linee => GraficoLinee(
                        etichette: [
                          for (final m in storico) meseBreve(context, m.mese),
                        ],
                        valuta: 'EUR',
                        serie: [
                          SerieTempo('Previsto', [
                            for (final m in storico) m.totalePrevisto,
                          ]),
                          SerieTempo(_t.realiDavvero, [
                            for (final m in storico) m.fisse + m.variabiliReali,
                          ]),
                        ],
                      ),
                      TipoGrafico.tabella => TabellaDati(
                        colonne: const [
                          'Mese',
                          'Fisse',
                          'Variabili previste',
                          'Variabili reali',
                          'Totale previsto',
                        ],
                        righe: [
                          for (final m in storico)
                            [
                              meseLeggibile(context, m.mese),
                              Importo.formatta(m.fisse, 'EUR'),
                              Importo.formatta(m.variabiliPreviste, 'EUR'),
                              Importo.formatta(m.variabiliReali, 'EUR'),
                              Importo.formatta(m.totalePrevisto, 'EUR'),
                            ],
                        ],
                      ),
                      _ => GraficoCostoVita(
                        mesi: storico,
                        nomeMese: (m) => meseBreve(context, m),
                        testoReale: _t.reale,
                      ),
                    },
                  ),
                  const SizedBox(height: 16),
                  _ElencoVoci(
                    titolo: _t.fisse,
                    voci: mese.voci.where((v) => v.fissa).toList(),
                    sessione: widget.sessione,
                    mese: _mese,
                    tipo: TipoVoce.fissa,
                    testi: _t,
                    suggerite: _t.suggeriteFisse,
                    onSuggerita: _suggerita,
                  ),
                  if (mese.rate.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ElencoRate(rate: mese.rate, sessione: widget.sessione),
                  ],
                  const SizedBox(height: 16),
                  _ElencoVoci(
                    titolo: _t.variabili,
                    voci: mese.voci.where((v) => !v.fissa).toList(),
                    sessione: widget.sessione,
                    mese: _mese,
                    tipo: TipoVoce.variabile,
                    testi: _t,
                    suggerite: _t.suggeriteVariabili,
                    onSuggerita: _suggerita,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SceltaMese extends StatelessWidget {
  const _SceltaMese({
    required this.mese,
    required this.onPrecedente,
    required this.onSuccessivo,
  });

  final DateTime mese;
  final VoidCallback onPrecedente;
  final VoidCallback onSuccessivo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Mese precedente',
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrecedente,
        ),
        SizedBox(
          width: 180,
          child: Text(
            meseLeggibile(context, mese),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          tooltip: 'Mese successivo',
          icon: const Icon(Icons.chevron_right),
          onPressed: onSuccessivo,
        ),
      ],
    );
  }
}

class _Riepilogo extends StatelessWidget {
  const _Riepilogo({required this.mese, required this.testi});

  final RiepilogoMese mese;
  final TestiVoci testi;

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    final colori = ColoriCostoVita.di(context);
    Widget voce(String etichetta, int valore, Color colore) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: colore,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(etichetta)),
          Text(
            Importo.formatta(valore, 'EUR'),
            style: const TextStyle(
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(testi.titoloMese, style: testo.labelLarge),
            Text(
              Importo.formatta(mese.totalePrevisto, 'EUR'),
              style: testo.headlineMedium,
            ),
            const SizedBox(height: 8),
            voce(testi.fisse, mese.fisse, colori.fisse),
            if (mese.ratePrestiti > 0)
              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Text(
                  'di cui rate dei prestiti '
                  '${Importo.formatta(mese.ratePrestiti, 'EUR')}',
                  style: testo.bodySmall,
                ),
              ),
            voce(
              'Variabili previste',
              mese.variabiliPreviste,
              colori.variabili,
            ),
            voce(testi.realiFinora, mese.variabiliReali, colori.reali),
          ],
        ),
      ),
    );
  }
}

/// Rate dei prestiti del mese: contano tra le spese fisse fino
/// all'estinzione. Si modificano dalla sezione Prestiti.
class _ElencoRate extends StatelessWidget {
  const _ElencoRate({required this.rate, required this.sessione});

  final List<RataDelMese> rate;
  final Sessione sessione;

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    final totale = rate.fold<int>(0, (t, r) => t + r.importo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Text('Prestiti e rate', style: testo.titleMedium),
              ),
              Text(Importo.formatta(totale, 'EUR'), style: testo.titleMedium),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              for (final r in rate)
                ListTile(
                  leading: Icon(
                    r.maxi ? Icons.flag_outlined : Icons.request_quote_outlined,
                  ),
                  title: Text(r.prestito.nome),
                  subtitle: Text(
                    [
                      r.maxi
                          ? 'Maxi rata finale'
                          : 'Rata ${r.numero} di ${r.prestito.numeroRate}',
                      'addebito il ${dataLeggibile(context, r.date.first)}',
                      if ((r.prestito.speseRataMinimo ?? 0) > 0)
                        'con ${Importo.formatta(r.prestito.speseRataMinimo!, 'EUR')} di spese',
                    ].join(' · '),
                  ),
                  trailing: Text(
                    Importo.formatta(r.importo, 'EUR'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PrestitoPagina(
                        sessione: sessione,
                        prestitoId: r.prestito.id,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
          child: Text(
            "Contano tra le spese fisse fino all'ultima rata. Si modificano "
            'nella sezione Prestiti.',
            style: testo.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _ElencoVoci extends StatelessWidget {
  const _ElencoVoci({
    required this.titolo,
    required this.voci,
    required this.sessione,
    required this.mese,
    required this.tipo,
    required this.testi,
    required this.suggerite,
    required this.onSuggerita,
  });

  final String titolo;
  final List<VoceDelMese> voci;
  final Sessione sessione;
  final DateTime mese;
  final String tipo;
  final TestiVoci testi;
  final List<(String, String)> suggerite;
  final Future<void> Function(String tipo, String nome, String categoria)
  onSuggerita;

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    final schema = Theme.of(context).colorScheme;
    final totale = voci.fold<int>(0, (t, v) => t + v.previsto);
    final nomiPresenti = voci.map((v) => v.voce.nome).toSet();
    final mancanti = suggerite.where((s) => !nomiPresenti.contains(s.$1));

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Text(titolo, style: testo.titleMedium),
              trailing: Text(
                Importo.formatta(totale, 'EUR'),
                style: testo.titleMedium,
              ),
            ),
            for (final v in voci)
              _RigaVoce(voce: v, sessione: sessione, mese: mese, testi: testi),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.add),
                    label: const Text('Aggiungi'),
                    onPressed: () => apriNuovaVoce(
                      context,
                      sessione,
                      tipo: tipo,
                      natura: testi.natura,
                    ),
                  ),
                  for (final (nome, categoria) in mancanti.take(6))
                    ActionChip(
                      label: Text(nome),
                      labelStyle: TextStyle(color: schema.onSurfaceVariant),
                      onPressed: () => onSuggerita(tipo, nome, categoria),
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

class _RigaVoce extends StatelessWidget {
  const _RigaVoce({
    required this.voce,
    required this.sessione,
    required this.mese,
    required this.testi,
  });

  final VoceDelMese voce;
  final Sessione sessione;
  final DateTime mese;
  final TestiVoci testi;

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    final note = <String>[
      if (voce.variato)
        'Solo questo mese (predefinito ${Importo.formatta(voce.predefinito, 'EUR')})',
      if (voce.prossimaModifica case final p?)
        'Dal ${_data(p.dal)}: ${Importo.formatta(p.importo, 'EUR')}',
      if (voce.addebito case final a?)
        '${Pianificatore.ricorrenzaDi(a).descrizione()}'
            '${a.portafoglioId == null ? ' (promemoria)' : ' (registrazione automatica)'}',
      if (voce.ripartita)
        '${Importo.formatta(voce.importoUnitario, 'EUR')} '
            '${Frequenza.daCodice(voce.addebito!.frequenza).etichetta.toLowerCase()}, '
            'suddivisi nei mesi',
    ];
    final reale = voce.reale;
    return ListTile(
      onTap: () => apriModificaVoce(context, sessione, voce, mese),
      title: Text(voce.voce.nome),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.isNotEmpty)
            Text(
              note.join(' · '),
              style: TextStyle(color: schema.primary, fontSize: 12),
            ),
          if (reale != null) ...[
            const SizedBox(height: 4),
            _Avanzamento(reale: reale, previsto: voce.previsto, testi: testi),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (voce.variato)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.edit_calendar, size: 16, color: schema.primary),
            ),
          Text(
            Importo.formatta(voce.previsto, 'EUR'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Modifica o elimina',
            onSelected: (scelta) => switch (scelta) {
              'elimina' => eliminaVoceConConferma(context, sessione, voce.voce),
              _ => apriModificaVoce(context, sessione, voce, mese),
            },
            itemBuilder: (context) => const [
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

  static String _data(String aaaammgg) {
    final p = aaaammgg.split('-');
    return '${p[2]}/${p[1]}/${p[0]}';
  }
}

/// Reale rispetto alla stima: barra + testo (mai solo colore). Per le spese
/// superare la stima è un avviso; per le entrate è una buona notizia.
class _Avanzamento extends StatelessWidget {
  const _Avanzamento({
    required this.reale,
    required this.previsto,
    required this.testi,
  });

  final int reale;
  final int previsto;
  final TestiVoci testi;

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    final colori = ColoriCostoVita.di(context);
    final oltre = previsto > 0 && reale > previsto;
    final allarme = oltre && !testi.entrate;
    final quota = previsto == 0 ? 1.0 : (reale / previsto).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: quota,
            minHeight: 6,
            color: allarme ? schema.error : colori.reali,
            backgroundColor: schema.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          oltre
              ? '${testi.reale} ${Importo.formatta(reale, 'EUR')}: '
                    '${Importo.formatta(reale - previsto, 'EUR')} ${testi.oltre}'
              : '${testi.reale} ${Importo.formatta(reale, 'EUR')} · '
                    '${testi.manca} ${Importo.formatta(previsto - reale, 'EUR')}',
          style: TextStyle(
            fontSize: 12,
            color: allarme ? schema.error : schema.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Prima volta: spiegazione e suggerimenti a un tocco.
class _PrimaConfigurazione extends StatelessWidget {
  const _PrimaConfigurazione({
    required this.onSuggerita,
    required this.sessione,
    required this.testi,
  });

  final Future<void> Function(String tipo, String nome, String categoria)
  onSuggerita;
  final Sessione sessione;
  final TestiVoci testi;

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    Widget gruppo(String titolo, String tipo, List<(String, String)> voci) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(titolo, style: testo.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (nome, categoria) in voci)
                  ActionChip(
                    label: Text(nome),
                    onPressed: () => onSuggerita(tipo, nome, categoria),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add),
                  label: const Text('Altra'),
                  onPressed: () => apriNuovaVoce(
                    context,
                    sessione,
                    tipo: tipo,
                    natura: testi.natura,
                  ),
                ),
              ],
            ),
          ],
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              testi.entrate ? Icons.trending_up : Icons.receipt_long_outlined,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(testi.primaTitolo, style: testo.headlineSmall),
            const SizedBox(height: 8),
            Text(testi.primaTesto),
            gruppo(testi.fisse, TipoVoce.fissa, testi.suggeriteFisse),
            gruppo(
              testi.variabili,
              TipoVoce.variabile,
              testi.suggeriteVariabili,
            ),
          ],
        ),
      ),
    );
  }
}
