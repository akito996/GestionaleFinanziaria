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
