import 'package:flutter/material.dart';

import '../../core/db/costo_vita.dart';
import '../../core/db/pianificatore.dart';
import '../../core/db/tabelle.dart';
import '../../core/importo.dart';
import '../../core/ricorrenza.dart';
import '../../core/sessione.dart';
import '../comuni/layout.dart';
import '../comuni/sezioni.dart';
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

  /// Voci del mese mostrato: la finestra "Nuova" non le ripropone tra i
  /// suggerimenti.
  Set<String> _nomiPresenti = const {};

  /// Un solo punto per aggiungere: il pulsante "Nuova" (scelta dell'utente).
  Future<void> _nuova() => apriNuovaVoce(
    context,
    widget.sessione,
    tipo: TipoVoce.fissa,
    natura: widget.natura,
    nomiPresenti: _nomiPresenti,
  );

  /// Prefisso delle preferenze delle sezioni (aperte o chiuse).
  String get _sezione => _t.entrate ? 'entrate' : 'costo_vita';

  @override
  Widget build(BuildContext context) {
    final cv = widget.sessione.costoVita;
    return Scaffold(
      appBar: AppBar(
        title: Text(_t.sezione),
        actions: [PulsanteBlocca(sessione: widget.sessione)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-$_sezione',
        onPressed: _nuova,
        icon: const Icon(Icons.add),
        label: const Text('Nuova'),
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
          _nomiPresenti = {for (final v in mese.voci) v.voce.nome};
          final senzaVoci = storico.every((m) => m.vuoto);
          return LayoutBuilder(
            builder: (context, vincoli) => ListView(
              // In fondo lo spazio per il pulsante "Nuova".
              padding: marginiPagina(vincoli, sopra: 8),
              children: [
                _SceltaMese(
                  mese: _mese,
                  onPrecedente: () => _spostaMese(-1),
                  onSuccessivo: () => _spostaMese(1),
                ),
                if (senzaVoci)
                  _PrimaConfigurazione(testi: _t)
                else ...[
                  _Riepilogo(mese: mese, testi: _t),
                  const SizedBox(height: 16),
                  SezioneRipiegabile.costruita(
                    sessione: widget.sessione,
                    chiave: '$_sezione.grafico',
                    titolo: 'Ultimi 6 mesi',
                    costruisci: (context, _, alterna) => SchedaGrafico(
                      sessione: widget.sessione,
                      chiave: _t.entrate
                          ? 'entrate.storico'
                          : 'costo_vita.storico',
                      titolo: 'Ultimi 6 mesi',
                      azione: IconButton(
                        tooltip: 'Mostra meno',
                        icon: const Icon(Icons.expand_less),
                        onPressed: alterna,
                      ),
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
                              for (final m in storico)
                                m.fisse + m.variabiliReali,
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
                  ),
                  const SizedBox(height: 16),
                  _ElencoVoci(
                    chiave: '$_sezione.fisse',
                    titolo: _t.fisse,
                    voci: mese.voci.where((v) => v.fissa).toList(),
                    sessione: widget.sessione,
                    mese: _mese,
                    testi: _t,
                  ),
                  if (mese.rate.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ElencoRate(
                      rate: mese.rate,
                      sessione: widget.sessione,
                      chiave: '$_sezione.rate',
                    ),
                  ],
                  const SizedBox(height: 16),
                  _ElencoVoci(
                    chiave: '$_sezione.variabili',
                    titolo: _t.variabili,
                    voci: mese.voci.where((v) => !v.fissa).toList(),
                    sessione: widget.sessione,
                    mese: _mese,
                    testi: _t,
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
  const _ElencoRate({
    required this.rate,
    required this.sessione,
    required this.chiave,
  });

  final List<RataDelMese> rate;
  final Sessione sessione;
  final String chiave;

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    final totale = rate.fold<int>(0, (t, r) => t + r.importo);
    return SezioneRipiegabile(
      sessione: sessione,
      chiave: chiave,
      titolo: 'Prestiti e rate',
      dettaglio: Importo.formatta(totale, 'EUR'),
      inScheda: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Column(
              children: [
                for (final r in rate)
                  ListTile(
                    leading: Icon(
                      r.maxi
                          ? Icons.flag_outlined
                          : Icons.request_quote_outlined,
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
      ),
    );
  }
}

class _ElencoVoci extends StatelessWidget {
  const _ElencoVoci({
    required this.chiave,
    required this.titolo,
    required this.voci,
    required this.sessione,
    required this.mese,
    required this.testi,
  });

  final String chiave;
  final String titolo;
  final List<VoceDelMese> voci;
  final Sessione sessione;
  final DateTime mese;
  final TestiVoci testi;

  @override
  Widget build(BuildContext context) {
    final totale = voci.fold<int>(0, (t, v) => t + v.previsto);

    return SezioneRipiegabile(
      sessione: sessione,
      chiave: chiave,
      titolo: titolo,
      dettaglio: Importo.formatta(totale, 'EUR'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final v in voci)
              _RigaVoce(voce: v, sessione: sessione, mese: mese, testi: testi),
            if (voci.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  'Nessuna voce: aggiungila con «Nuova».',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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

/// Prima volta: spiegazione e invito a usare "Nuova" (i suggerimenti a un
/// tocco sono nella finestra di inserimento).
class _PrimaConfigurazione extends StatelessWidget {
  const _PrimaConfigurazione({required this.testi});

  final TestiVoci testi;

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    final esempi = [
      ...testi.suggeriteFisse.take(2),
      ...testi.suggeriteVariabili.take(1),
    ].map((s) => s.$1).join(', ');
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
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.add_circle_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tocca «Nuova» in basso: trovi suggerimenti pronti '
                    'come $esempi.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
