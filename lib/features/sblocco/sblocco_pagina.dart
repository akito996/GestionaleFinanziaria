import 'package:flutter/material.dart';

import '../../core/crypto/eccezioni.dart';
import '../../core/sessione.dart';
import '../comuni/nuova_password.dart';

/// Archivio bloccato: si apre con la password principale.
class SbloccoPagina extends StatefulWidget {
  const SbloccoPagina({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<SbloccoPagina> createState() => _SbloccoPaginaState();
}

class _SbloccoPaginaState extends State<SbloccoPagina> {
  final _password = TextEditingController();
  bool _occupato = false;
  bool _nascosta = true;
  String? _errore;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _sblocca() async {
    if (_password.text.isEmpty || _occupato) {
      return;
    }
    setState(() {
      _occupato = true;
      _errore = null;
    });
    try {
      await widget.sessione.sblocca(_password.text);
    } on CryptoException catch (e) {
      if (mounted) {
        setState(() {
          _errore = e.messaggio;
          _occupato = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PaginaCentrata(
      children: [
        const Icon(Icons.lock_outline, size: 56),
        const SizedBox(height: 16),
        Text(
          'Archivio bloccato',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _password,
          autofocus: true,
          obscureText: _nascosta,
          enabled: !_occupato,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _sblocca(),
          decoration: InputDecoration(
            labelText: 'Password principale',
            errorText: _errore,
            suffixIcon: IconButton(
              tooltip: _nascosta ? 'Mostra password' : 'Nascondi password',
              icon: Icon(_nascosta ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _nascosta = !_nascosta),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_occupato)
          const Center(child: CircularProgressIndicator())
        else
          FilledButton(onPressed: _sblocca, child: const Text('Sblocca')),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _occupato
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RecuperoPagina(sessione: widget.sessione),
                  ),
                ),
          child: const Text('Ho dimenticato la password'),
        ),
      ],
    );
  }
}

/// Password dimenticata: si apre con la Recovery Key e si sceglie una nuova password.
class RecuperoPagina extends StatefulWidget {
  const RecuperoPagina({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<RecuperoPagina> createState() => _RecuperoPaginaState();
}

class _RecuperoPaginaState extends State<RecuperoPagina> {
  final _form = GlobalKey<FormState>();
  final _parole = TextEditingController();
  final _password = TextEditingController();
  final _conferma = TextEditingController();
  bool _occupato = false;
  String? _errore;

  @override
  void dispose() {
    _parole.dispose();
    _password.dispose();
    _conferma.dispose();
    super.dispose();
  }

  Future<void> _recupera() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _occupato = true;
      _errore = null;
    });
    try {
      await widget.sessione.recupera(_parole.text, _password.text);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on CryptoException catch (e) {
      if (mounted) {
        setState(() {
          _errore = e.messaggio;
          _occupato = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PaginaCentrata(
      appBar: AppBar(title: const Text('Recupera con la Recovery Key')),
      children: [
        Text(
          'Scrivi le 24 parole della Recovery Key, nell\'ordine, separate da spazi '
          '(bastano le prime 4 lettere). Poi scegli una nuova password.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _parole,
                minLines: 3,
                maxLines: 6,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'Le 24 parole',
                  errorText: _errore,
                  errorMaxLines: 3,
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Inserisci le parole della Recovery Key.'
                    : null,
              ),
              const SizedBox(height: 24),
              CampiNuovaPassword(
                password: _password,
                conferma: _conferma,
                etichetta: 'Nuova password principale',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_occupato)
          const Center(child: CircularProgressIndicator())
        else
          FilledButton(
            onPressed: _recupera,
            child: const Text('Recupera l\'archivio'),
          ),
      ],
    );
  }
}
