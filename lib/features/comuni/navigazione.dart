import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/db/notifiche.dart';
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
import '../impostazioni/impostazioni_pagina.dart';
import '../movimenti/movimenti_pagina.dart';
import '../notifiche/campanella.dart';
import '../sync/sync_pagina.dart';
import '../obiettivi/obiettivi_pagina.dart';
import '../sblocco/sblocco_rapido.dart';
import 'blocco_automatico.dart';
import 'firma_versione.dart';
import 'icone.dart';
import 'layout.dart';
import 'avvisi.dart';

/// Uno strumento del menu ☰ accanto al lucchetto, con la sua descrizione.
class Strumento {
  const Strumento({
    required this.icona,
    required this.titolo,
    required this.descrizione,
    required this.azione,
  });

  final Widget icona;
  final String titolo;
  final String descrizione;
  final VoidCallback azione;
}

/// In alto a destra in ogni sezione: la nuvola della sincronizzazione, la
/// campanella (solo se c'è una notifica da vedere), il lucchetto (archivio
/// aperto: tocca per bloccarlo) e il menu ☰ con gli altri strumenti
/// (notifiche e quelli della pagina, es. Esporta e Personalizza).
class PulsanteBlocca extends StatelessWidget {
  const PulsanteBlocca({
    super.key,
    required this.sessione,
    this.campanella = true,
    this.sincronizzazione = true,
    this.strumenti = const [],
  });

  final Sessione sessione;

  /// `false` nella pagina delle notifiche (ci sei già).
  final bool campanella;

  /// `false` nella pagina della sincronizzazione (ci sei già).
  final bool sincronizzazione;

  /// Strumenti della pagina, nel menu dopo "Notifiche".
  final List<Strumento> strumenti;

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
          // Tocco lungo: versione, licenza e codice sorgente.
          onLongPress: () => apriInformazioni(context),
        ),
        if (campanella || strumenti.isNotEmpty)
          MenuStrumenti(
            sessione: sessione,
            notifiche: campanella,
            strumenti: strumenti,
          ),
      ],
    );
  }
}

/// Il menu ☰: "Notifiche" (con quante sono da vedere) e gli strumenti della
/// pagina, ognuno con una riga che spiega a cosa serve.
class MenuStrumenti extends StatefulWidget {
  const MenuStrumenti({
    super.key,
    required this.sessione,
    required this.notifiche,
    required this.strumenti,
  });

  final Sessione sessione;
  final bool notifiche;
  final List<Strumento> strumenti;

  @override
  State<MenuStrumenti> createState() => _MenuStrumentiState();
}

class _MenuStrumentiState extends State<MenuStrumenti> {
  // Creato una volta sola: dopo il blocco non tocca più l'archivio.
  late final Stream<List<Notifica>> _notifiche = widget.sessione.notifiche
      .osserva();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Notifica>>(
      stream: widget.notifiche ? _notifiche : const Stream.empty(),
      builder: (context, snapshot) {
        final attive = (snapshot.data ?? const <Notifica>[])
            .where((n) => n.attiva)
            .length;
        Widget riga(Widget icona, String titolo, String descrizione) =>
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: icona,
              title: Text(titolo),
              subtitle: Text(descrizione),
            );
        return PopupMenuButton<int>(
          tooltip: 'Altri strumenti',
          icon: const Icon(Icons.menu),
          onSelected: (i) => i < 0
              ? apriPannelloNotifiche(context, widget.sessione)
              : widget.strumenti[i].azione(),
          itemBuilder: (context) => [
            if (widget.notifiche)
              PopupMenuItem(
                value: -1,
                child: riga(
                  Badge(
                    isLabelVisible: attive > 0,
                    label: Text('$attive'),
                    child: const Icon(Icons.notifications_none),
                  ),
                  'Notifiche',
                  attive == 0
                      ? 'Scadenze, conferme e avvisi'
                      : attive == 1
                      ? '1 da vedere'
                      : '$attive da vedere',
                ),
              ),
            for (final (i, s) in widget.strumenti.indexed)
              PopupMenuItem(
                value: i,
                child: riga(s.icona, s.titolo, s.descrizione),
              ),
          ],
        );
      },
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
  BloccoAutomatico? _blocco;

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
    // In secondo piano troppo a lungo: l'archivio si blocca (Impostazioni).
    _blocco = BloccoAutomatico(widget.sessione);
  }

  void _sincronizza() {
    if (widget.sessione.fase == FaseSessione.sbloccata) {
      widget.sessione.sync.sincronizza().ignore();
    }
  }

  Future<void> _avvisi() async {
    if (!mounted || widget.sessione.fase != FaseSessione.sbloccata) {
      return;
    }
    // Appena entrati con la password: proporre lo sblocco rapido (una volta).
    if (widget.sessione.prendiPropostaAttivazione()) {
      await proponiSbloccoRapido(context, widget.sessione);
    }
    if (mounted && widget.sessione.fase == FaseSessione.sbloccata) {
      await controllaAvvisiMaxi(context, widget.sessione);
    }
  }

  @override
  void dispose() {
    _controllo?.cancel();
    _sincronia?.cancel();
    _ciclo?.dispose();
    _blocco?.dispose();
    super.dispose();
  }

  Future<void> _registra() async {
    if (widget.sessione.fase != FaseSessione.sbloccata) {
      return;
    }
    final n = await widget.sessione.pianificatore.registraScadute();
    // Nel frattempo l'archivio può essersi bloccato (anche da solo).
    if (widget.sessione.fase != FaseSessione.sbloccata) {
      return;
    }
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
    (Icons.settings_outlined, Icons.settings, 'Impostazioni'),
  ];

  /// Sezioni visitate, per tornare indietro con il gesto (o il tasto) Indietro.
  final _storia = <int>[];

  /// Ultimo "indietro" sulla Panoramica: un secondo entro 2 secondi esce.
  DateTime? _ultimoIndietro;

  void _vaiA(int sezione) => setState(() {
    if (sezione != _sezione) {
      _storia
        ..remove(sezione)
        ..add(_sezione);
    }
    _sezione = sezione;
  });

  /// Indietro (gesto su Android): torna alla sezione di prima; dalla
  /// Panoramica, la prima volta avvisa e la seconda (entro 2 secondi) esce.
  void _indietro() {
    if (_storia.isNotEmpty || _sezione != 0) {
      setState(() => _sezione = _storia.isEmpty ? 0 : _storia.removeLast());
      return;
    }
    final adesso = DateTime.now();
    final prima = _ultimoIndietro;
    if (prima != null &&
        adesso.difference(prima) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _ultimoIndietro = adesso;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        avviso(
          content: const Text('Torna indietro ancora una volta per uscire'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

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
      ImpostazioniPagina(sessione: widget.sessione),
    ];
    final corpo = IndexedStack(index: _sezione, children: pagine);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (fatto, _) {
        if (!fatto) {
          _indietro();
        }
      },
      child: _struttura(corpo),
    );
  }

  Widget _struttura(Widget corpo) {
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
