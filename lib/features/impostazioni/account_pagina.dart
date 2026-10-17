import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/account.dart';
import '../../core/db/archivio.dart';
import '../../core/sessione.dart';
import '../comuni/avvisi.dart';
import '../comuni/blocco_automatico.dart';
import '../comuni/layout.dart';

/// La voce "Account" delle Impostazioni: nome, email e nome nelle
/// condivisioni, con un riepilogo.
class VoceAccount extends StatefulWidget {
  const VoceAccount({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<VoceAccount> createState() => _VoceAccountState();
}

class _VoceAccountState extends State<VoceAccount> {
  // Preparato una volta: dopo il blocco la sessione non ha più l'archivio.
  late final _profilo = widget.sessione.account.osserva();
  late final _codice = widget.sessione.account.idArchivio;

  @override
  Widget build(BuildContext context) => StreamBuilder<Profilo?>(
    stream: _profilo,
    builder: (context, snapshot) {
      final p = snapshot.data;
      final condivisione = ProfiloAccount.pulito(p?.nomeCondivisione);
      return Card(
        child: ListTile(
          leading: const Icon(Icons.account_circle_outlined),
          title: Text((p?.nome ?? '').isEmpty ? 'Il tuo account' : p!.nome),
          subtitle: Text(
            [
              if ((p?.email ?? '').isNotEmpty) p!.email,
              'Nelle condivisioni: '
                  '${condivisione.isEmpty ? _codice : condivisione}',
            ].join('\n'),
          ),
          isThreeLine: (p?.email ?? '').isNotEmpty,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AccountPagina(sessione: widget.sessione),
            ),
          ),
        ),
      );
    },
  );
}

/// Nome e cognome, email dell'account Google e nome nelle condivisioni.
class AccountPagina extends StatefulWidget {
  const AccountPagina({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<AccountPagina> createState() => _AccountPaginaState();
}

class _AccountPaginaState extends State<AccountPagina> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _condivisione = TextEditingController();
  late final _account = widget.sessione.account;
  bool _caricato = false;
  bool _occupato = false;

  @override
  void initState() {
    super.initState();
    _account.leggi().then((p) {
      if (!mounted) {
        return;
      }
      setState(() {
        _nome.text = p?.nome ?? '';
        _email.text = p?.email ?? '';
        _condivisione.text = p?.nomeCondivisione ?? '';
        _caricato = true;
      });
    });
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _condivisione.dispose();
    super.dispose();
  }

  void _avvisa(String testo) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(avviso(content: Text(testo)));

  /// Email (e nome, se manca) dell'account Google: dalla sincronizzazione o,
  /// se non è disponibile, dal permesso dei portafogli condivisi.
  Future<void> _daGoogle() async {
    setState(() => _occupato = true);
    try {
      final dati = await senzaBloccoAutomatico(() async {
        final sessione = widget.sessione;
        http.Client? client;
        if (sessione.accessoGoogle.disponibile) {
          try {
            client = await sessione.accessoGoogle.client(interattivo: true);
          } on Object {
            client = null;
          }
        }
        client ??= await sessione.accessoDriveFile.client();
        if (client == null) {
          return null;
        }
        try {
          return await ProfiloAccount.daGoogle(client);
        } finally {
          client.close();
        }
      });
      if (!mounted) {
        return;
      }
      if (dati == null || dati.email == null) {
        _avvisa('Accesso a Google annullato: scrivi l\'email a mano.');
        return;
      }
      setState(() {
        _email.text = dati.email!;
        if (_nome.text.trim().isEmpty && dati.nome != null) {
          _nome.text = dati.nome!;
        }
      });
    } on Object catch (e) {
      if (mounted) {
        _avvisa('Non riesco a leggere l\'account Google: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _occupato = false);
      }
    }
  }

  Future<void> _salva() async {
    final email = _email.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _avvisa('L\'email non sembra giusta: controllala.');
      return;
    }
    setState(() => _occupato = true);
    final navigatore = Navigator.of(context);
    await _account.salva(
      nome: _nome.text,
      email: email,
      nomeCondivisione: _condivisione.text,
    );
    // Il nome nuovo arriva subito alle persone dei portafogli condivisi.
    widget.sessione.condivisiSeAperto?.sincronizza().ignore();
    if (!mounted) {
      return;
    }
    _avvisa('Account salvato');
    navigatore.pop();
  }

  @override
  Widget build(BuildContext context) {
    final piccolo = Theme.of(context).textTheme.bodySmall;
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: LayoutBuilder(
        builder: (context, vincoli) => ListView(
          padding: marginiPagina(vincoli),
          children: [
            if (!_caricato || _occupato) const LinearProgressIndicator(),
            Text(
              'Questi dati restano cifrati nel tuo archivio e viaggiano solo '
              'tra i tuoi dispositivi.',
              style: piccolo,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nome,
              enabled: _caricato,
              maxLength: ProfiloAccount.lunghezzaMassima,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome e cognome',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _email,
              enabled: _caricato,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                helperText: 'Quella dell\'account Google con cui sincronizzi',
                prefixIcon: const Icon(Icons.mail_outline),
                suffixIcon: IconButton(
                  tooltip: 'Leggi da Google',
                  icon: const Icon(Icons.download_outlined),
                  onPressed: _occupato || !_caricato ? null : _daGoogle,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _condivisione,
              enabled: _caricato,
              maxLength: ProfiloAccount.lunghezzaMassima,
              decoration: InputDecoration(
                labelText: 'Nome nelle condivisioni',
                hintText: _account.idArchivio,
                helperText:
                    'Lo vedono le persone dei portafogli condivisi accanto '
                    'alle voci che inserisci. Vuoto = il codice del tuo '
                    'archivio (${_account.idArchivio}).',
                helperMaxLines: 3,
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _occupato || !_caricato ? null : _salva,
              icon: const Icon(Icons.check),
              label: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}
