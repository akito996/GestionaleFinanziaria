import 'lettura_foto.dart';

/// Testo di un contratto di prestito fotografato (una foto per pagina), da
/// passare a `LettoreContratto.leggi`.
///
/// Due passaggi: prima tutta la pagina, poi lo "zoom" sulle righe con i dati
/// che servono (TAN, TAEG, importo, rata, durata, spese...), rilette
/// ingrandite: lì un numero sbagliato cambierebbe tutto il piano.
abstract final class ContrattoDaFoto {
  static final righeImportanti = RegExp(
    r'T\.?\s?A\.?\s?N|T\.?\s?A\.?\s?E\.?\s?G|IMPORTO|CREDITO|RATA|RATE|DURATA|'
    r'SPESE|INCASSO|SCADENZA|FINANZIATORE|MESI|EUR|€',
    caseSensitive: false,
  );

  static final _cifre = RegExp(r'\d');

  /// Massimo di righe da ingrandire per pagina (lo zoom costa tempo).
  static const massimoZoomPerPagina = 40;

  static Future<String> leggi(
    LettoreFoto lettore,
    List<String> pagine, {
    void Function(int pagina, int totale)? avanzamento,
  }) async {
    final testi = <String>[];
    for (final (i, percorso) in pagine.indexed) {
      avanzamento?.call(i + 1, pagine.length);
      final foto = await lettore.leggi(percorso);
      final righe = <String>[];
      var ingrandite = 0;
      for (final r in foto.righe) {
        var testo = r.testo;
        if (ingrandite < massimoZoomPerPagina &&
            righeImportanti.hasMatch(testo) &&
            _cifre.hasMatch(testo)) {
          ingrandite++;
          try {
            final zona = await lettore.zona(
              percorso,
              r.riquadro.allargato(
                larghezzaFoto: foto.larghezza,
                altezzaFoto: foto.altezza,
              ),
            );
            // Si usa la rilettura solo se ha ancora i numeri.
            if (_cifre.hasMatch(zona.testo)) {
              testo = zona.testo;
            }
          } on Exception {
            // resta la prima lettura
          }
        }
        righe.add(testo);
      }
      testi.add(righe.join('\n'));
    }
    return testi.join('\n');
  }
}
