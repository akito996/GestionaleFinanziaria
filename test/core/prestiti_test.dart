import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/prestiti/ammortamento.dart';
import 'package:gestionale_finanziaria/core/prestiti/lettore_contratto.dart';

/// Estratto realistico di un modulo SECCI (come esce da un PDF: righe spezzate).
const _secci = '''
INFORMAZIONI EUROPEE DI BASE SUL CREDITO AI CONSUMATORI
1. Identità e contatti del finanziatore
Finanziatore: Banca Esempio S.p.A.
Indirizzo: Via Roma 1, 00100 Roma
2. Caratteristiche principali del prodotto di credito
Tipo di contratto di credito Prestito personale
Importo totale del credito
€ 10.000,00
Durata del contratto di credito 48 mesi
Rate ed, eventualmente, loro ordine di imputazione
n. 48 rate mensili di € 232,94
Scadenza prima rata: 05/12/2026
3. Costi del credito
Tasso annuo nominale (TAN) fisso 6,50 %
Tasso annuo effettivo globale (TAEG) 7,12 %
Importo totale dovuto dal consumatore € 11.181,12
''';

const _pies = '''
PROSPETTO INFORMATIVO EUROPEO STANDARDIZZATO (PIES)
Mutuante: Credito Casa S.p.A.
Importo e valuta del mutuo da concedere: 150.000,00 euro
Durata del prestito: 25 anni
Numero di rate: 300
Importo di ciascuna rata: 790,15 EUR
Tasso di interesse nominale annuo 3,20 %
Tasso annuo effettivo globale (TAEG): 3,45%
''';

void main() {
  group('piano di ammortamento alla francese', () {
    test('rata costante (verificata con la formula standard)', () {
      // 10.000 € in 48 rate al 6,50%: 237,15 € (formula francese).
      expect(
        Ammortamento.rata(capitale: 1000000, numeroRate: 48, tanPuntiBase: 650),
        23715,
      );
      // Tasso zero ("paga in 3 rate"): capitale diviso per le rate.
      expect(
        Ammortamento.rata(capitale: 30000, numeroRate: 3, tanPuntiBase: 0),
        10000,
      );
    });

    test('il piano chiude esattamente il debito', () {
      final piano = Ammortamento.piano(
        capitale: 1000000,
        numeroRate: 48,
        tanPuntiBase: 650,
      );
      expect(piano, hasLength(48));
      expect(piano.last.debitoResiduo, 0);
      expect(
        piano.map((r) => r.quotaCapitale).reduce((a, b) => a + b),
        1000000,
      );
      // Prima rata: più interessi; ultima: quasi solo capitale.
      expect(piano.first.quotaInteressi, 5417); // 10.000 × 6,5% / 12
      expect(
        piano.first.quotaInteressi,
        greaterThan(piano.last.quotaInteressi),
      );
      for (final r in piano) {
        expect(r.rata, r.quotaCapitale + r.quotaInteressi);
      }
    });

    test('TAN ricavato dalla rata', () {
      final tan = Ammortamento.tanDaRata(
        capitale: 1000000,
        numeroRate: 48,
        rata: 23715,
      );
      expect(tan, inInclusiveRange(648, 652));
      expect(
        Ammortamento.tanDaRata(capitale: 30000, numeroRate: 3, rata: 10000),
        0,
      );
      expect(
        Ammortamento.tanDaRata(capitale: 30000, numeroRate: 3, rata: 5000),
        isNull,
      );
    });
  });

  group('lettura del contratto', () {
    test('modulo SECCI (prestito personale)', () {
      final p = LettoreContratto.leggi(_secci);
      expect(p.finanziatore, 'Banca Esempio S.p.A.');
      expect(p.capitale, 1000000);
      expect(p.numeroRate, 48);
      expect(p.importoRata, 23294);
      expect(p.tanPuntiBase, 650);
      expect(p.taegPuntiBase, 712);
      expect(p.totaleDovuto, 1118112);
      expect(p.primaRata, DateTime(2026, 12, 5));
      expect(p.mutuo, isFalse);
      expect(p.campiTrovati, 7);
    });

    test('modulo PIES (mutuo)', () {
      final p = LettoreContratto.leggi(_pies);
      expect(p.mutuo, isTrue);
      expect(p.finanziatore, 'Credito Casa S.p.A.');
      expect(p.capitale, 15000000);
      expect(p.numeroRate, 300);
      expect(p.importoRata, 79015);
      expect(p.tanPuntiBase, 320);
      expect(p.taegPuntiBase, 345);
      expect(p.durataMesi, 300);
    });

    test('testo senza dati: nessuna invenzione', () {
      final p = LettoreContratto.leggi('Gentile cliente, la ringraziamo.');
      expect(p.campiTrovati, 0);
      expect(p.capitale, isNull);
      expect(p.numeroRate, isNull);
    });
  });
}
