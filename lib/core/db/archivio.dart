import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sodium/sodium.dart';
import 'package:sqlite3/sqlite3.dart' show Database, sqlite3;

import '../crypto/eccezioni.dart';
import 'id.dart';
import 'tabelle.dart';

part 'archivio.g.dart';

/// Database locale cifrato con SQLCipher (ADR-003).
@DriftDatabase(
  tables: [
    DefinizioniTipo,
    Portafogli,
    Categorie,
    Movimenti,
    Etichette,
    MovimentiEtichette,
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

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _tipiDiSistema();
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
