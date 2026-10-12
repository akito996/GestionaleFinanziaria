import '../importo.dart';

/// Dati trovati nel testo di un contratto di finanziamento. Ogni campo è
/// facoltativo: l'utente vede la proposta e la corregge prima di salvare.
class ProposteContratto {
  const ProposteContratto({
    this.nome,
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
    this.speseRata,
    this.mutuo = false,
  });

  /// Nome suggerito (es. "Rifinanziamento Auto"); il lettore non lo compila.
  final String? nome;
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

  /// Spese di incasso addebitate con ogni rata (es. 3,50 €), se indicate.
  final int? speseRata;

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

/// Una riga del piano di ammortamento trovata nel testo.
class _RigaPiano {
  const _RigaPiano(
    this.numero,
    this.data,
    this.rata,
    this.quotaCapitale,
    this.residuo,
  );

  final int numero;
  final DateTime data;
  final int rata;
  final int quotaCapitale;
  final int residuo;
}

/// Legge il testo dei moduli standard europei: **SECCI** ("Informazioni europee
/// di base sul credito ai consumatori", prestiti e rate), **PIES/ESIS** (mutui)
/// e i **documenti di trasparenza** delle finanziarie, compreso il **piano di
/// ammortamento** quando c'è (da lì si ricavano rate, date e maxi rata).
/// Tutto sul dispositivo: il contratto non viene inviato a nessuno.
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
    // Solo "durata ... N mesi": un "12 mesi" qualsiasi (es. nel testo sulla
    // privacy) non è la durata del finanziamento.
    final durataMesi = _intero(t, [r'durata[^\d]{0,60}?(\d{1,3})\s*mesi']);
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

    // Il piano di ammortamento, se c'è, è la fonte più affidabile.
    final piano = _piano(t);
    final rataPiano = piano == null ? null : _piuFrequente(piano);
    final maxiPiano =
        piano != null &&
            piano.length > 1 &&
            rataPiano != null &&
            piano.last.rata > rataPiano * 3 ~/ 2
        ? piano.last.rata
        : null;
    // Piano completo (dalla prima rata): dà anche capitale e data d'inizio.
    final primaDelPiano = piano != null && piano.first.numero == 1
        ? piano.first
        : null;

    return ProposteContratto(
      finanziatore: _finanziatore(t, testo),
      capitale:
          _importo(t, [
            r'importo\s*totale\s*del\s*credito',
            r'importo\s*(?:e\s*valuta\s*)?del\s*(?:prestito|finanziamento|mutuo)(?:\s*da\s*concedere)?',
            r'importo\s*finanziato',
            r'capitale\s*(?:finanziato|erogato)',
          ]) ??
          (primaDelPiano == null
              ? null
              : primaDelPiano.quotaCapitale + primaDelPiano.residuo),
      numeroRate:
          piano?.last.numero ??
          rate ??
          durataMesi ??
          (durataAnni == null ? null : durataAnni * 12),
      importoRata:
          rataPiano ??
          _importo(t, [
            r'importo\s*(?:di\s*ciascuna|della|delle)\s*rat[ae]',
            r'(?<!maxi[\s-]{0,2})\brat[ae]\s*(?:mensil[ei]\s*)?(?:costant[ei]\s*)?(?:di|da|pari\s*a)\b',
            r'rate\s*mensili\s*di',
          ]),
      maxiRata: maxiPiano ?? maxiRata,
      // "TAN", "T.A.N.", "Tasso annuo nominale".
      tanPuntiBase: _percentuale(t, [
        r'tasso\s*(?:annuo\s*)?(?:di\s*interesse\s*)?nominale(?:\s*annuo)?(?:\s*\(?T\.?A\.?N\.?\)?)?',
        r'\bT\.?\s?A\.?\s?N\.?(?![a-z])',
      ]),
      taegPuntiBase: _percentuale(t, [
        r'tasso\s*annuo\s*effettivo\s*globale(?:\s*\(?T\.?A\.?E\.?G\.?\)?)?',
        r'\bT\.?\s?A\.?\s?E\.?\s?G\.?(?![a-z])',
      ]),
      speseRata: _importo(t, [
        r'spese\s*(?:di\s*)?(?:gestione\s*e/o\s*)?incasso(?:\s*rat[ae])?',
      ]),
      totaleDovuto: _importo(t, [
        r'importo\s*totale\s*dovuto(?:\s*dal\s*consumatore)?',
        r'importo\s*totale\s*da\s*rimborsare',
      ]),
      durataMesi: durataMesi ?? (durataAnni == null ? null : durataAnni * 12),
      primaRata:
          primaDelPiano?.data ??
          _data(t, [
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
        // Un importo ha i centesimi ("139,00") o la valuta accanto ("€ 50"):
        // un numero da solo (es. il numero di riga di una tabella) non lo è.
        final cifra = m.group(2)!;
        final conValuta = RegExp(
          r'€|\bEUR\b|\beuro\b',
          caseSensitive: false,
        ).hasMatch(m.group(0)!);
        final valore = Importo.leggi(cifra);
        if (valore != null &&
            valore > 0 &&
            (cifra.contains(',') || conValuta)) {
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

  static String? _finanziatore(String t, String originale) {
    final m = RegExp(
      r'(?:Finanziatore|Creditore|Mutuante|Banca)\s*[:\-]?\s*([A-Z][\w&.\x27 ]{2,60}?(?:S\.?p\.?A\.?|S\.?r\.?l\.?|Banca[\w ]*|Bank|Credit[\w ]*))',
    ).firstMatch(t);
    if (m != null) {
      return m.group(1)!.trim();
    }
    // Senza etichetta: una riga che contiene solo il nome della società
    // (es. l'intestazione "Finanziaria Esempio S.p.A.").
    final riga = RegExp(
      r'^\s*([A-Z][\w&.\x27 ]{2,60}?(?:S\.p\.A\.|S\.r\.l\.))\s*$',
      multiLine: true,
    ).firstMatch(originale);
    return riga?.group(1)?.trim();
  }

  static const _cifra = r'(\d{1,3}(?:\.\d{3})*,\d{2})\s*(?:EUR|€)?';

  /// Righe del piano di ammortamento: "N data importo importo importo importo".
  /// Le colonne cambiano da una finanziaria all'altra: la rata è l'importo che
  /// è somma di altri due (quota capitale + quota interessi). Restituisce la
  /// sequenza più lunga di righe consecutive (almeno 2), oppure `null`.
  static List<_RigaPiano>? _piano(String t) {
    final modello = RegExp(
      '(?<![\\d.,/])(\\d{1,3}) (\\d{1,2})[./-](\\d{1,2})[./-](\\d{4}) '
      '$_cifra $_cifra $_cifra $_cifra',
    );
    final righe = <_RigaPiano>[];
    for (final m in modello.allMatches(t)) {
      final valori = [
        for (var g = 5; g <= 8; g++) Importo.leggi(m.group(g)!) ?? -1,
      ];
      final riga = _interpreta(
        int.parse(m.group(1)!),
        DateTime(
          int.parse(m.group(4)!),
          int.parse(m.group(3)!),
          int.parse(m.group(2)!),
        ),
        valori,
      );
      if (riga != null) {
        righe.add(riga);
      }
    }
    // La sequenza consecutiva più lunga (1, 2, 3, ...).
    var migliore = <_RigaPiano>[];
    var corrente = <_RigaPiano>[];
    for (final r in righe) {
      if (corrente.isNotEmpty && r.numero == corrente.last.numero + 1) {
        corrente.add(r);
      } else {
        corrente = [r];
      }
      if (corrente.length > migliore.length) {
        migliore = [...corrente];
      }
    }
    return migliore.length >= 2 ? migliore : null;
  }

  static _RigaPiano? _interpreta(int numero, DateTime data, List<int> v) {
    if (v.any((x) => x < 0) || numero < 1 || numero > 600) {
      return null;
    }
    // Cerca i, j, k tra i primi tre importi con v[i] + v[j] = v[k] (± 1 cent).
    for (var k = 0; k < 4; k++) {
      for (var i = 0; i < 4; i++) {
        for (var j = i + 1; j < 4; j++) {
          if (i == k || j == k) {
            continue;
          }
          if ((v[i] + v[j] - v[k]).abs() <= 1) {
            final residuo = [
              0,
              1,
              2,
              3,
            ].firstWhere((x) => x != i && x != j && x != k);
            // La quota capitale è la prima delle due quote nella riga.
            return _RigaPiano(numero, data, v[k], v[i], v[residuo]);
          }
        }
      }
    }
    return null;
  }

  /// La rata che compare più spesso (la rata "normale" del piano).
  static int? _piuFrequente(List<_RigaPiano> piano) {
    final conteggi = <int, int>{};
    for (final r in piano) {
      conteggi.update(r.rata, (n) => n + 1, ifAbsent: () => 1);
    }
    return conteggi.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }
}
