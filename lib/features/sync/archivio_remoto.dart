import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/crypto/eccezioni.dart';
import '../../core/sessione.dart';
import '../../core/sync/sincronizzatore.dart';
import '../../core/sync/sync_backend.dart';
import '../comuni/campo_secret_key.dart';
import '../comuni/errori.dart';
import '../comuni/nuova_password.dart';

/// Apre l'archivio che c'è su Google Drive: con la sua password o, se
/// dimenticata, con la Secret Key e una password nuova.
class ModuloArchivioRemoto extends StatefulWidget {
  const ModuloArchivioRemoto({
    super.key,
    required this.sessione,
    required this.remoto,
    required this.idRemoto,
    this.avvertenza,
  });

  final Sessione sessione;
  final SyncBackend remoto;
  final String idRemoto;

  /// Es. "I dati di questo dispositivo vengono messi da parte".
  final String? avvertenza;

  @override
  State<ModuloArchivioRemoto> createState() => _ModuloArchivioRemotoState();
}

class _ModuloArchivioRemotoState extends State<ModuloArchivioRemoto> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _secretKey = TextEditingController();
  final _nuova = TextEditingController();
  final _conferma = TextEditingController();
  bool _conSecretKey = false;
  bool _secretKeyValida = false;
  bool _nascosta = true;
  bool _occupato = false;
  String? _errore;

  @override
  void dispose() {
    _password.dispose();
    _secretKey.dispose();
    _nuova.dispose();
    _conferma.dispose();
    super.dispose();
  }

  Future<void> _apri() async {
    if (_occupato || !(_form.currentState?.validate() ?? true)) {
      return;
    }
    if (!_conSecretKey && _password.text.isEmpty) {
      setState(() => _errore = 'Scrivi la password dell\'archivio.');
      return;
    }
    setState(() {
      _occupato = true;
      _errore = null;
    });
    try {
      if (_conSecretKey) {
        await widget.sessione.apriArchivioRemotoConSecretKey(
          widget.remoto,
          _secretKey.text,
          _nuova.text,
        );
      } else {
        await widget.sessione.apriArchivioRemoto(widget.remoto, _password.text);
      }
    } on PasswordErrataException {
      _mostra('Password errata.');
    } on SecretKeyNonValidaException catch (e) {
      _mostra(e.messaggio);
    } on NessunArchivioRemoto catch (e) {
      _mostra('$e');
    } on SocketException {
      _mostra('Nessuna connessione a Internet: riprova.');
    } catch (e, stack) {
      if (mounted) {
        setState(() => _occupato = false);
        await mostraErroreImprevisto(context, e, stack);
      }
    }
  }

  void _mostra(String errore) {
    if (mounted) {
      setState(() {
        _occupato = false;
        _errore = errore;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cloud_done_outlined),
            title: const Text('Archivio trovato su Google Drive'),
            subtitle: Text('ID ${widget.idRemoto}'),
          ),
          if (widget.avvertenza != null)
            Card(
              color: schema.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(widget.avvertenza!),
              ),
            ),
          const SizedBox(height: 12),
          if (!_conSecretKey) ...[
            TextField(
              controller: _password,
              obscureText: _nascosta,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _apri(),
              decoration: InputDecoration(
                labelText: 'Password dell\'archivio',
                helperText: 'La stessa che usi sull\'altro dispositivo.',
                suffixIcon: IconButton(
                  tooltip: _nascosta ? 'Mostra password' : 'Nascondi password',
                  icon: Icon(
                    _nascosta ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _nascosta = !_nascosta),
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => setState(() {
                  _conSecretKey = true;
                  _errore = null;
                }),
                child: const Text(
                  'Ho dimenticato la password: uso la Secret Key',
                ),
              ),
            ),
          ] else ...[
            CampoSecretKey(
              controller: _secretKey,
              onValidita: (v) => setState(() => _secretKeyValida = v),
            ),
            const SizedBox(height: 12),
            CampiNuovaPassword(
              password: _nuova,
              conferma: _conferma,
              etichetta: 'Nuova password',
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => setState(() {
                  _conSecretKey = false;
                  _errore = null;
                }),
                child: const Text('Ricordo la password'),
              ),
            ),
          ],
          if (_errore != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_errore!, style: TextStyle(color: schema.error)),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _occupato || (_conSecretKey && !_secretKeyValida)
                ? null
                : _apri,
            icon: _occupato
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_download_outlined),
            label: Text(_occupato ? 'Scarico i dati…' : 'Scarica e apri'),
          ),
        ],
      ),
    );
  }
}

/// Primo avvio su un dispositivo nuovo: accesso a Google Drive e apertura
/// dell'archivio creato sull'altro dispositivo.
class CollegaDispositivo extends StatefulWidget {
  const CollegaDispositivo({
    super.key,
    required this.sessione,
    required this.onIndietro,
  });

  final Sessione sessione;
  final VoidCallback onIndietro;

  @override
  State<CollegaDispositivo> createState() => _CollegaDispositivoState();
}

class _CollegaDispositivoState extends State<CollegaDispositivo> {
  SyncBackend? _remoto;
  String? _idRemoto;
  bool _cerco = false;
  String? _messaggio;

  Future<void> _accedi() async {
    setState(() {
      _cerco = true;
      _messaggio = null;
    });
    try {
      final remoto = await widget.sessione.spazioRemoto();
      if (remoto == null) {
        setState(() => _cerco = false);
        return;
      }
      final id = await Sincronizzatore.idArchivioRemoto(remoto);
      if (!mounted) {
        return;
      }
      setState(() {
        _cerco = false;
        _remoto = remoto;
        _idRemoto = id;
        _messaggio = id == null ? '${const NessunArchivioRemoto()}' : null;
      });
    } on SocketException {
      if (mounted) {
        setState(() {
          _cerco = false;
          _messaggio = 'Nessuna connessione a Internet: riprova.';
        });
      }
    } catch (e, stack) {
      if (mounted) {
        setState(() => _cerco = false);
        await mostraErroreImprevisto(context, e, stack);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remoto = _remoto;
    final id = _idRemoto;
    return PaginaCentrata(
      appBar: AppBar(
        leading: BackButton(onPressed: widget.onIndietro),
        title: const Text('Ho già un archivio'),
      ),
      children: [
        const Icon(Icons.devices_outlined, size: 56),
        const SizedBox(height: 16),
        Text(
          'Usa qui l\'archivio dell\'altro dispositivo',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          '1. Sull\'altro dispositivo accendi la sincronizzazione (icona a '
          'forma di nuvola, in alto).\n'
          '2. Qui accedi allo stesso account Google.\n'
          '3. Apri l\'archivio con la sua password: i dati arrivano cifrati e '
          'si leggono solo qui.',
        ),
        const SizedBox(height: 24),
        if (remoto != null && id != null)
          ModuloArchivioRemoto(
            sessione: widget.sessione,
            remoto: remoto,
            idRemoto: id,
          )
        else ...[
          if (_messaggio != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _messaggio!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton.icon(
            onPressed: _cerco ? null : _accedi,
            icon: const Icon(Icons.login),
            label: Text(_cerco ? 'Attendo Google…' : 'Accedi a Google Drive'),
          ),
          if (!Platform.isAndroid)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Si apre il browser: accedi, consenti e poi torna qui.',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ],
    );
  }
}
