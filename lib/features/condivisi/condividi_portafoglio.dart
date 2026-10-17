import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr/qr.dart';

import '../../core/condivisi/drive_condiviso.dart';
import '../../core/condivisi/portafogli_condivisi.dart';
import '../../core/db/archivio.dart';
import '../../core/db/tabelle.dart';
import '../../core/sessione.dart';
import '../comuni/avvisi.dart';
import '../comuni/blocco_automatico.dart';
import 'guida_condivisi.dart';

/// Invita una persona nel portafoglio (ADR-019): alla prima volta il
/// portafoglio diventa condiviso. Google le manda un'email.
Future<void> apriInvito(
  BuildContext context,
  Sessione sessione,
  String portafoglioId,
) async {
  final email = await showDialog<String>(
    context: context,
    builder: (_) => const _ModuloInvito(),
  );
  if (email == null || !context.mounted) {
    return;
  }
  await invitaPersona(context, sessione, portafoglioId, email);
}

/// L'invito vero e proprio, con l'esito per l'utente.
Future<void> invitaPersona(
  BuildContext context,
  Sessione sessione,
  String portafoglioId,
  String email,
) async {
  final messaggi = ScaffoldMessenger.of(context);
  // Resta finché la condivisione non è finita (una decina di richieste).
  messaggi
    ..clearSnackBars()
    ..showSnackBar(
      const SnackBar(
        duration: Duration(minutes: 5),
        content: Row(
          children: [
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Expanded(child: Text('Preparo la condivisione su Google Drive…')),
          ],
        ),
      ),
    );
  try {
    // Il consenso di Google si dà nel browser o in una finestra di sistema.
    final esito = await senzaBloccoAutomatico(
      () => sessione.condivisi.invita(portafoglioId, email),
    );
    if (!context.mounted) {
      return;
    }
    messaggi.clearSnackBars();
    switch (esito) {
      case EsitoInvito.invitato:
        messaggi.showSnackBar(
          avviso(
            content: Text(
              'Invito mandato a ${email.trim()}: ha un\'ora per accettare. '
              'Intanto il portafoglio si usa normalmente.',
            ),
          ),
        );
      case EsitoInvito.giaPresente ||
          EsitoInvito.seiTu ||
          EsitoInvito.rimandato:
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.person_outline),
            title: const Text('Persona già presente'),
            content: Text(switch (esito) {
              EsitoInvito.seiTu =>
                '${email.trim()} è il tuo account: sei già il proprietario '
                    'del portafoglio.',
              EsitoInvito.rimandato =>
                '${email.trim()} è già presente nel portafoglio ma non è '
                    'ancora entrata: le ho rimandato l\'invito (Google le '
                    'manda di nuovo l\'email) e ha di nuovo un\'ora per '
                    'accettare.',
              _ =>
                '${email.trim()} è già presente nel portafoglio: non serve '
                    'invitarla di nuovo.',
            }),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      case EsitoInvito.annullato:
        messaggi.showSnackBar(
          avviso(content: const Text('Accesso a Google annullato.')),
        );
    }
  } catch (e) {
    messaggi.clearSnackBars();
    if (context.mounted) {
      await condivisioneNonRiuscita(
        context,
        e is ErroreDriveCondiviso && e.stato == 408
            ? e.dettaglio
            : e is ErroreDriveCondiviso
            ? 'Google Drive ha risposto ${e.stato}.'
            : 'Errore: $e',
      );
    }
  }
}

/// La condivisione non è partita (o è scaduta): il portafoglio resta e si
/// usa normalmente; si può condividere più tardi.
Future<void> condivisioneNonRiuscita(BuildContext context, String motivo) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.group_off_outlined),
        title: const Text('Condivisione non riuscita'),
        content: Text(
          '$motivo\n\nIl portafoglio c\'è e si usa normalmente: puoi '
          'condividerlo più tardi: aprilo e scegli «Condividi con altre '
          'persone» dal menu ☰.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

class _ModuloInvito extends StatefulWidget {
  const _ModuloInvito();

  @override
  State<_ModuloInvito> createState() => _ModuloInvitoState();
}

class _ModuloInvitoState extends State<_ModuloInvito> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _invia() {
    if (_form.currentState!.validate()) {
      Navigator.of(context).pop(_email.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const Icon(Icons.group_add_outlined),
    title: const Text('Condividi il portafoglio'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _invia(),
              decoration: const InputDecoration(
                labelText: 'Email Google della persona',
                hintText: 'nome@gmail.com',
              ),
              validator: (v) =>
                  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch(v?.trim() ?? '')
                  ? null
                  : 'Scrivi un indirizzo email valido',
            ),
            const SizedBox(height: 12),
            Text(
              'All\'altra persona arriva un\'email con il link d\'invito: lo '
              'apre dal telefono e tocca «Accetta» entro un\'ora. I dati '
              'viaggiano cifrati: Google non li può leggere.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => apriGuidaCondivisi(context),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Come si fa, passo passo'),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Annulla'),
      ),
      FilledButton(onPressed: _invia, child: const Text('Invita')),
    ],
  );
}

/// Le persone di un portafoglio condiviso, nel suo dettaglio. Niente se il
/// portafoglio non è condiviso. Quando tutti hanno accettato è chiusa (solo
/// con chi è condiviso); si apre e si chiude con le frecce.
class SchedaPersone extends StatefulWidget {
  const SchedaPersone({
    super.key,
    required this.sessione,
    required this.portafoglioId,
  });

  final Sessione sessione;
  final String portafoglioId;

  @override
  State<SchedaPersone> createState() => _SchedaPersoneState();
}

class _SchedaPersoneState extends State<SchedaPersone> {
  Sessione get sessione => widget.sessione;
  String get portafoglioId => widget.portafoglioId;

  /// Preparato una volta sola: dopo il blocco dell'archivio il servizio non
  /// c'è più, e la scheda può ridisegnarsi un'ultima volta.
  late final Stream<List<VistaCondiviso>> _flusso = sessione.condivisi
      .osserva();

  /// Aperta o chiusa: decisa alla prima apertura (aperta solo se c'è
  /// qualcosa da fare), poi la cambia l'utente.
  bool? _aperta;

  /// "Con mario@gmail.com", "Con mario@gmail.com e altre 2 persone".
  static String _conChi(VistaCondiviso vista) {
    final altri = [
      for (final m in vista.membri)
        if (m.fileId != vista.info.mioFileId && m.stato != StatoMembro.uscito)
          m.email,
    ];
    return switch (altri.length) {
      0 => 'Nessun\'altra persona',
      1 => 'Con ${altri.first}',
      2 => 'Con ${altri.first} e ${altri.last}',
      _ => 'Con ${altri.first} e altre ${altri.length - 1} persone',
    };
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<VistaCondiviso>>(
    stream: _flusso,
    builder: (context, snapshot) {
      final vista = snapshot.data
          ?.where((v) => v.info.portafoglioId == portafoglioId)
          .firstOrNull;
      if (vista == null) {
        return const SizedBox.shrink();
      }
      final schema = Theme.of(context).colorScheme;
      final proprietario = vista.info.ruolo == RuoloMembro.proprietario;
      final inAttesa = [
        for (final m in vista.membri)
          if (PortafogliCondivisiServizio.scadenzaDi(m) case final scade?)
            (m.email, scade),
      ];
      final aperta = _aperta ??=
          inAttesa.isNotEmpty ||
          vista.info.chiave.isEmpty ||
          vista.membri.any((m) => m.stato == StatoMembro.scaduto);
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avviso: si aspetta la risposta delle persone invitate.
            for (final (email, scade) in inAttesa)
              Container(
                color: schema.secondaryContainer,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.hourglass_top,
                      color: schema.onSecondaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'In attesa di risposta da $email: ha tempo fino alle '
                        '${TimeOfDay.fromDateTime(scade.toLocal()).format(context)}. '
                        'Intanto il portafoglio si usa normalmente.',
                        style: TextStyle(color: schema.onSecondaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ListTile(
              leading: const Icon(Icons.group_outlined),
              title: const Text('Portafoglio condiviso'),
              onTap: () => setState(() => _aperta = !aperta),
              subtitle: Text(
                !aperta
                    ? _conChi(vista)
                    : vista.info.chiave.isEmpty
                    ? 'In attesa che l\'app del proprietario ti consegni '
                          'la chiave.'
                    : proprietario
                    ? 'Sei il proprietario. Le voci le modificano chi le '
                          'inserisce e il proprietario.'
                    : 'Le voci le modificano chi le inserisce e il '
                          'proprietario.',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (proprietario && aperta)
                    IconButton(
                      tooltip: 'Invita una persona',
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      onPressed: () =>
                          apriInvito(context, sessione, portafoglioId),
                    ),
                  IconButton(
                    tooltip: aperta ? 'Mostra meno' : 'Mostra di più',
                    icon: Icon(aperta ? Icons.expand_less : Icons.expand_more),
                    onPressed: () => setState(() => _aperta = !aperta),
                  ),
                ],
              ),
            ),
            if (aperta) ...[
              for (final m in vista.membri)
                ListTile(
                  dense: true,
                  leading: Icon(
                    m.ruolo == RuoloMembro.proprietario
                        ? Icons.star_outline
                        : Icons.person_outline,
                  ),
                  title: Text(
                    m.stato == StatoMembro.invitato
                        ? '${m.email} (da confermare)'
                        : m.email,
                  ),
                  subtitle: Text(_statoPersona(vista.info, m)),
                  trailing: m.fileId == vista.info.mioFileId
                      ? null
                      : proprietario &&
                            (m.stato == StatoMembro.invitato ||
                                m.stato == StatoMembro.scaduto)
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (m.stato == StatoMembro.invitato)
                              IconButton(
                                tooltip: 'Copia il link d\'invito',
                                icon: const Icon(Icons.link),
                                onPressed: () => _copiaLink(m),
                              ),
                            IconButton(
                              tooltip: 'Invita di nuovo',
                              icon: const Icon(Icons.forward_to_inbox_outlined),
                              onPressed: () => invitaPersona(
                                context,
                                sessione,
                                portafoglioId,
                                m.email,
                              ),
                            ),
                          ],
                        )
                      : Icon(
                          m.verificato
                              ? Icons.verified_user_outlined
                              : Icons.gpp_maybe_outlined,
                          color: m.verificato
                              ? schema.primary
                              : schema.onSurfaceVariant,
                        ),
                  onTap:
                      m.fileId == vista.info.mioFileId || m.chiaveFirma == null
                      ? null
                      : () => apriCodiceSicurezza(context, sessione, m),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => interrompiCondivisione(
                    context,
                    sessione,
                    portafoglioId,
                    proprietario: proprietario,
                  ),
                  icon: const Icon(Icons.link_off),
                  label: Text(
                    proprietario
                        ? 'Interrompi la condivisione'
                        : 'Esci dalla condivisione',
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );

  /// Il link d'invito negli appunti, da incollare in WhatsApp o in un SMS.
  Future<void> _copiaLink(Membro m) async {
    final invito = await sessione.condivisi.invitoPer(portafoglioId, m);
    if (invito == null || !mounted) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: invito.link.toString()));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        avviso(
          content: Text(
            'Link d\'invito copiato: incollalo in un messaggio (WhatsApp, '
            'SMS) per ${m.email}. Dal suo telefono apre WalleCy sull\'invito.',
          ),
        ),
      );
  }

  static String _statoPersona(PortafoglioCondiviso info, Membro m) {
    final ruolo = m.ruolo == RuoloMembro.proprietario
        ? 'Proprietario'
        : 'Membro';
    if (m.fileId == info.mioFileId) {
      return '$ruolo · sei tu';
    }
    return switch (m.stato) {
      StatoMembro.invitato => '$ruolo · in attesa di risposta',
      StatoMembro.scaduto =>
        '$ruolo · invito scaduto (nessuna risposta entro un\'ora): '
            'puoi invitarla di nuovo',
      StatoMembro.uscito => '$ruolo · uscito',
      _ =>
        m.verificato
            ? '$ruolo · codice di sicurezza verificato'
            : '$ruolo · tocca per verificare il codice di sicurezza',
    };
  }
}

/// Codice di sicurezza tra me e [membro]: lo stesso sui due schermi. Si
/// confronta inquadrando il QR o leggendo le cifre.
Future<void> apriCodiceSicurezza(
  BuildContext context,
  Sessione sessione,
  Membro membro,
) async {
  final codice = sessione.condivisi.codiceSicurezza(membro);
  if (codice == null) {
    return;
  }
  final gruppi = codice.split(' ');
  final righe = [
    for (var i = 0; i < gruppi.length; i += 4)
      gruppi.skip(i).take(4).join('  '),
  ];
  final coincide = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.qr_code_2),
      title: const Text('Codice di sicurezza'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Con ${membro.email}: confrontalo con quello sul suo '
                'schermo, inquadrando il QR o leggendo le cifre. Se '
                'coincidono, nessuno si è messo in mezzo.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: SizedBox.square(
                  dimension: 200,
                  child: CustomPaint(painter: _DisegnoQr('wallecy:$codice')),
                ),
              ),
              const SizedBox(height: 16),
              for (final r in righe)
                Text(
                  r,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Non coincidono'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('I codici coincidono'),
        ),
      ],
    ),
  );
  if (!context.mounted || coincide == null) {
    return;
  }
  final messaggi = ScaffoldMessenger.of(context);
  if (coincide) {
    await sessione.condivisi.segnaVerificato(membro.id);
    messaggi
      ..clearSnackBars()
      ..showSnackBar(
        avviso(
          content: Text('${membro.email}: codice di sicurezza verificato.'),
        ),
      );
  } else {
    messaggi
      ..clearSnackBars()
      ..showSnackBar(
        avviso(
          content: const Text(
            'I codici non coincidono: non inserire dati riservati e parlane '
            'con l\'altra persona. Potrebbe esserci qualcuno in mezzo.',
          ),
        ),
      );
  }
}

/// Il QR del codice, disegnato con il pacchetto "qr" (BSD).
class _DisegnoQr extends CustomPainter {
  _DisegnoQr(String testo)
    : _immagine = QrImage(
        QrCode.fromData(data: testo, errorCorrectLevel: QrErrorCorrectLevel.M),
      );

  final QrImage _immagine;

  @override
  void paint(Canvas canvas, Size size) {
    final n = _immagine.moduleCount;
    final lato = size.shortestSide / n;
    final pennello = Paint()..color = Colors.black;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (_immagine.isDark(r, c)) {
          canvas.drawRect(
            Rect.fromLTWH(c * lato, r * lato, lato, lato),
            pennello,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_DisegnoQr vecchio) => false;
}

/// Fine della condivisione scelta da qui (ADR-019): il proprietario la chiude
/// per tutti, un membro esce. Il portafoglio resta come un portafoglio
/// normale e le voci degli altri diventano "ex membro". `true` se fatto.
Future<bool> interrompiCondivisione(
  BuildContext context,
  Sessione sessione,
  String portafoglioId, {
  required bool proprietario,
  bool conferma = true,
}) async {
  if (conferma) {
    final procedi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.link_off),
        title: Text(
          proprietario
              ? 'Interrompere la condivisione?'
              : 'Uscire dalla condivisione?',
        ),
        content: Text(
          proprietario
              ? 'La condivisione finisce per tutti: la cartella su Google Drive '
                    'va nel cestino. Il portafoglio resta qui e sui telefoni '
                    'degli altri come un portafoglio normale; le voci degli '
                    'altri diventano «ex membro».'
              : 'Non riceverai più le voci degli altri e loro non riceveranno '
                    'le tue. Il portafoglio resta qui come un portafoglio '
                    'normale; le voci degli altri diventano «ex membro».',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(proprietario ? 'Interrompi' : 'Esci'),
          ),
        ],
      ),
    );
    if (procedi != true || !context.mounted) {
      return false;
    }
  }
  final messaggi = ScaffoldMessenger.of(context);
  try {
    await senzaBloccoAutomatico(
      () => sessione.condivisi.interrompi(portafoglioId),
    );
  } on ErroreDriveCondiviso catch (e) {
    messaggi
      ..clearSnackBars()
      ..showSnackBar(
        avviso(
          content: Text(
            e.stato == 408
                ? e.dettaglio
                : 'Google Drive ha risposto ${e.stato}: condivisione non '
                      'interrotta. Riprova quando sei online.',
          ),
        ),
      );
    return false;
  }
  messaggi
    ..clearSnackBars()
    ..showSnackBar(
      avviso(
        content: Text(
          proprietario
              ? 'Condivisione interrotta: il portafoglio resta qui come un '
                    'portafoglio normale.'
              : 'Sei uscito dalla condivisione: il portafoglio resta qui come '
                    'un portafoglio normale.',
        ),
      ),
    );
  return true;
}
