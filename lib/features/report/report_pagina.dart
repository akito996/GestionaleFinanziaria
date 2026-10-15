import 'package:flutter/material.dart';

import '../../core/db/archivio.dart';
import '../../core/db/tabelle.dart';
import '../../core/report/documento.dart';
import '../../core/report/report_automatici.dart';
import '../../core/report/report_personalizzati.dart';
import '../../core/sessione.dart';
import '../comuni/campi.dart';
import '../comuni/errori.dart';
import '../comuni/filtri.dart';
import '../comuni/layout.dart';
import '../comuni/navigazione.dart';
import 'report_vista.dart';
import '../comuni/avvisi.dart';
import '../comuni/firma_versione.dart';

enum _Periodo {
  meseCorrente('Mese in corso'),
  ultimiTre('Ultimi 3 mesi'),
  ultimiDodici('Ultimi 12 mesi'),
  annoCorrente('Anno in corso'),
  scelto('Scegli le date');

  const _Periodo(this.etichetta);

  final String etichetta;
}

/// Le scelte per creare un report (una copia di lavoro nel pannello compatto).
class _Opzioni {
  Set<StrumentoReport> strumenti = {
    StrumentoReport.entrateUscite,
    StrumentoReport.costoVita,
    StrumentoReport.entratePreviste,
  };
  Dettaglio dettaglio = Dettaglio.mese;
  _Periodo periodo = _Periodo.ultimiDodici;
  DateTime da = DateTime(DateTime.now().year, DateTime.now().month - 2);
  DateTime a = DateUtils.dateOnly(DateTime.now());

  _Opzioni copia() => _Opzioni()
    ..strumenti = {...strumenti}
    ..dettaglio = dettaglio
    ..periodo = periodo
    ..da = da
    ..a = a;

  void prendiDa(_Opzioni altre) {
    strumenti = {...altre.strumenti};
    dettaglio = altre.dettaglio;
    periodo = altre.periodo;
    da = altre.da;
    a = altre.a;
  }

  /// "Entrate e uscite, Costo della vita · per mese · Ultimi 12 mesi".
  String descrizione(BuildContext context) => [
    strumenti.isEmpty
        ? 'Nessuno strumento scelto'
        : [for (final s in strumenti) s.etichetta].join(', '),
    'dettaglio: ${dettaglio.etichetta.toLowerCase()}',
    if (periodo == _Periodo.scelto)
      '${MaterialLocalizations.of(context).formatMediumDate(da)} – '
          '${MaterialLocalizations.of(context).formatMediumDate(a)}'
    else
      periodo.etichetta,
  ].join(' · ');
}

/// Sezione Report: crea un report del gestionale (strumenti, dettaglio,
/// periodo) e consulta i report automatici di ogni mese e di ogni anno.
///
/// Su telefono e tablet le scelte stanno nel pannello "Opzioni" e valgono
/// con "Applica".
class ReportPagina extends StatefulWidget {
  const ReportPagina({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<ReportPagina> createState() => _ReportPaginaState();
}

class _ReportPaginaState extends State<ReportPagina> {
  late final Stream<List<ReportSalvato>> _salvati = widget.sessione.report
      .osserva();
  final _opzioni = _Opzioni();
  bool _inCorso = false;

  ({DateTime da, DateTime a}) get _intervallo {
    final oggi = DateUtils.dateOnly(DateTime.now());
    return switch (_opzioni.periodo) {
      _Periodo.meseCorrente => (da: DateTime(oggi.year, oggi.month), a: oggi),
      _Periodo.ultimiTre => (da: DateTime(oggi.year, oggi.month - 2), a: oggi),
      _Periodo.ultimiDodici => (
        da: DateTime(oggi.year, oggi.month - 11),
        a: oggi,
      ),
      _Periodo.annoCorrente => (da: DateTime(oggi.year), a: oggi),
      _Periodo.scelto => (da: _opzioni.da, a: _opzioni.a),
    };
  }

  Future<void> _crea() async {
    final i = _intervallo;
    setState(() => _inCorso = true);
    try {
      final documento = await widget.sessione.reportPersonalizzati.crea(
        strumenti: _opzioni.strumenti,
        dettaglio: _opzioni.dettaglio,
        da: i.da,
        a: i.a,
      );
      if (mounted) {
        await _apri(documento);
      }
    } on ArgumentError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(avviso(content: Text('${e.message}')));
      }
    } catch (e, stack) {
      if (mounted) {
        await mostraErroreImprevisto(context, e, stack);
      }
    } finally {
      if (mounted) {
        setState(() => _inCorso = false);
      }
    }
  }

  Future<void> _apri(DocumentoReport documento) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => ReportVista(documento: documento)),
  );

  Widget _pulsanteCrea() => FilledButton.icon(
    onPressed: _opzioni.strumenti.isEmpty || _inCorso ? null : _crea,
    icon: _inCorso
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.assessment_outlined),
    label: const Text('Crea il report'),
  );

  /// Telefono e tablet: riepilogo delle scelte, "Opzioni" e "Crea il report".
  Widget _schedaCompatta(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Crea un report',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(_opzioni.descrizione(context)),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _apriOpzioni,
                icon: const Icon(Icons.tune),
                label: const Text('Opzioni'),
              ),
              _pulsanteCrea(),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _apriOpzioni() async {
    final bozza = _opzioni.copia();
    final applica = await apriPannelloFiltri(
      context,
      titolo: 'Opzioni del report',
      azzera: () => bozza.prendiDa(_Opzioni()),
      campi: (context, aggiorna) => _campi(context, bozza, aggiorna),
    );
    if (applica) {
      setState(() => _opzioni.prendiDa(bozza));
    }
  }

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const TitoloConFirma('Report'),
        actions: [PulsanteBlocca(sessione: widget.sessione)],
      ),
      body: LayoutBuilder(
        builder: (context, vincoli) => ListView(
          padding: marginiPagina(vincoli, sotto: 32),
          children: [
            if (filtriCompatti(vincoli))
              _schedaCompatta(context)
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Crea un report', style: testo.titleMedium),
                      const SizedBox(height: 4),
                      const Text(
                        'Scegli cosa analizzare, ogni quanto raggruppare i dati e '
                        'il periodo: lo vedi subito e puoi scaricarlo in PDF o '
                        'Excel.',
                      ),
                      const SizedBox(height: 12),
                      ..._campi(context, _opzioni, setState),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _pulsanteCrea(),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            StreamBuilder<List<ReportSalvato>>(
              stream: _salvati,
              builder: (context, snapshot) => _ReportAutomatici(
                salvati: snapshot.data,
                onApri: (r) => _apri(DocumentoReport.decodifica(r.contenuto)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le opzioni (in pagina o nel pannello).
List<Widget> _campi(
  BuildContext context,
  _Opzioni o,
  void Function(VoidCallback) cambia,
) {
  final testo = Theme.of(context).textTheme;
  return [
    Text('Strumenti', style: testo.labelLarge),
    const SizedBox(height: 6),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in StrumentoReport.values)
          FilterChip(
            label: Text(s.etichetta),
            selected: o.strumenti.contains(s),
            onSelected: (v) =>
                cambia(() => v ? o.strumenti.add(s) : o.strumenti.remove(s)),
          ),
      ],
    ),
    const SizedBox(height: 12),
    Text('Dettaglio', style: testo.labelLarge),
    const SizedBox(height: 6),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final d in Dettaglio.values)
          ChoiceChip(
            label: Text(d.etichetta),
            selected: o.dettaglio == d,
            onSelected: (_) => cambia(() => o.dettaglio = d),
          ),
      ],
    ),
    const SizedBox(height: 12),
    Text('Periodo', style: testo.labelLarge),
    const SizedBox(height: 6),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in _Periodo.values)
          ChoiceChip(
            label: Text(p.etichetta),
            selected: o.periodo == p,
            onSelected: (_) => cambia(() => o.periodo = p),
          ),
      ],
    ),
    if (o.periodo == _Periodo.scelto)
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Expanded(
              child: CampoData(
                etichetta: 'Dal',
                valore: o.da,
                primo: DateTime(2000),
                onChanged: (d) => cambia(() {
                  o.da = d;
                  if (o.a.isBefore(d)) {
                    o.a = d;
                  }
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CampoData(
                etichetta: 'Al',
                valore: o.a,
                primo: o.da,
                onChanged: (d) => cambia(() => o.a = d),
              ),
            ),
          ],
        ),
      ),
  ];
}

/// I report creati da soli, raggruppati per anno: l'annuale in cima.
class _ReportAutomatici extends StatelessWidget {
  const _ReportAutomatici({required this.salvati, required this.onApri});

  final List<ReportSalvato>? salvati;
  final void Function(ReportSalvato) onApri;

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    final schema = Theme.of(context).colorScheme;
    final elenco = salvati;
    final perAnno = <String, List<ReportSalvato>>{};
    for (final r in elenco ?? const <ReportSalvato>[]) {
      perAnno.putIfAbsent(r.periodo.substring(0, 4), () => []).add(r);
    }
    final anni = perAnno.keys.toList()..sort((a, b) => b.compareTo(a));
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Text('Report automatici', style: testo.titleMedium),
              subtitle: const Text(
                'Ogni mese e ogni anno l\'app prepara un report su entrate '
                'previste e costo della vita. I mensili restano 12 mesi, gli '
                'annuali sempre.',
              ),
            ),
            if (elenco == null)
              const LinearProgressIndicator()
            else if (elenco.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Il primo report arriverà alla fine di questo mese.',
                  style: TextStyle(color: schema.onSurfaceVariant),
                ),
              ),
            for (final anno in anni) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(anno, style: testo.labelLarge),
              ),
              for (final r
                  in perAnno[anno]!..sort(
                    (a, b) => a.periodicita == b.periodicita
                        ? b.periodo.compareTo(a.periodo)
                        : (a.periodicita == PeriodicitaReport.annuale ? -1 : 1),
                  ))
                ListTile(
                  leading: Icon(
                    r.periodicita == PeriodicitaReport.annuale
                        ? Icons.calendar_today_outlined
                        : Icons.calendar_view_month_outlined,
                  ),
                  title: Text(_titolo(r)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onApri(r),
                ),
            ],
          ],
        ),
      ),
    );
  }

  static String _titolo(ReportSalvato r) {
    if (r.periodicita == PeriodicitaReport.annuale) {
      return 'Report del ${r.periodo}';
    }
    final parti = r.periodo.split('-');
    final mese = DateTime(int.parse(parti[0]), int.parse(parti[1]));
    final nome = meseEsteso(mese);
    return 'Report di $nome';
  }
}
