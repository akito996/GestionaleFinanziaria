import '../importo.dart';

/// Dati trovati nel testo di un contratto di finanziamento. Ogni campo è
/// facoltativo: l'utente vede la proposta e la corregge prima di salvare.
class ProposteContratto {
  const ProposteContratto({
    this.finanziatore,
    this.capitale,
    this.numeroRate,
    this.importoRata,
    this.tanPuntiBase,
    this.taegPuntiBase,
    this.totaleDovuto,
    this.durataMesi,
    this.primaRata,
    this.mutuo = false,
  });

  final String? finanziatore;
  final int? capitale;
  final int? numeroRate;
  final int? importoRata;
  final int? tanPuntiBase;
  final int? taegPuntiBase;
  final int? totaleDovuto;
  final int? durataMesi;
  final DateTime? primaRata;

  /// Modulo PIES / contratto di mutuo.
  final bool mutuo;

  /// Quanti campi utili sono stati trovati (per dire all'utente quanto fidarsi).
  int get campiTrovati => [
    finanziatore,
    capitale,
    numeroRate,
    importoRata,
    tanPuntiBase,
    taegPuntiBase,
    primaRata,
  ].whereType<Object>().length;
}

/// Legge il testo dei moduli standard europei: **SECCI** ("Informazioni europee
/// di base sul credito ai consumatori", prestiti e rate) e **PIES/ESIS**
/// (mutui). Tutto sul dispositivo: il contratto non viene inviato a nessuno.
abstract final class LettoreContratto {
  static ProposteContratto leggi(String testo) {
    // Testo su una riga sola, spazi normalizzati: i PDF spezzano le frasi.
    final t = testo.replaceAll(RegExp(r'[ \s]+'), ' ');
    final mutuo = RegExp(
      r'\b(PIES|ESIS|mutuo|ipotecari)',
      caseSensitive: false,
    ).hasMatch(t);

    final numeroRate = _intero(t, [
      r'n(?:umero|\.)?\s*(?:di\s*)?(\d{1,3})\s*rate',
      r'(\d{1,3})\s*rate\s*(?:mensili|trimestrali|semestrali|annuali)',
      r'numero\s*(?:totale\s*)?(?:di\s*)?rate[^\d]{0,30}(\d{1,3})',
    ]);
    final durataMesi = _intero(t, [
      r'durata[^\d]{0,60}?(\d{1,3})\s*mesi',
      r'(\d{1,3})\s*mesi',
    ]);
    final durataAnni = _intero(t, [r'durata[^\d]{0,60}?(\d{1,2})\s*anni']);

    return ProposteContratto(
      finanziatore: _finanziatore(t),
      capitale: _importo(t, [
        r'importo\s*totale\s*del\s*credito',
        r'importo\s*(?:e\s*valuta\s*)?del\s*(?:prestito|finanziamento|mutuo)(?:\s*da\s*concedere)?',
        r'importo\s*finanziato',
        r'capitale\s*(?:finanziato|erogato)',
      ]),
      numeroRate:
          numeroRate ??
          durataMesi ??
          (durataAnni == null ? null : durataAnni * 12),
      importoRata: _importo(t, [
        r'importo\s*(?:di\s*ciascuna|della|delle)\s*rat[ae]',
        r'rat[ae]\s*(?:mensil[ei]\s*)?(?:costant[ei]\s*)?(?:di|da|pari\s*a)',
        r'rate\s*mensili\s*di',
      ]),
      tanPuntiBase: _percentuale(t, [
        r'tasso\s*(?:annuo\s*)?(?:di\s*interesse\s*)?nominale(?:\s*annuo)?(?:\s*\(?TAN\)?)?',
        r'\bTAN\b',
      ]),
      taegPuntiBase: _percentuale(t, [
        r'tasso\s*annuo\s*effettivo\s*globale(?:\s*\(?TAEG\)?)?',
        r'\bTAEG\b',
      ]),
      totaleDovuto: _importo(t, [
        r'importo\s*totale\s*dovuto(?:\s*dal\s*consumatore)?',
        r'importo\s*totale\s*da\s*rimborsare',
      ]),
      durataMesi: durataMesi ?? (durataAnni == null ? null : durataAnni * 12),
      primaRata: _data(t, [
        r'(?:prima\s*rata|decorrenza\s*(?:del\s*)?(?:piano|ammortamento)|scadenza\s*(?:della\s*)?prima\s*rata)',
      ]),
      mutuo: mutuo,
    );
  }

  /// Importo (€) che segue la prima etichetta trovata, entro pochi caratteri.
  static int? _importo(String t, List<String> etichette) {
    for (final e in etichette) {
      final m = RegExp(
        '$e[^\\d€]{0,80}?(?:€|EUR|euro)?\\s*([\\d.]{1,12}(?:,\\d{1,2})?)\\s*(?:€|EUR|euro)?',
        caseSensitive: false,
      ).firstMatch(t);
      if (m != null) {
        final valore = Importo.leggi(m.group(1)!);
        if (valore != null && valore > 0) {
          return valore;
        }
      }
    }
    return null;
  }

  static int? _percentuale(String t, List<String> etichette) {
    for (final e in etichette) {
      final m = RegExp(
        '$e[^\\d%]{0,60}?(\\d{1,2}(?:[.,]\\d{1,3})?)\\s*%',
        caseSensitive: false,
      ).firstMatch(t);
      if (m != null) {
        final testo = m.group(1)!.replaceAll(',', '.');
        final valore = double.tryParse(testo);
        if (valore != null && valore < 100) {
          return (valore * 100).round();
        }
      }
    }
    return null;
  }

  static int? _intero(String t, List<String> modelli) {
    for (final m in modelli) {
      final r = RegExp(m, caseSensitive: false).firstMatch(t);
      if (r != null) {
        final n = int.tryParse(r.group(1)!);
        if (n != null && n > 0 && n <= 600) {
          return n;
        }
      }
    }
    return null;
  }

  static DateTime? _data(String t, List<String> etichette) {
    for (final e in etichette) {
      final m = RegExp(
        '$e[^\\d]{0,40}?(\\d{1,2})[/.-](\\d{1,2})[/.-](\\d{2,4})',
        caseSensitive: false,
      ).firstMatch(t);
      if (m != null) {
        var anno = int.parse(m.group(3)!);
        if (anno < 100) {
          anno += 2000;
        }
        final mese = int.parse(m.group(2)!);
        final giorno = int.parse(m.group(1)!);
        if (mese >= 1 && mese <= 12 && giorno >= 1 && giorno <= 31) {
          return DateTime(anno, mese, giorno);
        }
      }
    }
    return null;
  }

  static String? _finanziatore(String t) {
    final m = RegExp(
      r'(?:Finanziatore|Creditore|Mutuante|Banca)\s*[:\-]?\s*([A-Z][\w&.\x27 ]{2,60}?(?:S\.?p\.?A\.?|S\.?r\.?l\.?|Banca[\w ]*|Bank|Credit[\w ]*))',
    ).firstMatch(t);
    return m?.group(1)?.trim();
  }
}
