import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/foto/contratto_foto.dart';
import 'package:gestionale_finanziaria/core/foto/lettura_foto.dart';
import 'package:gestionale_finanziaria/core/foto/scontrino.dart';
import 'package:gestionale_finanziaria/core/prestiti/lettore_contratto.dart';

/// Lettore finto: [righe] è la prima lettura (una riga ogni 40 pixel); lo zoom
/// restituisce [zoom] per la riga che contiene la zona (o il testo di prima).
class _LettoreFinto implements LettoreFoto {
  _LettoreFinto(this.righe, {this.zoom = const {}});

  final List<String> righe;
  final Map<String, String> zoom;
  final zone = <Riquadro>[];

  @override
  Future<FotoLetta> leggi(String percorso) async => FotoLetta(
    larghezza: 1000,
    altezza: righe.length * 40 + 40,
    righe: [
      for (final (i, t) in righe.indexed)
        RigaLetta(t, Riquadro(50, 20 + i * 40, 900, 50 + i * 40)),
    ],
  );

  @override
  Future<ZonaLetta> zona(
    String percorso,
    Riquadro zona, {
    bool riga = true,
  }) async {
    zone.add(zona);
    final i = ((zona.sopra + zona.sotto) / 2 - 20) ~/ 40;
    final originale = righe[i.clamp(0, righe.length - 1)];
    return ZonaLetta(
      testo: zoom[originale] ?? originale,
      affidabilita: 90,
      immagine: Uint8List.fromList([1, 2, 3]),
    );
  }

  @override
  Future<void> chiudi() async {}
}

void main() {
  final oggi = DateTime(2026, 10, 14, 12);

  const scontrino = [
    'LIDL ITALIA S.R.L.',
    'Via Roma 12 - 37100 Verona',
    'P.IVA 01234567890',
    'DOCUMENTO COMMERCIALE',
    'di vendita o prestazione',
    'Latte intero 4% 1,29',
    'Pane 4% 2,10',
    'SUBTOTALE 3,39',
    'TOTALE COMPLESSIVO 28,40', // letto male: in realtà 23,40
    'PAGAMENTO ELETTRONICO 23,40',
    'CONTANTE 50,00',
    'RESTO 26,60',
    '14-10-2026 10:21',
    'DOCUMENTO N. 0123-0456',
  ];

  group('scontrino', () {
    test('prima lettura: data, negozio e totale con le zone', () async {
      final foto = await _LettoreFinto(scontrino).leggi('x');
      final s = LettoreScontrino.interpreta(foto, oggi: oggi);
      expect(s.data!.valore, DateTime(2026, 10, 14));
      expect(s.negozio!.valore, 'Lidl Italia S.r.l.');
      expect(s.importo!.valore, 2840);
      // La zona del totale prende tutta la riga (l'importo è a destra).
      expect(s.importo!.zona!.sinistra, 0);
      expect(s.importo!.zona!.destra, 1000);
    });

    test('lo zoom corregge la prima lettura', () async {
      final lettore = _LettoreFinto(
        scontrino,
        zoom: {'TOTALE COMPLESSIVO 28,40': 'TOTALE COMPLESSIVO 23,40'},
      );
      final s = await LettoreScontrino.leggi(lettore, 'x', oggi: oggi);
      expect(s.importo!.valore, 2340);
      expect(s.importo!.immagine, isNotNull);
      expect(s.data!.valore, DateTime(2026, 10, 14));
      expect(s.negozio!.valore, 'Lidl Italia S.r.l.');
      expect(lettore.zone, hasLength(3)); // data, negozio, totale
    });

    test('senza "TOTALE": l\'importo più alto, escluso contante e resto', () {
      final foto = FotoLetta(
        larghezza: 1000,
        altezza: 400,
        righe: [
          for (final (i, t) in [
            'Bar Centrale',
            'Caffè 1,20',
            'Brioche 1,50',
            'Pagato 2,70',
            'Contante 10,00',
            'Resto 7,30',
          ].indexed)
            RigaLetta(t, Riquadro(0, i * 40, 1000, i * 40 + 30)),
        ],
      );
      final s = LettoreScontrino.interpreta(foto, oggi: oggi);
      expect(s.importo!.valore, 270);
      expect(s.negozio!.valore, 'Bar Centrale');
      expect(s.data, isNull);
    });

    test('date: valide, non future, anno a due cifre', () {
      expect(
        LettoreScontrino.primaData('13/10/26', oggi: oggi),
        DateTime(2026, 10, 13),
      );
      expect(
        LettoreScontrino.primaData('31/02/2026 01/10/2026', oggi: oggi),
        DateTime(2026, 10),
      );
      expect(LettoreScontrino.primaData('20/12/2026', oggi: oggi), isNull);
      expect(LettoreScontrino.primaData('01.01.2019', oggi: oggi), isNull);
    });

    test('importi e nomi', () {
      expect(LettoreScontrino.importoMassimo('TOTALE 1.234,56'), 123456);
      expect(LettoreScontrino.importoMassimo('TOTALE 12.50 EUR'), 1250);
      expect(LettoreScontrino.importoMassimo('Cassa 3'), isNull);
      expect(LettoreScontrino.nomeNegozio('*** ESSELUNGA ***'), 'Esselunga');
      expect(LettoreScontrino.nomeNegozio('P.IVA 01234567890'), isNull);
      expect(LettoreScontrino.nomeNegozio('Via Roma 12'), isNull);
      expect(LettoreScontrino.nomeNegozio('12/10'), isNull);
    });
  });

  test('contratto da foto: lo zoom sulle righe dei dati', () async {
    final lettore = _LettoreFinto(
      [
        'INFORMAZIONI EUROPEE DI BASE SUL CREDITO AI CONSUMATORI',
        'Finanziatore: Banca Esempio S.p.A.',
        'Importo totale del credito € 10.000,00',
        'n. 48 rate mensili di € 232,94',
        'Tasso annuo nominale (TAN) fisso 6,5O %', // letto male
        'Tasso annuo effettivo globale (TAEG) 7,12 %',
      ],
      zoom: {
        'Tasso annuo nominale (TAN) fisso 6,5O %':
            'Tasso annuo nominale (TAN) fisso 6,50 %',
      },
    );
    final testo = await ContrattoDaFoto.leggi(lettore, ['p1']);
    final proposte = LettoreContratto.leggi(testo);
    expect(proposte.tanPuntiBase, 650);
    expect(proposte.taegPuntiBase, 712);
    expect(proposte.capitale, 1000000);
    expect(proposte.numeroRate, 48);
    expect(proposte.importoRata, 23294);
    // Solo le righe con numeri e dati utili vengono ingrandite.
    expect(lettore.zone, hasLength(4));
  });
}
