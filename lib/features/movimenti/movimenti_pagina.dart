import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/db/contabilita.dart';
import '../../core/db/tabelle.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../categorie/scelta_categoria.dart';
import '../comuni/campi.dart';
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

/// Tutti i movimenti, con la ricerca e i filtri per periodo, tipo, categoria
/// e portafoglio. In alto quanti sono e quanto è entrato e uscito.
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
  _Periodo _periodo = _Periodo.sempre;
  DateTime? _dal;
  DateTime? _al;
  String? _effetto;
  String? _categoriaId;
  String _categoriaNome = '';
  Set<String>? _categorie;
  String? _portafoglioId;
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

  (DateTime?, DateTime?) _intervallo() {
    final oggi = DateUtils.dateOnly(DateTime.now());
    return switch (_periodo) {
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
      _Periodo.date => (_dal, _al),
    };
  }

  Stream<RisultatoMovimenti> _cerca() {
    final (da, a) = _intervallo();
    return _sessione.contabilita.osservaMovimentiFiltrati(
      FiltroMovimenti(
        da: da,
        a: a,
        testo: _ricerca.text,
        categorie: _categorie,
        portafoglioId: _portafoglioId,
        effetto: _effetto,
      ),
      limite: _limite,
    );
  }

  /// Cambia un filtro e rifà la ricerca dall'inizio.
  void _filtra(VoidCallback modifica) => setState(() {
    modifica();
    _limite = _pagina;
    _risultati = _cerca();
  });

  bool get _conFiltri =>
      _ricerca.text.isNotEmpty ||
      _periodo != _Periodo.sempre ||
      _effetto != null ||
      _categoriaId != null ||
      _portafoglioId != null;

  void _togliFiltri() => _filtra(() {
    _ricerca.clear();
    _periodo = _Periodo.sempre;
    _dal = null;
    _al = null;
    _effetto = null;
    _categoriaId = null;
    _categorie = null;
    _portafoglioId = null;
  });

  Future<void> _scegliCategoria() async {
    final scelta = await scegliCategoria(
      context,
      _sessione,
      selezionata: _categoriaId,
      titolo: 'Filtra per categoria',
    );
    if (scelta.annullata) {
      return;
    }
    final albero = AlberoCategorie(
      await _sessione.contabilita.osservaCategorie().first,
    );
    final id = scelta.id;
    _filtra(() {
      _categoriaId = id;
      _categorie = id == null ? null : albero.discendenti(id);
      _categoriaNome = id == null ? '' : albero.percorso(id);
    });
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
                  _filtri(context),
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
                          _conFiltri
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
                                portafoglioId: _portafoglioId,
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

  Widget _filtri(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    ChoiceChip tipo(String? effetto, String etichetta) => ChoiceChip(
      label: Text(etichetta),
      selected: _effetto == effetto,
      onSelected: (_) => _filtra(() => _effetto = effetto),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ricerca,
          onChanged: (_) {
            // Si cerca quando smetti di scrivere, non a ogni lettera.
            _attesa?.cancel();
            _attesa = Timer(
              const Duration(milliseconds: 300),
              () => _filtra(() {}),
            );
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Cerca: descrizione, categoria, portafoglio o importo',
            suffixIcon: _ricerca.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Cancella la ricerca',
                    icon: const Icon(Icons.clear),
                    onPressed: () => _filtra(_ricerca.clear),
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
                selected: _periodo == p,
                onSelected: (_) => _filtra(() {
                  _periodo = p;
                  if (p == _Periodo.date && _dal == null) {
                    final oggi = DateUtils.dateOnly(DateTime.now());
                    _dal = DateTime(oggi.year, oggi.month);
                    _al = oggi;
                  }
                }),
              ),
          ],
        ),
        if (_periodo == _Periodo.date) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CampoData(
                  etichetta: 'Dal',
                  valore: _dal,
                  ultimo: _al,
                  onChanged: (d) => _filtra(() => _dal = d),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CampoData(
                  etichetta: 'Al',
                  valore: _al,
                  primo: _dal,
                  onChanged: (d) => _filtra(() => _al = d),
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
          builder: (context, vincoli) {
            final categoria = InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: _scegliCategoria,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  suffixIcon: _categoriaId == null
                      ? const Icon(Icons.arrow_drop_down)
                      : IconButton(
                          tooltip: 'Tutte le categorie',
                          icon: const Icon(Icons.clear),
                          onPressed: () => _filtra(() {
                            _categoriaId = null;
                            _categorie = null;
                          }),
                        ),
                ),
                child: Text(
                  _categoriaId == null
                      ? 'Tutte (con le sottocategorie)'
                      : _categoriaNome,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
            final portafoglio = FutureBuilder<List<PortafoglioConSaldo>>(
              future: _portafogli,
              builder: (context, snapshot) {
                final portafogli = snapshot.data ?? const [];
                return DropdownButtonFormField<String?>(
                  key: ValueKey(
                    'portafoglio-$_portafoglioId-${portafogli.length}',
                  ),
                  isExpanded: true,
                  initialValue: _portafoglioId,
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
                  onChanged: (id) => _filtra(() => _portafoglioId = id),
                );
              },
            );
            if (vincoli.maxWidth < Larghezze.media) {
              return Column(
                children: [categoria, const SizedBox(height: 12), portafoglio],
              );
            }
            return Row(
              children: [
                Expanded(child: categoria),
                const SizedBox(width: 12),
                Expanded(child: portafoglio),
              ],
            );
          },
        ),
        if (_conFiltri)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: _togliFiltri,
              icon: Icon(Icons.filter_alt_off_outlined, color: schema.primary),
              label: const Text('Togli i filtri'),
            ),
          ),
      ],
    );
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
