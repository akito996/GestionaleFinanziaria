import 'package:drift/drift.dart';

/// Colonne comuni a ogni tabella sincronizzata.
///
/// - `id`: UUID v4 generato sul dispositivo (niente contatori: due dispositivi offline
///   non possono generare lo stesso id).
/// - `aggiornatoIl`: orologio logico (HLC) dell'ultima modifica, per risolvere i conflitti.
/// - `eliminato`: cancellazione "morbida" (tombstone), così la cancellazione si sincronizza.
mixin ColonneSincronizzate on Table {
  TextColumn get id => text()();
  TextColumn get aggiornatoIl => text()();
  BoolColumn get eliminato => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Tipi definiti come dati (portafogli, movimenti, finanziamenti, raccolte fondi, ...):
/// l'utente ne crea di nuovi senza aggiornare l'app. I campi personalizzati del tipo sono
/// descritti in [schemaCampi] (JSON Schema) e i valori stanno nel `campi` della riga.
@DataClassName('DefinizioneTipo')
class DefinizioniTipo extends Table with ColonneSincronizzate {
  /// A cosa si applica: vedi [AmbitoTipo].
  TextColumn get ambito => text()();
  TextColumn get nome => text().withLength(min: 1, max: 100)();

  /// Comportamento contabile per i tipi di movimento: vedi [EffettoSaldo].
  TextColumn get effetto => text().nullable()();
  TextColumn get schemaCampi => text().withDefault(const Constant('{}'))();
  IntColumn get versioneSchema => integer().withDefault(const Constant(1))();

  /// Tipi forniti dall'app (spesa, entrata, trasferimento...): rinominabili, non eliminabili.
  BoolColumn get diSistema => boolean().withDefault(const Constant(false))();
  BoolColumn get archiviato => boolean().withDefault(const Constant(false))();
  IntColumn get ordine => integer().withDefault(const Constant(0))();
}

@DataClassName('Portafoglio')
class Portafogli extends Table with ColonneSincronizzate {
  TextColumn get tipoId => text().references(DefinizioniTipo, #id)();
  TextColumn get nome => text().withLength(min: 1, max: 100)();

  /// Codice ISO 4217 (EUR, USD, ...) o codice crypto.
  TextColumn get valuta => text().withLength(min: 3, max: 10)();

  /// Importi sempre in unità minime intere (centesimi): mai numeri decimali per i soldi.
  IntColumn get saldoInizialeMinimo =>
      integer().withDefault(const Constant(0))();
  TextColumn get campi => text().withDefault(const Constant('{}'))();
  BoolColumn get archiviato => boolean().withDefault(const Constant(false))();
  IntColumn get ordine => integer().withDefault(const Constant(0))();
}

/// Categorie e sottocategorie ad albero senza limiti di profondità.
@DataClassName('Categoria')
class Categorie extends Table with ColonneSincronizzate {
  TextColumn get padreId => text().nullable().references(Categorie, #id)();
  TextColumn get nome => text().withLength(min: 1, max: 100)();
  TextColumn get icona => text().nullable()();
  IntColumn get colore => integer().nullable()();
  BoolColumn get archiviata => boolean().withDefault(const Constant(false))();
  IntColumn get ordine => integer().withDefault(const Constant(0))();
}

@DataClassName('Movimento')
@TableIndex(
  name: 'movimenti_pianificati_unici',
  columns: {#pianificazioneId, #dataPrevista},
  unique: true,
)
class Movimenti extends Table with ColonneSincronizzate {
  TextColumn get tipoId => text().references(DefinizioniTipo, #id)();
  @ReferenceName('movimentiInUscita')
  TextColumn get portafoglioId => text().references(Portafogli, #id)();

  /// Solo per i trasferimenti: portafoglio che riceve.
  @ReferenceName('movimentiInEntrata')
  TextColumn get portafoglioDestinazioneId =>
      text().nullable().references(Portafogli, #id)();
  TextColumn get categoriaId => text().nullable().references(Categorie, #id)();

  /// Importo positivo in unità minime; il segno lo decide l'effetto del tipo.
  IntColumn get importoMinimo => integer()();
  TextColumn get valuta => text().withLength(min: 3, max: 10)();

  /// Data contabile (giorno), formato AAAA-MM-GG.
  TextColumn get data => text().withLength(min: 10, max: 10)();
  TextColumn get descrizione => text().withDefault(const Constant(''))();
  TextColumn get campi => text().withDefault(const Constant('{}'))();

  /// Movimento creato da un pagamento programmato (bolletta, rata, carta):
  /// la coppia (pianificazione, data prevista) è unica, così non si registra due volte.
  @ReferenceName('movimentiGenerati')
  TextColumn get pianificazioneId =>
      text().nullable().references(Pianificazioni, #id)();
  TextColumn get dataPrevista => text().nullable()();
}

/// Tag multilivello (anche loro ad albero).
@DataClassName('Etichetta')
class Etichette extends Table with ColonneSincronizzate {
  TextColumn get padreId => text().nullable().references(Etichette, #id)();
  TextColumn get nome => text().withLength(min: 1, max: 100)();
}

@DataClassName('MovimentoEtichetta')
class MovimentiEtichette extends Table with ColonneSincronizzate {
  TextColumn get movimentoId => text().references(Movimenti, #id)();
  TextColumn get etichettaId => text().references(Etichette, #id)();
}

/// Costo della vita: una voce di spesa ricorrente, fissa (affitto, luce, ...) o
/// variabile con una stima (spesa alimentare, carburante, ...).
@DataClassName('VoceCosto')
class VociCosto extends Table with ColonneSincronizzate {
  TextColumn get nome => text().withLength(min: 1, max: 100)();

  /// Vedi [TipoVoce].
  TextColumn get tipo => text()();

  /// Per le variabili: le spese reali sono i movimenti di questa categoria
  /// (e delle sue sottocategorie).
  TextColumn get categoriaId => text().nullable().references(Categorie, #id)();
  TextColumn get valuta =>
      text().withLength(min: 3, max: 10).withDefault(const Constant('EUR'))();
  BoolColumn get archiviata => boolean().withDefault(const Constant(false))();
  IntColumn get ordine => integer().withDefault(const Constant(0))();
}

/// Importo predefinito mensile di una voce, con la data da cui vale.
/// Ogni modifica aggiunge una riga: lo storico dei mesi passati non cambia.
@DataClassName('ImportoVoce')
class ImportiVoce extends Table with ColonneSincronizzate {
  TextColumn get voceId => text().references(VociCosto, #id)();
  IntColumn get importoMinimo => integer()();

  /// AAAA-MM-GG: da questo giorno vale il nuovo importo.
  TextColumn get validoDal => text().withLength(min: 10, max: 10)();
}

/// Importo diverso solo per un mese (es. bolletta più alta a gennaio).
@DataClassName('VariazioneMese')
class VariazioniMese extends Table with ColonneSincronizzate {
  TextColumn get voceId => text().references(VociCosto, #id)();

  /// AAAA-MM.
  TextColumn get mese => text().withLength(min: 7, max: 7)();
  IntColumn get importoMinimo => integer()();
}

/// Pagamento programmato: si ripete secondo una regola (data, frequenza, fine)
/// e nel giorno previsto diventa un movimento. Lo usano costo della vita,
/// prestiti e carte di credito ([origine] + [origineId]).
@DataClassName('Pianificazione')
class Pianificazioni extends Table with ColonneSincronizzate {
  /// Vedi [OriginePianificazione].
  TextColumn get origine => text()();
  TextColumn get origineId => text().nullable()();

  /// Da dove escono i soldi. Senza portafoglio è solo un promemoria.
  @ReferenceName('pianificazioniInUscita')
  TextColumn get portafoglioId =>
      text().nullable().references(Portafogli, #id)();

  /// Per i trasferimenti (es. addebito della carta sul conto).
  @ReferenceName('pianificazioniInEntrata')
  TextColumn get destinazioneId =>
      text().nullable().references(Portafogli, #id)();
  TextColumn get tipoId => text().nullable().references(DefinizioniTipo, #id)();
  TextColumn get categoriaId => text().nullable().references(Categorie, #id)();
  TextColumn get descrizione => text().withDefault(const Constant(''))();

  /// Importo fisso; `null` = lo calcola l'origine (es. importo del mese della voce).
  IntColumn get importoMinimo => integer().nullable()();
  TextColumn get valuta =>
      text().withLength(min: 3, max: 10).withDefault(const Constant('EUR'))();

  /// Regola: primo giorno (AAAA-MM-GG), frequenza, fine per data o numero di volte.
  TextColumn get inizio => text().withLength(min: 10, max: 10)();
  TextColumn get frequenza => text().withDefault(const Constant('mensile'))();
  TextColumn get fine => text().nullable()();
  IntColumn get occorrenze => integer().nullable()();

  /// Quanti giorni prima avvisare.
  IntColumn get avvisoGiorni => integer().withDefault(const Constant(3))();
  BoolColumn get attiva => boolean().withDefault(const Constant(true))();
}

/// Carta di credito: le spese si registrano nel suo portafoglio (saldo negativo =
/// debito); nel giorno di addebito il conto collegato paga le spese del periodo
/// chiuso (pagamento programmato con origine `carta`).
@DataClassName('CartaCredito')
class CarteCredito extends Table with ColonneSincronizzate {
  @ReferenceName('cartaDelPortafoglio')
  TextColumn get portafoglioId => text().references(Portafogli, #id)();

  @ReferenceName('carteAddebitate')
  TextColumn get contoAddebitoId => text().references(Portafogli, #id)();

  /// Giorno del mese in cui il conto viene addebitato (es. 15).
  IntColumn get giornoAddebito => integer()();

  /// Ultimo giorno di spese incluse nell'addebito: 0 = fine del mese precedente,
  /// altrimenti quel giorno del mese precedente all'addebito.
  IntColumn get giornoChiusura => integer().withDefault(const Constant(0))();

  /// Plafond (fido) in unità minime, facoltativo.
  IntColumn get plafondMinimo => integer().nullable()();
  BoolColumn get archiviata => boolean().withDefault(const Constant(false))();
}

/// Prestito, mutuo o acquisto a rate: le rate diventano pagamenti programmati
/// (origine `prestito`) e si registrano da sole nel giorno previsto.
@DataClassName('Prestito')
class Prestiti extends Table with ColonneSincronizzate {
  TextColumn get nome => text().withLength(min: 1, max: 100)();

  /// Vedi [TipoPrestito].
  TextColumn get tipo => text()();
  TextColumn get finanziatore => text().withDefault(const Constant(''))();

  /// Capitale finanziato, in unità minime.
  IntColumn get capitaleMinimo => integer()();
  IntColumn get numeroRate => integer()();
  IntColumn get importoRataMinimo => integer()();

  /// Tassi in punti base (1% = 100), facoltativi.
  IntColumn get tanPuntiBase => integer().nullable()();
  IntColumn get taegPuntiBase => integer().nullable()();

  /// AAAA-MM-GG della prima rata.
  TextColumn get primaRata => text().withLength(min: 10, max: 10)();
  TextColumn get frequenza => text().withDefault(const Constant('mensile'))();

  /// Conto da cui escono le rate (senza: solo promemoria).
  TextColumn get portafoglioId =>
      text().nullable().references(Portafogli, #id)();
  TextColumn get categoriaId => text().nullable().references(Categorie, #id)();
  TextColumn get valuta =>
      text().withLength(min: 3, max: 10).withDefault(const Constant('EUR'))();
  TextColumn get note => text().withDefault(const Constant(''))();
  BoolColumn get archiviato => boolean().withDefault(const Constant(false))();
}

/// Valori ammessi per [Prestiti.tipo].
abstract final class TipoPrestito {
  static const mutuo = 'mutuo';
  static const prestito = 'prestito';
  static const rate = 'rate';
  static const privato = 'privato';
}

/// Valori ammessi per [Pianificazioni.origine].
abstract final class OriginePianificazione {
  static const costoVita = 'costo_vita';
  static const prestito = 'prestito';
  static const carta = 'carta';
}

/// Impostazioni locali del dispositivo (non sincronizzate): id dispositivo, contatori, ...
@DataClassName('Impostazione')
class Impostazioni extends Table {
  TextColumn get chiave => text()();
  TextColumn get valore => text()();

  @override
  Set<Column<Object>> get primaryKey => {chiave};
}

/// Valori ammessi per [DefinizioniTipo.ambito].
abstract final class AmbitoTipo {
  static const portafoglio = 'portafoglio';
  static const movimento = 'movimento';
  static const finanziamento = 'finanziamento';
  static const raccoltaFondi = 'raccolta_fondi';
}

/// Valori ammessi per [VociCosto.tipo].
abstract final class TipoVoce {
  static const fissa = 'fissa';
  static const variabile = 'variabile';
}

/// Valori ammessi per [DefinizioniTipo.effetto] (solo tipi di movimento).
abstract final class EffettoSaldo {
  static const uscita = 'uscita';
  static const entrata = 'entrata';
  static const trasferimento = 'trasferimento';
}
