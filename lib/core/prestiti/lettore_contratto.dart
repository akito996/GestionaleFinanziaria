import '../importo.dart';

/// Dati trovati nel testo di un contratto di finanziamento. Ogni campo è
/// facoltativo: l'utente vede la proposta e la corregge prima di salvare.
class ProposteContratto {
  const ProposteContratto({
    this.finanziatore,
    this.capitale,
    this.numeroRate,
    this.importoRata,
    this.maxiRata,
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

  /// Maxi rata finale (finanziamenti auto, "valore futuro garantito").
  final int? maxiRata;
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
    maxiRata,
    tanPuntiBase,
    taegPuntiBase,
    primaRata,
  ].whereType<Object>().length;
}

/// Legge il testo dei moduli standard europei: **SECCI** ("Informazioni europee
/// di base sul credito ai consumatori", prestiti e rate) e **PIES/ESIS**
/// (mutui). Tutto sul dispositivo: il contratto non viene inviato a nessuno.
abstract final class LettoreContratto {
  static final _altraVoce = RegExp(
    r'\b(?:importo\s*totale|credito|prezzo|TAN|TAEG|anticipo|durata)\b',
    caseSensitive: false,
  );

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
    final maxiRata = _importo(t, [
      r'maxi\s*-?\s*rata(?:\s*finale)?',
      r'rata\s*finale',
      r'valore\s*futuro\s*garantito',
      r'valore\s*garantito\s*futuro',
      r'\bVFG\b',
      r'rata\s*residua',
    ], escludi: _altraVoce);
    // "35 rate mensili + maxi rata finale": la maxi rata è la 36ª.
    var rate = numeroRate;
    if (maxiRata != null && rate != null) {
      final piuMaxi = RegExp(
        r'(\d{1,3})\s*rate[^.;]{0,60}?(?:\+|più(?=\s)|\be\b|oltre\s*(?:a\s*)?(?:la\s*)?)\s*(?:una\s*|1\s*)?(?:maxi\s*-?\s*rata|rata\s*finale)',
        caseSensitive: false,
      ).firstMatch(t);
      if (piuMaxi != null && int.tryParse(piuMaxi.group(1)!) == rate) {
        rate++;
      }
    }

    return ProposteContratto(
      finanziatore: _finanziatore(t),
      capitale: _importo(t, [
        r'importo\s*totale\s*del\s*credito',
        r'importo\s*(?:e\s*valuta\s*)?del\s*(?:prestito|finanziamento|mutuo)(?:\s*da\s*concedere)?',
        r'importo\s*finanziato',
        r'capitale\s*(?:finanziato|erogato)',
      ]),
      numeroRate:
          rate ?? durataMesi ?? (durataAnni == null ? null : durataAnni * 12),
      importoRata: _importo(t, [
        r'importo\s*(?:di\s*ciascuna|della|delle)\s*rat[ae]',
        r'(?<!maxi[\s-]{0,2})\brat[ae]\s*(?:mensil[ei]\s*)?(?:costant[ei]\s*)?(?:di|da|pari\s*a)',
        r'rate\s*mensili\s*di',
      ]),
      maxiRata: maxiRata,
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
  /// Con [escludi]: scarta i numeri preceduti da un'altra voce (es. "maxi
  /// rata finale Importo totale del credito € 20.000" non è la maxi rata).
  static int? _importo(String t, List<String> etichette, {RegExp? escludi}) {
    for (final e in etichette) {
      // (?![\d/]): non una data (es. "rata finale: 05/12/2030").
      final modello = RegExp(
        '$e([^\\d€]{0,80}?)(?:€|EUR|euro)?\\s*([\\d.]{1,12}(?:,\\d{1,2})?)(?![\\d/])\\s*(?:€|EUR|euro)?',
        caseSensitive: false,
      );
      for (final m in modello.allMatches(t)) {
        if (escludi != null && escludi.hasMatch(m.group(1)!)) {
          continue;
        }
        final valore = Importo.leggi(m.group(2)!);
        if (valore != null && valore > 0) {
          return valore;
        }
        if (escludi == null) {
          break; // come prima: solo la prima occorrenza dell'etichetta
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
