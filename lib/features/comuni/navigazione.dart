import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/sessione.dart';
import '../categorie/categorie_pagina.dart';
import '../costo_vita/costo_vita_pagina.dart';
import '../home/home_pagina.dart';
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
    (Icons.category_outlined, Icons.category, 'Categorie'),
  ];

  void _vaiA(int sezione) => setState(() => _sezione = sezione);

  @override
  Widget build(BuildContext context) {
    final pagine = [
      HomePagina(sessione: widget.sessione, apriCostoVita: () => _vaiA(1)),
      CostoVitaPagina(sessione: widget.sessione),
      CategoriePagina(sessione: widget.sessione),
    ];
    final corpo = IndexedStack(index: _sezione, children: pagine);

    return LayoutBuilder(
      builder: (context, vincoli) {
        if (vincoli.maxWidth >= 700) {
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
          bottomNavigationBar: NavigationBar(
            selectedIndex: _sezione,
            onDestinationSelected: _vaiA,
            destinations: [
              for (final (icona, selezionata, etichetta) in _voci)
                NavigationDestination(
                  icon: Icon(icona),
                  selectedIcon: Icon(selezionata),
                  label: etichetta,
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
