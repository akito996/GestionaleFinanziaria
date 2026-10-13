import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../export/esportazione.dart';
import '../export/xlsx.dart';
import '../importo.dart';
import 'documento.dart';

/// Scarica un [DocumentoReport] in PDF (con grafici) o in Excel (un foglio per
/// tabella, importi come numeri).
abstract final class EsportaReport {
  /// Colori della palette dei grafici (gli stessi dell'app).
  static const _colori = [
    PdfColor.fromInt(0xFF2A78D6),
    PdfColor.fromInt(0xFFEB6834),
    PdfColor.fromInt(0xFF1BAF7A),
    PdfColor.fromInt(0xFFEDA100),
    PdfColor.fromInt(0xFFE87BA4),
  ];
  static const _grigio = PdfColor.fromInt(0xFF6B6B66);

  /// [normale] e [grassetto]: file TTF del carattere (Roboto) per l'euro e gli
  /// accenti; senza, Helvetica e "EUR" al posto di "€".
  static Future<Uint8List> pdf(
    DocumentoReport d, {
    ByteData? normale,
    ByteData? grassetto,
  }) async {
    final conCarattere = normale != null;
    String t(String testo) =>
        Esportazione.testoPdf(testo, carattereCompleto: conCarattere);
    final doc = pw.Document(
      title: t(d.titolo),
      creator: 'GestionaleFinanziaria',
      theme: conCarattere
          ? pw.ThemeData.withFont(
              base: pw.Font.ttf(normale),
              bold: pw.Font.ttf(grassetto ?? normale),
            )
          : null,
    );

    pw.Widget titolo(String testo) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
      child: pw.Text(
        t(testo),
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );

    final contenuto = <pw.Widget>[
      pw.Text(
        t(d.titolo),
        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
      ),
      pw.Text(
        t(d.sottotitolo),
        style: const pw.TextStyle(fontSize: 9, color: _grigio),
      ),
    ];

    for (final b in d.blocchi) {
      contenuto.add(titolo(b.titolo));
      switch (b) {
        case CifreChiave(:final cifre):
          contenuto.add(
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in cifre)
                  pw.Container(
                    width: 160,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          t(c.etichetta),
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          t(Importo.formatta(c.importo, 'EUR')),
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (c.nota != null)
                          pw.Text(
                            t(c.nota!),
                            style: const pw.TextStyle(
                              fontSize: 7,
                              color: _grigio,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        case SerieReport():
          contenuto.add(_grafico(b, t));
        case TabellaReport(:final colonne, :final righe):
          contenuto.add(
            pw.TableHelper.fromTextArray(
              headers: [for (final c in colonne) t(c)],
              data: [
                for (final r in righe) [for (final c in r) t(c.testo)],
              ],
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              // Importi e numeri a destra.
              cellAlignments: {
                for (var i = 0; i < colonne.length; i++)
                  if (righe.isNotEmpty &&
                      righe.every(
                        (r) =>
                            i >= r.length ||
                            r[i] is! ValoreTesto ||
                            (r[i] as ValoreTesto).valore.isEmpty,
                      ) &&
                      righe.any((r) => i < r.length && r[i] is! ValoreTesto))
                    i: pw.Alignment.centerRight,
              },
            ),
          );
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            t(
              'GestionaleFinanziaria · pagina ${context.pageNumber} di '
              '${context.pagesCount}',
            ),
            style: const pw.TextStyle(fontSize: 7, color: _grigio),
          ),
        ),
        build: (_) => contenuto,
      ),
    );
    return doc.save();
  }

  /// Colonne affiancate per etichetta, una per serie, con la legenda.
  static pw.Widget _grafico(SerieReport s, String Function(String) t) {
    final massimo = [for (final x in s.serie) ...x.valori]
        .fold<int>(0, (m, v) => v > m ? v : m);
    const altezza = 110.0;
    double h(int v) => massimo <= 0 || v <= 0 ? 0 : altezza * v / massimo;
    final larghezza = s.serie.length <= 2 ? 8.0 : 5.0;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          height: altezza + 14,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < s.etichette.length; i++)
                pw.Expanded(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          for (final (k, x) in s.serie.indexed)
                            pw.Container(
                              width: larghezza,
                              height: h(x.valori[i]),
                              margin: const pw.EdgeInsets.symmetric(
                                horizontal: 0.5,
                              ),
                              color: _colori[k % _colori.length],
                            ),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        t(s.etichette[i]),
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final (k, x) in s.serie.indexed)
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Container(
                    width: 8,
                    height: 8,
                    color: _colori[k % _colori.length],
                  ),
                  pw.SizedBox(width: 4),
                  pw.Text(t(x.nome), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
          ],
        ),
      ],
    );
  }

  /// Excel: "Sintesi" con le cifre chiave, poi un foglio per ogni grafico e
  /// tabella (gli andamenti come tabella: periodo per riga).
  static Uint8List excel(DocumentoReport d) {
    final fogli = <Foglio>[];
    final nomi = <String>{};
    String nomeFoglio(String titolo) {
      var base = titolo.replaceAll(RegExp(r'[\\/?*\[\]:]'), ' ').trim();
      if (base.length > 28) {
        base = base.substring(0, 28).trim();
      }
      var nome = base;
      for (var n = 2; !nomi.add(nome); n++) {
        nome = '$base $n';
      }
      return nome;
    }

    final sintesi = Foglio(nomeFoglio('Sintesi'), ['Voce', 'Importo', 'Nota']);
    sintesi.aggiungi([Testo(d.titolo), const Testo(''), Testo(d.sottotitolo)]);
    for (final b in d.blocchi.whereType<CifreChiave>()) {
      for (final c in b.cifre) {
        sintesi.aggiungi([
          Testo(c.etichetta),
          Euro(c.importo),
          Testo(c.nota ?? ''),
        ]);
      }
    }
    fogli.add(sintesi);

    for (final b in d.blocchi) {
      switch (b) {
        case CifreChiave():
          break;
        case SerieReport(:final etichette, :final serie):
          final f = Foglio(nomeFoglio(b.titolo), [
            'Periodo',
            for (final x in serie) x.nome,
          ]);
          for (var i = 0; i < etichette.length; i++) {
            f.aggiungi([
              Testo(etichette[i]),
              for (final x in serie) Euro(x.valori[i]),
            ]);
          }
          fogli.add(f);
        case TabellaReport(:final colonne, :final righe):
          final f = Foglio(nomeFoglio(b.titolo), colonne);
          for (final r in righe) {
            f.aggiungi([
              for (final c in r)
                switch (c) {
                  ValoreImporto(:final minimo) => Euro(minimo),
                  ValoreNumero(:final valore) => Numero(valore),
                  ValoreTesto(:final valore) => Testo(valore),
                },
            ]);
          }
          fogli.add(f);
      }
    }
    return Xlsx.crea(fogli);
  }
}
