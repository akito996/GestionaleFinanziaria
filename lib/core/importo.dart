/// Importi in unità minime intere (centesimi): mai numeri decimali per i soldi.
///
/// Per ora tutte le valute usano 2 decimali; le crypto con più decimali arriveranno
/// con una tabella dei decimali per valuta.
abstract final class Importo {
  static const int decimali = 2;

  /// Legge quello che l'utente scrive: "12", "12,5", "12,50", "1.234,56", "1234.56", "€ 7".
  /// Restituisce i centesimi, oppure `null` se il testo non è un importo valido.
  static int? leggi(String testo) {
    var t = testo.replaceAll(RegExp(r'[\s€$£]'), '');
    if (t.isEmpty) {
      return null;
    }
    final negativo = t.startsWith('-');
    if (negativo) {
      t = t.substring(1);
    }
    // L'ultimo separatore seguito da 1-2 cifre è quello dei decimali;
    // gli altri punti/virgole sono separatori delle migliaia.
    final decimaliMatch = RegExp(r'[.,](\d{1,2})$').firstMatch(t);
    String interi;
    var parteDecimale = '';
    if (decimaliMatch != null) {
      interi = t.substring(0, decimaliMatch.start);
      parteDecimale = decimaliMatch.group(1)!;
    } else {
      interi = t;
    }
    interi = interi.replaceAll(RegExp(r'[.,]'), '');
    if (interi.isEmpty) {
      interi = '0';
    }
    if (!RegExp(r'^\d{1,13}$').hasMatch(interi)) {
      return null;
    }
    final centesimi =
        int.parse(interi) * 100 + int.parse(parteDecimale.padRight(2, '0'));
    return negativo ? -centesimi : centesimi;
  }

  /// "1.234,56 €" (formato italiano). [conSegno] aggiunge "+" ai positivi.
  static String formatta(int minimo, String valuta, {bool conSegno = false}) {
    final negativo = minimo < 0;
    final assoluto = minimo.abs();
    final interi = (assoluto ~/ 100).toString();
    final cent = (assoluto % 100).toString().padLeft(2, '0');
    final gruppi = StringBuffer();
    for (var i = 0; i < interi.length; i++) {
      if (i > 0 && (interi.length - i) % 3 == 0) {
        gruppi.write('.');
      }
      gruppi.write(interi[i]);
    }
    final segno = negativo ? '−' : (conSegno && minimo > 0 ? '+' : '');
    return '$segno$gruppi,$cent ${simbolo(valuta)}';
  }

  /// Testo per i campi di modifica: "1234,56" (senza separatore delle migliaia).
  static String perModifica(int minimo) {
    final assoluto = minimo.abs();
    return '${minimo < 0 ? '-' : ''}${assoluto ~/ 100},'
        '${(assoluto % 100).toString().padLeft(2, '0')}';
  }

  static String simbolo(String valuta) => switch (valuta) {
    'EUR' => '€',
    'USD' => r'$',
    'GBP' => '£',
    _ => valuta,
  };
}

/// Valute proposte nei menu (si può sempre scrivere un codice ISO a mano più avanti).
const valuteComuni = ['EUR', 'USD', 'GBP', 'CHF'];
