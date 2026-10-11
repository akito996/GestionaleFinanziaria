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

/// Finanziamento auto con maxi rata finale (dati inventati). Nella prima riga
/// "maxi rata finale" è seguito da un altro importo: non va confuso.
const _secciAuto = '''
INFORMAZIONI EUROPEE DI BASE SUL CREDITO AI CONSUMATORI
Finanziatore: Auto Credito Esempio S.p.A.
Tipo di contratto di credito: Finanziamento finalizzato con maxi rata finale
Importo totale del credito € 20.000,00
Durata del contratto di credito 36 mesi
Rate: n. 35 rate mensili di € 336,69 più una maxi rata finale di € 11.000,00
Scadenza della maxi rata: 05/11/2029
Scadenza prima rata: 05/12/2026
Tasso annuo nominale (TAN) fisso 5,95 %
Tasso annuo effettivo globale (TAEG) 7,40 %
''';

/// Documento di trasparenza di una finanziaria (dati inventati), con la
/// struttura reale: sigle puntate (T.A.N.), tabella delle rate e piano di
/// ammortamento. Contiene anche le trappole viste in un documento vero:
/// "12 mesi" nel testo sulla privacy e l'intestazione "Rata Data scadenza".
const _trasparenza = '''
Documento di trasparenza n°001
Finanziaria Esempio S.p.A.
Via Roma 1, 00100 ROMA - C.F. e P.Iva 00000000000
Capitale sociale Euro 1.000.000 i.v.
DOCUMENTO DI TRASPARENZA
Condizioni del Finanziamento
Prezzo di vendita del veicolo : 15.000,00 EUR
Importo anticipo : 9.000,00 EUR
Capitale finanziato : 6.000,00 EUR
T.A.N. : 3,50 %
T.A.E.G : 6.10 %
Prima rata
piano rientro
Ultima rata
piano rientro
Numero
rate
Importo
rata finanziaria
05/01/2027 05/05/2027 5 615,74 EUR 2,00 EUR 617,74 EUR
05/06/2027 05/06/2027 1 3.000,03 EUR 2,00 EUR 3.002,03 EUR
Spese di gestione e/o incasso : 2,00 EUR
Piano di Ammortamento
Rata Data
scadenza Quota Capitale Quota interessi Importo rata Capitale residuo
1 05.01.2027 598,24 EUR 17,50 EUR 615,74 EUR 5.401,76 EUR
2 05.02.2027 599,98 EUR 15,76 EUR 615,74 EUR 4.801,78 EUR
3 05.03.2027 601,73 EUR 14,01 EUR 615,74 EUR 4.200,05 EUR
4 05.04.2027 603,49 EUR 12,25 EUR 615,74 EUR 3.596,56 EUR
5 05.05.2027 605,25 EUR 10,49 EUR 615,74 EUR 2.991,31 EUR
6 05.06.2027 2.991,31 EUR 8,72 EUR 3.000,03 EUR 0,00 EUR
Pagamenti successivamente regolarizzati 12 mesi dalla data di registrazione.
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

    test("maxi rata finale: rate costanti più l'ultima che chiude", () {
      final rata = Ammortamento.rata(
        capitale: 2000000,
        numeroRate: 36,
        tanPuntiBase: 595,
        rataFinale: 1100000,
      );
      expect(rata, inInclusiveRange(33660, 33680));
      final piano = Ammortamento.piano(
        capitale: 2000000,
        numeroRate: 36,
        tanPuntiBase: 595,
        rataFissa: 33669,
        rataFinale: 1100000,
      );
      expect(piano, hasLength(36));
      expect(piano.first.rata, 33669);
      expect(piano.last.rata, 1100000);
      expect(piano.last.debitoResiduo, 0);
      expect(
        piano.map((r) => r.quotaCapitale).reduce((a, b) => a + b),
        2000000,
      );
      // Il TAN si ricava anche con la maxi rata.
      expect(
        Ammortamento.tanDaRata(
          capitale: 2000000,
          numeroRate: 36,
          rata: 33669,
          rataFinale: 1100000,
        ),
        inInclusiveRange(590, 600),
      );
      // Senza interessi: (capitale − maxi rata) diviso le altre rate.
      expect(
        Ammortamento.rata(
          capitale: 1200000,
          numeroRate: 3,
          tanPuntiBase: 0,
          rataFinale: 600000,
        ),
        300000,
      );
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

    test('finanziamento auto con maxi rata finale', () {
      final p = LettoreContratto.leggi(_secciAuto);
      expect(p.capitale, 2000000);
      expect(p.maxiRata, 1100000);
      expect(p.importoRata, 33669);
      // 35 rate + la maxi rata = 36.
      expect(p.numeroRate, 36);
      expect(p.tanPuntiBase, 595);
      expect(p.taegPuntiBase, 740);
      expect(p.primaRata, DateTime(2026, 12, 5));
      expect(p.campiTrovati, 8);
    });

    test('la data della rata finale non è un importo', () {
      final p = LettoreContratto.leggi(
        'Scadenza rata finale: 05/12/2030. Durata di 36 mesi.',
      );
      expect(p.maxiRata, isNull);
      expect(p.importoRata, isNull);
    });

    test('documento di trasparenza: sigle puntate e piano di ammortamento', () {
      final p = LettoreContratto.leggi(_trasparenza);
      expect(p.finanziatore, 'Finanziaria Esempio S.p.A.');
      expect(p.capitale, 600000);
      expect(p.numeroRate, 6); // dal piano, non i "12 mesi" della privacy
      expect(p.importoRata, 61574); // non "1" dall'intestazione "Rata Data"
      expect(p.maxiRata, 300003);
      expect(p.tanPuntiBase, 350); // "T.A.N."
      expect(p.taegPuntiBase, 610); // "T.A.E.G" con il punto decimale
      expect(p.primaRata, DateTime(2027, 1, 5));
      expect(p.speseRata, 200);
      expect(p.campiTrovati, 8);

      // Senza la riga "Capitale finanziato" il capitale si ricava dal piano.
      final senza = LettoreContratto.leggi(
        _trasparenza.replaceFirst('Capitale finanziato : 6.000,00 EUR', ''),
      );
      expect(senza.capitale, 600000);
    });

    test('un numero senza centesimi né valuta non è un importo', () {
      final p = LettoreContratto.leggi('Rata Data scadenza 1 e altro testo');
      expect(p.importoRata, isNull);
      expect(LettoreContratto.leggi('rata di € 250').importoRata, 25000);
    });

    test('testo senza dati: nessuna invenzione', () {
      final p = LettoreContratto.leggi('Gentile cliente, la ringraziamo.');
      expect(p.campiTrovati, 0);
      expect(p.capitale, isNull);
      expect(p.numeroRate, isNull);
    });
  });
}
