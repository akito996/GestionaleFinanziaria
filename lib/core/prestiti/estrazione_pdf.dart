import 'dart:typed_data';

import 'package:pdfrx_engine/pdfrx_engine.dart';

/// Testo di un PDF (tutte le pagine), estratto sul dispositivo con PDFium.
/// Il file non viene inviato a nessuno.
///
/// Restituisce stringa vuota se il PDF è una scansione senza testo (immagine):
/// in quel caso l'utente può incollare il testo o compilare a mano.
Future<String> testoDaPdf(String percorso) async {
  await pdfrxInitialize();
  return _testo(await PdfDocument.openFile(percorso));
}

/// Come [testoDaPdf], dal contenuto del file (su Android il file scelto non ha
/// sempre un percorso: si leggono i byte).
Future<String> testoDaPdfDati(Uint8List dati) async {
  await pdfrxInitialize();
  return _testo(await PdfDocument.openData(dati, sourceName: 'contratto.pdf'));
}

Future<String> _testo(PdfDocument documento) async {
  try {
    final testo = StringBuffer();
    for (final pagina in documento.pages) {
      final contenuto = await pagina.loadText();
      testo.writeln(contenuto?.fullText ?? '');
    }
    return testo.toString().trim();
  } finally {
    await documento.dispose();
  }
}
