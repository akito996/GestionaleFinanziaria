import 'package:flutter/material.dart';

import '../../core/db/prestiti.dart';
import '../../core/db/tabelle.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../comuni/navigazione.dart';
import '../movimenti/riga_movimento.dart';
import 'prestito_modulo.dart';

String etichettaTipoPrestito(String tipo) => switch (tipo) {
  TipoPrestito.mutuo => 'Mutuo',
  TipoPrestito.rate => 'Pagamento a rate',
  TipoPrestito.privato => 'Prestito tra privati',
  _ => 'Prestito',
};

/// Prestiti e rate: mutui, prestiti, acquisti a rate. Le rate si registrano da sole.
class PrestitiPagina extends StatefulWidget {
  const PrestitiPagina({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<PrestitiPagina> createState() => _PrestitiPaginaState();
}

class _PrestitiPaginaState extends State<PrestitiPagina> {
  late final Stream<List<PrestitoConStato>> _prestiti = widget.sessione.prestiti
      .osserva();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prestiti e rate'),
        actions: [PulsanteBlocca(sessione: widget.sessione)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-prestiti',
        onPressed: () => apriNuovoPrestito(context, widget.sessione),
        icon: const Icon(Icons.add),
        label: const Text('Nuovo'),
      ),
      body: StreamBuilder<List<PrestitoConStato>>(
        stream: _prestiti,
        builder: (context, snapshot) {
          final prestiti = snapshot.data;
          if (prestiti == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prestiti.isEmpty) {
            return const _NessunPrestito();
          }
          final residuo = prestiti.fold<int>(0, (t, p) => t + p.debitoResiduo);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Debito residuo totale'),
                  trailing: Text(
                    Importo.formatta(residuo, 'EUR'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              for (final p in prestiti)
                _SchedaPrestito(sessione: widget.sessione, stato: p),
            ],
          );
        },
      ),
    );
  }
}

class _NessunPrestito extends StatelessWidget {
  const _NessunPrestito();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.request_quote_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                'Mutui, prestiti e acquisti a rate',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Premi "Nuovo": puoi far leggere all\'app il contratto (PDF) o '
                'inserire i dati a mano. Le rate verranno registrate da sole nel '
                'giorno previsto, nella categoria Finanziamenti.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SchedaPrestito extends StatelessWidget {
  const _SchedaPrestito({required this.sessione, required this.stato});

  final Sessione sessione;
  final PrestitoConStato stato;

  @override
  Widget build(BuildContext context) {
    final s = stato;
    final p = s.prestito;
    final testo = Theme.of(context).textTheme;
    final schema = Theme.of(context).colorScheme;
    final prossima = s.prossima;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                PrestitoPagina(sessione: sessione, prestitoId: p.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(p.nome, style: testo.titleLarge)),
                  Text(
                    etichettaTipoPrestito(p.tipo),
                    style: testo.labelMedium?.copyWith(color: schema.primary),
                  ),
                ],
              ),
              if (p.finanziatore.isNotEmpty)
                Text(p.finanziatore, style: testo.bodySmall),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: s.avanzamento,
                  minHeight: 8,
                  backgroundColor: schema.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${s.ratePagate} rate pagate su ${p.numeroRate} · '
                'restano ${s.rateRimanenti}',
                style: testo.bodySmall,
              ),
              const SizedBox(height: 8),
              if (prossima != null)
                Text(
                  'Prossima rata: ${dataLeggibile(context, prossima.data)} · '
                  '${Importo.formatta(prossima.piano.rata, p.valuta)}',
                )
              else
                const Text('Tutte le rate sono pagate'),
              Text(
                'Debito residuo ${Importo.formatta(s.debitoResiduo, p.valuta)}'
                '${s.fine == null ? '' : ' · fine ${dataLeggibile(context, s.fine!)}'}',
                style: testo.bodySmall?.copyWith(
                  color: schema.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dettaglio: riepilogo e piano completo delle rate (pagate ✓ / da pagare).
class PrestitoPagina extends StatelessWidget {
  const PrestitoPagina({
    super.key,
    required this.sessione,
    required this.prestitoId,
  });

  final Sessione sessione;
  final String prestitoId;

  Future<void> _archivia(BuildContext context, PrestitoConStato s) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Archiviare "${s.prestito.nome}"?'),
        content: const Text(
          'Usalo se il prestito è estinto (anche in anticipo): le rate future non '
          'verranno più registrate. Le rate già pagate restano.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archivia'),
          ),
        ],
      ),
    );
    if (conferma != true || !context.mounted) {
      return;
    }
    final servizio = sessione.prestiti;
    await servizio.archivia(s.prestito.id);
    if (!context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('"${s.prestito.nome}" archiviato'),
          action: SnackBarAction(
            label: 'Annulla',
            onPressed: () =>
                servizio.archivia(s.prestito.id, archiviato: false),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PrestitoConStato>>(
      stream: sessione.prestiti.osserva(),
      builder: (context, snapshot) {
        final s = snapshot.data
            ?.where((x) => x.prestito.id == prestitoId)
            .firstOrNull;
        if (s == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final p = s.prestito;
        final testo = Theme.of(context).textTheme;
        final schema = Theme.of(context).colorScheme;
        String euro(int v) => Importo.formatta(v, p.valuta);
        return Scaffold(
          appBar: AppBar(
            title: Text(p.nome),
            actions: [
              IconButton(
                tooltip: 'Modifica',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    apriModuloPrestito(context, sessione, esistente: s),
              ),
              IconButton(
                tooltip: 'Archivia (estinto)',
                icon: const Icon(Icons.archive_outlined),
                onPressed: () => _archivia(context, s),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 32,
                    runSpacing: 12,
                    children: [
                      _Dato('Importo finanziato', euro(p.capitaleMinimo)),
                      _Dato('Rata', euro(p.importoRataMinimo)),
                      if (p.maxiRataMinimo != null)
                        _Dato('Maxi rata finale', euro(p.maxiRataMinimo!)),
                      _Dato('Rate', '${s.ratePagate} / ${p.numeroRate}'),
                      _Dato('Debito residuo', euro(s.debitoResiduo)),
                      _Dato('Ancora da pagare', euro(s.daPagare)),
                      if (p.tanPuntiBase != null)
                        _Dato(
                          'TAN',
                          '${(p.tanPuntiBase! / 100).toStringAsFixed(2)} %',
                        ),
                      if (p.taegPuntiBase != null)
                        _Dato(
                          'TAEG',
                          '${(p.taegPuntiBase! / 100).toStringAsFixed(2)} %',
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Piano delle rate', style: testo.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('N.')),
                      DataColumn(label: Text('Data')),
                      DataColumn(label: Text('Rata'), numeric: true),
                      DataColumn(label: Text('Capitale'), numeric: true),
                      DataColumn(label: Text('Interessi'), numeric: true),
                      DataColumn(label: Text('Residuo'), numeric: true),
                      DataColumn(label: Text('Stato')),
                    ],
                    rows: [
                      for (final r in s.rate)
                        DataRow(
                          cells: [
                            DataCell(Text('${r.piano.numero}')),
                            DataCell(Text(dataLeggibile(context, r.data))),
                            DataCell(Text(euro(r.piano.rata))),
                            DataCell(Text(euro(r.piano.quotaCapitale))),
                            DataCell(Text(euro(r.piano.quotaInteressi))),
                            DataCell(Text(euro(r.piano.debitoResiduo))),
                            DataCell(
                              r.pagata
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: coloreEntrata(context),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text('Pagata'),
                                      ],
                                    )
                                  : Text(
                                      'Da pagare',
                                      style: TextStyle(
                                        color: schema.onSurfaceVariant,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              if (p.tanPuntiBase == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Quote di capitale e interessi stimate dalla rata (TAN non indicato).',
                    style: testo.bodySmall,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.etichetta, this.valore);

  final String etichetta;
  final String valore;

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(etichetta, style: testo.labelMedium),
        Text(valore, style: testo.titleMedium),
      ],
    );
  }
}
