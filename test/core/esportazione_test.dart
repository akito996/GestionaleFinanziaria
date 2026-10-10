import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/crypto/derivazione.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';
import 'package:gestionale_finanziaria/core/db/prestiti.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';
import 'package:gestionale_finanziaria/core/export/esportazione.dart';
import 'package:gestionale_finanziaria/core/export/xlsx.dart';
import 'package:gestionale_finanziaria/core/prestiti/estrazione_pdf.dart';
import 'package:gestionale_finanziaria/core/sessione.dart';
import 'package:sodium/sodium_sumo.dart';

void main() {
  late SodiumSumo sodium;
  late Directory cartella;
  late Sessione s;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() async {
    cartella = await Directory.systemTemp.createTemp('export_test');
    s = Sessione(
      sodium: sodium,
      deposito: DepositoLocale(cartella),
      costoArgon2: (
        ops: ParametriArgon2.opsMinimo,
        mem: ParametriArgon2.memMinima,
      ),
    );
    await s.avvia();
    await s.preparaNuovoArchivio('Password-Lunga-1');
    await s.confermaNuovoArchivio();
  });

  tearDown(() async {
    await s.blocca();
    try {
      await cartella.delete(recursive: true);
    } on FileSystemException {
      // ignorato
    }
  });

  Future<OpzioniExport> datiDiProva() async {
    final c = s.contabilita;
    final tipi = {
      for (final t in [
        ...await c.tipi(AmbitoTipo.movimento),
        ...await c.tipi(AmbitoTipo.portafoglio),
      ])
        t.nome: t.id,
    };
    final conto = await c.creaPortafoglio(
      nome: 'Conto',
      tipoId: tipi['Conto corrente']!,
      valuta: 'EUR',
      saldoIniziale: 150000,
    );
    final spesa = (await c.osservaCategorie().first).firstWhere(
      (x) => x.nome == 'Spesa',
    );
    final oggi = DateTime.now();
    await c.registraMovimento(
      tipoId: tipi['Spesa']!,
      portafoglioId: conto,
      categoriaId: spesa.id,
      importo: 1250,
      valuta: 'EUR',
      data: oggi,
      descrizione: 'Pizzeria Da Mario',
    );
    await s.costoVita.creaVoce(
      nome: 'Affitto',
      tipo: TipoVoce.fissa,
      importo: 80000,
    );
    await s.carte.crea(
      nome: 'Visa',
      contoAddebitoId: conto,
      giornoAddebito: 15,
    );
    await s.prestiti.crea(
      DatiPrestito(
        nome: 'Lavatrice',
        tipo: TipoPrestito.rate,
        capitale: 30000,
        numeroRate: 3,
        importoRata: 10000,
        primaRata: DateTime(oggi.year, oggi.month + 1, 5),
      ),
    );
    await s.obiettivi.crea(
      nome: 'Regalo Anna',
      tipo: TipoObiettivo.colletta,
      importoObiettivo: 9000,
      partecipanti: [(nome: 'Marco', quota: null)],
    );
    return OpzioniExport(
      da: DateTime(oggi.year, oggi.month),
      a: DateTime(oggi.year, oggi.month + 1, 0),
      sezioni: SezioneExport.values.toSet(),
    );
  }

  test('Excel: un foglio per sezione, valori numerici e testo', () async {
    final dati = await Esportazione.raccogli(s, await datiDiProva());
    final zip = ZipDecoder().decodeBytes(Esportazione.excel(dati));
    String file(String nome) =>
        utf8.decode(zip.findFile(nome)!.content as List<int>);

    final cartellaXml = file('xl/workbook.xml');
    for (final nome in [
      'Portafogli',
      'Movimenti',
      'Spese per categoria',
      'Costo della vita',
      'Carte di credito',
      'Piani delle rate',
      'Obiettivi e collette',
    ]) {
      expect(cartellaXml, contains('name="$nome"'));
    }
    final movimenti = file('xl/worksheets/sheet2.xml');
    expect(movimenti, contains('Pizzeria Da Mario'));
    expect(movimenti, contains('<v>-12.50</v>'));
    expect(file('xl/worksheets/sheet6.xml'), contains('Lavatrice'));
    expect(file('xl/styles.xml'), contains('€'));
  });

  test('PDF: documento valido; su Windows il testo si rilegge', () async {
    final dati = await Esportazione.raccogli(s, await datiDiProva());
    ByteData carattere(String nome) =>
        ByteData.sublistView(File('assets/fonts/$nome').readAsBytesSync());
    final byte = await Esportazione.pdf(
      dati,
      normale: carattere('Roboto-Regular.ttf'),
      grassetto: carattere('Roboto-Bold.ttf'),
    );
    expect(String.fromCharCodes(byte.take(5)), '%PDF-');
    expect(byte.length, greaterThan(2000));

    if (Platform.isWindows) {
      final f = File('${cartella.path}${Platform.pathSeparator}report.pdf');
      await f.writeAsBytes(byte);
      final testo = await testoDaPdf(f.path);
      expect(testo, contains('Portafogli e saldi'));
      expect(testo, contains('Pizzeria Da Mario'));
      expect(testo, contains('Costo della vita'));
      expect(testo, contains('Lavatrice'));
      expect(testo, contains('Regalo Anna'));
      expect(testo, contains('€'));
    }
  });

  test('Xlsx: nomi delle schede validi e caratteri speciali protetti', () {
    final foglio = Foglio('Spese / casa [2026]?', ['A <b>', 'B & C'])
      ..aggiungi([const Testo('"virgolette" & <tag>'), const Euro(-1530)]);
    final zip = ZipDecoder().decodeBytes(Xlsx.crea([foglio]));
    final wb = utf8.decode(
      zip.findFile('xl/workbook.xml')!.content as List<int>,
    );
    expect(wb, contains('name="Spese   casa  2026"'));
    final sh = utf8.decode(
      zip.findFile('xl/worksheets/sheet1.xml')!.content as List<int>,
    );
    expect(sh, contains('&quot;virgolette&quot; &amp; &lt;tag&gt;'));
    expect(sh, contains('<v>-15.30</v>'));
  });
}
