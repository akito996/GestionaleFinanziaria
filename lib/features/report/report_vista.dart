import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/importo.dart';
import '../../core/report/documento.dart';
import '../../core/report/esporta_report.dart';
import '../comuni/errori.dart';
import '../comuni/layout.dart';
import '../comuni/salva_file.dart';
import '../grafici/grafici.dart';
import '../grafici/grafici_avanzati.dart';
import '../comuni/avvisi.dart';
import '../comuni/firma_versione.dart';

/// Un report a schermo, con i pulsanti per scaricarlo in PDF ed Excel.
class ReportVista extends StatefulWidget {
  const ReportVista({super.key, required this.documento, this.nomeFile});

  final DocumentoReport documento;

  /// Nome del file scaricato (senza estensione).
  final String? nomeFile;

  @override
  State<ReportVista> createState() => _ReportVistaState();
}

class _ReportVistaState extends State<ReportVista> {
  bool _inCorso = false;

  String get _nome =>
      widget.nomeFile ??
      widget.documento.titolo
          .replaceAll(RegExp(r'[^A-Za-z0-9àèéìòù ]'), '')
          .trim()
          .replaceAll(' ', '_');

  Future<void> _scarica(String estensione) async {
    setState(() => _inCorso = true);
    try {
      final Uint8List byte;
      if (estensione == 'pdf') {
        byte = await EsportaReport.pdf(
          widget.documento,
          normale: await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
          grassetto: await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
        );
      } else {
        byte = EsportaReport.excel(widget.documento);
      }
      final dove = await salvaConNome(
        nome: '$_nome.$estensione',
        byte: byte,
        tipo: estensione == 'pdf' ? 'PDF' : 'Excel',
        estensione: estensione,
        mime: estensione == 'pdf' ? 'application/pdf' : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (dove != null && mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            avviso(
              content: Text(
                'Report salvato ($dove). Il file non è cifrato: '
                'conservalo in un posto sicuro.',
              ),
            ),
          );
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

  @override
  Widget build(BuildContext context) {
    final d = widget.documento;
    final testo = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: TitoloConFirma(d.titolo),
        actions: [
          IconButton(
            tooltip: 'Scarica in PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _inCorso ? null : () => _scarica('pdf'),
          ),
          IconButton(
            tooltip: 'Scarica in Excel',
            icon: const Icon(Icons.table_view_outlined),
            onPressed: _inCorso ? null : () => _scarica('xlsx'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, vincoli) => ListView(
          padding: marginiPagina(vincoli, sotto: 32),
          children: [
            Text(
              d.sottotitolo,
              style: testo.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (_inCorso) const LinearProgressIndicator(),
            for (final b in d.blocchi)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _Blocco(blocco: b),
              ),
          ],
        ),
      ),
    );
  }
}

class _Blocco extends StatelessWidget {
  const _Blocco({required this.blocco});

  final BloccoReport blocco;

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    final schema = Theme.of(context).colorScheme;
    final b = blocco;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(b.titolo, style: testo.titleMedium),
            const SizedBox(height: 12),
            switch (b) {
              CifreChiave(:final cifre) => Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  for (final c in cifre)
                    SizedBox(
                      width: 170,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.etichetta, style: testo.labelMedium),
                          Text(
                            Importo.formatta(c.importo, 'EUR'),
                            style: testo.titleLarge?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          if (c.nota != null)
                            Text(
                              c.nota!,
                              style: testo.bodySmall?.copyWith(
                                color: schema.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              SerieReport(:final etichette, :final serie, :final aColonne) =>
                aColonne
                    ? ColonneRaggruppate(
                        etichette: etichette,
                        valuta: 'EUR',
                        serie: [
                          for (final s in serie) SerieTempo(s.nome, s.valori),
                        ],
                      )
                    : GraficoLinee(
                        etichette: etichette,
                        valuta: 'EUR',
                        serie: [
                          for (final s in serie) SerieTempo(s.nome, s.valori),
                        ],
                      ),
              TabellaReport(:final colonne, :final righe) =>
                righe.isEmpty
                    ? Text(
                        'Nessun dato nel periodo.',
                        style: TextStyle(color: schema.onSurfaceVariant),
                      )
                    : TabellaDati(
                        colonne: colonne,
                        righe: [
                          for (final r in righe) [for (final c in r) c.testo],
                        ],
                      ),
            },
          ],
        ),
      ),
    );
  }
}
