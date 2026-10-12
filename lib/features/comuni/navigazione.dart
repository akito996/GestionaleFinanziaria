import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/sessione.dart';
import '../carte/carte_pagina.dart';
import '../categorie/categorie_pagina.dart';
import '../prestiti/avviso_maxi.dart';
import '../prestiti/prestiti_pagina.dart';
import '../costo_vita/costo_vita_pagina.dart';
import '../home/home_pagina.dart';
import '../obiettivi/obiettivi_pagina.dart';
import 'icone.dart';
import 'layout.dart';

/// Pulsante "blocca" presente in ogni sezione: lucchetto aperto = archivio
/// aperto. Accanto, la campanella delle decisioni in sospeso (maxi rate).
class PulsanteBlocca extends StatelessWidget {
  const PulsanteBlocca({super.key, required this.sessione});

  final Sessione sessione;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CampanellaMaxi(sessione: sessione),
        IconButton(
          tooltip: 'Archivio aperto: tocca per bloccarlo',
          icon: const LucchettoAperto(),
          onPressed: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            sessione.blocca();
          },
        ),
      ],
    );
  }
}

/// Da questa larghezza la navigazione è una barra laterale; sotto, una barra
/// in basso (telefono in verticale).
const larghezzaBarraLaterale = Larghezze.media;

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
    // All'apertura: le decisioni da prendere (es. maxi rata in arrivo).
    WidgetsBinding.instance.addPostFrameCallback((_) => _avvisi());
  }

  Future<void> _avvisi() async {
    if (mounted && widget.sessione.fase == FaseSessione.sbloccata) {
      await controllaAvvisiMaxi(context, widget.sessione);
    }
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
    // Se l'app resta aperta per giorni, le richieste rimandate tornano.
    await _avvisi();
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
                // Scorrevole: sul telefono in orizzontale le voci non stanno
                // tutte in altezza.
                LayoutBuilder(
                  builder: (context, barra) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: barra.maxHeight),
                      child: IntrinsicHeight(
                        child: NavigationRail(
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
                      ),
                    ),
                  ),
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
