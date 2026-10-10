import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/sessione.dart';
import '../comuni/nuova_password.dart';

/// Primo avvio: spiegazione → password → Recovery Key → verifica di 3 parole.
/// L'archivio viene creato solo alla fine, dopo la verifica.
class PrimoAvvioPagina extends StatefulWidget {
  const PrimoAvvioPagina({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<PrimoAvvioPagina> createState() => _PrimoAvvioPaginaState();
}

enum _Passo { introduzione, password, parole, verifica }

class _PrimoAvvioPaginaState extends State<PrimoAvvioPagina> {
  final _formPassword = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _conferma = TextEditingController();
  final _risposte = List.generate(3, (_) => TextEditingController());

  _Passo _passo = _Passo.introduzione;
  bool _occupato = false;
  String? _errore;
  List<String> _parole = const [];
  List<int> _daVerificare = const [];
  bool _scritte = false;

  @override
  void dispose() {
    _password.dispose();
    _conferma.dispose();
    for (final c in _risposte) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _creaChiavi() async {
    if (!_formPassword.currentState!.validate()) {
      return;
    }
    setState(() => _occupato = true);
    final parole = await widget.sessione.preparaNuovoArchivio(_password.text);
    if (!mounted) {
      return;
    }
    setState(() {
      _password.clear();
      _conferma.clear();
      _parole = parole;
      _scritte = false;
      _occupato = false;
      _passo = _Passo.parole;
    });
  }

  void _vaiAllaVerifica() {
    final casuale = Random.secure();
    final posizioni = <int>{};
    while (posizioni.length < _risposte.length) {
      posizioni.add(casuale.nextInt(_parole.length));
    }
    for (final c in _risposte) {
      c.clear();
    }
    setState(() {
      _daVerificare = posizioni.toList()..sort();
      _errore = null;
      _passo = _Passo.verifica;
    });
  }

  Future<void> _verificaECrea() async {
    for (var i = 0; i < _daVerificare.length; i++) {
      if (!_corrisponde(_risposte[i].text, _parole[_daVerificare[i]])) {
        setState(
          () => _errore =
              'La parola n. ${_daVerificare[i] + 1} non corrisponde. '
              'Ricontrolla quello che hai scritto.',
        );
        return;
      }
    }
    setState(() {
      _occupato = true;
      _errore = null;
    });
    _parole = const [];
    await widget.sessione.confermaNuovoArchivio();
  }

  /// Come nella Recovery Key: maiuscole e spazi non contano, bastano le prime 4 lettere.
  static bool _corrisponde(String scritta, String attesa) {
    final s = scritta.trim().toLowerCase();
    return s.length >= 4 && attesa.startsWith(s);
  }

  void _ricomincia() {
    widget.sessione.annullaNuovoArchivio();
    setState(() {
      _parole = const [];
      _passo = _Passo.introduzione;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_passo) {
      _Passo.introduzione => _introduzione(context),
      _Passo.password => _sceltaPassword(context),
      _Passo.parole => _mostraParole(context),
      _Passo.verifica => _verifica(context),
    };
  }

  Widget _introduzione(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    return PaginaCentrata(
      children: [
        const Icon(Icons.lock_outline, size: 56),
        const SizedBox(height: 16),
        Text(
          'Benvenuto in GestionaleFinanziaria',
          style: testo.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        const _Punto(
          icona: Icons.phonelink_lock,
          testo:
              'I tuoi dati restano sui tuoi dispositivi, cifrati. '
              'Nessuno può leggerli: nemmeno noi o Google.',
        ),
        const _Punto(
          icona: Icons.password,
          testo: 'Sceglierai una password principale: serve ad aprire l\'archivio.',
        ),
        const _Punto(
          icona: Icons.key,
          testo: 'Riceverai una Recovery Key di 24 parole: serve se dimentichi la password.',
        ),
        const _Punto(
          icona: Icons.warning_amber,
          testo:
              'Se perdi sia la password sia la Recovery Key, i dati non si possono '
              'recuperare in nessun modo. È il prezzo della privacy totale.',
          importante: true,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => setState(() => _passo = _Passo.password),
          child: const Text('Inizia'),
        ),
      ],
    );
  }

  Widget _sceltaPassword(BuildContext context) {
    return PaginaCentrata(
      appBar: AppBar(
        title: const Text('Password principale'),
        leading: BackButton(onPressed: _occupato ? null : _ricomincia),
      ),
      children: [
        Text(
          'Scegli la password che userai per aprire l\'archivio su tutti i tuoi dispositivi.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Form(
          key: _formPassword,
          child: AutofillGroup(
            child: CampiNuovaPassword(
              password: _password,
              conferma: _conferma,
              onInvio: _occupato ? null : _creaChiavi,
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_occupato)
          const _Attesa(testo: 'Sto proteggendo la password…')
        else
          FilledButton(onPressed: _creaChiavi, child: const Text('Continua')),
      ],
    );
  }

  Widget _mostraParole(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    return PaginaCentrata(
      appBar: AppBar(
        title: const Text('Recovery Key'),
        leading: BackButton(onPressed: _ricomincia),
      ),
      children: [
        Text(
          'Scrivi queste 24 parole su carta, nell\'ordine, e conservale in un posto sicuro. '
          'Non fare foto o screenshot.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _parole.length; i++)
                  SizedBox(
                    width: 150,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${(i + 1).toString().padLeft(2)}. ',
                            style: TextStyle(color: schema.outline),
                          ),
                          TextSpan(
                            text: _parole[i],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _scritte,
          onChanged: (v) => setState(() => _scritte = v ?? false),
          title: const Text('Le ho scritte e messe al sicuro'),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _scritte ? _vaiAllaVerifica : null,
          child: const Text('Continua'),
        ),
      ],
    );
  }

  Widget _verifica(BuildContext context) {
    return PaginaCentrata(
      appBar: AppBar(
        title: const Text('Verifica'),
        leading: BackButton(
          onPressed: _occupato
              ? null
              : () => setState(() => _passo = _Passo.parole),
        ),
      ),
      children: [
        Text(
          'Per essere sicuri che le parole siano scritte bene, '
          'inserisci quelle richieste (bastano le prime 4 lettere).',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _daVerificare.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _risposte[i],
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: i == _daVerificare.length - 1
                  ? TextInputAction.done
                  : TextInputAction.next,
              onSubmitted: i == _daVerificare.length - 1 && !_occupato
                  ? (_) => _verificaECrea()
                  : null,
              decoration: InputDecoration(
                labelText: 'Parola n. ${_daVerificare[i] + 1}',
              ),
            ),
          ),
        if (_errore != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _errore!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_occupato)
          const _Attesa(testo: 'Creo l\'archivio cifrato…')
        else
          FilledButton(
            onPressed: _verificaECrea,
            child: const Text('Crea l\'archivio'),
          ),
      ],
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto({
    required this.icona,
    required this.testo,
    this.importante = false,
  });

  final IconData icona;
  final String testo;
  final bool importante;

  @override
  Widget build(BuildContext context) {
    final colore = importante ? Theme.of(context).colorScheme.error : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icona, color: colore),
          const SizedBox(width: 12),
          Expanded(
            child: Text(testo, style: TextStyle(color: colore)),
          ),
        ],
      ),
    );
  }
}

class _Attesa extends StatelessWidget {
  const _Attesa({required this.testo});

  final String testo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(testo),
      ],
    );
  }
}
