import 'package:flutter/material.dart';

import '../../core/db/archivio.dart';
import '../../core/db/carte_credito.dart';
import '../../core/db/contabilita.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../comuni/errori.dart';
import '../comuni/navigazione.dart';
import '../movimenti/movimento_modulo.dart';
import '../movimenti/riga_movimento.dart';
import '../portafogli/portafoglio_pagina.dart';

/// Carte di credito: spese della carta, prossimo addebito sul conto, plafond.
class CartePagina extends StatefulWidget {
  const CartePagina({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<CartePagina> createState() => _CartePaginaState();
}

class _CartePaginaState extends State<CartePagina> {
  late final Stream<List<CartaConStato>> _carte = widget.sessione.carte
      .osserva();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte di credito'),
        actions: [PulsanteBlocca(sessione: widget.sessione)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nuova-carta',
        onPressed: () => apriModuloCarta(context, widget.sessione),
        icon: const Icon(Icons.add_card),
        label: const Text('Nuova carta'),
      ),
      body: StreamBuilder<List<CartaConStato>>(
        stream: _carte,
        builder: (context, snapshot) {
          final carte = snapshot.data;
          if (carte == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (carte.isEmpty) {
            return const _NessunaCarta();
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              for (final c in carte)
                _SchedaCarta(sessione: widget.sessione, stato: c),
            ],
          );
        },
      ),
    );
  }
}

class _NessunaCarta extends StatelessWidget {
  const _NessunaCarta();

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.credit_card, size: 64),
              const SizedBox(height: 16),
              Text(
                'Aggiungi la tua carta di credito',
                style: testo.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Registri qui le spese fatte con la carta. Il giorno dell\'addebito '
                'l\'app scala da sola il totale dal conto collegato, e ti avvisa '
                'prima nel portafoglio di quel conto.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SchedaCarta extends StatelessWidget {
  const _SchedaCarta({required this.sessione, required this.stato});

  final Sessione sessione;
  final CartaConStato stato;

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    final schema = Theme.of(context).colorScheme;
    final s = stato;
    final valuta = s.portafoglio.valuta;
    final plafond = s.usoPlafond;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PortafoglioPagina(
              sessione: sessione,
              portafoglioId: s.portafoglio.id,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.credit_card),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s.portafoglio.nome, style: testo.titleLarge),
                  ),
                  IconButton(
                    tooltip: 'Modifica carta',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        apriModuloCarta(context, sessione, esistente: s),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Il ${dataLeggibile(context, s.prossimoAddebito)} verranno '
                'addebitati sul conto "${s.conto.nome}"',
                style: testo.bodyMedium,
              ),
              Text(
                Importo.formatta(s.daAddebitare, valuta),
                style: testo.headlineMedium,
              ),
              Text(
                'Spese fino al ${dataLeggibile(context, s.chiusura)}',
                style: testo.bodySmall?.copyWith(
                  color: schema.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              // Sul telefono il pulsante va sotto, invece di uscire dal bordo.
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Debito totale: ${Importo.formatta(s.debitoTotale, valuta)}',
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => apriModuloMovimento(
                      context,
                      sessione,
                      portafoglioId: s.portafoglio.id,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Spesa con la carta'),
                  ),
                ],
              ),
              if (plafond != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: plafond,
                    minHeight: 6,
                    color: plafond >= 0.9 ? schema.error : schema.primary,
                    backgroundColor: schema.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Plafond usato: ${(plafond * 100).round()}% di '
                  '${Importo.formatta(s.carta.plafondMinimo!, valuta)}',
                  style: testo.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Avviso nel portafoglio collegato (o nella carta stessa): giorno e importo del
/// prossimo addebito. Sempre visibile quando c'è un debito.
class AvvisiCarte extends StatefulWidget {
  const AvvisiCarte({
    super.key,
    required this.sessione,
    required this.portafoglioId,
  });

  final Sessione sessione;
  final String portafoglioId;

  @override
  State<AvvisiCarte> createState() => _AvvisiCarteState();
}

class _AvvisiCarteState extends State<AvvisiCarte> {
  late final Stream<List<CartaConStato>> _carte = widget.sessione.carte
      .osserva();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CartaConStato>>(
      stream: _carte,
      builder: (context, snapshot) {
        final rilevanti = (snapshot.data ?? const <CartaConStato>[])
            .where(
              (c) =>
                  (c.carta.contoAddebitoId == widget.portafoglioId ||
                      c.carta.portafoglioId == widget.portafoglioId) &&
                  c.debitoTotale > 0,
            )
            .toList();
        if (rilevanti.isEmpty) {
          return const SizedBox.shrink();
        }
        final schema = Theme.of(context).colorScheme;
        return Column(
          children: [
            for (final c in rilevanti)
              Card(
                color: schema.secondaryContainer,
                child: ListTile(
                  leading: Icon(
                    Icons.credit_card,
                    color: schema.onSecondaryContainer,
                  ),
                  title: Text(
                    c.daAddebitare > 0
                        ? 'Il ${dataLeggibile(context, c.prossimoAddebito)} '
                              'verranno addebitati '
                              '${Importo.formatta(c.daAddebitare, c.portafoglio.valuta)}'
                        : 'Nessun addebito il '
                              '${dataLeggibile(context, c.prossimoAddebito)}',
                  ),
                  subtitle: Text(
                    'Carta "${c.portafoglio.nome}" su "${c.conto.nome}" · '
                    'debito totale '
                    '${Importo.formatta(c.debitoTotale, c.portafoglio.valuta)}',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Nuova carta o modifica.
Future<void> apriModuloCarta(
  BuildContext context,
  Sessione sessione, {
  CartaConStato? esistente,
}) => showDialog<void>(
  context: context,
  builder: (_) => _ModuloCarta(sessione: sessione, esistente: esistente),
);

class _ModuloCarta extends StatefulWidget {
  const _ModuloCarta({required this.sessione, this.esistente});

  final Sessione sessione;
  final CartaConStato? esistente;

  @override
  State<_ModuloCarta> createState() => _ModuloCartaState();
}

class _ModuloCartaState extends State<_ModuloCarta> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(
    text: widget.esistente?.portafoglio.nome ?? '',
  );
  late final _plafond = TextEditingController(
    text: widget.esistente?.carta.plafondMinimo == null
        ? ''
        : Importo.perModifica(widget.esistente!.carta.plafondMinimo!),
  );
  late String? _conto = widget.esistente?.carta.contoAddebitoId;
  late int _giorno = widget.esistente?.carta.giornoAddebito ?? 15;
  late int _chiusura = widget.esistente?.carta.giornoChiusura ?? 0;
  List<Portafoglio> _conti = const [];
  bool _salvataggio = false;

  @override
  void initState() {
    super.initState();
    _carica();
  }

  Future<void> _carica() async {
    final portafogli = await widget.sessione.contabilita
        .osservaPortafogli()
        .first;
    final carte = (await widget.sessione.carte.stati())
        .map((c) => c.portafoglio.id)
        .toSet();
    if (mounted) {
      setState(() {
        _conti = [
          for (final p in portafogli)
            if (!carte.contains(p.portafoglio.id)) p.portafoglio,
        ];
        _conto ??= _conti.firstOrNull?.id;
      });
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _plafond.dispose();
    super.dispose();
  }

  Future<void> _salva() async {
    if (_salvataggio || !_form.currentState!.validate()) {
      return;
    }
    final plafond = _plafond.text.trim().isEmpty
        ? null
        : Importo.leggi(_plafond.text);
    final servizio = widget.sessione.carte;
    setState(() => _salvataggio = true);
    try {
      if (widget.esistente == null) {
        await servizio.crea(
          nome: _nome.text,
          contoAddebitoId: _conto!,
          giornoAddebito: _giorno,
          giornoChiusura: _chiusura,
          plafond: plafond,
        );
      } else {
        await servizio.modifica(
          widget.esistente!.carta.id,
          nome: _nome.text,
          contoAddebitoId: _conto!,
          giornoAddebito: _giorno,
          giornoChiusura: _chiusura,
          plafond: plafond,
        );
      }
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

  Future<void> _archivia() async {
    final servizio = widget.sessione.carte;
    final carta = widget.esistente!;
    final messenger = ScaffoldMessenger.of(context);
    await servizio.archivia(carta.carta.id);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Carta "${carta.portafoglio.nome}" archiviata'),
          action: SnackBarAction(
            label: 'Annulla',
            onPressed: () =>
                servizio.archivia(carta.carta.id, archiviata: false),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final modifica = widget.esistente != null;
    return AlertDialog(
      title: Text(modifica ? 'Modifica carta' : 'Nuova carta di credito'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nome,
                  autofocus: !modifica,
                  decoration: const InputDecoration(
                    labelText: 'Nome della carta',
                    hintText: 'Es. Visa, Mastercard Oro, Amex',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Dai un nome alla carta'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _conto,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Conto da cui vengono prelevati i soldi',
                  ),
                  items: [
                    for (final p in _conti)
                      DropdownMenuItem(value: p.id, child: Text(p.nome)),
                  ],
                  onChanged: (v) => setState(() => _conto = v),
                  validator: (v) => v == null
                      ? 'Scegli il conto (crealo prima nella Panoramica)'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _giorno,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Giorno dell\'addebito sul conto',
                  ),
                  items: [
                    for (var g = 1; g <= 31; g++)
                      DropdownMenuItem(value: g, child: Text('Il giorno $g')),
                  ],
                  onChanged: (g) => setState(() => _giorno = g ?? _giorno),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _chiusura,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Spese incluse nell\'addebito',
                    helperText: 'Lo trovi sull\'estratto conto della carta',
                    helperMaxLines: 2,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('Fino a fine mese precedente'),
                    ),
                    for (var g = 1; g <= 28; g++)
                      DropdownMenuItem(
                        value: g,
                        child: Text('Fino al giorno $g del mese precedente'),
                      ),
                  ],
                  onChanged: (g) => setState(() => _chiusura = g ?? _chiusura),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _plafond,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Plafond (facoltativo)',
                    hintText: 'Es. 1.500,00',
                    suffixText: '€',
                  ),
                  validator: (v) =>
                      v != null &&
                          v.trim().isNotEmpty &&
                          Importo.leggi(v) == null
                      ? 'Scrivi un importo, per esempio 1.500,00'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (modifica)
          TextButton.icon(
            onPressed: _salvataggio ? null : _archivia,
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archivia'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _salvataggio ? null : _salva,
          child: Text(modifica ? 'Salva' : 'Aggiungi'),
        ),
      ],
    );
  }
}

/// Usato per escludere i portafogli carta dove serve un "conto".
Future<Set<String>> portafogliCarta(Sessione sessione) async =>
    (await sessione.carte.stati()).map((c) => c.portafoglio.id).toSet();

/// Nomi dei portafogli per id (utilità per le descrizioni).
Map<String, String> nomiPortafogli(List<PortafoglioConSaldo> portafogli) => {
  for (final p in portafogli) p.portafoglio.id: p.portafoglio.nome,
};
