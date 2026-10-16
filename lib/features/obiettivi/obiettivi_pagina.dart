import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/db/archivio.dart';
import '../../core/db/contabilita.dart';
import '../../core/db/obiettivi.dart';
import '../../core/db/tabelle.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../comuni/sezioni.dart';
import '../comuni/campi.dart';
import '../comuni/errori.dart';
import '../comuni/layout.dart';
import '../comuni/navigazione.dart';
import '../movimenti/riga_movimento.dart';
import '../comuni/avvisi.dart';

/// Obiettivi di risparmio personali e collette con altre persone.
class ObiettiviPagina extends StatefulWidget {
  const ObiettiviPagina({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<ObiettiviPagina> createState() => _ObiettiviPaginaState();
}

class _ObiettiviPaginaState extends State<ObiettiviPagina> {
  late final Stream<List<ObiettivoConStato>> _obiettivi = widget
      .sessione
      .obiettivi
      .osserva();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obiettivi e collette'),
        actions: [PulsanteBlocca(sessione: widget.sessione)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-obiettivi',
        onPressed: () => apriModuloObiettivo(context, widget.sessione),
        icon: const Icon(Icons.add),
        label: const Text('Nuovo'),
      ),
      body: StreamBuilder<List<ObiettivoConStato>>(
        stream: _obiettivi,
        builder: (context, snapshot) {
          final obiettivi = snapshot.data;
          if (obiettivi == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (obiettivi.isEmpty) {
            return const _Vuoto();
          }
          return ElencoRipiegabile(
            sessione: widget.sessione,
            chiave: 'obiettivi',
            voci: [
              for (final o in obiettivi)
                VoceRipiegabile(
                  id: o.obiettivo.id,
                  titolo: o.obiettivo.nome,
                  sottotitolo: o.raggiunto
                      ? 'Raggiunto'
                      : '${(o.avanzamento * 100).round()}% · mancano '
                            '${Importo.formatta(o.mancante, o.obiettivo.valuta)}',
                  valore: Importo.formatta(o.versato, o.obiettivo.valuta),
                  icona: o.colletta
                      ? Icons.groups_outlined
                      : Icons.savings_outlined,
                  completa: _SchedaObiettivo(
                    sessione: widget.sessione,
                    stato: o,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Vuoto extends StatelessWidget {
  const _Vuoto();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.savings_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                'Metti da parte per qualcosa, da solo o con altri',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Un obiettivo personale (vacanza, auto, fondo emergenze) o una '
                'colletta con amici e parenti (regalo, viaggio, cena): vedi '
                'quanto manca e chi ha già versato.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SchedaObiettivo extends StatelessWidget {
  const _SchedaObiettivo({required this.sessione, required this.stato});

  final Sessione sessione;
  final ObiettivoConStato stato;

  @override
  Widget build(BuildContext context) {
    final s = stato;
    final o = s.obiettivo;
    final testo = Theme.of(context).textTheme;
    final schema = Theme.of(context).colorScheme;
    String euro(int v) => Importo.formatta(v, o.valuta);
    final inRegola = s.quote.where((q) => q.inRegola).length;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ObiettivoPagina(sessione: sessione, obiettivoId: o.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    s.colletta ? Icons.groups_outlined : Icons.savings_outlined,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(o.nome, style: testo.titleLarge)),
                  if (s.raggiunto)
                    Chip(
                      avatar: const Icon(Icons.check, size: 16),
                      label: const Text('Raggiunto'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: s.avanzamento,
                  minHeight: 8,
                  backgroundColor: schema.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${euro(s.versato)} di ${euro(o.importoObiettivoMinimo)}'
                '${s.raggiunto ? '' : ' · mancano ${euro(s.mancante)}'}',
              ),
              if (s.colletta)
                Text(
                  '$inRegola di ${s.quote.length} hanno versato la loro quota',
                  style: testo.bodySmall,
                )
              else if (s.alMese != null)
                Text(
                  'Metti da parte ${euro(s.alMese!)} al mese fino al '
                  '${dataLeggibile(context, s.scadenza!)}',
                  style: testo.bodySmall?.copyWith(color: schema.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dettaglio: avanzamento, partecipanti, versamenti, riepilogo da condividere.
class ObiettivoPagina extends StatelessWidget {
  const ObiettivoPagina({
    super.key,
    required this.sessione,
    required this.obiettivoId,
  });

  final Sessione sessione;
  final String obiettivoId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ObiettivoConStato>>(
      stream: sessione.obiettivi.osserva(),
      builder: (context, snapshot) {
        final s = snapshot.data
            ?.where((x) => x.obiettivo.id == obiettivoId)
            .firstOrNull;
        if (s == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final o = s.obiettivo;
        final testo = Theme.of(context).textTheme;
        String euro(int v) => Importo.formatta(v, o.valuta);
        final nomi = {
          for (final q in s.quote) q.partecipante.id: q.partecipante.nome,
        };
        return Scaffold(
          appBar: AppBar(
            title: Text(o.nome),
            actions: [
              IconButton(
                tooltip: 'Copia riepilogo',
                icon: const Icon(Icons.copy_all),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: s.riepilogo()));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      avviso(
                        content: Text('Riepilogo copiato: incollalo dove vuoi'),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                tooltip: 'Modifica',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    apriModuloObiettivo(context, sessione, esistente: s),
              ),
              IconButton(
                tooltip: 'Archivia',
                icon: const Icon(Icons.archive_outlined),
                onPressed: () async {
                  final servizio = sessione.obiettivi;
                  final messenger = ScaffoldMessenger.of(context);
                  await servizio.archivia(o.id);
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pop();
                  messenger.showSnackBar(
                    avviso(
                      content: Text('"${o.nome}" archiviato'),
                      action: SnackBarAction(
                        label: 'Annulla',
                        onPressed: () =>
                            servizio.archivia(o.id, archiviato: false),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab-obiettivo-$obiettivoId',
            onPressed: () => apriVersamento(context, sessione, s),
            icon: const Icon(Icons.add),
            label: const Text('Versamento'),
          ),
          body: LayoutBuilder(
            builder: (context, vincoli) => ListView(
              padding: marginiPagina(vincoli),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(euro(s.versato), style: testo.displaySmall),
                        Text('di ${euro(o.importoObiettivoMinimo)}'),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: s.avanzamento,
                          minHeight: 10,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.raggiunto
                              ? 'Obiettivo raggiunto!'
                              : 'Mancano ${euro(s.mancante)}'
                                    '${s.alMese == null ? '' : ' · ${euro(s.alMese!)} al mese fino al ${dataLeggibile(context, s.scadenza!)}'}',
                        ),
                      ],
                    ),
                  ),
                ),
                if (s.colletta) ...[
                  const SizedBox(height: 16),
                  Text('Partecipanti', style: testo.titleMedium),
                  Card(
                    child: Column(
                      children: [
                        for (final q in s.quote)
                          ListTile(
                            leading: Icon(
                              q.inRegola
                                  ? Icons.check_circle
                                  : Icons.hourglass_bottom,
                              color: q.inRegola ? coloreEntrata(context) : null,
                            ),
                            title: Text(q.partecipante.nome),
                            subtitle: Text(
                              q.inRegola
                                  ? 'Ha versato ${euro(q.versato)}'
                                  : 'Ha versato ${euro(q.versato)} · mancano ${euro(q.mancante)}',
                            ),
                            trailing: Text('Quota ${euro(q.quota)}'),
                            onTap: q.inRegola
                                ? null
                                : () => apriVersamento(
                                    context,
                                    sessione,
                                    s,
                                    partecipante: q,
                                  ),
                          ),
                        ListTile(
                          leading: const Icon(Icons.person_add_alt),
                          title: const Text('Aggiungi partecipante'),
                          onTap: () async {
                            final nome = await _chiediNome(context);
                            if (nome != null) {
                              await sessione.obiettivi.aggiungiPartecipante(
                                o.id,
                                nome,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text('Versamenti', style: testo.titleMedium),
                Card(
                  child: Column(
                    children: [
                      if (s.versamenti.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Ancora nessun versamento.'),
                        ),
                      for (final v in s.versamenti)
                        ListTile(
                          leading: const Icon(Icons.payments_outlined),
                          title: Text(euro(v.importoMinimo)),
                          subtitle: Text(
                            [
                              if (v.partecipanteId != null)
                                nomi[v.partecipanteId] ?? '',
                              dataLeggibile(
                                context,
                                Contabilita.daGiorno(v.data),
                              ),
                              if (v.nota.isNotEmpty) v.nota,
                              if (v.movimentoId != null)
                                'registrato nel portafoglio',
                            ].where((t) => t.isNotEmpty).join(' · '),
                          ),
                          trailing: IconButton(
                            tooltip: 'Annulla versamento',
                            icon: const Icon(Icons.undo),
                            onPressed: () async {
                              final servizio = sessione.obiettivi;
                              await servizio.annullaVersamento(v.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  avviso(
                                    content: const Text('Versamento annullato'),
                                    action: SnackBarAction(
                                      label: 'Ripristina',
                                      onPressed: () =>
                                          servizio.annullaVersamento(
                                            v.id,
                                            annullato: false,
                                          ),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<String?> _chiediNome(BuildContext context) async {
    final nome = await showDialog<String>(
      context: context,
      builder: (_) => const _NomePartecipante(),
    );
    return nome == null || nome.trim().isEmpty ? null : nome.trim();
  }
}

class _NomePartecipante extends StatefulWidget {
  const _NomePartecipante();

  @override
  State<_NomePartecipante> createState() => _NomePartecipanteState();
}

class _NomePartecipanteState extends State<_NomePartecipante> {
  final _nome = TextEditingController();

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuovo partecipante'),
      content: TextField(
        controller: _nome,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nome'),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_nome.text),
          child: const Text('Aggiungi'),
        ),
      ],
    );
  }
}

/// Nuovo versamento (con partecipante per le collette).
Future<void> apriVersamento(
  BuildContext context,
  Sessione sessione,
  ObiettivoConStato stato, {
  QuotaPartecipante? partecipante,
}) => showDialog<void>(
  context: context,
  builder: (_) =>
      _Versamento(sessione: sessione, stato: stato, partecipante: partecipante),
);

class _Versamento extends StatefulWidget {
  const _Versamento({
    required this.sessione,
    required this.stato,
    this.partecipante,
  });

  final Sessione sessione;
  final ObiettivoConStato stato;
  final QuotaPartecipante? partecipante;

  @override
  State<_Versamento> createState() => _VersamentoState();
}

class _VersamentoState extends State<_Versamento> {
  final _form = GlobalKey<FormState>();
  final _importo = ControllerImporto();
  String? _partecipante;
  String? _portafoglio;
  List<PortafoglioConSaldo> _portafogli = const [];
  bool _salvataggio = false;

  @override
  void initState() {
    super.initState();
    final q = widget.partecipante;
    _partecipante = q?.partecipante.id;
    final suggerito =
        q?.mancante ?? (widget.stato.colletta ? null : widget.stato.alMese);
    if (suggerito != null && suggerito > 0) {
      _importo.text = Importo.perModifica(suggerito);
    }
    widget.sessione.contabilita.osservaPortafogli().first.then((p) {
      if (mounted) {
        setState(() => _portafogli = p);
      }
    });
  }

  @override
  void dispose() {
    _importo.dispose();
    super.dispose();
  }

  Future<void> _salva() async {
    if (_salvataggio || !_form.currentState!.validate()) {
      return;
    }
    setState(() => _salvataggio = true);
    try {
      await widget.sessione.obiettivi.versa(
        widget.stato.obiettivo.id,
        importo: Importo.leggi(_importo.text)!,
        partecipanteId: _partecipante,
        portafoglioDaId: _portafoglio,
      );
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

  @override
  Widget build(BuildContext context) {
    final s = widget.stato;
    final personale = !s.colletta;
    return AlertDialog(
      title: const Text('Nuovo versamento'),
      content: SizedBox(
        width: 420,
        child: Form(
          // Dopo il primo errore il campo si ricontrolla a ogni modifica:
          // il messaggio sparisce appena il valore è giusto.
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (s.colletta) ...[
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _partecipante,
                  decoration: const InputDecoration(
                    labelText: 'Chi ha versato',
                  ),
                  items: [
                    for (final q in s.quote)
                      DropdownMenuItem(
                        value: q.partecipante.id,
                        child: Text(q.partecipante.nome),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    _partecipante = v;
                    final q = s.quote.firstWhere((x) => x.partecipante.id == v);
                    if (q.mancante > 0) {
                      _importo.text = Importo.perModifica(q.mancante);
                    }
                  }),
                  validator: (v) => v == null ? 'Scegli chi ha versato' : null,
                ),
                const SizedBox(height: 12),
              ],
              CampoImporto(
                controller: _importo,
                autofocus: true,
                valuta: s.obiettivo.valuta,
                textInputAction: TextInputAction.done,
                onInvio: _salva,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _portafoglio,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: personale
                      ? 'Da quale portafoglio prendi i soldi'
                      : 'In quale portafoglio li ricevi',
                  helperText: 'Facoltativo: registra anche il movimento',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    child: Text('Non registrare nei portafogli'),
                  ),
                  for (final p in _portafogli)
                    DropdownMenuItem<String?>(
                      value: p.portafoglio.id,
                      child: Text(p.portafoglio.nome),
                    ),
                ],
                onChanged: (v) => setState(() => _portafoglio = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _salvataggio ? null : _salva,
          child: const Text('Registra'),
        ),
      ],
    );
  }
}

/// Nuovo obiettivo/colletta o modifica.
Future<void> apriModuloObiettivo(
  BuildContext context,
  Sessione sessione, {
  ObiettivoConStato? esistente,
}) => showDialog<void>(
  context: context,
  builder: (_) => _ModuloObiettivo(sessione: sessione, esistente: esistente),
);

class _ModuloObiettivo extends StatefulWidget {
  const _ModuloObiettivo({required this.sessione, this.esistente});

  final Sessione sessione;
  final ObiettivoConStato? esistente;

  @override
  State<_ModuloObiettivo> createState() => _ModuloObiettivoState();
}

class _ModuloObiettivoState extends State<_ModuloObiettivo> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(
    text: widget.esistente?.obiettivo.nome ?? '',
  );
  late final _importo = ControllerImporto(
    text: widget.esistente == null
        ? ''
        : Importo.perModifica(
            widget.esistente!.obiettivo.importoObiettivoMinimo,
          ),
  );
  final _nuovoPartecipante = TextEditingController();
  late String _tipo =
      widget.esistente?.obiettivo.tipo ?? TipoObiettivo.personale;
  late DateTime? _scadenza = widget.esistente?.scadenza;
  late String? _portafoglio = widget.esistente?.obiettivo.portafoglioId;
  final List<String> _partecipanti = ['Io'];
  List<Portafoglio> _portafogli = const [];
  bool _salvataggio = false;

  bool get _modifica => widget.esistente != null;

  @override
  void initState() {
    super.initState();
    widget.sessione.contabilita.osservaPortafogli().first.then((p) {
      if (mounted) {
        setState(() => _portafogli = [for (final x in p) x.portafoglio]);
      }
    });
  }

  @override
  void dispose() {
    _nome.dispose();
    _importo.dispose();
    _nuovoPartecipante.dispose();
    super.dispose();
  }

  void _aggiungiPartecipante() {
    final nome = _nuovoPartecipante.text.trim();
    if (nome.isEmpty) {
      return;
    }
    setState(() {
      _partecipanti.add(nome);
      _nuovoPartecipante.clear();
    });
  }

  Future<void> _salva() async {
    if (_salvataggio || !_form.currentState!.validate()) {
      return;
    }
    setState(() => _salvataggio = true);
    try {
      final servizio = widget.sessione.obiettivi;
      final importo = Importo.leggi(_importo.text)!;
      if (_modifica) {
        await servizio.modifica(
          widget.esistente!.obiettivo.id,
          nome: _nome.text,
          importoObiettivo: importo,
          scadenza: _scadenza,
          portafoglioId: _portafoglio,
        );
      } else {
        await servizio.crea(
          nome: _nome.text,
          tipo: _tipo,
          importoObiettivo: importo,
          scadenza: _scadenza,
          portafoglioId: _tipo == TipoObiettivo.personale ? _portafoglio : null,
          partecipanti: _tipo == TipoObiettivo.colletta
              ? [for (final n in _partecipanti) (nome: n, quota: null)]
              : const [],
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

  @override
  Widget build(BuildContext context) {
    final colletta = _tipo == TipoObiettivo.colletta;
    return AlertDialog(
      title: Text(_modifica ? 'Modifica' : 'Nuovo obiettivo o colletta'),
      content: SizedBox(
        width: 460,
        child: Form(
          // Dopo il primo errore il campo si ricontrolla a ogni modifica:
          // il messaggio sparisce appena il valore è giusto.
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_modifica)
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: TipoObiettivo.personale,
                        icon: Icon(Icons.savings_outlined),
                        label: Text('Obiettivo personale'),
                      ),
                      ButtonSegment(
                        value: TipoObiettivo.colletta,
                        icon: Icon(Icons.groups_outlined),
                        label: Text('Colletta'),
                      ),
                    ],
                    selected: {_tipo},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() => _tipo = s.first),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nome,
                  autofocus: !_modifica,
                  decoration: InputDecoration(
                    labelText: 'Nome',
                    hintText: colletta
                        ? 'Es. Regalo per Anna, Viaggio a Lisbona'
                        : 'Es. Vacanza, Auto nuova, Fondo emergenze',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Dai un nome' : null,
                ),
                const SizedBox(height: 12),
                CampoImporto(
                  controller: _importo,
                  etichetta: colletta
                      ? 'Totale da raccogliere'
                      : 'Quanto vuoi mettere da parte',
                ),
                const SizedBox(height: 12),
                CampoData(
                  etichetta: 'Entro quando (facoltativo)',
                  valore: _scadenza,
                  vuoto: 'Nessuna scadenza',
                  primo: DateTime(2000),
                  onChanged: (d) => setState(() => _scadenza = d),
                  onTogli: () => setState(() => _scadenza = null),
                ),
                if (!colletta) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _portafogli.any((p) => p.id == _portafoglio)
                        ? _portafoglio
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Dove tieni questi soldi (facoltativo)',
                      helperText:
                          'Es. "Risparmi" o "Salvadanaio". Nel portafoglio '
                          'vedrai quanta parte dei soldi è per questo obiettivo.',
                      helperMaxLines: 2,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(child: Text('Nessuno')),
                      for (final p in _portafogli)
                        DropdownMenuItem<String?>(
                          value: p.id,
                          child: Text(p.nome),
                        ),
                    ],
                    onChanged: (v) => setState(() => _portafoglio = v),
                  ),
                ],
                if (colletta && !_modifica) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Partecipanti (quote in parti uguali, modificabili dopo)',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final (i, n) in _partecipanti.indexed)
                        InputChip(
                          label: Text(n),
                          onDeleted: () =>
                              setState(() => _partecipanti.removeAt(i)),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nuovoPartecipante,
                          decoration: const InputDecoration(
                            labelText: 'Aggiungi partecipante',
                          ),
                          onSubmitted: (_) => _aggiungiPartecipante(),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Aggiungi',
                        icon: const Icon(Icons.person_add_alt),
                        onPressed: _aggiungiPartecipante,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _salvataggio ? null : _salva,
          child: Text(_modifica ? 'Salva' : 'Crea'),
        ),
      ],
    );
  }
}
