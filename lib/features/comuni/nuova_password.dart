import 'package:flutter/material.dart';

import 'firma_versione.dart';

/// Lunghezza minima della password principale.
const int lunghezzaMinimaPassword = 12;

/// Due campi (password + conferma) con le regole della password principale.
/// Va usato dentro un [Form]: la validazione parte con `FormState.validate()`.
class CampiNuovaPassword extends StatefulWidget {
  const CampiNuovaPassword({
    super.key,
    required this.password,
    required this.conferma,
    this.etichetta = 'Password principale',
    this.onInvio,
  });

  final TextEditingController password;
  final TextEditingController conferma;
  final String etichetta;
  final VoidCallback? onInvio;

  @override
  State<CampiNuovaPassword> createState() => _CampiNuovaPasswordState();
}

class _CampiNuovaPasswordState extends State<CampiNuovaPassword> {
  bool _nascosta = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.password,
          obscureText: _nascosta,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: widget.etichetta,
            helperText:
                'Almeno $lunghezzaMinimaPassword caratteri. '
                'Una frase lunga è più sicura e più facile da ricordare.',
            helperMaxLines: 2,
            suffixIcon: IconButton(
              tooltip: _nascosta ? 'Mostra password' : 'Nascondi password',
              icon: Icon(_nascosta ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _nascosta = !_nascosta),
            ),
          ),
          validator: (valore) {
            if (valore == null || valore.length < lunghezzaMinimaPassword) {
              return 'Servono almeno $lunghezzaMinimaPassword caratteri.';
            }
            if (valore.trim().length != valore.length) {
              return 'Niente spazi all\'inizio o alla fine.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: widget.conferma,
          obscureText: _nascosta,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => widget.onInvio?.call(),
          decoration: const InputDecoration(labelText: 'Ripeti la password'),
          validator: (valore) => valore != widget.password.text
              ? 'Le due password non coincidono.'
              : null,
        ),
      ],
    );
  }
}

/// Contenitore centrato e di larghezza leggibile, per le schermate di accesso.
class PaginaCentrata extends StatelessWidget {
  const PaginaCentrata({super.key, required this.children, this.appBar});

  final List<Widget> children;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...children,
                  // Senza barra in alto la versione sta in fondo alla pagina.
                  if (appBar == null) const FirmaInFondo(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
