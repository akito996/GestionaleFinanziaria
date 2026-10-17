import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

import '../../core/condivisi/drive_condiviso.dart';
import '../../core/condivisi/portafogli_condivisi.dart';
import '../../core/db/archivio.dart';
import '../../core/db/tabelle.dart';
import '../../core/sessione.dart';
import '../comuni/avvisi.dart';
import '../comuni/blocco_automatico.dart';
import '../comuni/errori.dart';

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
  messaggi
    ..clearSnackBars()
    ..showSnackBar(
      avviso(content: const Text('Preparo la condivisione su Google Drive…')),
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
              'Invito mandato a ${email.trim()}: riceverà un\'email da Google. '
              'Resta "da confermare" finché non entra con WalleCy.',
            ),
          ),
        );
      case EsitoInvito.giaPresente || EsitoInvito.seiTu:
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.person_outline),
            title: const Text('Persona già presente'),
            content: Text(
              esito == EsitoInvito.seiTu
                  ? '${email.trim()} è il tuo account: sei già il '
                        'proprietario del portafoglio.'
                  : '${email.trim()} è già presente nel portafoglio: non '
                        'serve invitarla di nuovo.',
            ),
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
  } on ErroreDriveCondiviso catch (e) {
    messaggi
      ..clearSnackBars()
      ..showSnackBar(
        avviso(
          content: Text(
            'Google Drive ha risposto ${e.stato}: invito non mandato. '
            'Riprova tra poco.',
          ),
        ),
      );
  } catch (e, stack) {
    messaggi.clearSnackBars();
    if (context.mounted) {
      await mostraErroreImprevisto(context, e, stack);
    }
  }
}

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
              'Google le manda un\'email. Lei apre WalleCy e preme '
              '"Unisciti" in Impostazioni › Portafogli condivisi. I dati '
              'viaggiano cifrati: Google non li può leggere.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
/// portafoglio non è condiviso.
class SchedaPersone extends StatelessWidget {
  const SchedaPersone({
    super.key,
    required this.sessione,
    required this.portafoglioId,
  });

  final Sessione sessione;
  final String portafoglioId;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<VistaCondiviso>>(
    stream: sessione.condivisi.osserva(),
    builder: (context, snapshot) {
      final vista = snapshot.data
          ?.where((v) => v.info.portafoglioId == portafoglioId)
          .firstOrNull;
      if (vista == null) {
        return const SizedBox.shrink();
      }
      final schema = Theme.of(context).colorScheme;
      final proprietario = vista.info.ruolo == RuoloMembro.proprietario;
      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.group_outlined),
              title: const Text('Portafoglio condiviso'),
              subtitle: Text(
                vista.info.chiave.isEmpty
                    ? 'In attesa che l\'app del proprietario ti consegni '
                          'la chiave.'
                    : proprietario
                    ? 'Sei il proprietario. Le voci le modificano chi le '
                          'inserisce e il proprietario.'
                    : 'Le voci le modificano chi le inserisce e il '
                          'proprietario.',
              ),
              trailing: proprietario
                  ? IconButton(
                      tooltip: 'Invita una persona',
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      onPressed: () =>
                          apriInvito(context, sessione, portafoglioId),
                    )
                  : null,
            ),
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
                    : Icon(
                        m.verificato
                            ? Icons.verified_user_outlined
                            : Icons.gpp_maybe_outlined,
                        color: m.verificato
                            ? schema.primary
                            : schema.onSurfaceVariant,
                      ),
                onTap: m.fileId == vista.info.mioFileId || m.chiaveFirma == null
                    ? null
                    : () => apriCodiceSicurezza(context, sessione, m),
              ),
          ],
        ),
      );
    },
  );

  static String _statoPersona(PortafoglioCondiviso info, Membro m) {
    final ruolo = m.ruolo == RuoloMembro.proprietario
        ? 'Proprietario'
        : 'Membro';
    if (m.fileId == info.mioFileId) {
      return '$ruolo · sei tu';
    }
    return switch (m.stato) {
      StatoMembro.invitato => '$ruolo · invitato, non ancora entrato',
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
