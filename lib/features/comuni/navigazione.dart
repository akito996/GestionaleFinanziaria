import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/sessione.dart';
import '../carte/carte_pagina.dart';
import '../categorie/categorie_pagina.dart';
import '../prestiti/prestiti_pagina.dart';
import '../costo_vita/costo_vita_pagina.dart';
import '../home/home_pagina.dart';
import '../obiettivi/obiettivi_pagina.dart';
import 'icone.dart';

/// Pulsante "blocca" presente in ogni sezione: lucchetto aperto = archivio aperto.
class PulsanteBlocca extends StatelessWidget {
  const PulsanteBlocca({super.key, required this.sessione});

  final Sessione sessione;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Archivio aperto: tocca per bloccarlo',
      icon: const LucchettoAperto(),
      onPressed: () {
        ScaffoldMessenger.of(context).clearSnackBars();
        sessione.blocca();
      },
    );
  }
}

/// Da questa larghezza la navigazione è una barra laterale; sotto, una barra
/// in basso (telefono).
const larghezzaBarraLaterale = 700.0;

/// Sezioni dell'app: barra laterale su schermi larghi (Windows), barra in basso
/// sul telefono.
class Guscio extends StatefulWidget {
  const Guscio({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<Guscio> createState() => _GuscioState();
}

class _GuscioState extends State<Guscio> {
  int _sezione = 0;
  Timer? _controllo;

  @override
  void initState() {
    super.initState();
    // Se l'app resta aperta, le scadenze del giorno si registrano comunque.
    _controllo = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _registra(),
    );
  }

  @override
  void dispose() {
    _controllo?.cancel();
    super.dispose();
  }

  Future<void> _registra() async {
    if (widget.sessione.fase != FaseSessione.sbloccata) {
      return;
    }
    final n = await widget.sessione.pianificatore.registraScadute();
    if (n > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            n == 1
                ? 'Registrato 1 pagamento programmato'
                : 'Registrati $n pagamenti programmati',
          ),
        ),
      );
    }
  }

  static const _voci = [
    (Icons.dashboard_outlined, Icons.dashboard, 'Panoramica'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Costo della vita'),
    (Icons.credit_card_outlined, Icons.credit_card, 'Carte'),
    (Icons.request_quote_outlined, Icons.request_quote, 'Prestiti'),
    (Icons.savings_outlined, Icons.savings, 'Obiettivi'),
    (Icons.category_outlined, Icons.category, 'Categorie'),
  ];

  void _vaiA(int sezione) => setState(() => _sezione = sezione);

  /// Sezioni visibili nella barra in basso del telefono (le altre in "Altro").
  static const _inBarra = 4;

  Future<void> _apriAltro(BuildContext context) async {
    final scelta = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = _inBarra; i < _voci.length; i++)
              ListTile(
                leading: Icon(_voci[i].$1),
                title: Text(_voci[i].$3),
                selected: i == _sezione,
                onTap: () => Navigator.of(context).pop(i),
              ),
          ],
        ),
      ),
    );
    if (scelta != null) {
      _vaiA(scelta);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pagine = [
      HomePagina(sessione: widget.sessione, apriCostoVita: () => _vaiA(1)),
      CostoVitaPagina(sessione: widget.sessione),
      CartePagina(sessione: widget.sessione),
      PrestitiPagina(sessione: widget.sessione),
      ObiettiviPagina(sessione: widget.sessione),
      CategoriePagina(sessione: widget.sessione),
    ];
    final corpo = IndexedStack(index: _sezione, children: pagine);

    return LayoutBuilder(
      builder: (context, vincoli) {
        if (vincoli.maxWidth >= larghezzaBarraLaterale) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _sezione,
                  onDestinationSelected: _vaiA,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final (icona, selezionata, etichetta) in _voci)
                      NavigationRailDestination(
                        icon: Icon(icona),
                        selectedIcon: Icon(selezionata),
                        label: Text(etichetta),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: corpo),
              ],
            ),
          );
        }
        return Scaffold(
          body: corpo,
          // Telefono: le prime 4 sezioni in basso, le altre in "Altro".
          bottomNavigationBar: NavigationBar(
            selectedIndex: _sezione < _inBarra ? _sezione : _inBarra,
            onDestinationSelected: (i) =>
                i < _inBarra ? _vaiA(i) : _apriAltro(context),
            destinations: [
              for (final (icona, selezionata, etichetta) in _voci.take(
                _inBarra,
              ))
                NavigationDestination(
                  icon: Icon(icona),
                  selectedIcon: Icon(selezionata),
                  label: etichetta,
                ),
              const NavigationDestination(
                icon: Icon(Icons.more_horiz),
                label: 'Altro',
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "Ottobre 2026".
String meseLeggibile(BuildContext context, DateTime mese) {
  final testo = MaterialLocalizations.of(context).formatMonthYear(mese);
  return testo.isEmpty ? testo : testo[0].toUpperCase() + testo.substring(1);
}
