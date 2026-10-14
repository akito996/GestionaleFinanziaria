import 'package:flutter/material.dart';

import '../../core/db/archivio.dart';
import '../../core/db/carte_credito.dart';
import '../../core/db/contabilita.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../movimenti/riga_movimento.dart';
import 'portafoglio_pagina.dart';

/// Portafogli mostrati nella Panoramica: tutti tranne le carte di credito
/// (che compaiono come avviso nel conto collegato).
List<PortafoglioConSaldo> portafogliVisibili(
  List<PortafoglioConSaldo> portafogli,
  Set<String> idCarte,
) => [
  for (final p in portafogli)
    if (!idCarte.contains(p.portafoglio.id) &&
        p.tipo.nome != tipoCartaDiCredito)
      p,
];

/// Portafogli della Panoramica:
/// - i preferiti ⭐ in cima, sempre visibili;
/// - gli altri dietro "Mostra altro" / "Mostra meno" (la scelta è ricordata);
///   senza preferiti, da chiuso se ne vedono i primi [_minimoVisibili];
/// - le carte di credito non compaiono: il loro avviso sta nel conto collegato.
class ElencoPortafogli extends StatefulWidget {
  const ElencoPortafogli({
    super.key,
    required this.sessione,
    required this.portafogli,
  });

  final Sessione sessione;
  final List<PortafoglioConSaldo> portafogli;

  @override
  State<ElencoPortafogli> createState() => _ElencoPortafogliState();
}

class _ElencoPortafogliState extends State<ElencoPortafogli> {
  static const _preferenza = 'panoramica.portafogli.tutti';
  static const _minimoVisibili = 3;

  late final Stream<List<CartaConStato>> _carte = widget.sessione.carte
      .osserva();

  /// `false` = "mostra meno" (predefinito: schermata più pulita).
  bool _tutti = false;

  @override
  void initState() {
    super.initState();
    widget.sessione.statistiche.preferenza(_preferenza).then((v) {
      if (mounted && v == '1') {
        setState(() => _tutti = true);
      }
    });
  }

  void _alterna() {
    setState(() => _tutti = !_tutti);
    widget.sessione.statistiche.salvaPreferenza(
      _preferenza,
      _tutti ? '1' : '0',
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CartaConStato>>(
      stream: _carte,
      builder: (context, snapshot) {
        final carte = snapshot.data ?? const <CartaConStato>[];
        final idCarte = {for (final c in carte) c.portafoglio.id};
        final visibili = portafogliVisibili(widget.portafogli, idCarte);
        final preferiti = [
          for (final p in visibili)
            if (p.portafoglio.preferito) p,
        ];
        final altri = [
          for (final p in visibili)
            if (!p.portafoglio.preferito) p,
        ];
        // Da chiuso: solo i preferiti; senza preferiti, i primi tre.
        final sempre = preferiti.isEmpty
            ? altri.take(_minimoVisibili).toList()
            : const <PortafoglioConSaldo>[];
        final nascosti = altri.skip(sempre.length).toList();

        Widget riga(PortafoglioConSaldo p) => _RigaPortafoglio(
          sessione: widget.sessione,
          voce: p,
          carte: [
            for (final c in carte)
              if (c.carta.contoAddebitoId == p.portafoglio.id &&
                  c.debitoTotale > 0)
                c,
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final p in preferiti) riga(p),
            for (final p in sempre) riga(p),
            if (_tutti)
              for (final p in nascosti) riga(p),
            if (nascosti.isNotEmpty)
              Align(
                child: TextButton.icon(
                  onPressed: _alterna,
                  icon: Icon(_tutti ? Icons.expand_less : Icons.expand_more),
                  label: Text(
                    _tutti
                        ? 'Mostra meno'
                        : 'Mostra altro (${nascosti.length} '
                              'portafogl${nascosti.length == 1 ? 'io' : 'i'})',
                  ),
                ),
              ),
            if (nascosti.isNotEmpty && preferiti.isEmpty && !_tutti)
              Text(
                'Tocca ☆ su un portafoglio per tenerlo sempre in vista.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        );
      },
    );
  }
}

class _RigaPortafoglio extends StatelessWidget {
  const _RigaPortafoglio({
    required this.sessione,
    required this.voce,
    required this.carte,
  });

  final Sessione sessione;
  final PortafoglioConSaldo voce;

  /// Carte con debito che vengono addebitate su questo conto.
  final List<CartaConStato> carte;

  @override
  Widget build(BuildContext context) {
    final p = voce.portafoglio;
    final testo = Theme.of(context).textTheme;
    final schema = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                PortafoglioPagina(sessione: sessione, portafoglioId: p.id),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: IconButton(
                tooltip: p.preferito
                    ? 'Togli dai preferiti'
                    : 'Aggiungi ai preferiti',
                icon: Icon(
                  p.preferito ? Icons.star : Icons.star_border,
                  color: p.preferito ? const Color(0xFFEDA100) : null,
                ),
                onPressed: () =>
                    sessione.contabilita.impostaPreferito(p.id, !p.preferito),
              ),
              title: Text(p.nome),
              subtitle: Text(voce.tipo.nome),
              // Un saldo molto lungo si rimpicciolisce invece di schiacciare
              // il nome (telefoni piccoli).
              trailing: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    Importo.formatta(voce.saldo, p.valuta),
                    style: testo.titleMedium?.copyWith(
                      color: voce.saldo < 0 ? schema.error : null,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
            for (final c in carte)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: schema.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.credit_card,
                      size: 18,
                      color: schema.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.daAddebitare > 0
                            ? 'Carta "${c.portafoglio.nome}": '
                                  '${Importo.formatta(c.daAddebitare, c.portafoglio.valuta)} '
                                  'verranno addebitati il '
                                  '${dataLeggibile(context, c.prossimoAddebito)}'
                            : 'Carta "${c.portafoglio.nome}": '
                                  '${Importo.formatta(c.debitoTotale, c.portafoglio.valuta)} '
                                  'di spese, nel prossimo estratto conto',
                        style: TextStyle(color: schema.onSecondaryContainer),
                      ),
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
