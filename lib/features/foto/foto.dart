import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/foto/lettura_foto.dart';
import '../../core/foto/scontrino.dart';
import '../../core/importo.dart';
import '../comuni/campi.dart';
import '../comuni/errori.dart';

/// Lettura delle foto: per ora solo su Android (sostituibile nei test).
bool Function() fotoDisponibile = () => !kIsWeb && Platform.isAndroid;

/// Il motore che legge il testo (sostituibile nei test).
LettoreFoto lettoreFoto = const LettoreFotoAndroid();

/// Da dove arriva la foto: fotocamera o galleria (sostituibile nei test).
Future<String?> Function(ImageSource sorgente) prendiFoto = (sorgente) async =>
    (await ImagePicker().pickImage(source: sorgente))?.path;

/// Chiede "Scatta una foto" o "Scegli dalla galleria" e restituisce il file.
Future<String?> scegliFoto(
  BuildContext context, {
  required String titolo,
}) async {
  final sorgente = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(titolo),
            subtitle: const Text(
              'La foto viene letta solo su questo telefono e poi cancellata. '
              'Tienila dritta, vicina e con buona luce.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Scatta una foto'),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Scegli dalla galleria'),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  return sorgente == null ? null : prendiFoto(sorgente);
}

/// Esegue [lettura] mostrando "Leggo…" (non si chiude toccando fuori).
/// `null` se qualcosa va storto (l'errore viene mostrato).
Future<T?> leggiConAttesa<T>(
  BuildContext context,
  ValueListenable<String> messaggio,
  Future<T> Function() lettura,
) async {
  final navigatore = Navigator.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: messaggio,
                builder: (_, testo, _) => Text(testo),
              ),
            ),
          ],
        ),
      ),
    ),
  ).ignore();
  // Si chiude una volta sola: sotto c'è il modulo che ha chiesto la lettura.
  var chiusa = false;
  void chiudi() {
    if (!chiusa) {
      chiusa = true;
      navigatore.pop();
    }
  }

  try {
    final risultato = await lettura();
    chiudi();
    return risultato;
  } catch (e, stack) {
    chiudi();
    if (context.mounted) {
      await mostraErroreImprevisto(context, e, stack);
    }
    return null;
  } finally {
    lettoreFoto.chiudi().ignore();
  }
}

/// Cancella la foto dopo la lettura: gli scontrini non restano sul telefono.
void cancellaFoto(String percorso) {
  try {
    File(percorso).deleteSync();
  } on FileSystemException {
    // già cancellata o non nostra (galleria): niente da fare
  }
}

/// Mostra cosa è stato letto dallo scontrino, con le zone ingrandite, e
/// lascia correggere. Restituisce i dati da usare (o `null`).
Future<Scontrino?> confermaScontrino(BuildContext context, Scontrino letto) =>
    showDialog<Scontrino>(
      context: context,
      builder: (_) => _ConfermaScontrino(letto: letto),
    );

class _ConfermaScontrino extends StatefulWidget {
  const _ConfermaScontrino({required this.letto});

  final Scontrino letto;

  @override
  State<_ConfermaScontrino> createState() => _ConfermaScontrinoState();
}

class _ConfermaScontrinoState extends State<_ConfermaScontrino> {
  late final _negozio = TextEditingController(
    text: widget.letto.negozio?.valore ?? '',
  );
  late final _importo = ControllerImporto()
    ..text = widget.letto.importo == null
        ? ''
        : Importo.perCampo(widget.letto.importo!.valore);
  late DateTime? _data = widget.letto.data?.valore;

  @override
  void dispose() {
    _negozio.dispose();
    _importo.dispose();
    super.dispose();
  }

  Widget _zona(DatoLetto<Object?>? dato, String etichetta, Widget campo) {
    final testo = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(etichetta, style: testo.labelLarge),
          const SizedBox(height: 6),
          if (dato?.immagine != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ColoredBox(
                color: Colors.white,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 72),
                  child: Image.memory(
                    dato!.immagine!,
                    fit: BoxFit.contain,
                    semanticLabel: 'Zona della foto: $etichetta',
                    // Un'immagine rovinata non deve bloccare la conferma.
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            )
          else if (dato == null)
            Text(
              'Non trovato: scrivilo tu.',
              style: testo.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          const SizedBox(height: 8),
          campo,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.letto;
    return AlertDialog(
      scrollable: true,
      title: const Text('Ecco cosa ho letto'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _zona(
              l.negozio,
              'Negozio',
              TextField(
                controller: _negozio,
                decoration: const InputDecoration(labelText: 'Negozio'),
              ),
            ),
            _zona(
              l.importo,
              'Importo',
              CampoImporto(controller: _importo, valuta: 'EUR'),
            ),
            _zona(
              l.data,
              'Data',
              CampoData(
                etichetta: 'Data',
                valore: _data,
                primo: DateTime(2000),
                ultimo: DateTime.now(),
                onChanged: (d) => setState(() => _data = d),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            final importo = Importo.leggi(_importo.text);
            final negozio = _negozio.text.trim();
            Navigator.of(context).pop(
              Scontrino(
                negozio: negozio.isEmpty ? null : DatoLetto(negozio),
                importo: importo == null || importo <= 0
                    ? null
                    : DatoLetto(importo),
                data: _data == null ? null : DatoLetto(_data!),
              ),
            );
          },
          child: const Text('Usa questi dati'),
        ),
      ],
    );
  }
}
