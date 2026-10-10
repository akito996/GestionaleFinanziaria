import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/prestiti/estrazione_pdf.dart';
import 'package:gestionale_finanziaria/core/prestiti/lettore_contratto.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  test('dal PDF del contratto ai dati del prestito, tutto in locale', () async {
    final cartella = await Directory.systemTemp.createTemp('contratto');
    addTearDown(() => cartella.delete(recursive: true));
    final file = File('${cartella.path}${Platform.pathSeparator}secci.pdf');

    // Un PDF con testo vero, come quelli che consegnano le banche.
    final doc = pw.Document()
      ..addPage(
        pw.Page(
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'INFORMAZIONI EUROPEE DI BASE SUL CREDITO AI CONSUMATORI',
              ),
              pw.Text('Finanziatore: Banca Esempio S.p.A.'),
              pw.Text('Importo totale del credito EUR 10.000,00'),
              pw.Text('n. 48 rate mensili di EUR 232,94'),
              pw.Text('Tasso annuo nominale (TAN) fisso 6,50 %'),
              pw.Text('Tasso annuo effettivo globale (TAEG) 7,12 %'),
            ],
          ),
        ),
      );
    await file.writeAsBytes(await doc.save());

    final testo = await testoDaPdf(file.path);
    expect(testo, contains('Importo totale del credito'));

    final p = LettoreContratto.leggi(testo);
    expect(p.finanziatore, 'Banca Esempio S.p.A.');
    expect(p.capitale, 1000000);
    expect(p.numeroRate, 48);
    expect(p.importoRata, 23294);
    expect(p.tanPuntiBase, 650);
    expect(p.taegPuntiBase, 712);
  });
}
