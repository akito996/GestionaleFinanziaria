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

  /// Non più usata (v7): i gruppi sono stati sostituiti da "Mostra altro".
  /// Resta per compatibilità con gli archivi esistenti.
  TextColumn get gruppo => text().nullable()();

  /// Preferito: sempre in evidenza in cima, anche con "Mostra meno".
  BoolColumn get preferito => boolean().withDefault(const Constant(false))();
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

  /// Nei portafogli condivisi (ADR-019): chi l'ha inserito e chi l'ha
  /// modificato per ultimo (id in [Membri]). Vuoti negli altri portafogli.
  TextColumn get inseritoDa => text().nullable()();
  TextColumn get modificatoDa => text().nullable()();
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

  /// Solo per gli addebiti non mensili (es. una volta l'anno): `true` = la
  /// spesa si suddivide nei mesi (1.200 €/anno → 100 € al mese), `false` = pesa
  /// solo nel mese del pagamento.
  BoolColumn get ripartita => boolean().withDefault(const Constant(false))();

  /// Vedi [NaturaVoce]: spesa (costo della vita) o entrata (entrate previste).
  TextColumn get natura =>
      text().withDefault(const Constant(NaturaVoce.spesa))();
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

  /// `true` = nel giorno previsto non si registra da sola: resta nelle
  /// notifiche finché l'utente conferma, sposta o annulla.
  BoolColumn get richiedeConferma =>
      boolean().withDefault(const Constant(false))();

  /// AAAA-MM-GG, "Conta dal": le scadenze prima di questo giorno erano già
  /// avvenute quando è stata inserita (prestito o entrata già in corso): non
  /// si registrano, non si notificano e non contano nel costo della vita.
  /// `null` = tutte (archivi creati prima della v13).
  TextColumn get registraDal => text().nullable()();
}

/// Scelta dell'utente su una singola scadenza di un pagamento programmato:
/// spostata a un altro giorno, annullata o fatta (promemoria).
///
/// L'id è `<pianificazioneId>:<dataPrevista>`: due dispositivi che decidono
/// sulla stessa scadenza aggiornano la stessa riga.
@DataClassName('Occorrenza')
class Occorrenze extends Table with ColonneSincronizzate {
  TextColumn get pianificazioneId => text().references(Pianificazioni, #id)();

  /// AAAA-MM-GG: il giorno della regola (resta lo stesso anche se spostata).
  TextColumn get dataPrevista => text().withLength(min: 10, max: 10)();

  /// Vedi [StatoOccorrenza]; `null` = nessuna scelta.
  TextColumn get stato => text().nullable()();

  /// AAAA-MM-GG: il nuovo giorno, se spostata.
  TextColumn get nuovaData => text().nullable()();
}

/// Valori ammessi per [Occorrenze.stato].
abstract final class StatoOccorrenza {
  static const spostata = 'spostata';
  static const annullata = 'annullata';

  /// Promemoria senza portafoglio segnato come fatto.
  static const fatta = 'fatta';
}

/// Notifiche lette: un avviso letto sparisce dalla campanella (resta
/// nell'elenco completo). L'id è la chiave della notifica (es.
/// `scadenza:<pianificazioneId>:<dataPrevista>`).
@DataClassName('NotificaLetta')
class NotificheLette extends Table with ColonneSincronizzate {
  /// Data e ora locali della lettura (ISO 8601).
  TextColumn get lettaIl => text()();
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

  /// Maxi rata finale (es. finanziamenti auto): l'ultima delle [numeroRate]
  /// rate vale questa cifra invece di [importoRataMinimo]. `null` = nessuna.
  IntColumn get maxiRataMinimo => integer().nullable()();

  /// Spese di incasso addebitate con ogni rata (es. 3,50 €). Il movimento
  /// registrato è rata + spese, come sull'estratto conto; il piano di
  /// ammortamento resta sulla sola rata. `null` = nessuna.
  IntColumn get speseRataMinimo => integer().nullable()();

  /// Cosa fare della maxi rata (vedi [DecisioneMaxi]); `null` = da decidere.
  TextColumn get decisioneMaxi => text().nullable()();

  /// AAAA-MM-GG dell'ultima volta che l'utente ha rimandato la decisione.
  TextColumn get maxiRimandataIl => text().nullable()();

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

/// Valori ammessi per [Prestiti.decisioneMaxi].
abstract final class DecisioneMaxi {
  /// Un nuovo prestito paga la maxi rata: dal conto non esce.
  static const rifinanzia = 'rifinanzia';

  /// La maxi rata si paga in un'unica soluzione alla scadenza.
  static const estingui = 'estingui';
}

/// Valori ammessi per [Prestiti.tipo].
abstract final class TipoPrestito {
  static const mutuo = 'mutuo';
  static const prestito = 'prestito';
  static const rate = 'rate';
  static const privato = 'privato';
}

/// Obiettivo di risparmio personale o colletta con altre persone.
@DataClassName('Obiettivo')
class Obiettivi extends Table with ColonneSincronizzate {
  TextColumn get nome => text().withLength(min: 1, max: 100)();

  /// Vedi [TipoObiettivo].
  TextColumn get tipo => text()();
  IntColumn get importoObiettivoMinimo => integer()();

  /// AAAA-MM-GG entro cui raggiungerlo (facoltativa).
  TextColumn get scadenza => text().nullable()();

  /// Portafoglio dove finiscono i soldi (facoltativo, es. "Salvadanaio").
  TextColumn get portafoglioId =>
      text().nullable().references(Portafogli, #id)();
  TextColumn get valuta =>
      text().withLength(min: 3, max: 10).withDefault(const Constant('EUR'))();
  TextColumn get note => text().withDefault(const Constant(''))();
  BoolColumn get archiviato => boolean().withDefault(const Constant(false))();
}

/// Partecipante di una colletta, con la sua quota (null = parti uguali).
@DataClassName('Partecipante')
class Partecipanti extends Table with ColonneSincronizzate {
  TextColumn get obiettivoId => text().references(Obiettivi, #id)();
  TextColumn get nome => text().withLength(min: 1, max: 100)();
  IntColumn get quotaMinimo => integer().nullable()();
}

/// Soldi versati per un obiettivo (da un partecipante, o da me se personale).
@DataClassName('Versamento')
class Versamenti extends Table with ColonneSincronizzate {
  TextColumn get obiettivoId => text().references(Obiettivi, #id)();
  TextColumn get partecipanteId =>
      text().nullable().references(Partecipanti, #id)();
  IntColumn get importoMinimo => integer()();
  TextColumn get data => text().withLength(min: 10, max: 10)();
  TextColumn get nota => text().withDefault(const Constant(''))();

  /// Movimento registrato insieme al versamento (facoltativo).
  TextColumn get movimentoId => text().nullable().references(Movimenti, #id)();
}

/// Valori ammessi per [Obiettivi.tipo].
abstract final class TipoObiettivo {
  static const personale = 'personale';
  static const colletta = 'colletta';
}

/// Valori ammessi per [Pianificazioni.origine].
abstract final class OriginePianificazione {
  static const costoVita = 'costo_vita';
  static const prestito = 'prestito';
  static const carta = 'carta';
}

/// Portafoglio condiviso (ADR-019): la parte su Google Drive di un
/// portafoglio. Il proprietario prepara la cartella, il registro e un file per
/// ogni membro; ognuno scrive solo nel proprio file.
@DataClassName('PortafoglioCondiviso')
class PortafogliCondivisi extends Table with ColonneSincronizzate {
  /// Senza vincolo: il membro riceve la riga del portafoglio solo dopo
  /// essere entrato.
  TextColumn get portafoglioId => text()();

  /// Ruolo di questo archivio: vedi [RuoloMembro].
  TextColumn get ruolo => text()();

  /// Cartella su Drive (id).
  TextColumn get cartellaId => text()();

  /// Registro del portafoglio (membri, ruoli, quote), scritto dal proprietario.
  TextColumn get registroId => text()();

  /// Il file di questo archivio nella cartella (dove scrive le sue modifiche).
  TextColumn get mioFileId => text().nullable()();

  /// Chiave del portafoglio (32 byte, base64). Sta nell'archivio cifrato e
  /// viaggia solo nei pacchetti cifrati della sincronizzazione (ADR-015).
  TextColumn get chiave => text()();
}

/// Una persona di un portafoglio condiviso, proprietario compreso.
@DataClassName('Membro')
class Membri extends Table with ColonneSincronizzate {
  /// Senza vincolo: il membro riceve la riga del portafoglio solo dopo
  /// essere entrato.
  TextColumn get portafoglioId => text()();

  /// Email Google con cui è stato invitato.
  TextColumn get email => text()();
  TextColumn get nome => text().withDefault(const Constant(''))();

  /// Vedi [RuoloMembro].
  TextColumn get ruolo => text()();

  /// Vedi [StatoMembro].
  TextColumn get stato => text()();

  /// Il suo file nella cartella su Drive (id), preparato dal proprietario.
  TextColumn get fileId => text().nullable()();

  /// Chiavi pubbliche (base64): per ricevere la chiave del portafoglio
  /// (X25519) e per verificare le sue firme (Ed25519).
  TextColumn get chiaveScambio => text().nullable()();
  TextColumn get chiaveFirma => text().nullable()();

  /// Codice di sicurezza confrontato (a voce o con il QR).
  BoolColumn get verificato => boolean().withDefault(const Constant(false))();

  /// Quota del totale in centesimi di punto (5000 = 50%); vuota = non
  /// indicata (consegna 2).
  IntColumn get quota => integer().nullable()();

  /// Quando è partito l'ultimo invito (UTC, ISO 8601): ha un'ora per
  /// accettare.
  TextColumn get invitatoIl => text().nullable()();
}

/// L'ultima versione **firmata** di ogni riga di un portafoglio condiviso
/// (il portafoglio stesso o un suo movimento), com'è scritta nei file su
/// Drive. `id` = `<portafoglio>:<riga>`, `aggiornatoIl` = orologio di chi
/// l'ha cambiata (vale l'ultima). Chiunque la può ricopiare: la firma dice
/// chi l'ha cambiata davvero.
@DataClassName('RigaCondivisa')
class RigheCondivise extends Table with ColonneSincronizzate {
  TextColumn get portafoglioId => text()();

  /// Id della riga nella sua tabella.
  TextColumn get rigaId => text()();

  /// "portafoglio" o "movimento".
  TextColumn get tipo => text()();

  /// Il membro che l'ha firmata.
  TextColumn get firmatario => text()();

  /// JSON canonico della riga (quello firmato).
  TextColumn get contenuto => text()();
  TextColumn get firma => text()();

  /// L'orologio della riga locale dopo l'ultima scrittura da qui o da un
  /// file condiviso: se la riga ne ha uno diverso, è cambiata su questo
  /// archivio e va pubblicata.
  TextColumn get rigaAggiornataIl => text()();
}

/// Valori ammessi per [PortafogliCondivisi.ruolo] e [Membri.ruolo].
abstract final class RuoloMembro {
  static const proprietario = 'proprietario';
  static const membro = 'membro';
}

/// Valori ammessi per [Membri.stato].
abstract final class StatoMembro {
  /// Invitato, non ancora entrato: "nome (da confermare)".
  static const invitato = 'invitato';
  static const attivo = 'attivo';

  /// Uscito o tolto dal proprietario.
  static const uscito = 'uscito';

  /// Non ha accettato in tempo: la cartella non gli è più condivisa; si può
  /// invitare di nuovo.
  static const scaduto = 'scaduto';
}

/// Chi usa l'archivio (Impostazioni › Account): una sola riga (id "io") che
/// viaggia tra i propri dispositivi. Il nome nelle condivisioni è quello che
/// vedono le altre persone accanto alle voci dei portafogli condivisi.
@DataClassName('Profilo')
class Profili extends Table with ColonneSincronizzate {
  /// Nome e cognome.
  TextColumn get nome => text().withDefault(const Constant(''))();

  /// L'email dell'account Google usato per sincronizzare.
  TextColumn get email => text().withDefault(const Constant(''))();

  /// Vuoto = il codice dell'archivio (GF-XXXX-XXXX).
  TextColumn get nomeCondivisione => text().withDefault(const Constant(''))();
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
/// Valori ammessi per [VociCosto.natura].
abstract final class NaturaVoce {
  /// Costo della vita.
  static const spesa = 'spesa';

  /// Entrate previste (stipendio, pensione...).
  static const entrata = 'entrata';
}

/// Report automatico salvato: mensile o annuale (vedi [PeriodicitaReport]).
/// Il contenuto è un JSON con i dati del periodo, così resta com'era anche se
/// poi cambiano le voci.
@DataClassName('ReportSalvato')
class Report extends Table with ColonneSincronizzate {
  /// Vedi [PeriodicitaReport].
  TextColumn get periodicita => text()();

  /// "2026-10" (mensile) o "2026" (annuale).
  TextColumn get periodo => text().withLength(min: 4, max: 7)();

  /// Dati del report (JSON, con la versione del formato).
  TextColumn get contenuto => text()();
}

/// Valori ammessi per [Report.periodicita].
abstract final class PeriodicitaReport {
  static const mensile = 'mensile';
  static const annuale = 'annuale';
}

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
