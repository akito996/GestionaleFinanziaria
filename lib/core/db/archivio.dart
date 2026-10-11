import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:sodium/sodium.dart';
import 'package:sqlite3/sqlite3.dart' show Database, sqlite3;

import '../crypto/eccezioni.dart';
import 'id.dart';
import 'tabelle.dart';

part 'archivio.g.dart';

/// Categoria delle rate di prestiti e mutui.
const categoriaFinanziamenti = 'Finanziamenti';
const sottocategorieFinanziamenti = ['Mutuo', 'Prestiti', 'Pagamenti a rate'];

/// Nome del tipo di portafoglio delle carte di credito.
const tipoCartaDiCredito = 'Carta di credito';

/// Categorie iniziali: (nome, icona, sottocategorie).
const categorieProposte = [
  (
    'Casa',
    'casa',
    ['Affitto o mutuo', 'Bollette', 'Condominio', 'Manutenzione'],
  ),
  ('Alimentari', 'alimentari', ['Spesa', 'Ristoranti e bar']),
  ('Trasporti', 'trasporti', ['Carburante', 'Mezzi pubblici', 'Auto']),
  ('Salute', 'salute', ['Farmacia', 'Visite mediche']),
  ('Abbonamenti', 'abbonamenti', ['Telefono e internet', 'Streaming']),
  ('Svago', 'svago', ['Viaggi', 'Hobby', 'Regali']),
  ('Persona', 'persona', ['Abbigliamento', 'Cura personale', 'Istruzione']),
  ('Tasse e assicurazioni', 'tasse', ['Tasse', 'Assicurazioni']),
  (categoriaFinanziamenti, 'finanziamenti', sottocategorieFinanziamenti),
  ('Entrate', 'entrate', ['Stipendio', 'Rimborsi', 'Altre entrate']),
];

/// Database locale cifrato con SQLCipher (ADR-003).
@DriftDatabase(
  tables: [
    DefinizioniTipo,
    Portafogli,
    Categorie,
    Movimenti,
    Etichette,
    MovimentiEtichette,
    VociCosto,
    ImportiVoce,
    VariazioniMese,
    Pianificazioni,
    CarteCredito,
    Prestiti,
    Obiettivi,
    Partecipanti,
    Versamenti,
    Impostazioni,
  ],
)
class Archivio extends _$Archivio {
  Archivio._(super.e);

  /// Apre (o crea) il database in [file], cifrato con una chiave derivata dalla [dek].
  ///
  /// La chiave del database non viene mai salvata: si ricava dalla chiave dei dati
  /// a ogni sblocco. Lancia [DatiNonValidiException] se la chiave non è quella giusta.
  static Archivio apri(File file, Sodium sodium, SecureKey dek) {
    final chiaveHex = _chiaveDatabaseHex(sodium, dek);

    // Verifica sincrona prima di passare il database all'isolate in background:
    // qui gli errori SQLite arrivano diretti, senza incapsulamenti.
    final prova = sqlite3.open(file.path);
    try {
      _sblocca(prova, chiaveHex);
      // Prima lettura reale: con la chiave sbagliata SQLCipher la rifiuta qui.
      prova.select('SELECT count(*) FROM sqlite_master;');
    } on SqliteException {
      throw const DatiNonValidiException(
        'Impossibile aprire l\'archivio locale: chiave non valida o file danneggiato.',
      );
    } finally {
      prova.close();
    }

    return Archivio._(
      NativeDatabase.createInBackground(
        file,
        setup: (db) {
          _sblocca(db, chiaveHex);
          db.execute('PRAGMA foreign_keys = ON;');
        },
      ),
    );
  }

  static void _sblocca(Database db, String chiaveHex) {
    db.execute("PRAGMA key = \"x'$chiaveHex'\";");
    // Senza SQLCipher il PRAGMA key verrebbe ignorato e il file resterebbe in chiaro.
    if (db.select('PRAGMA cipher_version;').isEmpty) {
      throw StateError('SQLCipher non disponibile: archivio non aperto.');
    }
  }

  /// Solo per i test: database in memoria, non cifrato.
  Archivio.inMemoria() : super(NativeDatabase.memory());

  /// Solo per i test: database su un esecutore dato (es. test di migrazione).
  @visibleForTesting
  Archivio.conEsecutore(super.e);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _tipiDiSistema();
      await _tipoCartaDiCredito();
      await _categorieIniziali();
    },
    onUpgrade: (m, da, a) async {
      // v2: categorie iniziali e costo della vita. I dati esistenti restano.
      if (da < 2) {
        await m.createTable(vociCosto);
        await m.createTable(importiVoce);
        await m.createTable(variazioniMese);
        final categorieEsistenti = await select(categorie).get();
        if (categorieEsistenti.isEmpty) {
          await _categorieIniziali();
        }
      }
      // v3: pagamenti programmati e collegamento movimento ↔ scadenza.
      if (da < 3) {
        await m.createTable(pianificazioni);
        await m.addColumn(movimenti, movimenti.pianificazioneId);
        await m.addColumn(movimenti, movimenti.dataPrevista);
        await m.createIndex(movimentiPianificatiUnici);
      }
      // v4: carte di credito.
      if (da < 4) {
        await m.createTable(carteCredito);
        await _tipoCartaDiCredito();
      }
      // v5: prestiti e rate, categoria "Finanziamenti".
      if (da < 5) {
        await m.createTable(prestiti);
        await _categoriaFinanziamenti();
      }
      // v6: obiettivi e collette.
      if (da < 6) {
        await m.createTable(obiettivi);
        await m.createTable(partecipanti);
        await m.createTable(versamenti);
      }
      // v7: gruppi e preferiti dei portafogli.
      if (da < 7) {
        await m.addColumn(portafogli, portafogli.gruppo);
        await m.addColumn(portafogli, portafogli.preferito);
      }
      // v8: spese annuali suddivise nei mesi, maxi rata finale dei prestiti.
      // Le tabelle create sopra (da < 2, da < 5) hanno già le colonne nuove.
      if (da < 8) {
        if (da >= 2) {
          await m.addColumn(vociCosto, vociCosto.ripartita);
        }
        if (da >= 5) {
          await m.addColumn(prestiti, prestiti.maxiRataMinimo);
        }
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );

  /// Tipi forniti al primo avvio: l'utente può rinominarli e aggiungerne altri.
  Future<void> _tipiDiSistema() async {
    const orologioIniziale = '0';
    final tipi = [
      (AmbitoTipo.movimento, 'Spesa', EffettoSaldo.uscita),
      (AmbitoTipo.movimento, 'Entrata', EffettoSaldo.entrata),
      (AmbitoTipo.movimento, 'Trasferimento', EffettoSaldo.trasferimento),
      (AmbitoTipo.portafoglio, 'Contanti', null),
      (AmbitoTipo.portafoglio, 'Conto corrente', null),
      (AmbitoTipo.portafoglio, 'Carta', null),
      (AmbitoTipo.portafoglio, 'Risparmi', null),
    ];
    await batch((b) {
      for (final (i, (ambito, nome, effetto)) in tipi.indexed) {
        b.insert(
          definizioniTipo,
          DefinizioniTipoCompanion.insert(
            id: nuovoId(),
            aggiornatoIl: orologioIniziale,
            ambito: ambito,
            nome: nome,
            effetto: Value(effetto),
            diSistema: const Value(true),
            ordine: Value(i),
          ),
        );
      }
    });
  }

  /// Tipo di portafoglio "Carta di credito" (dalla v4), se non esiste già.
  Future<void> _tipoCartaDiCredito() async {
    final esistente =
        await (select(definizioniTipo)..where(
              (t) =>
                  t.ambito.equals(AmbitoTipo.portafoglio) &
                  t.nome.equals(tipoCartaDiCredito),
            ))
            .getSingleOrNull();
    if (esistente != null) {
      return;
    }
    await into(definizioniTipo).insert(
      DefinizioniTipoCompanion.insert(
        id: nuovoId(),
        aggiornatoIl: '0',
        ambito: AmbitoTipo.portafoglio,
        nome: tipoCartaDiCredito,
        diSistema: const Value(true),
        ordine: const Value(10),
      ),
    );
  }

  /// Categoria "Finanziamenti" (dalla v5) per chi ha già le categorie.
  Future<void> _categoriaFinanziamenti() async {
    final esistente =
        await (select(categorie)..where(
              (c) => c.nome.equals(categoriaFinanziamenti) & c.padreId.isNull(),
            ))
            .getSingleOrNull();
    if (esistente != null) {
      return;
    }
    final padre = nuovoId();
    await batch((b) {
      b.insert(
        categorie,
        CategorieCompanion.insert(
          id: padre,
          aggiornatoIl: '0',
          nome: categoriaFinanziamenti,
          icona: const Value('finanziamenti'),
          ordine: const Value(8),
        ),
      );
      for (final (i, nome) in sottocategorieFinanziamenti.indexed) {
        b.insert(
          categorie,
          CategorieCompanion.insert(
            id: nuovoId(),
            aggiornatoIl: '0',
            nome: nome,
            padreId: Value(padre),
            ordine: Value(i),
          ),
        );
      }
    });
  }

  /// Categorie proposte al primo avvio (modificabili, eliminabili, ampliabili).
  Future<void> _categorieIniziali() async {
    const orologioIniziale = '0';
    await batch((b) {
      for (final (i, (nome, icona, figli)) in categorieProposte.indexed) {
        final padre = nuovoId();
        b.insert(
          categorie,
          CategorieCompanion.insert(
            id: padre,
            aggiornatoIl: orologioIniziale,
            nome: nome,
            icona: Value(icona),
            ordine: Value(i),
          ),
        );
        for (final (j, figlio) in figli.indexed) {
          b.insert(
            categorie,
            CategorieCompanion.insert(
              id: nuovoId(),
              aggiornatoIl: orologioIniziale,
              nome: figlio,
              padreId: Value(padre),
              ordine: Value(j),
            ),
          );
        }
      }
    });
  }

  /// Chiave SQLCipher "raw" (256 bit, niente PBKDF2 interno: la DEK è già casuale),
  /// separata dalla DEK con un contesto KDF dedicato.
  static String _chiaveDatabaseHex(Sodium sodium, SecureKey dek) {
    final chiave = sodium.crypto.kdf.deriveFromKey(
      masterKey: dek,
      context: 'GFdb0001',
      subkeyId: BigInt.one,
      subkeyLen: 32,
    );
    try {
      return chiave.runUnlockedSync(
        (byte) => byte.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      );
    } finally {
      chiave.dispose();
    }
  }
}
