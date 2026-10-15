import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/crypto/eccezioni.dart';
import '../../core/sessione.dart';
import '../comuni/campo_secret_key.dart';
import '../comuni/errori.dart';
import '../comuni/nuova_password.dart';
import '../comuni/salva_file.dart';
import '../sync/archivio_remoto.dart';
import '../../core/identita.dart';

/// Primo avvio: spiegazione → password → Secret Key (salva file o copia) → verifica.
/// L'archivio viene creato solo alla fine, dopo la verifica.
class PrimoAvvioPagina extends StatefulWidget {
  const PrimoAvvioPagina({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<PrimoAvvioPagina> createState() => _PrimoAvvioPaginaState();
}

enum _Passo { introduzione, password, secretKey, verifica, collega }

class _PrimoAvvioPaginaState extends State<PrimoAvvioPagina> {
  final _formPassword = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _conferma = TextEditingController();
  final _verifica = TextEditingController();

  _Passo _passo = _Passo.introduzione;
  bool _occupato = false;
  ({String idArchivio, String secretKey})? _creata;
  String? _salvataggio;
  bool _verificaValida = false;
  String? _erroreVerifica;

  @override
  void dispose() {
    _password.dispose();
    _conferma.dispose();
    _verifica.dispose();
    super.dispose();
  }

  Future<void> _esegui(Future<void> Function() azione) async {
    try {
      await azione();
    } catch (e, stack) {
      if (mounted) {
        setState(() => _occupato = false);
        await mostraErroreImprevisto(context, e, stack);
      }
    }
  }

  Future<void> _creaChiavi() => _esegui(() async {
    if (!_formPassword.currentState!.validate()) {
      return;
    }
    setState(() => _occupato = true);
    final creata = await widget.sessione.preparaNuovoArchivio(_password.text);
    if (!mounted) {
      return;
    }
    setState(() {
      _password.clear();
      _conferma.clear();
      _creata = creata;
      _salvataggio = null;
      _occupato = false;
      _passo = _Passo.secretKey;
    });
  });

  String get _nomeFile =>
      '${Identita.nome}-SecretKey-${_creata!.idArchivio}.txt';

  String _contenutoFile() {
    final oggi = DateTime.now();
    final data =
        '${oggi.day.toString().padLeft(2, '0')}/'
        '${oggi.month.toString().padLeft(2, '0')}/${oggi.year}';
    return [
      '${Identita.nome} - Secret Key',
      '',
      'ID archivio: ${_creata!.idArchivio}',
      'Secret Key:  ${_creata!.secretKey}',
      'Creata il:   $data',
      '',
      'A cosa serve: se dimentichi la password principale, con questa Secret Key',
      'recuperi l\'archivio e ne scegli una nuova.',
      'Come si usa: nell\'app premi "Ho dimenticato la password", poi',
      '"Scegli il file" (questo file) oppure incolla la riga "Secret Key".',
      '',
    ].join(Platform.isWindows ? '\r\n' : '\n');
  }

  Future<void> _salvaFile() => _esegui(() async {
    final dove = await salvaConNome(
      nome: _nomeFile,
      byte: Uint8List.fromList(utf8.encode(_contenutoFile())),
      tipo: 'Testo',
      estensione: 'txt',
      mime: 'text/plain',
    );
    if (dove == null) {
      return;
    }
    if (mounted) {
      setState(() => _salvataggio = 'Salvata nel file $dove');
    }
  });

  Future<void> _copia() => _esegui(() async {
    await Clipboard.setData(ClipboardData(text: _creata!.secretKey));
    if (mounted) {
      setState(() => _salvataggio = 'Copiata: incollala dove vuoi conservarla');
    }
  });

  void _vaiAllaVerifica() {
    _verifica.clear();
    setState(() {
      _erroreVerifica = null;
      _verificaValida = false;
      _passo = _Passo.verifica;
    });
  }

  Future<void> _verificaECrea() => _esegui(() async {
    final bool corrisponde;
    try {
      corrisponde = widget.sessione.verificaSecretKey(_verifica.text);
    } on SecretKeyNonValidaException catch (e) {
      setState(() => _erroreVerifica = e.messaggio);
      return;
    }
    if (!corrisponde) {
      setState(
        () => _erroreVerifica =
            'Questa non è la Secret Key appena creata: '
            'carica il file giusto o copiala di nuovo.',
      );
      return;
    }
    setState(() {
      _occupato = true;
      _erroreVerifica = null;
    });
    _creata = null;
    await widget.sessione.confermaNuovoArchivio();
  });

  void _ricomincia() {
    widget.sessione.annullaNuovoArchivio();
    setState(() {
      _creata = null;
      _passo = _Passo.introduzione;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_passo) {
      _Passo.introduzione => _introduzione(context),
      _Passo.password => _sceltaPassword(context),
      _Passo.secretKey => _mostraSecretKey(context),
      _Passo.verifica => _verificaSecretKey(context),
      _Passo.collega => CollegaDispositivo(
        sessione: widget.sessione,
        onIndietro: () => setState(() => _passo = _Passo.introduzione),
      ),
    };
  }

  Widget _introduzione(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    return PaginaCentrata(
      children: [
        const Icon(Icons.lock_outline, size: 56),
        const SizedBox(height: 16),
        Text(
          'Benvenuto in ${Identita.nome}',
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
          testo:
              'Riceverai una Secret Key da salvare come file o da copiare: '
              'serve se dimentichi la password.',
        ),
        const _Punto(
          icona: Icons.warning_amber,
          testo:
              'Se perdi sia la password sia la Secret Key, i dati non si possono '
              'recuperare in nessun modo. È il prezzo della privacy totale.',
          importante: true,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => setState(() => _passo = _Passo.password),
          child: const Text('Inizia'),
        ),
        // Secondo dispositivo: l'archivio arriva da Google Drive.
        if (widget.sessione.accessoGoogle.disponibile) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _passo = _Passo.collega),
            icon: const Icon(Icons.devices_outlined),
            label: const Text('Ho già un archivio su un altro dispositivo'),
          ),
        ],
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
          const InCorso(testo: 'Sto proteggendo la password…')
        else
          FilledButton(onPressed: _creaChiavi, child: const Text('Continua')),
      ],
    );
  }

  Widget _mostraSecretKey(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    final creata = _creata!;
    return PaginaCentrata(
      appBar: AppBar(
        title: const Text('La tua Secret Key'),
        leading: BackButton(onPressed: _ricomincia),
      ),
      children: [
        Text(
          'È la chiave di riserva del tuo archivio: se dimentichi la password, '
          'con questa lo recuperi. Salvala adesso come file oppure copiala '
          'dove preferisci (per esempio nel tuo password manager).',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID archivio',
                  style: TextStyle(color: schema.outline, fontSize: 12),
                ),
                SelectableText(
                  creata.idArchivio,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Secret Key',
                  style: TextStyle(color: schema.outline, fontSize: 12),
                ),
                SelectableText(
                  creata.secretKey,
                  key: const Key('secret-key'),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: _salvaFile,
              icon: const Icon(Icons.save_alt),
              label: const Text('Salva come file'),
            ),
            OutlinedButton.icon(
              onPressed: _copia,
              icon: const Icon(Icons.copy),
              label: const Text('Copia'),
            ),
          ],
        ),
        if (_salvataggio != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: schema.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(_salvataggio!)),
              ],
            ),
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _salvataggio != null ? _vaiAllaVerifica : null,
          child: const Text('Continua'),
        ),
        if (_salvataggio == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Salva o copia la Secret Key per continuare.',
              textAlign: TextAlign.center,
              style: TextStyle(color: schema.outline),
            ),
          ),
      ],
    );
  }

  Widget _verificaSecretKey(BuildContext context) {
    return PaginaCentrata(
      appBar: AppBar(
        title: const Text('Verifica'),
        leading: BackButton(
          onPressed: _occupato
              ? null
              : () => setState(() => _passo = _Passo.secretKey),
        ),
      ),
      children: [
        Text(
          'Ultimo passo: controlliamo che la Secret Key sia salvata bene. '
          'Scegli il file che hai appena salvato oppure incolla la Secret Key.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        CampoSecretKey(
          controller: _verifica,
          errore: _erroreVerifica,
          onValidita: (valida) => setState(() {
            _verificaValida = valida;
            _erroreVerifica = null;
          }),
        ),
        const SizedBox(height: 24),
        if (_occupato)
          const InCorso(testo: 'Creo l\'archivio cifrato…')
        else
          FilledButton(
            onPressed: _verificaValida ? _verificaECrea : null,
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
