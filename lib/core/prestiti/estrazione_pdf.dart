import 'package:pdfrx_engine/pdfrx_engine.dart';

/// Testo di un PDF (tutte le pagine), estratto sul dispositivo con PDFium.
/// Il file non viene inviato a nessuno.
///
/// Restituisce stringa vuota se il PDF è una scansione senza testo (immagine):
/// in quel caso l'utente può incollare il testo o compilare a mano.
Future<String> testoDaPdf(String percorso) async {
  await pdfrxInitialize();
  final documento = await PdfDocument.openFile(percorso);
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
