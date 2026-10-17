import 'dart:typed_data';

import 'lettura_foto.dart';

/// Un dato letto dallo scontrino: il valore, la zona della foto da cui viene e
/// l'immagine ingrandita (per farla vedere all'utente).
class DatoLetto<T> {
  const DatoLetto(this.valore, {this.zona, this.immagine});

  final T valore;
  final Riquadro? zona;
  final Uint8List? immagine;
}

/// Data, negozio e importo letti da uno scontrino.
class Scontrino {
  const Scontrino({this.data, this.negozio, this.importo});

  final DatoLetto<DateTime>? data;
  final DatoLetto<String>? negozio;

  /// In centesimi.
  final DatoLetto<int>? importo;

  bool get vuoto => data == null && negozio == null && importo == null;
}

/// Prima lettura: i dati trovati e se il totale aveva la sua parola
/// ("TOTALE", "IMPORTO PAGATO"...) o è solo l'importo più alto.
typedef _Prima = ({
  DatoLetto<DateTime>? data,
  DatoLetto<String>? negozio,
  DatoLetto<int>? importo,
  bool conParolaTotale,
});

/// Interpreta il testo degli scontrini italiani (documento commerciale).
///
/// Due passaggi: prima tutta la foto per trovare dove sono i dati, poi lo
/// "zoom" ([LettoreFoto.zona]) su data, negozio e totale, riletti ingranditi.
/// Se la data o la parola del totale non si trovano subito (scontrini lunghi,
/// testo piccolo), si ingrandiscono le righe dove di solito stanno.
abstract final class LettoreScontrino {
  /// Righe ingrandite al massimo per cercare la data o il totale.
  static const _tentativi = 4;

  static Future<Scontrino> leggi(
    LettoreFoto lettore,
    String percorso, {
    DateTime? oggi,
    void Function(String messaggio)? avanzamento,
  }) async {
    final foto = await lettore.leggi(percorso);
    final prima = _primaLettura(foto, oggi: oggi);
    Future<ZonaLetta?> zoom(Riquadro? zona) async {
      if (zona == null) {
        return null;
      }
      try {
        return await lettore.zona(percorso, zona);
      } on Exception {
        return null; // si tiene la prima lettura
      }
    }

    DatoLetto<T>? scegli<T>(
      DatoLetto<T>? primo,
      ZonaLetta? ingrandita,
      T? Function(String) leggiValore,
    ) {
      if (primo == null) {
        return null;
      }
      // La lettura ingrandita è più precisa: vince se ha trovato il dato.
      final valore = ingrandita == null ? null : leggiValore(ingrandita.testo);
      return DatoLetto(
        valore ?? primo.valore,
        zona: primo.zona,
        immagine: ingrandita?.immagine,
      );
    }

    /// Ingrandisce le righe [candidate] finché [trova] dà un valore.
    Future<DatoLetto<T>?> cerca<T>(
      Iterable<RigaLetta> candidate,
      T? Function(String testo) trova,
    ) async {
      for (final r in candidate.take(_tentativi)) {
        final zona = _zona(foto, [r], tuttaLaRiga: true);
        final z = await zoom(zona);
        final valore = z == null ? null : trova(z.testo);
        if (valore != null) {
          return DatoLetto(valore, zona: zona, immagine: z!.immagine);
        }
      }
      return null;
    }

    var data = prima.data == null
        ? null
        : scegli(
            prima.data,
            await zoom(prima.data!.zona),
            (t) => primaData(t, oggi: oggi),
          );
    if (data == null) {
      avanzamento?.call('Cerco la data…');
      data = await cerca(_candidateData(foto), (t) => primaData(t, oggi: oggi));
    }

    final negozio = scegli(
      prima.negozio,
      await zoom(prima.negozio?.zona),
      nomeNegozio,
    );

    DatoLetto<int>? importo;
    if (!prima.conParolaTotale) {
      // Senza la parola del totale si guarda meglio dove potrebbe essere.
      avanzamento?.call('Cerco il totale…');
      importo = await cerca(
        _candidateTotale(foto),
        (t) => haParolaTotale(t) ? importoMassimo(t) : null,
      );
    }
    importo ??= scegli(
      prima.importo,
      await zoom(prima.importo?.zona),
      importoMassimo,
    );

    return Scontrino(data: data, negozio: negozio, importo: importo);
  }

  /// Primo passaggio: trova i dati e le zone da ingrandire.
  static Scontrino interpreta(FotoLetta foto, {DateTime? oggi}) {
    final p = _primaLettura(foto, oggi: oggi);
    return Scontrino(data: p.data, negozio: p.negozio, importo: p.importo);
  }

  static _Prima _primaLettura(FotoLetta foto, {DateTime? oggi}) {
    DatoLetto<DateTime>? data;
    for (final r in foto.righe) {
      final d = primaData(r.testo, oggi: oggi);
      if (d != null) {
        data = DatoLetto(d, zona: _zona(foto, [r]));
        break;
      }
    }

    DatoLetto<String>? negozio;
    // Il nome è in alto: tra le prime righe, la prima che sembra un nome.
    final inAlto = foto.righe
        .where((r) => r.riquadro.sopra < foto.altezza * 0.4)
        .take(8);
    for (final r in inAlto) {
      final nome = nomeNegozio(r.testo);
      if (nome != null) {
        negozio = DatoLetto(nome, zona: _zona(foto, [r]));
        break;
      }
    }

    final totale = _totaleConParola(foto);
    if (totale != null) {
      return (
        data: data,
        negozio: negozio,
        importo: totale,
        conParolaTotale: true,
      );
    }
    // Senza "TOTALE": l'importo più alto (escluse le righe come "RESTO").
    DatoLetto<int>? importo;
    RigaLetta? migliore;
    var massimo = 0;
    for (final r in foto.righe) {
      if (_escluse.hasMatch(_lettere(r.testo))) {
        continue;
      }
      final valore = importoMassimo(r.testo) ?? 0;
      if (valore > massimo) {
        massimo = valore;
        migliore = r;
      }
    }
    if (migliore != null) {
      importo = DatoLetto(
        massimo,
        zona: _zona(foto, [migliore], tuttaLaRiga: true),
      );
    }
    return (
      data: data,
      negozio: negozio,
      importo: importo,
      conParolaTotale: false,
    );
  }

  // ------------------------------------------------------------- posizioni

  /// La zona da ingrandire: le righe indicate, con un margine; con
  /// [tuttaLaRiga] da un bordo all'altro (l'importo è spesso a destra).
  static Riquadro _zona(
    FotoLetta foto,
    List<RigaLetta> righe, {
    bool tuttaLaRiga = false,
  }) {
    var unione = righe.first.riquadro;
    for (final r in righe.skip(1)) {
      final q = r.riquadro;
      unione = Riquadro(
        q.sinistra < unione.sinistra ? q.sinistra : unione.sinistra,
        q.sopra < unione.sopra ? q.sopra : unione.sopra,
        q.destra > unione.destra ? q.destra : unione.destra,
        q.sotto > unione.sotto ? q.sotto : unione.sotto,
      );
    }
    return unione.allargato(
      larghezzaFoto: foto.larghezza,
      altezzaFoto: foto.altezza,
      tuttaLaRiga: tuttaLaRiga,
    );
  }

  /// [b] sta sulla stessa riga dello scontrino di [a] (anche se la lettura
  /// l'ha messa in un'altra colonna, come succede ai prezzi).
  static bool _stessaRiga(RigaLetta a, RigaLetta b) {
    final h = a.riquadro.altezza;
    final centro = (b.riquadro.sopra + b.riquadro.sotto) / 2;
    return centro >= a.riquadro.sopra - h * 0.3 &&
        centro <= a.riquadro.sotto + h * 0.3;
  }

  /// [b] è la riga subito sotto [a].
  static bool _subitoSotto(RigaLetta a, RigaLetta b) {
    final h = a.riquadro.altezza;
    return b.riquadro.sopra >= a.riquadro.sotto - h * 0.3 &&
        b.riquadro.sopra <= a.riquadro.sotto + h * 1.5;
  }

  /// Il totale con la sua parola: la riga migliore ("TOTALE COMPLESSIVO"
  /// vince su "TOTALE EURO", poi "TOTALE", poi "IMPORTO PAGATO"...) e
  /// l'importo sulla stessa riga, anche se letto in un'altra colonna, o
  /// subito sotto.
  static DatoLetto<int>? _totaleConParola(FotoLetta foto) {
    final candidate = [
      for (final r in foto.righe)
        if (haParolaTotale(r.testo)) (r, _punteggioTotale(r.testo)),
    ];
    // Punteggio più alto prima; a pari punteggio la più in basso.
    candidate.sort(
      (a, b) => a.$2 != b.$2
          ? b.$2.compareTo(a.$2)
          : b.$1.riquadro.sopra.compareTo(a.$1.riquadro.sopra),
    );
    for (final (riga, _) in candidate) {
      final suRiga = importoMassimo(riga.testo);
      if (suRiga != null) {
        return DatoLetto(suRiga, zona: _zona(foto, [riga], tuttaLaRiga: true));
      }
      for (final vicina in [
        ...foto.righe.where((r) => r != riga && _stessaRiga(riga, r)),
        ...foto.righe.where((r) => r != riga && _subitoSotto(riga, r)),
      ]) {
        if (_escluse.hasMatch(_lettere(vicina.testo))) {
          continue;
        }
        final valore = importoMassimo(vicina.testo);
        if (valore != null) {
          return DatoLetto(
            valore,
            zona: _zona(foto, [riga, vicina], tuttaLaRiga: true),
          );
        }
      }
    }
    return null;
  }

  /// Dove cercare il totale se la parola non si è letta: gli importi più
  /// alti nella parte bassa dello scontrino.
  static List<RigaLetta> _candidateTotale(FotoLetta foto) {
    final conImporto = [
      for (final r in foto.righe)
        if (r.riquadro.sopra > foto.altezza * 0.2 &&
            !_escluse.hasMatch(_lettere(r.testo)))
          if (importoMassimo(r.testo) case final v?) (r, v),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final (r, _) in conImporto) r];
  }

  static final _ora = RegExp(r'(?<!\d)\d{1,2}\s?:\s?\d{2}(?!\d)');
  static final _treNumeri = RegExp(r'\d+\s?[/\-.]\s?\d+\s?[/\-.]\s?\d+');
  static final _parolaData = RegExp(r'\bDATA\b|\bORE\b|\bDEL\b|DOCUMENTO');

  /// Dove cercare la data se non si è letta: righe con l'ora, con "DATA",
  /// "ORE", "DOCUMENTO N.", o con tre numeri separati; dal basso.
  static List<RigaLetta> _candidateData(FotoLetta foto) {
    int punti(RigaLetta r) {
      final numeri = comeNumeri(r.testo);
      return (_ora.hasMatch(numeri) ? 2 : 0) +
          (_treNumeri.hasMatch(numeri) ? 2 : 0) +
          (_parolaData.hasMatch(_lettere(r.testo)) ? 1 : 0);
    }

    final candidate = [
      for (final r in foto.righe)
        if (punti(r) > 0) (r, punti(r)),
    ];
    candidate.sort(
      (a, b) => a.$2 != b.$2
          ? b.$2.compareTo(a.$2)
          : b.$1.riquadro.sopra.compareTo(a.$1.riquadro.sopra),
    );
    return [for (final (r, _) in candidate) r];
  }

  // ---------------------------------------------------------------- testo

  /// Le cifre lette come lettere, nei gruppi che hanno già almeno due cifre:
  /// "2O26" → "2026", "l4/10" → "14/10", "23,4O" → "23,40".
  static String comeNumeri(String testo) => testo.replaceAllMapped(
    // Gruppi non attaccati ad altre lettere: "14-ott-26" resta com'è.
    RegExp(
      r'(?<![A-Za-zÀ-ÿ])[0-9OoQIl|!SB][0-9OoQIl|!SB,./:\-]*[0-9OoQIl|!SB]'
      r'(?![A-Za-zÀ-ÿ])',
    ),
    (m) {
      final g = m.group(0)!;
      if (RegExp(r'\d').allMatches(g).length < 2) {
        return g;
      }
      return g
          .replaceAll(RegExp('[OoQ]'), '0')
          .replaceAll(RegExp(r'[Il|!]'), '1')
          .replaceAll('S', '5')
          .replaceAll('B', '8');
    },
  );

  /// Le lettere lette come cifre, per riconoscere le parole: "T0TALE" →
  /// "TOTALE" (in maiuscolo).
  static String _lettere(String testo) => testo
      .toUpperCase()
      .replaceAll('0', 'O')
      .replaceAll(RegExp('[1|!]'), 'I')
      .replaceAll('4', 'A')
      .replaceAll('3', 'E')
      .replaceAll('5', 'S')
      .replaceAll('7', 'T')
      .replaceAll('8', 'B');

  static final _importo = RegExp(
    r'(\d{1,3}(?:[.\s]\d{3})+|\d+)\s?[,.]\s?(\d{2})(?!\d)',
  );

  /// L'importo più alto scritto nel testo, in centesimi ("12,50" → 1250).
  static int? importoMassimo(String testo) {
    int? massimo;
    for (final m in _importo.allMatches(comeNumeri(testo))) {
      final interi = m.group(1)!.replaceAll(RegExp(r'[.\s]'), '');
      final valore = int.parse(interi) * 100 + int.parse(m.group(2)!);
      if (valore > 0 && (massimo == null || valore > massimo)) {
        massimo = valore;
      }
    }
    return massimo;
  }

  static final _data = RegExp(
    r'(?<!\d)(\d{1,2})\s?[/\-.]\s?(\d{1,2})\s?[/\-.]\s?(\d{4}|\d{2})(?!\d)',
  );
  static final _dataIso = RegExp(
    r'(?<!\d)(\d{4})\s?[/\-.]\s?(\d{1,2})\s?[/\-.]\s?(\d{1,2})(?!\d)',
  );
  static const _mesi = [
    'GEN',
    'FEB',
    'MAR',
    'APR',
    'MAG',
    'GIU',
    'LUG',
    'AGO',
    'SET',
    'OTT',
    'NOV',
    'DIC',
  ];
  static final _dataMese = RegExp(
    r'(?<!\d)(\d{1,2})\s?[/\-.]?\s?(GEN|FEB|MAR|APR|MAG|GIU|LUG|AGO|SET|OTT|'
    r'NOV|DIC)[A-Z]*\.?\s?[/\-.]?\s?(\d{4}|\d{2})(?!\d)',
  );

  /// La prima data valida nel testo (gg/mm/aaaa, gg-mm-aa, gg.mm.aaaa,
  /// aaaa-mm-gg, "14 OTT 2026"), non nel futuro e non più vecchia di 3 anni.
  /// Corregge le cifre lette come lettere ("2O26").
  static DateTime? primaData(String testo, {DateTime? oggi}) {
    final adesso = oggi ?? DateTime.now();
    final limite = DateTime(adesso.year, adesso.month, adesso.day + 1);
    final numeri = comeNumeri(testo);
    DateTime? valida(int giorno, int mese, int anno) {
      if (anno < 100) {
        anno += 2000;
      }
      if (mese < 1 || mese > 12 || giorno < 1 || giorno > 31) {
        return null;
      }
      final data = DateTime(anno, mese, giorno);
      if (data.month != mese || data.isAfter(limite)) {
        return null; // es. 31/02, o una data futura
      }
      if (data.isBefore(DateTime(adesso.year - 3, adesso.month, adesso.day))) {
        return null;
      }
      return data;
    }

    // In ordine di posizione nel testo: vince la prima data valida.
    final trovate = <(int, DateTime)>[
      for (final m in _data.allMatches(numeri))
        if (valida(
              int.parse(m.group(1)!),
              int.parse(m.group(2)!),
              int.parse(m.group(3)!),
            )
            case final d?)
          (m.start, d),
      for (final m in _dataIso.allMatches(numeri))
        if (valida(
              int.parse(m.group(3)!),
              int.parse(m.group(2)!),
              int.parse(m.group(1)!),
            )
            case final d?)
          (m.start, d),
      for (final m in _dataMese.allMatches(numeri.toUpperCase()))
        if (valida(
              int.parse(m.group(1)!),
              _mesi.indexOf(m.group(2)!) + 1,
              int.parse(m.group(3)!),
            )
            case final d?)
          (m.start, d),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return trovate.firstOrNull?.$2;
  }

  static final _nonNome = RegExp(
    r'DOCUMENTO|COMMERCIALE|VENDITA|PRESTAZIONE|P\.?\s?IVA|PARTITA|C\.?\s?F\.|'
    r'COD(ICE)?\.?\s?FISC|\bTEL\b|TELEFONO|\bFAX\b|\bVIA\b|VIALE|PIAZZA|\bP\.?ZZA\b|'
    r'CORSO|C\.SO|LARGO|LOCALIT|\bCAP\b|WWW|@|SCONTRINO|BENVENUT|GRAZIE|CASSA|'
    r'OPERATORE|DESCRIZIONE|\bEURO\b|\bIVA\b',
    caseSensitive: false,
  );

  /// Il nome del negozio, se la riga sembra un nome (lettere, niente
  /// indirizzi o partite IVA). In maiuscolo diventa "Lidl Italia".
  static String? nomeNegozio(String testo) {
    final pulito = testo
        .replaceAll(RegExp(r'^[^A-Za-zÀ-ÿ0-9]+|[^A-Za-zÀ-ÿ0-9.)]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final lettere = RegExp(r'[A-Za-zÀ-ÿ]').allMatches(pulito).length;
    if (lettere < 3 ||
        lettere < pulito.replaceAll(' ', '').length * 0.6 ||
        _nonNome.hasMatch(pulito)) {
      return null;
    }
    if (pulito != pulito.toUpperCase()) {
      return pulito;
    }
    return pulito
        .split(' ')
        .map(
          (p) =>
              p.isEmpty ? p : p[0].toUpperCase() + p.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  /// Le parole del totale, anche lette male ("T0TALE", "TOTAIE", "IOTALE").
  static final _parolaTotale = RegExp(
    r'[TI]\s?O\s?[TI]\s?A\s?[LI]\s?[EF]|\bTOT\b|IMPORTO\s+PAGATO|'
    r'DA\s+PAGARE|PAGAMENTO\s+ELETTRONICO|PAGATO\s+CON',
  );

  /// Righe che hanno un importo ma non sono il totale.
  static final _escluse = RegExp(
    r'SUB\s?[TI]\s?O\s?[TI]|RESTO|CONTANT|\bIVA\b|IMPONIBIL|SCONT|RISPARM|'
    r'NUMERO|ARTICOL|PEZZI|PUNTI|\bBUON[OI]\b|NON\s+RISCOSS|P\.?\s?IVA|'
    r'\bTEL\b|TELEFONO',
  );

  /// La riga ha la parola del totale (e non è un subtotale, un resto...).
  static bool haParolaTotale(String testo) {
    final lettere = _lettere(testo);
    return _parolaTotale.hasMatch(lettere) && !_escluse.hasMatch(lettere);
  }

  static int _punteggioTotale(String testo) {
    final l = _lettere(testo);
    if (RegExp(r'C\s?O\s?M\s?P\s?L|MPLESS').hasMatch(l)) {
      return 4;
    }
    if (RegExp(r'[TI]OTALE\s?EUR').hasMatch(l)) {
      return 3;
    }
    if (RegExp(r'[TI]\s?O\s?[TI]\s?A\s?[LI]\s?[EF]|\bTOT\b').hasMatch(l)) {
      return 2;
    }
    return 1;
  }
}
