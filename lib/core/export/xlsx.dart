import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Cella di un foglio: testo, numero o importo in euro (formato "#.##0,00 €").
sealed class Cella {
  const Cella();
}

class Testo extends Cella {
  const Testo(this.valore);
  final String valore;
}

class Numero extends Cella {
  const Numero(this.valore);
  final num valore;
}

/// Importo in unità minime (centesimi): scritto come numero con 2 decimali.
class Euro extends Cella {
  const Euro(this.minimo);
  final int minimo;
}

class Foglio {
  Foglio(this.nome, this.intestazione);

  /// Nome della scheda (max 31 caratteri, senza \ / ? * [ ]).
  final String nome;
  final List<String> intestazione;
  final List<List<Cella>> righe = [];

  void aggiungi(List<Cella> riga) => righe.add(riga);
}

/// Scrittore minimo di file Excel (.xlsx, Office Open XML), senza dipendenze
/// esterne oltre allo zip: fogli con intestazione in grassetto, testo,
/// numeri e importi in euro. Compatibile con Excel e LibreOffice.
abstract final class Xlsx {
  static Uint8List crea(List<Foglio> fogli) {
    final archivio = Archive();
    void file(String nome, String contenuto) {
      final byte = utf8.encode(contenuto);
      archivio.addFile(ArchiveFile(nome, byte.length, byte));
    }

    file('[Content_Types].xml', _tipi(fogli.length));
    file('_rels/.rels', _relRadice);
    file('xl/workbook.xml', _cartella(fogli));
    file('xl/_rels/workbook.xml.rels', _relCartella(fogli.length));
    file('xl/styles.xml', _stili);
    for (final (i, f) in fogli.indexed) {
      file('xl/worksheets/sheet${i + 1}.xml', _foglio(f));
    }
    return Uint8List.fromList(ZipEncoder().encode(archivio));
  }

  static String _esc(String t) => t
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      // Caratteri di controllo non ammessi in XML.
      .replaceAll(RegExp('[\u0000-\u0008\u000B\u000C\u000E-\u001F]'), '');

  static String _nomeScheda(String n) {
    final pulito = n.replaceAll(RegExp(r'[\\/?*\[\]:]'), ' ').trim();
    return pulito.length > 31 ? pulito.substring(0, 31) : pulito;
  }

  /// Colonna in lettere: 0 → A, 26 → AA.
  static String _colonna(int i) {
    var n = i + 1;
    final s = StringBuffer();
    final lettere = <String>[];
    while (n > 0) {
      final r = (n - 1) % 26;
      lettere.insert(0, String.fromCharCode(65 + r));
      n = (n - 1) ~/ 26;
    }
    s.writeAll(lettere);
    return s.toString();
  }

  static String _foglio(Foglio f) {
    final righe = StringBuffer();
    void riga(int r, List<Cella> celle, {bool intestazione = false}) {
      righe.write('<row r="${r + 1}">');
      for (final (c, cella) in celle.indexed) {
        final rif = '${_colonna(c)}${r + 1}';
        switch (cella) {
          case Testo(:final valore):
            righe.write(
              '<c r="$rif" t="inlineStr"${intestazione ? ' s="1"' : ''}>'
              '<is><t xml:space="preserve">${_esc(valore)}</t></is></c>',
            );
          case Numero(:final valore):
            righe.write('<c r="$rif"><v>$valore</v></c>');
          case Euro(:final minimo):
            righe.write(
              '<c r="$rif" s="2"><v>${(minimo / 100).toStringAsFixed(2)}</v></c>',
            );
        }
      }
      righe.write('</row>');
    }

    riga(0, [for (final h in f.intestazione) Testo(h)], intestazione: true);
    for (final (i, r) in f.righe.indexed) {
      riga(i + 1, r);
    }
    final colonne = StringBuffer('<cols>');
    for (var c = 0; c < f.intestazione.length; c++) {
      colonne.write(
        '<col min="${c + 1}" max="${c + 1}" width="20" customWidth="1"/>',
      );
    }
    colonne.write('</cols>');
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" '
        'activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>'
        '$colonne<sheetData>$righe</sheetData></worksheet>';
  }

  static String _tipi(int n) {
    final fogli = StringBuffer();
    for (var i = 1; i <= n; i++) {
      fogli.write(
        '<Override PartName="/xl/worksheets/sheet$i.xml" ContentType='
        '"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>',
      );
    }
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType='
        '"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType='
        '"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        '$fogli</Types>';
  }

  static const _relRadice =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" '
      'Target="xl/workbook.xml"/></Relationships>';

  static String _cartella(List<Foglio> fogli) {
    final schede = StringBuffer();
    final usati = <String>{};
    for (final (i, f) in fogli.indexed) {
      var nome = _nomeScheda(f.nome);
      if (nome.isEmpty || !usati.add(nome.toLowerCase())) {
        nome = 'Foglio${i + 1}';
        usati.add(nome.toLowerCase());
      }
      schede.write(
        '<sheet name="${_esc(nome)}" sheetId="${i + 1}" r:id="rId${i + 1}"/>',
      );
    }
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<sheets>$schede</sheets></workbook>';
  }

  static String _relCartella(int n) {
    final rel = StringBuffer();
    for (var i = 1; i <= n; i++) {
      rel.write(
        '<Relationship Id="rId$i" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" '
        'Target="worksheets/sheet$i.xml"/>',
      );
    }
    rel.write(
      '<Relationship Id="rId${n + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" '
      'Target="styles.xml"/>',
    );
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '$rel</Relationships>';
  }

  /// Stili: 0 normale, 1 intestazione in grassetto, 2 importo in euro.
  static const _stili =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<numFmts count="1"><numFmt numFmtId="164" formatCode="#,##0.00\\ &quot;€&quot;"/></numFmts>'
      '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
      '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
      '<fills count="2"><fill><patternFill patternType="none"/></fill>'
      '<fill><patternFill patternType="gray125"/></fill></fills>'
      '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
      '<cellXfs count="3">'
      '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
      '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
      '<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>'
      '</cellXfs></styleSheet>';
}
