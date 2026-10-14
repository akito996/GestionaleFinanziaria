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

/// Interpreta il testo degli scontrini italiani (documento commerciale).
///
/// Due passaggi: prima tutta la foto per trovare dove sono i dati, poi lo
/// "zoom" ([LettoreFoto.zona]) su data, negozio e totale, riletti ingranditi.
abstract final class LettoreScontrino {
  static Future<Scontrino> leggi(
    LettoreFoto lettore,
    String percorso, {
    DateTime? oggi,
  }) async {
    final foto = await lettore.leggi(percorso);
    final prima = interpreta(foto, oggi: oggi);
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

    final zonaData = await zoom(prima.data?.zona);
    final zonaNegozio = await zoom(prima.negozio?.zona);
    final zonaImporto = await zoom(prima.importo?.zona);

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

    return Scontrino(
      data: scegli(prima.data, zonaData, (t) => primaData(t, oggi: oggi)),
      negozio: scegli(prima.negozio, zonaNegozio, nomeNegozio),
      importo: scegli(prima.importo, zonaImporto, importoMassimo),
    );
  }

  /// Primo passaggio: trova i dati e le zone da ingrandire.
  static Scontrino interpreta(FotoLetta foto, {DateTime? oggi}) {
    Riquadro zonaDi(RigaLetta r, {bool tuttaLaRiga = false}) =>
        r.riquadro.allargato(
          larghezzaFoto: foto.larghezza,
          altezzaFoto: foto.altezza,
          tuttaLaRiga: tuttaLaRiga,
        );

    DatoLetto<DateTime>? data;
    for (final r in foto.righe) {
      final d = primaData(r.testo, oggi: oggi);
      if (d != null) {
        data = DatoLetto(d, zona: zonaDi(r));
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
        negozio = DatoLetto(nome, zona: zonaDi(r));
        break;
      }
    }

    DatoLetto<int>? importo;
    final totale = _rigaTotale(foto.righe);
    if (totale != null) {
      // L'importo può stare sulla stessa riga o subito sotto.
      final i = foto.righe.indexOf(totale);
      for (final r in foto.righe.skip(i).take(2)) {
        final valore = importoMassimo(r.testo);
        if (valore != null) {
          importo = DatoLetto(valore, zona: zonaDi(r, tuttaLaRiga: true));
          break;
        }
      }
    }
    if (importo == null) {
      // Senza "TOTALE": l'importo più alto (escluse le righe come "RESTO").
      RigaLetta? migliore;
      var massimo = 0;
      for (final r in foto.righe) {
        if (_esclusaDalTotale.hasMatch(r.testo)) {
          continue;
        }
        final valore = importoMassimo(r.testo) ?? 0;
        if (valore > massimo) {
          massimo = valore;
          migliore = r;
        }
      }
      if (migliore != null) {
        importo = DatoLetto(massimo, zona: zonaDi(migliore, tuttaLaRiga: true));
      }
    }
    return Scontrino(data: data, negozio: negozio, importo: importo);
  }

  // ---------------------------------------------------------------- testo

  static final _importo = RegExp(
    r'(\d{1,3}(?:[.\s]\d{3})+|\d+)\s?[,.]\s?(\d{2})(?!\d)',
  );

  /// L'importo più alto scritto nel testo, in centesimi ("12,50" → 1250).
  static int? importoMassimo(String testo) {
    int? massimo;
    for (final m in _importo.allMatches(testo)) {
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

  /// La prima data valida nel testo (gg/mm/aaaa, gg-mm-aa, gg.mm.aaaa), non
  /// nel futuro e non più vecchia di 3 anni.
  static DateTime? primaData(String testo, {DateTime? oggi}) {
    final adesso = oggi ?? DateTime.now();
    final limite = DateTime(adesso.year, adesso.month, adesso.day + 1);
    for (final m in _data.allMatches(testo)) {
      final giorno = int.parse(m.group(1)!);
      final mese = int.parse(m.group(2)!);
      var anno = int.parse(m.group(3)!);
      if (anno < 100) {
        anno += 2000;
      }
      if (mese < 1 || mese > 12 || giorno < 1 || giorno > 31) {
        continue;
      }
      final data = DateTime(anno, mese, giorno);
      if (data.month != mese || data.isAfter(limite)) {
        continue; // es. 31/02, o una data futura
      }
      if (data.isBefore(DateTime(adesso.year - 3, adesso.month, adesso.day))) {
        continue;
      }
      return data;
    }
    return null;
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

  static final _totale = RegExp(
    r'TOTALE|\bTOT\b\.?|IMPORTO\s+PAGATO|DA\s+PAGARE|PAGAMENTO\s+ELETTRONICO',
    caseSensitive: false,
  );

  static final _esclusaDalTotale = RegExp(
    r'SUB\s?TOTALE|RESTO|CONTANT|\bIVA\b|SCONTO|RISPARMI|NUMERO|ARTICOL|PEZZI|'
    r'P\.?\s?IVA|TEL',
    caseSensitive: false,
  );

  /// La riga del totale: "TOTALE COMPLESSIVO" vince su "TOTALE EURO", poi
  /// "TOTALE", poi "IMPORTO PAGATO"/"PAGAMENTO ELETTRONICO".
  static RigaLetta? _rigaTotale(List<RigaLetta> righe) {
    int punteggio(String t) {
      final maiuscolo = t.toUpperCase();
      if (maiuscolo.contains('COMPLESSIVO')) {
        return 4;
      }
      if (maiuscolo.contains('TOTALE EUR')) {
        return 3;
      }
      if (maiuscolo.contains('TOTALE') ||
          RegExp(r'\bTOT\b').hasMatch(maiuscolo)) {
        return 2;
      }
      return 1;
    }

    RigaLetta? migliore;
    var massimo = 0;
    for (final r in righe) {
      if (!_totale.hasMatch(r.testo) || _esclusaDalTotale.hasMatch(r.testo)) {
        continue;
      }
      final p = punteggio(r.testo);
      if (p > massimo) {
        massimo = p;
        migliore = r;
      }
    }
    return migliore;
  }
}
