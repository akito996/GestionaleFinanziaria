import 'package:flutter/material.dart';

import '../../core/db/archivio.dart';
import '../../core/db/carte_credito.dart';
import '../../core/db/contabilita.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../movimenti/riga_movimento.dart';
import 'portafoglio_pagina.dart';

/// Portafogli della Panoramica:
/// - i preferiti ⭐ in cima, sempre visibili (mai dentro un gruppo chiuso);
/// - poi quelli senza gruppo;
/// - poi i gruppi, richiudibili, con il totale (aperto/chiuso viene ricordato);
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
  late final Stream<List<CartaConStato>> _carte = widget.sessione.carte
      .osserva();
  final Map<String, bool> _aperti = {};

  static String _chiave(String gruppo) => 'gruppo_portafogli_aperto.$gruppo';

  Future<void> _caricaStato(String gruppo) async {
    if (_aperti.containsKey(gruppo)) {
      return;
    }
    _aperti[gruppo] = false; // predefinito: chiuso (schermata più pulita)
    final v = await widget.sessione.statistiche.preferenza(_chiave(gruppo));
    if (v != null && mounted) {
      setState(() => _aperti[gruppo] = v == '1');
    }
  }

  void _alterna(String gruppo) {
    final aperto = !(_aperti[gruppo] ?? false);
    setState(() => _aperti[gruppo] = aperto);
    widget.sessione.statistiche.salvaPreferenza(
      _chiave(gruppo),
      aperto ? '1' : '0',
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CartaConStato>>(
      stream: _carte,
      builder: (context, snapshot) {
        final carte = snapshot.data ?? const <CartaConStato>[];
        final idCarte = {for (final c in carte) c.portafoglio.id};
        final visibili = widget.portafogli
            .where(
              (p) =>
                  !idCarte.contains(p.portafoglio.id) &&
                  p.tipo.nome != tipoCartaDiCredito,
            )
            .toList();
        final preferiti = visibili
            .where((p) => p.portafoglio.preferito)
            .toList();
        final altri = visibili.where((p) => !p.portafoglio.preferito);
        final senzaGruppo = altri
            .where((p) => p.portafoglio.gruppo == null)
            .toList();
        final gruppi = <String, List<PortafoglioConSaldo>>{};
        for (final p in altri.where((p) => p.portafoglio.gruppo != null)) {
          gruppi.putIfAbsent(p.portafoglio.gruppo!, () => []).add(p);
        }
        final nomiGruppi = gruppi.keys.toList()..sort();
        for (final g in nomiGruppi) {
          _caricaStato(g);
        }

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
            for (final p in senzaGruppo) riga(p),
            for (final g in nomiGruppi)
              _Gruppo(
                nome: g,
                portafogli: gruppi[g]!,
                aperto: _aperti[g] ?? false,
                onAlterna: () => _alterna(g),
                riga: riga,
              ),
          ],
        );
      },
    );
  }
}

class _Gruppo extends StatelessWidget {
  const _Gruppo({
    required this.nome,
    required this.portafogli,
    required this.aperto,
    required this.onAlterna,
    required this.riga,
  });

  final String nome;
  final List<PortafoglioConSaldo> portafogli;
  final bool aperto;
  final VoidCallback onAlterna;
  final Widget Function(PortafoglioConSaldo) riga;

  @override
  Widget build(BuildContext context) {
    final valute = portafogli.map((p) => p.portafoglio.valuta).toSet();
    final totale = valute.length == 1
        ? Importo.formatta(
            portafogli.fold<int>(0, (t, p) => t + p.saldo),
            valute.single,
          )
        : '${portafogli.length} portafogli';
    final schema = Theme.of(context).colorScheme;
    return Card(
      color: schema.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: Icon(aperto ? Icons.folder_open : Icons.folder_outlined),
            title: Text(nome),
            subtitle: Text(
              '${portafogli.length} portafogl${portafogli.length == 1 ? 'io' : 'i'}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  totale,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Icon(aperto ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            onTap: onAlterna,
          ),
          if (aperto)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(children: [for (final p in portafogli) riga(p)]),
            ),
        ],
      ),
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
              subtitle: Text([voce.tipo.nome, ?p.gruppo].join(' · ')),
              trailing: Text(
                Importo.formatta(voce.saldo, p.valuta),
                style: testo.titleMedium?.copyWith(
                  color: voce.saldo < 0 ? schema.error : null,
                  fontFeatures: const [FontFeature.tabularFigures()],
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
