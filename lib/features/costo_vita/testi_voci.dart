import '../../core/db/tabelle.dart';

/// Testi delle due sezioni gemelle: Costo della vita (spese) ed Entrate
/// previste. Il motore è lo stesso: cambiano solo le parole.
class TestiVoci {
  const TestiVoci._({
    required this.natura,
    required this.sezione,
    required this.titoloMese,
    required this.fisse,
    required this.variabili,
    required this.realiFinora,
    required this.realiDavvero,
    required this.primaTitolo,
    required this.primaTesto,
    required this.suggeriteFisse,
    required this.suggeriteVariabili,
    required this.nuovaFissa,
    required this.nuovaVariabile,
    required this.descrizioneFissa,
    required this.descrizioneVariabile,
    required this.categoriaReali,
    required this.eliminata,
    required this.data,
    required this.dataSpiegazione,
    required this.primaData,
    required this.ultimaData,
    required this.quanteVolte,
    required this.perData,
    required this.portafoglio,
    required this.portafoglioSpiegazione,
    required this.suddividi,
    required this.reale,
    required this.manca,
    required this.oltre,
  });

  final String natura;

  /// Titolo della sezione ("Costo della vita").
  final String sezione;

  /// "Costo previsto del mese".
  final String titoloMese;
  final String fisse;
  final String variabili;

  /// "Variabili spese finora".
  final String realiFinora;

  /// "Speso davvero (fisse + variabili)".
  final String realiDavvero;
  final String primaTitolo;
  final String primaTesto;

  /// Suggerimenti a un tocco: (nome, categoria proposta).
  final List<(String, String)> suggeriteFisse;
  final List<(String, String)> suggeriteVariabili;
  final String nuovaFissa;
  final String nuovaVariabile;
  final String descrizioneFissa;
  final String descrizioneVariabile;
  final String categoriaReali;

  /// Testo della conferma di eliminazione.
  final String eliminata;

  /// "Data di addebito" / "Data di accredito".
  final String data;
  final String dataSpiegazione;
  final String primaData;
  final String ultimaData;
  final String quanteVolte;

  /// "per addebito" / "per accredito".
  final String perData;
  final String portafoglio;
  final String portafoglioSpiegazione;
  final String suddividi;

  /// "Speso" / "Ricevuto".
  final String reale;

  /// "restano" / "mancano".
  final String manca;

  /// "oltre la stima" / "più del previsto".
  final String oltre;

  bool get entrate => natura == NaturaVoce.entrata;

  static TestiVoci per(String natura) =>
      natura == NaturaVoce.entrata ? entratePreviste : costoVita;

  static const costoVita = TestiVoci._(
    natura: NaturaVoce.spesa,
    sezione: 'Costo della vita',
    titoloMese: 'Costo previsto del mese',
    fisse: 'Spese fisse',
    variabili: 'Spese variabili',
    realiFinora: 'Variabili spese finora',
    realiDavvero: 'Speso davvero (fisse + variabili)',
    primaTitolo: 'Quanto ti costa vivere ogni mese?',
    primaTesto:
        'Aggiungi le spese fisse (affitto, bollette, abbonamenti) e una stima '
        "delle spese variabili (spesa, carburante, svago). Ogni mese l'app "
        'parte da questi importi: puoi cambiarli per un solo mese oppure da '
        'domani o dal mese prossimo in poi.',
    suggeriteFisse: [
      ('Affitto o mutuo', 'Affitto o mutuo'),
      ('Condominio', 'Condominio'),
      ('Telefono e internet', 'Telefono e internet'),
      ('Assicurazione auto', 'Assicurazioni'),
      ('Abbonamenti streaming', 'Streaming'),
      ('Palestra', 'Hobby'),
    ],
    suggeriteVariabili: [
      ('Luce', 'Bollette'),
      ('Gas', 'Bollette'),
      ('Acqua', 'Bollette'),
      ('Spesa alimentare', 'Spesa'),
      ('Ristoranti e bar', 'Ristoranti e bar'),
      ('Carburante', 'Carburante'),
      ('Farmacia', 'Farmacia'),
      ('Svago', 'Svago'),
      ('Abbigliamento', 'Abbigliamento'),
    ],
    nuovaFissa: 'Nuova spesa fissa',
    nuovaVariabile: 'Nuova spesa variabile',
    descrizioneFissa: 'Una spesa che si ripete uguale ogni mese.',
    descrizioneVariabile:
        'Una spesa che cambia ogni mese: indica quanto prevedi di spendere. '
        "Con una categoria l'app confronta la stima con quello che spendi "
        'davvero.',
    categoriaReali: 'Categoria delle spese reali',
    eliminata:
        'Sparisce dal costo della vita, anche dai mesi passati, e gli addebiti '
        'automatici si fermano. I movimenti già registrati restano.',
    data: 'Data di addebito',
    dataSpiegazione: 'Quando scalano i soldi dal conto',
    primaData: 'Primo addebito',
    ultimaData: 'Ultimo addebito entro',
    quanteVolte: 'Dopo quanti addebiti finisce',
    perData: 'per addebito',
    portafoglio: 'Da quale portafoglio',
    portafoglioSpiegazione:
        'Con un portafoglio la spesa si registra da sola nel giorno previsto '
        '(ti avviso 3 giorni prima).',
    suddividi: 'Suddividi la spesa nei mesi',
    reale: 'Speso',
    manca: 'restano',
    oltre: 'oltre la stima',
  );

  static const entratePreviste = TestiVoci._(
    natura: NaturaVoce.entrata,
    sezione: 'Entrate previste',
    titoloMese: 'Entrate previste del mese',
    fisse: 'Entrate fisse',
    variabili: 'Entrate variabili',
    realiFinora: 'Variabili ricevute finora',
    realiDavvero: 'Ricevuto davvero (fisse + variabili)',
    primaTitolo: 'Quanto entra ogni mese?',
    primaTesto:
        'Aggiungi le entrate fisse (stipendio, pensione, affitti percepiti) e '
        'una stima di quelle variabili (provvigioni, lavori extra, rimborsi). '
        "Ogni mese l'app parte da questi importi: puoi cambiarli per un solo "
        'mese oppure da domani o dal mese prossimo in poi.',
    suggeriteFisse: [
      ('Stipendio', 'Stipendio'),
      ('Pensione', 'Altre entrate'),
      ('Affitto percepito', 'Altre entrate'),
      ('Assegno unico', 'Altre entrate'),
    ],
    suggeriteVariabili: [
      ('Provvigioni e bonus', 'Stipendio'),
      ('Lavori extra', 'Altre entrate'),
      ('Rimborsi', 'Rimborsi'),
      ('Interessi e dividendi', 'Altre entrate'),
    ],
    nuovaFissa: 'Nuova entrata fissa',
    nuovaVariabile: 'Nuova entrata variabile',
    descrizioneFissa:
        "Un'entrata che arriva uguale ogni mese (per esempio lo stipendio).",
    descrizioneVariabile:
        "Un'entrata che cambia ogni mese: indica quanto prevedi di ricevere. "
        "Con una categoria l'app confronta la stima con quello che ricevi "
        'davvero.',
    categoriaReali: 'Categoria delle entrate reali',
    eliminata:
        'Sparisce dalle entrate previste, anche dai mesi passati, e gli '
        'accrediti automatici si fermano. I movimenti già registrati restano.',
    data: 'Data di accredito',
    dataSpiegazione: 'Quando arrivano i soldi sul conto',
    primaData: 'Primo accredito',
    ultimaData: 'Ultimo accredito entro',
    quanteVolte: 'Dopo quanti accrediti finisce',
    perData: 'per accredito',
    portafoglio: 'Su quale portafoglio',
    portafoglioSpiegazione:
        "Con un portafoglio l'entrata si registra da sola nel giorno previsto "
        '(ti avviso 3 giorni prima).',
    suddividi: "Suddividi l'entrata nei mesi",
    reale: 'Ricevuto',
    manca: 'mancano',
    oltre: 'più del previsto',
  );
}
