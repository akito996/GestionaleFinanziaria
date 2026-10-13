import 'dart:convert';

import '../importo.dart';

/// Un report pronto da mostrare a schermo, salvare (JSON nell'archivio
/// cifrato) o scaricare (PDF, Excel): titolo, cifre chiave, grafici, tabelle.
///
/// Gli importi sono in unità minime (centesimi), come nel resto dell'app.
class DocumentoReport {
  const DocumentoReport({
    required this.titolo,
    required this.sottotitolo,
    required this.blocchi,
  });

  /// Versione del formato salvato: si alza se cambia la struttura del JSON.
  static const versioneFormato = 1;

  final String titolo;
  final String sottotitolo;
  final List<BloccoReport> blocchi;

  Map<String, Object?> versoJson() => {
    'versione': versioneFormato,
    'titolo': titolo,
    'sottotitolo': sottotitolo,
    'blocchi': [for (final b in blocchi) b.versoJson()],
  };

  String codifica() => jsonEncode(versoJson());

  static DocumentoReport decodifica(String testo) {
    final json = jsonDecode(testo) as Map<String, Object?>;
    return DocumentoReport(
      titolo: json['titolo']! as String,
      sottotitolo: json['sottotitolo']! as String,
      blocchi: [
        for (final b in json['blocchi']! as List<Object?>)
          BloccoReport.daJson(b! as Map<String, Object?>),
      ],
    );
  }
}

/// Un pezzo del report.
sealed class BloccoReport {
  const BloccoReport(this.titolo);

  final String titolo;

  Map<String, Object?> versoJson();

  static BloccoReport daJson(Map<String, Object?> j) => switch (j['tipo']) {
    'cifre' => CifreChiave(j['titolo']! as String, [
      for (final c in j['cifre']! as List<Object?>)
        Cifra.daJson(c! as Map<String, Object?>),
    ]),
    'serie' => SerieReport(
      j['titolo']! as String,
      etichette: [
        for (final e in j['etichette']! as List<Object?>) e! as String,
      ],
      serie: [
        for (final s
            in (j['serie']! as List<Object?>).cast<Map<String, Object?>>())
          (
            nome: s['nome']! as String,
            valori: [
              for (final v in s['valori']! as List<Object?>)
                (v! as num).toInt(),
            ],
          ),
      ],
      aColonne: j['aColonne'] == true,
    ),
    'tabella' => TabellaReport(
      j['titolo']! as String,
      colonne: [for (final c in j['colonne']! as List<Object?>) c! as String],
      righe: [
        for (final r in j['righe']! as List<Object?>)
          [
            for (final c in r! as List<Object?>)
              ValoreReport.daJson(c! as Map<String, Object?>),
          ],
      ],
    ),
    final tipo => throw FormatException('Blocco di report sconosciuto: $tipo'),
  };
}

/// Una cifra chiave: "Entrate previste 2.100,00 €", con un confronto
/// facoltativo ("+5% rispetto al mese prima").
class Cifra {
  const Cifra(this.etichetta, this.importo, {this.nota});

  final String etichetta;
  final int importo;
  final String? nota;

  Map<String, Object?> versoJson() => {
    'etichetta': etichetta,
    'importo': importo,
    'nota': ?nota,
  };

  static Cifra daJson(Map<String, Object?> j) => Cifra(
    j['etichetta']! as String,
    (j['importo']! as num).toInt(),
    nota: j['nota'] as String?,
  );
}

class CifreChiave extends BloccoReport {
  const CifreChiave(super.titolo, this.cifre);

  final List<Cifra> cifre;

  @override
  Map<String, Object?> versoJson() => {
    'tipo': 'cifre',
    'titolo': titolo,
    'cifre': [for (final c in cifre) c.versoJson()],
  };
}

/// Andamento nel tempo: una o più serie di importi sulle stesse [etichette].
class SerieReport extends BloccoReport {
  const SerieReport(
    super.titolo, {
    required this.etichette,
    required this.serie,
    this.aColonne = false,
  });

  final List<String> etichette;
  final List<({String nome, List<int> valori})> serie;

  /// `true`: colonne affiancate (confronti); `false`: linee (andamento).
  final bool aColonne;

  @override
  Map<String, Object?> versoJson() => {
    'tipo': 'serie',
    'titolo': titolo,
    'etichette': etichette,
    'serie': [
      for (final s in serie) {'nome': s.nome, 'valori': s.valori},
    ],
    'aColonne': aColonne,
  };
}

/// Valore di una cella: testo, importo (centesimi) o numero.
sealed class ValoreReport {
  const ValoreReport();

  String get testo;

  Map<String, Object?> versoJson();

  static ValoreReport daJson(Map<String, Object?> j) => switch (j['t']) {
    'e' => ValoreImporto((j['v']! as num).toInt()),
    'n' => ValoreNumero(j['v']! as num),
    _ => ValoreTesto(j['v']! as String),
  };
}

class ValoreTesto extends ValoreReport {
  const ValoreTesto(this.valore);

  final String valore;

  @override
  String get testo => valore;

  @override
  Map<String, Object?> versoJson() => {'t': 's', 'v': valore};
}

class ValoreImporto extends ValoreReport {
  const ValoreImporto(this.minimo);

  final int minimo;

  @override
  String get testo => Importo.formatta(minimo, 'EUR');

  @override
  Map<String, Object?> versoJson() => {'t': 'e', 'v': minimo};
}

class ValoreNumero extends ValoreReport {
  const ValoreNumero(this.valore);

  final num valore;

  @override
  String get testo => valore is int
      ? '$valore'
      : valore.toStringAsFixed(1).replaceAll('.', ',');

  @override
  Map<String, Object?> versoJson() => {'t': 'n', 'v': valore};
}

class TabellaReport extends BloccoReport {
  const TabellaReport(
    super.titolo, {
    required this.colonne,
    required this.righe,
  });

  final List<String> colonne;
  final List<List<ValoreReport>> righe;

  @override
  Map<String, Object?> versoJson() => {
    'tipo': 'tabella',
    'titolo': titolo,
    'colonne': colonne,
    'righe': [
      for (final r in righe) [for (final c in r) c.versoJson()],
    ],
  };
}
