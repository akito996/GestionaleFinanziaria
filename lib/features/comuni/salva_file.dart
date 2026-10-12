import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';

/// "Salva con nome" su tutte le piattaforme:
/// - Windows: la finestra di salvataggio di file_selector;
/// - Android: la finestra di sistema "Salva in…" (Download, Drive, ...),
///   perché file_selector su Android non sa salvare.
///
/// Restituisce dove è stato salvato (da mostrare all'utente), `null` se
/// l'utente ha annullato.
Future<String?> salvaConNome({
  required String nome,
  required Uint8List byte,
  required String tipo,
  required String estensione,
  required String mime,
}) async {
  if (Platform.isAndroid) {
    final uri = await FilePicker.saveFile(
      fileName: nome,
      bytes: byte,
      mimeType: mime,
    );
    return uri == null ? null : nome;
  }
  final destinazione = await getSaveLocation(
    suggestedName: nome,
    acceptedTypeGroups: [
      XTypeGroup(label: tipo, extensions: [estensione], mimeTypes: [mime]),
    ],
    confirmButtonText: 'Salva',
  );
  if (destinazione == null) {
    return null;
  }
  var percorso = destinazione.path;
  if (!percorso.toLowerCase().endsWith('.$estensione')) {
    percorso = '$percorso.$estensione';
  }
  await File(percorso).writeAsBytes(byte, flush: true);
  return percorso;
}
