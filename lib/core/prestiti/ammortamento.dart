import 'dart:math' as math;

/// Una riga del piano di ammortamento.
class RataPiano {
  const RataPiano({
    required this.numero,
    required this.rata,
    required this.quotaCapitale,
    required this.quotaInteressi,
    required this.debitoResiduo,
  });

  final int numero;
  final int rata;
  final int quotaCapitale;
  final int quotaInteressi;

  /// Debito che resta dopo aver pagato questa rata.
  final int debitoResiduo;
}

/// Piano di ammortamento "alla francese" (rata costante), lo standard di mutui
/// e prestiti in Italia. Importi in centesimi, tassi in punti base (1% = 100).
///
/// Con la **maxi rata finale** ([rataFinale], tipica dei finanziamenti auto)
/// le prime `numeroRate - 1` rate sono costanti e l'ultima, più alta, chiude
/// il debito.
abstract final class Ammortamento {
  /// Rata costante per [capitale] in [numeroRate] rate con TAN [tanPuntiBase],
  /// con [rateAllAnno] rate all'anno (12 = mensile). Con tasso zero: capitale / n.
  /// Con [rataFinale] l'ultima rata vale quella cifra e la rata costante vale
  /// per le altre.
  static int rata({
    required int capitale,
    required int numeroRate,
    required int tanPuntiBase,
    int rateAllAnno = 12,
    int? rataFinale,
  }) {
    if (numeroRate <= 0) {
      throw ArgumentError.value(numeroRate, 'numeroRate', 'deve essere > 0');
    }
    if (rataFinale != null && numeroRate < 2) {
      throw ArgumentError.value(
        numeroRate,
        'numeroRate',
        'con la maxi rata servono almeno 2 rate',
      );
    }
    final i = tanPuntiBase / 10000 / rateAllAnno;
    if (rataFinale == null) {
      if (i == 0) {
        return (capitale / numeroRate).ceil();
      }
      return (capitale * i / (1 - math.pow(1 + i, -numeroRate))).round();
    }
    // Capitale = rata × (rate costanti attualizzate) + maxi rata attualizzata.
    final costanti = numeroRate - 1;
    if (i == 0) {
      return math.max(0, ((capitale - rataFinale) / costanti).ceil());
    }
    final attualeFinale = rataFinale * math.pow(1 + i, -numeroRate);
    final r = (capitale - attualeFinale) * i / (1 - math.pow(1 + i, -costanti));
    return math.max(0, r.round());
  }

  /// Piano completo. L'ultima rata chiude esattamente il debito (arrotondamenti);
  /// con [rataFinale] l'ultima rata è la maxi rata indicata nel contratto.
  static List<RataPiano> piano({
    required int capitale,
    required int numeroRate,
    required int tanPuntiBase,
    int? rataFissa,
    int rateAllAnno = 12,
    int? rataFinale,
  }) {
    final r =
        rataFissa ??
        rata(
          capitale: capitale,
          numeroRate: numeroRate,
          tanPuntiBase: tanPuntiBase,
          rateAllAnno: rateAllAnno,
          rataFinale: rataFinale,
        );
    final i = tanPuntiBase / 10000 / rateAllAnno;
    var residuo = capitale;
    final righe = <RataPiano>[];
    for (var n = 1; n <= numeroRate; n++) {
      var interessi = (residuo * i).round();
      var capitaleRata = r - interessi;
      var importo = r;
      final ultima = n == numeroRate;
      if (ultima || capitaleRata > residuo) {
        capitaleRata = residuo;
        importo = capitaleRata + interessi;
        // La maxi rata è quella del contratto: la differenza di arrotondamento
        // (o di un TAN stimato) finisce negli interessi.
        if (ultima && rataFinale != null && rataFinale >= capitaleRata) {
          importo = rataFinale;
          interessi = rataFinale - capitaleRata;
        }
      }
      residuo -= capitaleRata;
      righe.add(
        RataPiano(
          numero: n,
          rata: importo,
          quotaCapitale: capitaleRata,
          quotaInteressi: interessi,
          debitoResiduo: residuo,
        ),
      );
      if (residuo <= 0) {
        break;
      }
    }
    return righe;
  }

  /// TAN ricavato da capitale, rata e numero di rate (quando il contratto non lo
  /// riporta). Ricerca per bisezione; `null` se i dati non sono coerenti.
  static int? tanDaRata({
    required int capitale,
    required int numeroRate,
    required int rata,
    int rateAllAnno = 12,
    int? rataFinale,
  }) {
    final totale = rataFinale == null
        ? rata * numeroRate
        : rata * (numeroRate - 1) + rataFinale;
    if (totale < capitale) {
      return null;
    }
    if (totale == capitale) {
      return 0;
    }
    var basso = 0.0;
    var alto = 10000.0; // 100%
    for (var k = 0; k < 100; k++) {
      final medio = (basso + alto) / 2;
      final calcolata = Ammortamento.rata(
        capitale: capitale,
        numeroRate: numeroRate,
        tanPuntiBase: medio.round(),
        rateAllAnno: rateAllAnno,
        rataFinale: rataFinale,
      );
      if (calcolata < rata) {
        basso = medio;
      } else {
        alto = medio;
      }
    }
    return ((basso + alto) / 2).round();
  }
}
