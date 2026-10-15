import 'package:flutter/material.dart';

import '../../core/crypto/eccezioni.dart';
import '../../core/sessione.dart';
import '../comuni/campo_secret_key.dart';
import '../comuni/errori.dart';
import '../comuni/nuova_password.dart';
import '../comuni/firma_versione.dart';

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
    if (_occupato) {
      return;
    }
    if (_password.text.isEmpty) {
      setState(() => _errore = 'Scrivi la password principale.');
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
    } catch (e, stack) {
      if (mounted) {
        setState(() => _occupato = false);
        await mostraErroreImprevisto(context, e, stack);
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
          const InCorso(testo: 'Sto aprendo l\'archivio…')
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

/// Password dimenticata, in due passi: 1) Secret Key (file o incolla) 2) nuova password.
class RecuperoPagina extends StatefulWidget {
  const RecuperoPagina({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<RecuperoPagina> createState() => _RecuperoPaginaState();
}

class _RecuperoPaginaState extends State<RecuperoPagina> {
  final _form = GlobalKey<FormState>();
  final _secretKey = TextEditingController();
  final _password = TextEditingController();
  final _conferma = TextEditingController();
  bool _secretKeyValida = false;
  bool _passoPassword = false;
  bool _occupato = false;
  String? _erroreSecretKey;

  @override
  void dispose() {
    _secretKey.dispose();
    _password.dispose();
    _conferma.dispose();
    super.dispose();
  }

  Future<void> _recupera() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    setState(() => _occupato = true);
    try {
      await widget.sessione.recupera(_secretKey.text, _password.text);
      _secretKey.clear();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on CryptoException catch (e) {
      // Secret Key di un altro archivio: si torna al primo passo.
      if (mounted) {
        setState(() {
          _erroreSecretKey = e.messaggio;
          _passoPassword = false;
          _occupato = false;
        });
      }
    } catch (e, stack) {
      if (mounted) {
        setState(() => _occupato = false);
        await mostraErroreImprevisto(context, e, stack);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme.bodyLarge;
    return PaginaCentrata(
      appBar: AppBar(
        title: TitoloConFirma(
          _passoPassword ? 'Nuova password (2 di 2)' : 'Secret Key (1 di 2)',
        ),
        leading: BackButton(
          onPressed: _occupato
              ? null
              : _passoPassword
              ? () => setState(() => _passoPassword = false)
              : () => Navigator.of(context).pop(),
        ),
      ),
      children: _passoPassword
          ? [
              Text(
                'Secret Key valida. Ora scegli una nuova password principale.',
                style: testo,
              ),
              const SizedBox(height: 24),
              Form(
                key: _form,
                child: AutofillGroup(
                  child: CampiNuovaPassword(
                    password: _password,
                    conferma: _conferma,
                    etichetta: 'Nuova password principale',
                    onInvio: _occupato ? null : _recupera,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_occupato)
                const InCorso(testo: 'Sto recuperando l\'archivio…')
              else
                FilledButton(
                  onPressed: _recupera,
                  child: const Text('Recupera l\'archivio'),
                ),
            ]
          : [
              Text(
                'Scegli il file della Secret Key che hai salvato, '
                'oppure incolla la Secret Key.',
                style: testo,
              ),
              const SizedBox(height: 16),
              CampoSecretKey(
                controller: _secretKey,
                errore: _erroreSecretKey,
                onValidita: (valida) => setState(() {
                  _secretKeyValida = valida;
                  _erroreSecretKey = null;
                }),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _secretKeyValida
                    ? () => setState(() => _passoPassword = true)
                    : null,
                child: const Text('Continua'),
              ),
            ],
    );
  }
}
