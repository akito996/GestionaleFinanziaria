import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/db/tabelle.dart';
import '../../core/sessione.dart';
import '../../core/sync/sincronizzazione.dart';
import '../carte/carte_pagina.dart';
import '../categorie/categorie_pagina.dart';
import '../prestiti/avviso_maxi.dart';
import '../prestiti/prestiti_pagina.dart';
import '../report/report_pagina.dart';
import '../costo_vita/costo_vita_pagina.dart';
import '../home/home_pagina.dart';
import '../movimenti/movimenti_pagina.dart';
import '../notifiche/campanella.dart';
import '../sync/sync_pagina.dart';
import '../obiettivi/obiettivi_pagina.dart';
import 'icone.dart';
import 'layout.dart';
import 'avvisi.dart';

/// Pulsante "blocca" presente in ogni sezione: lucchetto aperto = archivio
/// aperto. Accanto, la campanella delle notifiche.
class PulsanteBlocca extends StatelessWidget {
  const PulsanteBlocca({
    super.key,
    required this.sessione,
    this.campanella = true,
    this.sincronizzazione = true,
  });

  final Sessione sessione;

  /// `false` nella pagina delle notifiche (ci sei già).
  final bool campanella;

  /// `false` nella pagina della sincronizzazione (ci sei già).
  final bool sincronizzazione;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sincronizzazione) IconaSync(sessione: sessione),
        if (campanella) CampanellaNotifiche(sessione: sessione),
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
  Timer? _sincronia;
  AppLifecycleListener? _ciclo;

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
    // Sincronizzazione con gli altri dispositivi: ogni 5 minuti, quando l'app
    // va in secondo piano (invia le ultime modifiche) e quando torna.
    _sincronia = Timer.periodic(
      Sincronizzazione.intervallo,
      (_) => _sincronizza(),
    );
    _ciclo = AppLifecycleListener(
      onPause: _sincronizza,
      onResume: _sincronizza,
    );
  }

  void _sincronizza() {
    if (widget.sessione.fase == FaseSessione.sbloccata) {
      widget.sessione.sync.sincronizza().ignore();
    }
  }

  Future<void> _avvisi() async {
    if (mounted && widget.sessione.fase == FaseSessione.sbloccata) {
      await controllaAvvisiMaxi(context, widget.sessione);
    }
  }

  @override
  void dispose() {
    _controllo?.cancel();
    _sincronia?.cancel();
    _ciclo?.dispose();
    super.dispose();
  }

  Future<void> _registra() async {
    if (widget.sessione.fase != FaseSessione.sbloccata) {
      return;
    }
    final n = await widget.sessione.pianificatore.registraScadute();
    // A cavallo di fine mese: il report del mese appena concluso.
    await widget.sessione.report.aggiorna();
    // Se l'app resta aperta per giorni, le richieste rimandate tornano.
    await _avvisi();
    if (n > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        avviso(
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
    (Icons.swap_vert_circle_outlined, Icons.swap_vert_circle, 'Movimenti'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Costo della vita'),
    (Icons.trending_up_outlined, Icons.trending_up, 'Entrate'),
    (Icons.credit_card_outlined, Icons.credit_card, 'Carte'),
    (Icons.request_quote_outlined, Icons.request_quote, 'Prestiti'),
    (Icons.savings_outlined, Icons.savings, 'Obiettivi'),
    (Icons.assessment_outlined, Icons.assessment, 'Report'),
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
      HomePagina(
        sessione: widget.sessione,
        apriMovimenti: () => _vaiA(1),
        apriCostoVita: () => _vaiA(2),
        apriEntrate: () => _vaiA(3),
      ),
      MovimentiPagina(sessione: widget.sessione),
      CostoVitaPagina(sessione: widget.sessione),
      CostoVitaPagina(sessione: widget.sessione, natura: NaturaVoce.entrata),
      CartePagina(sessione: widget.sessione),
      PrestitiPagina(sessione: widget.sessione),
      ObiettiviPagina(sessione: widget.sessione),
      ReportPagina(sessione: widget.sessione),
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
