import 'package:flutter/material.dart';

import '../../core/condivisi/accesso_drive_file.dart';
import '../../core/condivisi/drive_condiviso.dart';
import '../comuni/blocco_automatico.dart';
import '../comuni/layout.dart';

/// Laboratorio (ADR-019, consegna 0): prova la condivisione di una cartella
/// di Google Drive fra due account, prima di costruire i portafogli
/// condivisi. Nessun dato dell'archivio: solo file di testo di prova.
class ProvaCondivisionePagina extends StatefulWidget {
  const ProvaCondivisionePagina({
    super.key,
    required this.codice,
    this.accesso,
  });

  /// Chi sei (l'ID del tuo archivio, es. GF-7K3P-Q9XW): entra nei nomi della
  /// cartella e dei file, così si capisce chi li ha creati.
  final String codice;

  /// Sostituibile nei test.
  final AccessoDriveFile? accesso;

  @override
  State<ProvaCondivisionePagina> createState() =>
      _ProvaCondivisionePaginaState();
}

class _ProvaCondivisionePaginaState extends State<ProvaCondivisionePagina> {
  late final AccessoDriveFile _accesso =
      widget.accesso ?? AccessoDriveFile.perPiattaforma();
  final _email = TextEditingController();
  final _righe = <(bool?, String)>[];
  String? _cartella;
  bool _occupato = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _scrivi(bool? riuscito, String testo) =>
      setState(() => _righe.add((riuscito, testo)));

  Future<void> _passo(Future<void> Function() lavoro) async {
    setState(() => _occupato = true);
    try {
      await senzaBloccoAutomatico(lavoro);
    } on SceltaAnnullata {
      _scrivi(null, 'Scelta annullata.');
    } on ErroreDriveCondiviso catch (e) {
      _scrivi(false, 'Drive ha risposto ${e.stato}: ${_breve(e.dettaglio)}');
    } catch (e) {
      _scrivi(false, 'Errore: ${_breve('$e')}');
    } finally {
      if (mounted) {
        setState(() => _occupato = false);
      }
    }
  }

  static String _breve(String testo) =>
      testo.length > 300 ? '${testo.substring(0, 300)}…' : testo;

  String get _ora => TimeOfDay.now().format(context);

  /// Nomi chiari: la cartella del proprietario e un file per ogni persona.
  String get _nomeCartella => 'wallecy_share_${widget.codice}';
  String _nomeFile(String codice) => 'wallecy_$codice.txt';
  bool _mio(FileCondiviso f) => f.nome == _nomeFile(widget.codice);

  /// 1. Proprietario: crea la cartella, scrive un file e la condivide.
  Future<void> _creaECondividi() => _passo(() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      _scrivi(false, 'Scrivi l\'email Google dell\'altro account.');
      return;
    }
    final client = await _accesso.client();
    if (client == null) {
      _scrivi(null, 'Accesso a Google annullato.');
      return;
    }
    final drive = DriveCondiviso(client);
    try {
      final id = await drive.creaCartella(_nomeCartella);
      _cartella = id;
      _scrivi(true, 'Cartella "$_nomeCartella" creata nel tuo Drive.');
      await drive.scrivi(
        id,
        _nomeFile(widget.codice),
        'Ciao dal proprietario ${widget.codice}, $_ora',
      );
      _scrivi(true, 'File "${_nomeFile(widget.codice)}" scritto.');
      await drive.condividi(id, email);
      _scrivi(true, 'Cartella condivisa con $email (riceverà un\'email).');
    } finally {
      drive.chiudi();
    }
  });

  /// 2. Membro: sceglie la cartella, legge e scrive.
  Future<void> _scegliELeggi() => _passo(() async {
    final scelta = await _accesso.scegliCartella();
    final drive = DriveCondiviso(scelta.client);
    try {
      if (scelta.scelti.isEmpty) {
        _scrivi(false, 'Nessuna cartella scelta.');
        return;
      }
      final id = scelta.scelti.first;
      final scelto = await drive.info(id);
      if (!scelto.cartella) {
        _scrivi(
          false,
          'Hai scelto il file "${scelto.nome}". Scegli invece la cartella '
          '"wallecy_share_…" (la cartella, non i file al suo interno).',
        );
        return;
      }
      _scrivi(true, 'Cartella scelta: "${scelto.nome}".');
      final file = await drive.elenca(id);
      _scrivi(
        file.isNotEmpty,
        file.isEmpty
            ? 'Non vedo i file dentro la cartella.'
            : 'Vedo ${file.length} file: '
                  '${file.map((f) => '${f.nome} (${f.autore})').join(', ')}.',
      );
      for (final f in file.where((f) => !_mio(f))) {
        final testo = await drive.leggi(f.id);
        _scrivi(true, 'Letto "${f.nome}": $testo');
      }
      await drive.scrivi(
        id,
        _nomeFile(widget.codice),
        'Ciao dal membro ${widget.codice}, $_ora',
      );
      _scrivi(
        true,
        'File "${_nomeFile(widget.codice)}" scritto nella cartella condivisa.',
      );
    } finally {
      drive.chiudi();
    }
  });

  /// 3. Proprietario: vede il file del membro?
  Future<void> _controlla() => _passo(() async {
    final id = _cartella;
    if (id == null) {
      _scrivi(false, 'Prima crea la cartella (passo 1) su questo dispositivo.');
      return;
    }
    final client = await _accesso.client();
    if (client == null) {
      return;
    }
    final drive = DriveCondiviso(client);
    try {
      final file = await drive.elenca(id);
      final membri = file.where((f) => !_mio(f));
      _scrivi(
        membri.isNotEmpty,
        membri.isEmpty
            ? 'Il file del membro non c\'è ancora (file visti: '
                  '${file.map((f) => f.nome).join(', ')}).'
            : 'Vedo il file del membro.',
      );
      for (final f in membri) {
        _scrivi(true, 'Letto "${f.nome}": ${await drive.leggi(f.id)}');
      }
    } finally {
      drive.chiudi();
    }
  });

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Prova di condivisione')),
      body: LayoutBuilder(
        builder: (context, vincoli) => ListView(
          padding: marginiPagina(vincoli),
          children: [
            const Text(
              'Prova tecnica per i portafogli condivisi, con due account '
              'Google su due dispositivi. Usa solo file di testo di prova, '
              'nessun dato del tuo archivio.',
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '1 · Proprietario (questo dispositivo)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Google dell\'altro account',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _occupato ? null : _creaECondividi,
                      child: const Text('Crea la cartella e condividila'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _occupato ? null : _controlla,
                      child: const Text('3 · Controlla il file del membro'),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '2 · Membro (sull\'altro dispositivo)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nella finestra di Google apri «Condivisi con me» e '
                      'scegli la cartella «wallecy_share_…» (si vedono solo '
                      'le cartelle).',
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _occupato ? null : _scegliELeggi,
                      child: const Text('Scegli la cartella condivisa'),
                    ),
                  ],
                ),
              ),
            ),
            if (_occupato) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            for (final (riuscito, testo) in _righe)
              ListTile(
                dense: true,
                leading: Icon(
                  switch (riuscito) {
                    true => Icons.check_circle_outline,
                    false => Icons.error_outline,
                    null => Icons.info_outline,
                  },
                  color: switch (riuscito) {
                    true => schema.primary,
                    false => schema.error,
                    null => schema.onSurfaceVariant,
                  },
                ),
                title: Text(testo),
              ),
          ],
        ),
      ),
    );
  }
}
