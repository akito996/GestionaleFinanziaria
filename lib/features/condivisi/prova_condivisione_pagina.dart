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
  bool _mio(String nome) => nome == _nomeFile(widget.codice);

  /// Nel file del proprietario ogni membro lascia l'id del proprio file.
  static final _segnalazione = RegExp(
    r'^membro (\S+): (\S+)$',
    multiLine: true,
  );

  /// File dei membri segnalati nel file del proprietario (passo 3).
  var _segnalati = <String>[];

  static const _invito =
      'Ti ho invitato a provare la condivisione di WalleCy. Sul tuo '
      'dispositivo apri WalleCy, Impostazioni, Laboratorio, e premi '
      '"Scegli la cartella o il file condiviso".';

  /// 1. Proprietario: cartella dentro «WalleCy» (riusata se c'è già), il suo
  /// file e la condivisione con l'altro account.
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
      final cartella = await drive.cartellaDentroWalleCy(_nomeCartella);
      final percorso = '${DriveCondiviso.cartellaApp}/$_nomeCartella';
      _scrivi(true, switch (cartella.origine) {
        Origine.creata => 'Cartella "$percorso" creata nel tuo Drive.',
        Origine.trovata => 'Cartella "$percorso" già presente: la riuso.',
        Origine.spostata =>
          'Cartella "$_nomeCartella" già presente: spostata dentro '
              '"${DriveCondiviso.cartellaApp}".',
      });
      final nome = _nomeFile(widget.codice);
      final esistente = await drive.trovaFile(cartella.id, nome);
      // Le segnalazioni dei membri restano anche se il file si riscrive.
      final segnalazioni = esistente == null
          ? const <String>[]
          : [
              for (final m in _segnalazione.allMatches(
                await drive.leggi(esistente),
              ))
                m[0]!,
            ];
      await drive.scrivi(
        cartella.id,
        nome,
        [
          'Ciao dal proprietario ${widget.codice}, $_ora',
          ...segnalazioni,
        ].join('\n'),
      );
      _scrivi(
        true,
        'File "$nome" ${esistente == null ? 'scritto' : 'aggiornato'}.',
      );
      await drive.condividi(cartella.id, email, messaggio: _invito);
      _scrivi(
        true,
        'Cartella condivisa con $email: riceverà un\'email da Google con '
        'le istruzioni.',
      );
    } finally {
      drive.chiudi();
    }
  });

  /// 2. Membro: sceglie la cartella (o il file che c'è dentro), legge il file
  /// del proprietario e scrive il suo. Se non può scrivere nella cartella,
  /// mette il file nel proprio Drive, lo condivide col proprietario e glielo
  /// segnala nel file del proprietario.
  Future<void> _scegliELeggi() => _passo(() async {
    final scelta = await _accesso.scegli();
    final drive = DriveCondiviso(scelta.client);
    try {
      if (scelta.scelti.isEmpty) {
        _scrivi(false, 'Non hai scelto niente.');
        return;
      }
      String? cartella;
      String? emailProprietario;
      final altrui = <String>[];
      for (final id in scelta.scelti) {
        final info = await drive.info(id);
        if (info.cartella) {
          cartella ??= id;
          _scrivi(true, 'Hai scelto la cartella "${info.nome}".');
        } else {
          cartella ??= info.padri.firstOrNull;
          if (!_mio(info.nome)) {
            altrui.add(id);
          }
          _scrivi(true, 'Hai scelto il file "${info.nome}".');
        }
        if (!_mio(info.nome)) {
          emailProprietario ??= info.emailProprietario;
        }
      }
      if (cartella != null) {
        try {
          final file = await drive.elenca(cartella);
          _scrivi(
            null,
            file.isEmpty
                ? 'Nella cartella non vedo file.'
                : 'Nella cartella vedo ${file.length} file: '
                      '${file.map((f) => f.nome).join(', ')}.',
          );
          for (final f in file) {
            if (!_mio(f.nome) && !altrui.contains(f.id)) {
              altrui.add(f.id);
            }
          }
        } on ErroreDriveCondiviso catch (e) {
          _scrivi(false, 'Non posso elencare la cartella (Drive ${e.stato}).');
        }
      }
      String? fileProprietario;
      for (final id in altrui) {
        try {
          final testo = await drive.leggi(id);
          fileProprietario ??= id;
          _scrivi(true, 'Letto: ${testo.split('\n').first}');
        } on ErroreDriveCondiviso catch (e) {
          _scrivi(false, 'Non posso leggere un file (Drive ${e.stato}).');
        }
      }
      if (fileProprietario == null) {
        _scrivi(
          false,
          'Non vedo il file del proprietario: riprova scegliendo il file '
          '"wallecy_….txt" dentro la cartella.',
        );
      }

      final nome = _nomeFile(widget.codice);
      final testo = 'Ciao dal membro ${widget.codice}, $_ora';
      String? mio;
      if (cartella != null) {
        try {
          mio = await drive.scrivi(cartella, nome, testo);
          _scrivi(true, 'File "$nome" scritto nella cartella condivisa.');
        } on ErroreDriveCondiviso catch (e) {
          _scrivi(
            false,
            'Non posso scrivere nella cartella condivisa (Drive ${e.stato}).',
          );
        }
      }
      if (mio == null) {
        if (emailProprietario == null) {
          _scrivi(false, 'Non so chi è il proprietario: non condivido niente.');
          return;
        }
        // Piano B: il file nel mio Drive, condiviso col proprietario.
        mio = await drive.scrivi(await drive.cartellaWalleCy(), nome, testo);
        await drive.condividi(mio, emailProprietario);
        _scrivi(
          true,
          'File "$nome" scritto nel tuo Drive (cartella '
          '"${DriveCondiviso.cartellaApp}") e condiviso con $emailProprietario.',
        );
      }
      if (fileProprietario != null) {
        try {
          final vecchio = await drive.leggi(fileProprietario);
          await drive.aggiorna(
            fileProprietario,
            [
              for (final r in vecchio.split('\n'))
                if (!r.startsWith('membro ${widget.codice}:')) r,
              'membro ${widget.codice}: $mio',
            ].join('\n'),
          );
          _scrivi(true, 'Segnalato il tuo file nel file del proprietario.');
        } on ErroreDriveCondiviso catch (e) {
          _scrivi(
            false,
            'Non posso scrivere nel file del proprietario (Drive ${e.stato}).',
          );
        }
      }
    } finally {
      drive.chiudi();
    }
  });

  /// 3. Proprietario: vede il file del membro? Se no, cerca la segnalazione.
  Future<void> _controlla() => _passo(() async {
    final client = await _accesso.client();
    if (client == null) {
      return;
    }
    final drive = DriveCondiviso(client);
    try {
      final cartella = await drive.trovaCartella(_nomeCartella);
      if (cartella == null) {
        _scrivi(false, 'Prima crea la cartella (passo 1).');
        return;
      }
      final file = await drive.elenca(cartella);
      final membri = file.where((f) => !_mio(f.nome)).toList();
      for (final f in membri) {
        _scrivi(true, 'Letto "${f.nome}": ${await drive.leggi(f.id)}');
      }
      final mio = file.where((f) => _mio(f.nome)).firstOrNull;
      final visti = {for (final f in membri) f.id};
      _segnalati = mio == null
          ? []
          : [
              for (final m in _segnalazione.allMatches(
                await drive.leggi(mio.id),
              ))
                if (!visti.contains(m[2])) m[2]!,
            ];
      if (membri.isNotEmpty) {
        _scrivi(true, 'Vedo il file del membro nella cartella.');
      } else if (_segnalati.isNotEmpty) {
        _scrivi(
          null,
          'Il membro ha segnalato il suo file, ma non lo vedo ancora: '
          'premi «4 · Apri il file del membro».',
        );
      } else {
        _scrivi(
          false,
          'Il file del membro non c\'è ancora (file visti: '
          '${file.map((f) => f.nome).join(', ')}).',
        );
      }
    } finally {
      drive.chiudi();
    }
  });

  /// 4. Proprietario: apre il file del membro con la finestra di Google
  /// (mostra solo i file segnalati, se ce ne sono).
  Future<void> _apriFileMembro() => _passo(() async {
    final scelta = await _accesso.scegli(soloId: _segnalati);
    final drive = DriveCondiviso(scelta.client);
    try {
      var letti = 0;
      for (final id in scelta.scelti) {
        final info = await drive.info(id);
        if (info.cartella || _mio(info.nome)) {
          continue;
        }
        _scrivi(true, 'Letto "${info.nome}": ${await drive.leggi(id)}');
        letti++;
      }
      if (letti == 0) {
        _scrivi(false, 'Scegli il file "wallecy_….txt" del membro.');
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
              'nessun dato del tuo archivio, tutti nella cartella «WalleCy» '
              'del tuo Drive.',
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
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _occupato ? null : _apriFileMembro,
                      child: const Text('4 · Apri il file del membro'),
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
                      'scegli la cartella «wallecy_share_…». Se toccandola '
                      'la cartella si apre, scegli il file «wallecy_….txt» '
                      'che c\'è dentro: va bene lo stesso.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _occupato ? null : _scegliELeggi,
                      child: const Text(
                        'Scegli la cartella o il file condiviso',
                      ),
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
