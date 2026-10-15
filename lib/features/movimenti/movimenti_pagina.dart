import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/db/contabilita.dart';
import '../../core/db/tabelle.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../categorie/scelta_categoria.dart';
import '../comuni/campi.dart';
import '../comuni/filtri.dart';
import '../comuni/layout.dart';
import '../comuni/navigazione.dart';
import 'movimento_modulo.dart';
import 'riga_movimento.dart';

/// Periodi già pronti (o date a scelta).
enum _Periodo {
  sempre('Sempre'),
  questoMese('Questo mese'),
  meseScorso('Mese scorso'),
  treMesi('Ultimi 3 mesi'),
  anno("Quest'anno"),
  date('Scegli le date');

  const _Periodo(this.etichetta);

  final String etichetta;
}

/// Le scelte di ricerca e filtro (una copia di lavoro nel pannello compatto).
class _Filtri {
  String testo = '';
  _Periodo periodo = _Periodo.sempre;
  DateTime? dal;
  DateTime? al;
  String? effetto;
  String? categoriaId;
  String categoriaNome = '';
  Set<String>? categorie;
  String? portafoglioId;
  String portafoglioNome = '';

  _Filtri copia() => _Filtri()
    ..testo = testo
    ..periodo = periodo
    ..dal = dal
    ..al = al
    ..effetto = effetto
    ..categoriaId = categoriaId
    ..categoriaNome = categoriaNome
    ..categorie = categorie
    ..portafoglioId = portafoglioId
    ..portafoglioNome = portafoglioNome;

  /// Quanti filtri sono attivi.
  int get attivi => [
    testo.trim().isNotEmpty,
    periodo != _Periodo.sempre,
    effetto != null,
    categoriaId != null,
    portafoglioId != null,
  ].where((a) => a).length;

  (DateTime?, DateTime?) intervallo() {
    final oggi = DateUtils.dateOnly(DateTime.now());
    return switch (periodo) {
      _Periodo.sempre => (null, null),
      _Periodo.questoMese => (
        DateTime(oggi.year, oggi.month),
        DateTime(oggi.year, oggi.month + 1, 0),
      ),
      _Periodo.meseScorso => (
        DateTime(oggi.year, oggi.month - 1),
        DateTime(oggi.year, oggi.month, 0),
      ),
      _Periodo.treMesi => (DateTime(oggi.year, oggi.month - 2), oggi),
      _Periodo.anno => (DateTime(oggi.year), DateTime(oggi.year, 12, 31)),
      _Periodo.date => (dal, al),
    };
  }

  /// "Ultimi 3 mesi · Uscite · Spesa · «lidl»".
  String descrizione(BuildContext context) {
    final parti = [
      if (periodo == _Periodo.date && dal != null && al != null)
        '${dataLeggibile(context, dal!)} – ${dataLeggibile(context, al!)}'
      else if (periodo != _Periodo.sempre)
        periodo.etichetta,
      switch (effetto) {
        EffettoSaldo.entrata => 'Entrate',
        EffettoSaldo.uscita => 'Uscite',
        EffettoSaldo.trasferimento => 'Trasferimenti',
        _ => '',
      },
      categoriaNome,
      portafoglioNome,
      if (testo.trim().isNotEmpty) '«${testo.trim()}»',
    ].where((p) => p.isNotEmpty);
    return parti.isEmpty ? 'Tutti i movimenti' : parti.join(' · ');
  }
}

/// Tutti i movimenti, con la ricerca e i filtri per periodo, tipo, categoria
/// e portafoglio. In alto quanti sono e quanto è entrato e uscito.
///
/// Sul PC i filtri sono nella pagina e agiscono subito; su telefono e tablet
/// stanno nel pannello "Filtri" e agiscono con "Applica".
class MovimentiPagina extends StatefulWidget {
  const MovimentiPagina({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<MovimentiPagina> createState() => _MovimentiPaginaState();
}

class _MovimentiPaginaState extends State<MovimentiPagina> {
  static const _pagina = 300;

  final _ricerca = TextEditingController();
  Timer? _attesa;
  _Filtri _filtri = _Filtri();
  int _limite = _pagina;
  late Stream<RisultatoMovimenti> _risultati = _cerca();
  late final Future<List<PortafoglioConSaldo>> _portafogli = widget
      .sessione
      .contabilita
      .osservaPortafogli()
      .first;

  Sessione get _sessione => widget.sessione;

  @override
  void dispose() {
    _attesa?.cancel();
    _ricerca.dispose();
    super.dispose();
  }

  Stream<RisultatoMovimenti> _cerca() {
    final f = _filtri;
    final (da, a) = f.intervallo();
    return _sessione.contabilita.osservaMovimentiFiltrati(
      FiltroMovimenti(
        da: da,
        a: a,
        testo: f.testo,
        categorie: f.categorie,
        portafoglioId: f.portafoglioId,
        effetto: f.effetto,
      ),
      limite: _limite,
    );
  }

  /// Cambia i filtri e rifà la ricerca dall'inizio.
  void _filtra(VoidCallback modifica) => setState(() {
    modifica();
    _limite = _pagina;
    _risultati = _cerca();
  });

  void _togliFiltri() => _filtra(() {
    _filtri = _Filtri();
    _ricerca.clear();
  });

  /// Telefono e tablet: le scelte su una copia, valide solo con "Applica".
  Future<void> _apriPannello() async {
    final bozza = _filtri.copia();
    final ricerca = TextEditingController(text: bozza.testo);
    final applica = await apriPannelloFiltri(
      context,
      titolo: 'Filtri',
      azzera: () {
        final vuoti = _Filtri();
        bozza
          ..testo = vuoti.testo
          ..periodo = vuoti.periodo
          ..dal = null
          ..al = null
          ..effetto = null
          ..categoriaId = null
          ..categoriaNome = ''
          ..categorie = null
          ..portafoglioId = null
          ..portafoglioNome = '';
        ricerca.clear();
      },
      campi: (context, aggiorna) => _campi(
        context,
        bozza,
        cambia: aggiorna,
        ricerca: ricerca,
        onTesto: (t) => aggiorna(() => bozza.testo = t),
      ),
    );
    ricerca.dispose();
    if (applica) {
      _filtra(() {
        _filtri = bozza;
        _ricerca.text = bozza.testo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    void nuovo() => apriModuloMovimento(context, _sessione);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): nuovo,
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Movimenti'),
          actions: [PulsanteBlocca(sessione: _sessione)],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab-movimenti',
          onPressed: nuovo,
          tooltip: 'Nuovo movimento (Ctrl+N)',
          icon: const Icon(Icons.add),
          label: const Text('Movimento'),
        ),
        body: StreamBuilder<RisultatoMovimenti>(
          stream: _risultati,
          builder: (context, snapshot) {
            final r = snapshot.data;
            return LayoutBuilder(
              builder: (context, vincoli) => ListView(
                padding: marginiPagina(vincoli),
                children: [
                  if (filtriCompatti(vincoli))
                    BarraFiltri(
                      attivi: _filtri.attivi,
                      descrizione: _filtri.descrizione(context),
                      onApri: _apriPannello,
                      onTogli: _togliFiltri,
                    )
                  else
                    ..._campiInPagina(context),
                  const SizedBox(height: 12),
                  if (r == null)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    _Riepilogo(risultato: r),
                    const SizedBox(height: 8),
                    if (r.movimenti.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _filtri.attivi > 0
                              ? 'Nessun movimento con questi filtri.'
                              : 'Ancora nessun movimento.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (final m in r.movimenti)
                              RigaMovimento(
                                key: ValueKey(m.movimento.id),
                                sessione: _sessione,
                                dettaglio: m,
                                portafoglioId: _filtri.portafoglioId,
                              ),
                          ],
                        ),
                      ),
                    if (!r.completo)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Center(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() {
                              _limite += _pagina;
                              _risultati = _cerca();
                            }),
                            icon: const Icon(Icons.expand_more),
                            label: Text(
                              'Mostra altri '
                              '(${r.movimenti.length} di ${r.totale})',
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// PC: i filtri nella pagina, agiscono subito (la ricerca quando smetti di
  /// scrivere).
  List<Widget> _campiInPagina(BuildContext context) => [
    ..._campi(
      context,
      _filtri,
      cambia: _filtra,
      ricerca: _ricerca,
      onTesto: (t) {
        _attesa?.cancel();
        _attesa = Timer(
          const Duration(milliseconds: 300),
          () => _filtra(() => _filtri.testo = t),
        );
      },
    ),
    if (_filtri.attivi > 0)
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: TextButton.icon(
          onPressed: _togliFiltri,
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Togli i filtri'),
        ),
      ),
  ];

  /// Ricerca e opzioni su [f]; [cambia] le applica (subito o nella copia).
  List<Widget> _campi(
    BuildContext context,
    _Filtri f, {
    required void Function(VoidCallback) cambia,
    required TextEditingController ricerca,
    required ValueChanged<String> onTesto,
  }) {
    ChoiceChip tipo(String? effetto, String etichetta) => ChoiceChip(
      label: Text(etichetta),
      selected: f.effetto == effetto,
      onSelected: (_) => cambia(() => f.effetto = effetto),
    );
    Future<void> scegliCategoriaPer() async {
      final scelta = await scegliCategoria(
        context,
        _sessione,
        selezionata: f.categoriaId,
        titolo: 'Filtra per categoria',
      );
      if (scelta.annullata) {
        return;
      }
      final albero = AlberoCategorie(
        await _sessione.contabilita.osservaCategorie().first,
      );
      final id = scelta.id;
      cambia(() {
        f.categoriaId = id;
        f.categorie = id == null ? null : albero.discendenti(id);
        f.categoriaNome = id == null ? '' : albero.percorso(id);
      });
    }

    final categoria = InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: scegliCategoriaPer,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Categoria',
          suffixIcon: f.categoriaId == null
              ? const Icon(Icons.arrow_drop_down)
              : IconButton(
                  tooltip: 'Tutte le categorie',
                  icon: const Icon(Icons.clear),
                  onPressed: () => cambia(() {
                    f.categoriaId = null;
                    f.categorie = null;
                    f.categoriaNome = '';
                  }),
                ),
        ),
        child: Text(
          f.categoriaId == null
              ? 'Tutte (con le sottocategorie)'
              : f.categoriaNome,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    final portafoglio = FutureBuilder<List<PortafoglioConSaldo>>(
      future: _portafogli,
      builder: (context, snapshot) {
        final portafogli = snapshot.data ?? const [];
        return DropdownButtonFormField<String?>(
          key: ValueKey('portafoglio-${f.portafoglioId}-${portafogli.length}'),
          isExpanded: true,
          initialValue: f.portafoglioId,
          decoration: const InputDecoration(labelText: 'Portafoglio'),
          items: [
            const DropdownMenuItem<String?>(child: Text('Tutti')),
            for (final p in portafogli)
              DropdownMenuItem<String?>(
                value: p.portafoglio.id,
                child: Text(
                  p.portafoglio.nome,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (id) => cambia(() {
            f.portafoglioId = id;
            f.portafoglioNome = id == null
                ? ''
                : portafogli
                      .firstWhere((p) => p.portafoglio.id == id)
                      .portafoglio
                      .nome;
          }),
        );
      },
    );
    return [
      TextField(
        controller: ricerca,
        onChanged: onTesto,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Cerca: descrizione, categoria, portafoglio o importo',
          suffixIcon: ricerca.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Cancella la ricerca',
                  icon: const Icon(Icons.clear),
                  onPressed: () => cambia(() {
                    ricerca.clear();
                    f.testo = '';
                  }),
                ),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final p in _Periodo.values)
            ChoiceChip(
              label: Text(p.etichetta),
              selected: f.periodo == p,
              onSelected: (_) => cambia(() {
                f.periodo = p;
                if (p == _Periodo.date && f.dal == null) {
                  final oggi = DateUtils.dateOnly(DateTime.now());
                  f.dal = DateTime(oggi.year, oggi.month);
                  f.al = oggi;
                }
              }),
            ),
        ],
      ),
      if (f.periodo == _Periodo.date) ...[
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CampoData(
                etichetta: 'Dal',
                valore: f.dal,
                ultimo: f.al,
                onChanged: (d) => cambia(() => f.dal = d),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CampoData(
                etichetta: 'Al',
                valore: f.al,
                primo: f.dal,
                onChanged: (d) => cambia(() => f.al = d),
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          tipo(null, 'Tutti'),
          tipo(EffettoSaldo.entrata, 'Entrate'),
          tipo(EffettoSaldo.uscita, 'Uscite'),
          tipo(EffettoSaldo.trasferimento, 'Trasferimenti'),
        ],
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, vincoli) => vincoli.maxWidth < Larghezze.media
            ? Column(
                children: [categoria, const SizedBox(height: 12), portafoglio],
              )
            : Row(
                children: [
                  Expanded(child: categoria),
                  const SizedBox(width: 12),
                  Expanded(child: portafoglio),
                ],
              ),
      ),
    ];
  }
}

/// "12 movimenti · Entrate +1.808,00 € · Uscite −352,00 €".
class _Riepilogo extends StatelessWidget {
  const _Riepilogo({required this.risultato});

  final RisultatoMovimenti risultato;

  @override
  Widget build(BuildContext context) {
    final r = risultato;
    final stile = Theme.of(context).textTheme.bodyMedium;
    const cifre = [FontFeature.tabularFigures()];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text.rich(
        TextSpan(
          style: stile,
          children: [
            TextSpan(
              text: r.totale == 1 ? '1 movimento' : '${r.totale} movimenti',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const TextSpan(text: ' · Entrate '),
            TextSpan(
              text: Importo.formatta(r.entrate, 'EUR', conSegno: true),
              style: TextStyle(
                color: coloreEntrata(context),
                fontWeight: FontWeight.w600,
                fontFeatures: cifre,
              ),
            ),
            const TextSpan(text: ' · Uscite '),
            TextSpan(
              text: Importo.formatta(-r.uscite, 'EUR'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
                fontFeatures: cifre,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
