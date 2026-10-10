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
abstract final class Ammortamento {
  /// Rata costante per [capitale] in [numeroRate] rate con TAN [tanPuntiBase],
  /// con [rateAllAnno] rate all'anno (12 = mensile). Con tasso zero: capitale / n.
  static int rata({
    required int capitale,
    required int numeroRate,
    required int tanPuntiBase,
    int rateAllAnno = 12,
  }) {
    if (numeroRate <= 0) {
      throw ArgumentError.value(numeroRate, 'numeroRate', 'deve essere > 0');
    }
    final i = tanPuntiBase / 10000 / rateAllAnno;
    if (i == 0) {
      return (capitale / numeroRate).ceil();
    }
    final r = capitale * i / (1 - math.pow(1 + i, -numeroRate));
    return r.round();
  }

  /// Piano completo. L'ultima rata chiude esattamente il debito (arrotondamenti).
  static List<RataPiano> piano({
    required int capitale,
    required int numeroRate,
    required int tanPuntiBase,
    int? rataFissa,
    int rateAllAnno = 12,
  }) {
    final r =
        rataFissa ??
        rata(
          capitale: capitale,
          numeroRate: numeroRate,
          tanPuntiBase: tanPuntiBase,
          rateAllAnno: rateAllAnno,
        );
    final i = tanPuntiBase / 10000 / rateAllAnno;
    var residuo = capitale;
    final righe = <RataPiano>[];
    for (var n = 1; n <= numeroRate; n++) {
      final interessi = (residuo * i).round();
      var capitaleRata = r - interessi;
      var importo = r;
      if (n == numeroRate || capitaleRata > residuo) {
        capitaleRata = residuo;
        importo = capitaleRata + interessi;
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
  }) {
    if (rata * numeroRate < capitale) {
      return null;
    }
    if (rata * numeroRate == capitale) {
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
