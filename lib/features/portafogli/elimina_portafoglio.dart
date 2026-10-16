import 'package:flutter/material.dart';

import '../../core/db/archivio.dart';
import '../../core/db/contabilita.dart';
import '../../core/db/eliminazione_portafoglio.dart';
import '../../core/importo.dart';
import '../../core/sessione.dart';
import '../comuni/avvisi.dart';
import '../comuni/errori.dart';
import '../comuni/layout.dart';
import '../movimenti/riga_movimento.dart';

/// Elimina un portafoglio, scegliendo cosa fare dei suoi movimenti.
Future<void> apriEliminaPortafoglio(
  BuildContext context,
  Sessione sessione,
  Portafoglio portafoglio,
) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) =>
        EliminaPortafoglioPagina(sessione: sessione, portafoglio: portafoglio),
  ),
);

enum _Scelta { tutti, sposta, scegli }

class EliminaPortafoglioPagina extends StatefulWidget {
  const EliminaPortafoglioPagina({
    super.key,
    required this.sessione,
    required this.portafoglio,
  });

  final Sessione sessione;
  final Portafoglio portafoglio;

  @override
  State<EliminaPortafoglioPagina> createState() =>
      _EliminaPortafoglioPaginaState();
}

typedef _Dati = ({
  CollegamentiPortafoglio collegati,
  List<MovimentoDettaglio> movimenti,
  List<PortafoglioConSaldo> altri,
});

class _EliminaPortafoglioPaginaState extends State<EliminaPortafoglioPagina> {
  late final Future<_Dati> _dati = _carica();
  _Scelta _scelta = _Scelta.tutti;
  String? _destinazione;
  final _daEliminare = <String>{};
  bool _occupato = false;

  Contabilita get _c => widget.sessione.contabilita;
  Portafoglio get _p => widget.portafoglio;

  Future<_Dati> _carica() async {
    final collegati = await _c.eliminazione.collegamenti(_p.id);
    final movimenti = await _c
        .osservaMovimenti(portafoglioId: _p.id, limite: 5000)
        .first;
    // Anche gli archiviati possono accogliere i movimenti.
    final altri =
        [
          ...await _c.osservaPortafogli().first,
          ...await _c.osservaPortafogli(archiviati: true).first,
        ].where(
          (x) => x.portafoglio.id != _p.id && x.portafoglio.valuta == _p.valuta,
        );
    return (collegati: collegati, movimenti: movimenti, altri: altri.toList());
  }

  /// Quanti movimenti restano e vanno spostati.
  int _restano(_Dati d) => switch (_scelta) {
    _Scelta.tutti => 0,
    _Scelta.sposta => d.movimenti.length,
    _Scelta.scegli => d.movimenti.length - _daEliminare.length,
  };

  Future<void> _elimina(_Dati d) async {
    final restano = _restano(d);
    if (restano > 0 && _destinazione == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        avviso(content: const Text('Scegli dove spostare i movimenti')),
      );
      return;
    }
    final eliminati = switch (_scelta) {
      _Scelta.tutti => {for (final m in d.movimenti) m.movimento.id},
      _Scelta.sposta => <String>{},
      _Scelta.scegli => _daEliminare,
    };
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text('Eliminare "${_p.nome}"?'),
        content: Text(
          [
            if (eliminati.isNotEmpty)
              'Si eliminano ${eliminati.length} '
                  '${eliminati.length == 1 ? 'movimento' : 'movimenti'}.',
            if (restano > 0) '$restano vanno nel portafoglio scelto.',
            'Subito dopo puoi ancora annullare.',
          ].join(' '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (conferma != true || !mounted) {
      return;
    }
    setState(() => _occupato = true);
    final messaggi = ScaffoldMessenger.of(context);
    final navigatore = Navigator.of(context);
    try {
      final annulla = await _c.eliminazione.elimina(
        _p.id,
        daEliminare: eliminati,
        spostaIn: restano > 0 || d.collegati.altri > 0 ? _destinazione : null,
      );
      navigatore.popUntil((rotta) => rotta.isFirst);
      messaggi
        ..clearSnackBars()
        ..showSnackBar(
          avviso(
            content: Text('"${_p.nome}" eliminato'),
            action: SnackBarAction(label: 'Annulla', onPressed: annulla),
          ),
        );
    } catch (e, stack) {
      if (mounted) {
        setState(() => _occupato = false);
        await mostraErroreImprevisto(context, e, stack);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Elimina "${_p.nome}"')),
      body: FutureBuilder<_Dati>(
        future: _dati,
        builder: (context, snapshot) {
          final d = snapshot.data;
          if (d == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return LayoutBuilder(
            builder: (context, vincoli) => ListView(
              padding: marginiPagina(vincoli),
              children: _contenuto(context, d),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _contenuto(BuildContext context, _Dati d) {
    final schema = Theme.of(context).colorScheme;
    final testo = Theme.of(context).textTheme;
    if (d.collegati.carta case final carta?) {
      return [
        Card(
          color: schema.errorContainer,
          child: ListTile(
            leading: const Icon(Icons.credit_card),
            title: Text('Collegato alla carta "$carta"'),
            subtitle: const Text(
              'È la carta stessa o il conto che la paga. Eliminala o '
              'cambiane il conto dalla sezione Carte, poi torna qui.',
            ),
          ),
        ),
      ];
    }
    final n = d.movimenti.length;
    final restano = _restano(d);
    final serveDestinazione = restano > 0 || d.collegati.altri > 0;
    return [
      Text(
        n == 0
            ? 'Il portafoglio non ha movimenti.'
            : 'Il portafoglio ha $n ${n == 1 ? 'movimento' : 'movimenti'}. '
                  'Cosa vuoi farne?',
        style: testo.bodyLarge,
      ),
      const SizedBox(height: 8),
      if (n > 0)
        RadioGroup<_Scelta>(
          groupValue: _scelta,
          onChanged: (s) => setState(() => _scelta = s ?? _scelta),
          child: Column(
            children: [
              const RadioListTile(
                value: _Scelta.tutti,
                title: Text('Elimina anche tutti i movimenti'),
              ),
              RadioListTile(
                value: _Scelta.sposta,
                enabled: d.altri.isNotEmpty,
                title: const Text('Tieni i movimenti'),
                subtitle: const Text('Passano a un altro portafoglio'),
              ),
              RadioListTile(
                value: _Scelta.scegli,
                enabled: d.altri.isNotEmpty,
                title: const Text('Scegli quali eliminare'),
                subtitle: const Text(
                  'Gli altri passano a un altro portafoglio',
                ),
              ),
            ],
          ),
        ),
      if (d.collegati.altri > 0) ...[
        const SizedBox(height: 8),
        Text(
          'Collegati: ${[if (d.collegati.programmati > 0) '${d.collegati.programmati} pagamenti programmati', if (d.collegati.prestiti > 0) '${d.collegati.prestiti} prestiti', if (d.collegati.obiettivi > 0) '${d.collegati.obiettivi} obiettivi'].join(', ')}. Passano al portafoglio scelto; senza, restano '
          'come promemoria.',
          style: TextStyle(color: schema.onSurfaceVariant),
        ),
      ],
      if (serveDestinazione && d.altri.isNotEmpty) ...[
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          isExpanded: true,
          initialValue: _destinazione,
          decoration: InputDecoration(
            labelText: restano > 0
                ? 'Sposta in'
                : 'Sposta i collegamenti in (facoltativo)',
          ),
          items: [
            if (restano == 0)
              const DropdownMenuItem<String?>(
                child: Text('Nessuno: restano promemoria'),
              ),
            for (final a in d.altri)
              DropdownMenuItem<String?>(
                value: a.portafoglio.id,
                child: Text(
                  '${a.portafoglio.nome} · '
                  '${Importo.formatta(a.saldo, a.portafoglio.valuta)}'
                  '${a.portafoglio.archiviato ? ' (archiviato)' : ''}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (id) => setState(() => _destinazione = id),
        ),
      ],
      if (_scelta == _Scelta.scegli) ...[
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Da eliminare: ${_daEliminare.length} di $n',
                style: testo.titleSmall,
              ),
            ),
            TextButton(
              onPressed: () => setState(
                () =>
                    _daEliminare.addAll(d.movimenti.map((m) => m.movimento.id)),
              ),
              child: const Text('Tutti'),
            ),
            TextButton(
              onPressed: () => setState(_daEliminare.clear),
              child: const Text('Nessuno'),
            ),
          ],
        ),
        for (final m in d.movimenti)
          CheckboxListTile(
            value: _daEliminare.contains(m.movimento.id),
            onChanged: (v) => setState(
              () => v == true
                  ? _daEliminare.add(m.movimento.id)
                  : _daEliminare.remove(m.movimento.id),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              m.movimento.descrizione.isEmpty
                  ? (m.categoria?.nome ?? m.tipo.nome)
                  : m.movimento.descrizione,
            ),
            subtitle: Text(
              dataLeggibile(context, Contabilita.daGiorno(m.movimento.data)),
            ),
            secondary: Text(
              Importo.formatta(m.effettoSu(_p.id), _p.valuta, conSegno: true),
            ),
          ),
      ],
      const SizedBox(height: 24),
      FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: schema.error,
          foregroundColor: schema.onError,
        ),
        onPressed: _occupato ? null : () => _elimina(d),
        icon: const Icon(Icons.delete_outline),
        label: const Text('Elimina il portafoglio'),
      ),
      const SizedBox(height: 8),
      Text(
        'Se vuoi solo nasconderlo, usa «Archivia»: i movimenti restano e lo '
        'ritrovi in Impostazioni › Portafogli archiviati.',
        style: TextStyle(color: schema.onSurfaceVariant),
      ),
    ];
  }
}
