import 'package:flutter/material.dart';

import '../../core/importo.dart';
import '../movimenti/riga_movimento.dart' show dataLeggibile;

/// Finestra con il calendario per scegliere una data (sempre calendario, mai
/// campo di testo), con le scorciatoie "Oggi" e "Ieri".
Future<DateTime?> scegliData(
  BuildContext context, {
  required DateTime iniziale,
  String titolo = 'Scegli la data',
  DateTime? primo,
  DateTime? ultimo,
  bool scorciatoie = true,
}) => showDialog<DateTime>(
  context: context,
  builder: (_) => _DialogoCalendario(
    iniziale: DateUtils.dateOnly(iniziale),
    titolo: titolo,
    primo: primo ?? DateTime(1990),
    ultimo: ultimo ?? DateTime(2100),
    scorciatoie: scorciatoie,
  ),
);

class _DialogoCalendario extends StatefulWidget {
  const _DialogoCalendario({
    required this.iniziale,
    required this.titolo,
    required this.primo,
    required this.ultimo,
    required this.scorciatoie,
  });

  final DateTime iniziale;
  final String titolo;
  final DateTime primo;
  final DateTime ultimo;
  final bool scorciatoie;

  @override
  State<_DialogoCalendario> createState() => _DialogoCalendarioState();
}

class _DialogoCalendarioState extends State<_DialogoCalendario> {
  late DateTime _scelta = widget.iniziale.isBefore(widget.primo)
      ? widget.primo
      : widget.iniziale.isAfter(widget.ultimo)
      ? widget.ultimo
      : widget.iniziale;
  // Cambia quando si usa una scorciatoia, così il calendario salta al mese giusto.
  int _versione = 0;

  void _vaiA(DateTime d) => setState(() {
    _scelta = d;
    _versione++;
  });

  @override
  Widget build(BuildContext context) {
    final oggi = DateUtils.dateOnly(DateTime.now());
    final ieri = oggi.subtract(const Duration(days: 1));
    final testo = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(widget.titolo),
      contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              dataLeggibile(context, _scelta),
              textAlign: TextAlign.center,
              style: testo.headlineSmall,
            ),
            if (widget.scorciatoie)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    if (!oggi.isBefore(widget.primo) &&
                        !oggi.isAfter(widget.ultimo))
                      ActionChip(
                        label: const Text('Oggi'),
                        onPressed: () => _vaiA(oggi),
                      ),
                    if (!ieri.isBefore(widget.primo) &&
                        !ieri.isAfter(widget.ultimo))
                      ActionChip(
                        label: const Text('Ieri'),
                        onPressed: () => _vaiA(ieri),
                      ),
                  ],
                ),
              ),
            CalendarDatePicker(
              key: ValueKey(_versione),
              initialDate: _scelta,
              firstDate: widget.primo,
              lastDate: widget.ultimo,
              onDateChanged: (d) => setState(() => _scelta = d),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_scelta),
          child: const Text('Scegli'),
        ),
      ],
    );
  }
}

/// Campo data: mostra la data e al tocco apre il calendario in una finestra.
class CampoData extends StatelessWidget {
  const CampoData({
    super.key,
    required this.etichetta,
    required this.valore,
    required this.onChanged,
    this.primo,
    this.ultimo,
    this.vuoto = 'Scegli…',
    this.onTogli,
  });

  final String etichetta;
  final DateTime? valore;
  final ValueChanged<DateTime> onChanged;
  final DateTime? primo;
  final DateTime? ultimo;

  /// Testo quando non c'è ancora una data.
  final String vuoto;

  /// Se presente, mostra la "x" per togliere la data (date facoltative).
  final VoidCallback? onTogli;

  @override
  Widget build(BuildContext context) {
    final v = valore;
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        final d = await scegliData(
          context,
          iniziale: v ?? DateTime.now(),
          titolo: etichetta,
          primo: primo,
          ultimo: ultimo,
        );
        if (d != null) {
          onChanged(d);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etichetta,
          prefixIcon: const Icon(Icons.calendar_month_outlined),
          suffixIcon: v != null && onTogli != null
              ? IconButton(
                  tooltip: 'Togli la data',
                  icon: const Icon(Icons.close),
                  onPressed: onTogli,
                )
              : null,
        ),
        child: Text(v == null ? vuoto : dataLeggibile(context, v)),
      ),
    );
  }
}

/// Campo importo grande e centrato, con il simbolo della valuta.
class CampoImporto extends StatelessWidget {
  const CampoImporto({
    super.key,
    required this.controller,
    this.etichetta = 'Importo',
    this.valuta = 'EUR',
    this.colore,
    this.autofocus = false,
    this.obbligatorio = true,
    this.ammettiZero = false,
    this.ammettiNegativo = false,
    this.onInvio,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final String etichetta;
  final String valuta;
  final Color? colore;
  final bool autofocus;
  final bool obbligatorio;
  final bool ammettiZero;
  final bool ammettiNegativo;
  final VoidCallback? onInvio;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final stile = Theme.of(context).textTheme.displaySmall?.copyWith(
      color: colore,
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      textAlign: TextAlign.center,
      style: stile,
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: ammettiNegativo,
      ),
      textInputAction: textInputAction,
      onFieldSubmitted: onInvio == null ? null : (_) => onInvio!(),
      decoration: InputDecoration(
        labelText: etichetta,
        floatingLabelAlignment: FloatingLabelAlignment.center,
        hintText: '0,00',
        hintStyle: stile?.copyWith(color: Theme.of(context).hintColor),
        suffixText: Importo.simbolo(valuta),
        suffixStyle: stile?.copyWith(fontSize: (stile.fontSize ?? 36) * 0.6),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
      ),
      validator: (v) {
        final testo = v?.trim() ?? '';
        if (testo.isEmpty) {
          return obbligatorio ? 'Scrivi un importo, per esempio 12,50' : null;
        }
        final importo = Importo.leggi(testo);
        if (importo == null) {
          return 'Scrivi un importo, per esempio 12,50';
        }
        if (!ammettiNegativo && importo < 0) {
          return 'L\'importo non può essere negativo';
        }
        if (!ammettiZero && importo == 0) {
          return 'L\'importo deve essere maggiore di zero';
        }
        return null;
      },
    );
  }
}
