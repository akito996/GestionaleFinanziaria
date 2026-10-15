import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/db/archivio.dart';
import '../../core/db/contabilita.dart';
import '../../core/db/tabelle.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../categorie/scelta_categoria.dart';
import '../comuni/campi.dart';
import '../../core/foto/scontrino.dart';
import '../comuni/errori.dart';
import '../foto/foto.dart';
import 'riga_movimento.dart';

/// Apre il modulo per un nuovo movimento (o per modificarne uno [esistente]).
/// Restituisce `true` se è stato salvato.
Future<bool> apriModuloMovimento(
  BuildContext context,
  Sessione sessione, {
  MovimentoDettaglio? esistente,
  String? portafoglioId,
}) async {
  final salvato = await showDialog<bool>(
    context: context,
    builder: (_) => _MovimentoModulo(
      sessione: sessione,
      esistente: esistente,
      portafoglioIniziale: portafoglioId,
    ),
  );
  return salvato ?? false;
}

/// Ultimo portafoglio usato (in questa sessione): proposto al movimento successivo.
String? _ultimoPortafoglio;

class _MovimentoModulo extends StatefulWidget {
  const _MovimentoModulo({
    required this.sessione,
    this.esistente,
    this.portafoglioIniziale,
  });

  final Sessione sessione;
  final MovimentoDettaglio? esistente;
  final String? portafoglioIniziale;

  @override
  State<_MovimentoModulo> createState() => _MovimentoModuloState();
}

class _MovimentoModuloState extends State<_MovimentoModulo> {
  final _form = GlobalKey<FormState>();
  final _importo = ControllerImporto();
  final _descrizione = TextEditingController();

  List<DefinizioneTipo> _tipi = const [];
  List<PortafoglioConSaldo> _portafogli = const [];
  DefinizioneTipo? _tipo;
  String? _portafoglio;
  String? _destinazione;
  String? _categoria;
  DateTime _data = DateTime.now();
  bool _salvataggio = false;

  bool get _trasferimento => _tipo?.effetto == EffettoSaldo.trasferimento;

  @override
  void initState() {
    super.initState();
    _carica();
  }

  Future<void> _carica() async {
    final contabilita = widget.sessione.contabilita;
    final tipi = await contabilita.tipi(AmbitoTipo.movimento);
    final portafogli = await contabilita.osservaPortafogli().first;
    final esistente = widget.esistente;
    if (!mounted) {
      return;
    }
    setState(() {
      _tipi = tipi;
      _portafogli = portafogli;
      final ids = portafogli.map((p) => p.portafoglio.id).toSet();
      if (esistente != null) {
        final m = esistente.movimento;
        _tipo = tipi.where((t) => t.id == m.tipoId).firstOrNull ?? tipi.first;
        _portafoglio = m.portafoglioId;
        _destinazione = m.portafoglioDestinazioneId;
        _categoria = m.categoriaId;
        _data = Contabilita.daGiorno(m.data);
        _importo.text = Importo.perModifica(m.importoMinimo);
        _descrizione.text = m.descrizione;
      } else {
        _tipo = tipi.firstOrNull;
        _portafoglio =
            [
              widget.portafoglioIniziale,
              _ultimoPortafoglio,
              portafogli.firstOrNull?.portafoglio.id,
            ].firstWhere(
              (id) => id != null && ids.contains(id),
              orElse: () => null,
            );
      }
    });
  }

  @override
  void dispose() {
    _importo.dispose();
    _descrizione.dispose();
    super.dispose();
  }

  /// Dalla foto dello scontrino: data, negozio e importo (lo "zoom" sui dati
  /// li rilegge ingranditi), da controllare prima di usarli.
  Future<void> _daFoto() async {
    final percorso = await scegliFoto(context, titolo: 'Foto dello scontrino');
    if (percorso == null || !mounted) {
      return;
    }
    final messaggio = ValueNotifier('Leggo lo scontrino…');
    final letto = await leggiConAttesa(
      context,
      messaggio,
      () => LettoreScontrino.leggi(lettoreFoto, percorso),
    );
    messaggio.dispose();
    cancellaFoto(percorso);
    if (letto == null || !mounted) {
      return;
    }
    if (letto.vuoto) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.receipt_long_outlined),
          title: const Text('Non riesco a leggere lo scontrino'),
          content: const Text(
            'Riprova con lo scontrino dritto, ben illuminato e che riempia la '
            'foto. Puoi anche scrivere i dati a mano.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ho capito'),
            ),
          ],
        ),
      );
      return;
    }
    final scelto = await confermaScontrino(context, letto);
    if (scelto == null || !mounted) {
      return;
    }
    setState(() {
      // Uno scontrino è una spesa.
      _tipo =
          _tipi.where((t) => t.effetto == EffettoSaldo.uscita).firstOrNull ??
          _tipo;
      if (scelto.importo case final importo?) {
        _importo.text = Importo.perCampo(importo.valore);
      }
      if (scelto.negozio case final negozio?) {
        _descrizione.text = negozio.valore;
      }
      if (scelto.data case final data?) {
        _data = data.valore;
      }
    });
  }

  Portafoglio? _portafoglioDa(String? id) =>
      _portafogli.where((p) => p.portafoglio.id == id).firstOrNull?.portafoglio;

  Future<void> _salva() async {
    if (_salvataggio || !_form.currentState!.validate()) {
      return;
    }
    final portafoglio = _portafoglioDa(_portafoglio)!;
    final importo = Importo.leggi(_importo.text)!;
    final contabilita = widget.sessione.contabilita;
    setState(() => _salvataggio = true);
    try {
      final destinazione = _trasferimento ? _destinazione : null;
      if (_trasferimento) {
        _categoria = null;
      }
      if (widget.esistente == null) {
        await contabilita.registraMovimento(
          tipoId: _tipo!.id,
          portafoglioId: portafoglio.id,
          destinazioneId: destinazione,
          categoriaId: _categoria,
          importo: importo,
          valuta: portafoglio.valuta,
          data: _data,
          descrizione: _descrizione.text,
        );
      } else {
        await contabilita.modificaMovimento(
          widget.esistente!.movimento.id,
          tipoId: _tipo!.id,
          portafoglioId: portafoglio.id,
          destinazioneId: destinazione,
          categoriaId: _categoria,
          importo: importo,
          valuta: portafoglio.valuta,
          data: _data,
          descrizione: _descrizione.text,
        );
      }
      _ultimoPortafoglio = portafoglio.id;
      if (mounted) {
        Navigator.of(context).pop(true);
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
    final modifica = widget.esistente != null;
    final valuta = _portafoglioDa(_portafoglio)?.valuta ?? 'EUR';
    final colore = coloreEffetto(context, _tipo?.effetto);

    // Sul telefono il modulo usa quasi tutta la larghezza dello schermo.
    final stretto = MediaQuery.sizeOf(context).width < 600;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _salva,
      },
      child: AlertDialog(
        insetPadding: stretto
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 24)
            : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        contentPadding: stretto
            ? const EdgeInsets.fromLTRB(16, 16, 16, 0)
            : null,
        title: Row(
          children: [
            Expanded(
              child: Text(modifica ? 'Modifica movimento' : 'Nuovo movimento'),
            ),
            if (!modifica && fotoDisponibile())
              IconButton(
                tooltip: 'Leggi da una foto dello scontrino',
                icon: const Icon(Icons.photo_camera_outlined),
                onPressed: _tipo == null ? null : _daFoto,
              ),
          ],
        ),
        content: _tipo == null
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : SizedBox(
                width: 460,
                child: Form(
                  key: _form,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SceltaTipoMovimento(
                          tipi: _tipi,
                          selezionato: _tipo!,
                          onChanged: (t) => setState(() => _tipo = t),
                        ),
                        const SizedBox(height: 16),
                        CampoImporto(
                          controller: _importo,
                          autofocus: true,
                          valuta: valuta,
                          colore: colore,
                        ),
                        const SizedBox(height: 16),
                        _sceltaPortafoglio(
                          etichetta: _trasferimento ? 'Da' : 'Portafoglio',
                          valore: _portafoglio,
                          onChanged: (v) => setState(() => _portafoglio = v),
                        ),
                        if (_trasferimento) ...[
                          const SizedBox(height: 16),
                          _sceltaPortafoglio(
                            etichetta: 'A',
                            valore: _destinazione,
                            onChanged: (v) => setState(() => _destinazione = v),
                            escludi: _portafoglio,
                            // Per ora i trasferimenti sono tra portafogli con la
                            // stessa valuta (il cambio arriverà con i tassi BCE).
                            soloValuta: valuta,
                          ),
                        ],
                        if (!_trasferimento) ...[
                          const SizedBox(height: 16),
                          CampoCategoria(
                            sessione: widget.sessione,
                            valore: _categoria,
                            onChanged: (c) => setState(() => _categoria = c),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descrizione,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _salva(),
                          decoration: const InputDecoration(
                            labelText: 'Descrizione (facoltativa)',
                            hintText: 'Es. Pizzeria, Stipendio, Bolletta luce',
                          ),
                        ),
                        const SizedBox(height: 16),
                        CampoData(
                          etichetta: 'Data del movimento',
                          valore: _data,
                          primo: DateTime(1970),
                          ultimo: DateTime.now().add(
                            const Duration(days: 365 * 5),
                          ),
                          onChanged: (d) => setState(() => _data = d),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: _tipo == null || _salvataggio ? null : _salva,
            child: Text(modifica ? 'Salva modifiche' : 'Salva'),
          ),
        ],
      ),
    );
  }

  Widget _sceltaPortafoglio({
    required String etichetta,
    required String? valore,
    required ValueChanged<String?> onChanged,
    String? escludi,
    String? soloValuta,
  }) {
    final scelte = _portafogli.where(
      (p) =>
          p.portafoglio.id != escludi &&
          (soloValuta == null || p.portafoglio.valuta == soloValuta),
    );
    return DropdownButtonFormField<String>(
      initialValue: scelte.any((p) => p.portafoglio.id == valore)
          ? valore
          : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: etichetta),
      items: [
        for (final p in scelte)
          DropdownMenuItem(
            value: p.portafoglio.id,
            child: Text(
              '${p.portafoglio.nome} · '
              '${Importo.formatta(p.saldo, p.portafoglio.valuta)}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
      validator: (v) => v == null ? 'Scegli un portafoglio' : null,
    );
  }
}

/// Spesa / Entrata / Trasferimento. Sugli schermi stretti l'icona sta sopra
/// il nome, su una riga sola (niente parole spezzate lettera per lettera).
class SceltaTipoMovimento extends StatelessWidget {
  const SceltaTipoMovimento({
    super.key,
    required this.tipi,
    required this.selezionato,
    required this.onChanged,
  });

  final List<DefinizioneTipo> tipi;
  final DefinizioneTipo selezionato;
  final ValueChanged<DefinizioneTipo> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, vincoli) {
        final stretto = vincoli.maxWidth < 420;
        return SegmentedButton<String>(
          style: stretto
              ? const ButtonStyle(
                  visualDensity: VisualDensity.comfortable,
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  ),
                )
              : null,
          segments: [
            for (final t in tipi)
              stretto
                  ? ButtonSegment(
                      value: t.id,
                      tooltip: t.nome,
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(iconaEffetto(t.effetto), size: 20),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(t.nome, maxLines: 1, softWrap: false),
                          ),
                        ],
                      ),
                    )
                  : ButtonSegment(
                      value: t.id,
                      label: Text(t.nome, maxLines: 1, softWrap: false),
                      icon: Icon(iconaEffetto(t.effetto)),
                    ),
          ],
          selected: {selezionato.id},
          showSelectedIcon: false,
          onSelectionChanged: (s) =>
              onChanged(tipi.firstWhere((t) => t.id == s.first)),
        );
      },
    );
  }
}
