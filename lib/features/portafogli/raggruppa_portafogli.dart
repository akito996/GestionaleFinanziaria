import 'package:flutter/material.dart';

import '../../core/db/archivio.dart';
import '../../core/db/contabilita.dart';
import '../../core/sessione.dart';
import '../comuni/errori.dart';

/// Crea un gruppo (o modifica [gruppo]): nome e portafogli da metterci dentro.
/// [portafogli] = quelli che si possono raggruppare (le carte sono escluse).
Future<void> apriRaggruppa(
  BuildContext context,
  Sessione sessione,
  List<PortafoglioConSaldo> portafogli, {
  String? gruppo,
}) => showDialog<void>(
  context: context,
  builder: (_) => _DialogoRaggruppa(
    sessione: sessione,
    portafogli: portafogli,
    gruppo: gruppo,
  ),
);

/// Toglie il gruppo: i portafogli restano, fuori dai gruppi ("Annulla" lo
/// ricrea).
Future<void> sciogliGruppo(
  BuildContext context,
  Sessione sessione,
  String gruppo,
  List<PortafoglioConSaldo> membri,
) async {
  final contabilita = sessione.contabilita;
  final messenger = ScaffoldMessenger.of(context);
  final ids = [for (final p in membri) p.portafoglio.id];
  await contabilita.impostaGruppo(ids, null);
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text('Gruppo "$gruppo" sciolto: i portafogli restano'),
        action: SnackBarAction(
          label: 'Annulla',
          onPressed: () => contabilita.impostaGruppo(ids, gruppo),
        ),
      ),
    );
}

class _DialogoRaggruppa extends StatefulWidget {
  const _DialogoRaggruppa({
    required this.sessione,
    required this.portafogli,
    this.gruppo,
  });

  final Sessione sessione;
  final List<PortafoglioConSaldo> portafogli;
  final String? gruppo;

  @override
  State<_DialogoRaggruppa> createState() => _DialogoRaggruppaState();
}

class _DialogoRaggruppaState extends State<_DialogoRaggruppa> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.gruppo ?? '');
  late final Set<String> _scelti = {
    for (final p in widget.portafogli)
      if (widget.gruppo != null && p.portafoglio.gruppo == widget.gruppo)
        p.portafoglio.id,
  };
  bool _salvataggio = false;

  List<String> get _gruppiEsistenti =>
      {for (final p in widget.portafogli) ?p.portafoglio.gruppo}.toList()
        ..sort();

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  /// Sceglie un gruppo già esistente: ne seleziona i portafogli.
  void _usaGruppo(String gruppo) => setState(() {
    _nome.text = gruppo;
    _scelti
      ..clear()
      ..addAll([
        for (final p in widget.portafogli)
          if (p.portafoglio.gruppo == gruppo) p.portafoglio.id,
      ]);
  });

  Future<void> _salva() async {
    if (_salvataggio || !_form.currentState!.validate()) {
      return;
    }
    final nome = _nome.text.trim();
    // Chi era nel gruppo (vecchio o nuovo nome) e non è più spuntato, esce.
    final daTogliere = [
      for (final p in widget.portafogli)
        if ((p.portafoglio.gruppo == nome ||
                p.portafoglio.gruppo == widget.gruppo) &&
            !_scelti.contains(p.portafoglio.id))
          p.portafoglio.id,
    ];
    setState(() => _salvataggio = true);
    try {
      final c = widget.sessione.contabilita;
      await c.impostaGruppo(daTogliere, null);
      await c.impostaGruppo(_scelti, nome);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, stack) {
      if (mounted) {
        setState(() => _salvataggio = false);
        await mostraErroreImprevisto(context, e, stack);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    final esistenti = _gruppiEsistenti;
    return AlertDialog(
      title: Text(
        widget.gruppo == null
            ? 'Raggruppa i portafogli'
            : 'Gruppo "${widget.gruppo}"',
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Un gruppo raccoglie più portafogli in un riquadro che si apre '
                  'e si chiude, con il totale. I preferiti ⭐ restano sempre in '
                  'cima, fuori dai gruppi.',
                  style: TextStyle(color: schema.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nome,
                  autofocus: widget.gruppo == null,
                  decoration: const InputDecoration(
                    labelText: 'Nome del gruppo',
                    hintText: 'Es. Banche, Risparmi, Investimenti',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Dai un nome al gruppo'
                      : null,
                ),
                if (widget.gruppo == null && esistenti.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final g in esistenti)
                        ActionChip(
                          avatar: const Icon(Icons.folder_outlined, size: 18),
                          label: Text(g),
                          onPressed: () => _usaGruppo(g),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Portafogli nel gruppo',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                for (final p in widget.portafogli)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _scelti.contains(p.portafoglio.id),
                    onChanged: (v) => setState(
                      () => v == true
                          ? _scelti.add(p.portafoglio.id)
                          : _scelti.remove(p.portafoglio.id),
                    ),
                    secondary: p.portafoglio.preferito
                        ? const Tooltip(
                            message: 'Preferito: resta in cima',
                            child: Icon(Icons.star, color: Color(0xFFEDA100)),
                          )
                        : null,
                    title: Text(p.portafoglio.nome),
                    subtitle: Text(_descrizione(p)),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _salvataggio ? null : _salva,
          child: const Text('Salva'),
        ),
      ],
    );
  }

  String _descrizione(PortafoglioConSaldo p) {
    final g = p.portafoglio.gruppo;
    return [
      p.tipo.nome,
      if (g != null && g != _nome.text.trim()) 'ora in "$g"',
    ].join(' · ');
  }
}

/// Portafogli che si possono raggruppare: tutti tranne le carte di credito
/// (che compaiono come avviso nel conto collegato).
List<PortafoglioConSaldo> raggruppabili(
  List<PortafoglioConSaldo> portafogli,
  Set<String> idCarte,
) => [
  for (final p in portafogli)
    if (!idCarte.contains(p.portafoglio.id) &&
        p.tipo.nome != tipoCartaDiCredito)
      p,
];
