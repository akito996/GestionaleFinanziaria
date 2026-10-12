import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/export/esportazione.dart';
import '../../core/sessione.dart';
import '../comuni/campi.dart';
import '../comuni/errori.dart';
import '../comuni/icone.dart';
import '../comuni/salva_file.dart';
import '../movimenti/riga_movimento.dart';

enum _Periodo { meseCorrente, ultimiTre, annoCorrente, personalizzato }

enum _Formato { pdf, excel, entrambi }

/// Export: scegli cosa, il periodo e il formato (PDF con grafici, Excel, entrambi).
Future<void> apriExport(BuildContext context, Sessione sessione) =>
    showDialog<void>(
      context: context,
      builder: (_) => _ExportDialogo(sessione: sessione),
    );

class _ExportDialogo extends StatefulWidget {
  const _ExportDialogo({required this.sessione});

  final Sessione sessione;

  @override
  State<_ExportDialogo> createState() => _ExportDialogoState();
}

class _ExportDialogoState extends State<_ExportDialogo> {
  final Set<SezioneExport> _sezioni = SezioneExport.values.toSet();
  _Periodo _periodo = _Periodo.meseCorrente;
  _Formato _formato = _Formato.entrambi;
  late DateTimeRange _personalizzato = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month),
    end: DateUtils.dateOnly(DateTime.now()),
  );
  bool _inCorso = false;

  DateTimeRange get _intervallo {
    final oggi = DateUtils.dateOnly(DateTime.now());
    return switch (_periodo) {
      _Periodo.meseCorrente => DateTimeRange(
        start: DateTime(oggi.year, oggi.month),
        end: DateTime(oggi.year, oggi.month + 1, 0),
      ),
      _Periodo.ultimiTre => DateTimeRange(
        start: DateTime(oggi.year, oggi.month - 2),
        end: DateTime(oggi.year, oggi.month + 1, 0),
      ),
      _Periodo.annoCorrente => DateTimeRange(
        start: DateTime(oggi.year),
        end: DateTime(oggi.year, 12, 31),
      ),
      _Periodo.personalizzato => _personalizzato,
    };
  }

  String _nomeBase() {
    final i = _intervallo;
    String g(DateTime d) =>
        '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
    return 'GestionaleFinanziaria_${g(i.start)}-${g(i.end)}';
  }

  Future<bool> _salva(String nome, String estensione, Uint8List byte) async =>
      await salvaConNome(
        nome: '$nome.$estensione',
        byte: byte,
        tipo: estensione == 'pdf' ? 'PDF' : 'Excel',
        estensione: estensione,
        mime: estensione == 'pdf' ? 'application/pdf' : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      ) !=
      null;

  Future<void> _esporta() async {
    setState(() => _inCorso = true);
    try {
      final i = _intervallo;
      final dati = await Esportazione.raccogli(
        widget.sessione,
        OpzioniExport(da: i.start, a: i.end, sezioni: _sezioni),
      );
      final nome = _nomeBase();
      var salvati = 0;
      if (_formato != _Formato.excel &&
          await _salva(
            nome,
            'pdf',
            await Esportazione.pdf(
              dati,
              normale: await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
              grassetto: await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
            ),
          )) {
        salvati++;
      }
      if (_formato != _Formato.pdf &&
          await _salva(nome, 'xlsx', Esportazione.excel(dati))) {
        salvati++;
      }
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      if (salvati > 0) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              salvati == 1 ? 'File esportato' : '$salvati file esportati',
            ),
          ),
        );
      }
    } catch (e, stack) {
      if (mounted) {
        setState(() => _inCorso = false);
        await mostraErroreImprevisto(context, e, stack);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    final testo = Theme.of(context).textTheme;
    final i = _intervallo;
    return AlertDialog(
      title: const Text('Esporta'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cosa esportare', style: testo.labelLarge),
              for (final s in SezioneExport.values)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _sezioni.contains(s),
                  title: Text(s.etichetta),
                  onChanged: (v) => setState(
                    () => v == true ? _sezioni.add(s) : _sezioni.remove(s),
                  ),
                ),
              const SizedBox(height: 8),
              Text('Periodo', style: testo.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (p, etichetta) in const [
                    (_Periodo.meseCorrente, 'Mese in corso'),
                    (_Periodo.ultimiTre, 'Ultimi 3 mesi'),
                    (_Periodo.annoCorrente, 'Anno in corso'),
                    (_Periodo.personalizzato, 'Scegli le date'),
                  ])
                    ChoiceChip(
                      label: Text(etichetta),
                      selected: _periodo == p,
                      onSelected: (_) => setState(() => _periodo = p),
                    ),
                ],
              ),
              if (_periodo == _Periodo.personalizzato)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: CampoData(
                          etichetta: 'Dal',
                          valore: _personalizzato.start,
                          primo: DateTime(2000),
                          onChanged: (d) => setState(
                            () => _personalizzato = DateTimeRange(
                              start: d,
                              end: d.isAfter(_personalizzato.end)
                                  ? d
                                  : _personalizzato.end,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CampoData(
                          etichetta: 'Al',
                          valore: _personalizzato.end,
                          primo: _personalizzato.start,
                          onChanged: (d) => setState(
                            () => _personalizzato = DateTimeRange(
                              start: _personalizzato.start,
                              end: d,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Dal ${dataLeggibile(context, i.start)} al ${dataLeggibile(context, i.end)}',
                    style: testo.bodySmall,
                  ),
                ),
              const SizedBox(height: 12),
              Text('Formato', style: testo.labelLarge),
              const SizedBox(height: 6),
              SegmentedButton<_Formato>(
                segments: const [
                  ButtonSegment(
                    value: _Formato.pdf,
                    icon: Icon(Icons.picture_as_pdf_outlined),
                    label: Text('PDF'),
                  ),
                  ButtonSegment(
                    value: _Formato.excel,
                    icon: Icon(Icons.table_chart_outlined),
                    label: Text('Excel'),
                  ),
                  ButtonSegment(
                    value: _Formato.entrambi,
                    label: Text('Entrambi'),
                  ),
                ],
                selected: {_formato},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _formato = s.first),
              ),
              const SizedBox(height: 6),
              Text(
                'PDF: report da leggere o stampare, con grafici. '
                'Excel: tutti i dati, un foglio per sezione.',
                style: testo.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: schema.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Il file esportato non è cifrato: conservalo con cura.',
                      style: testo.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _inCorso ? null : () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton.icon(
          onPressed: _inCorso || _sezioni.isEmpty ? null : _esporta,
          icon: _inCorso
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const IconaEsporta(),
          label: const Text('Esporta'),
        ),
      ],
    );
  }
}
