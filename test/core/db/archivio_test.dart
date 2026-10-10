import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/crypto/cifratura.dart';
import 'package:gestionale_finanziaria/core/crypto/eccezioni.dart';
import 'package:gestionale_finanziaria/core/db/archivio.dart';
import 'package:gestionale_finanziaria/core/db/id.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';
import 'package:sodium/sodium_sumo.dart';

void main() {
  late SodiumSumo sodium;
  late Directory cartella;
  late File file;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() async {
    cartella = await Directory.systemTemp.createTemp('archivio_test');
    file = File('${cartella.path}${Platform.pathSeparator}archivio.db');
  });

  tearDown(() async {
    await cartella.delete(recursive: true);
  });

  Future<String> spesaPizzeria(Archivio db) async {
    final tipoSpesa = await (db.select(
      db.definizioniTipo,
    )..where((t) => t.nome.equals('Spesa'))).getSingle();
    final tipoContanti = await (db.select(
      db.definizioniTipo,
    )..where((t) => t.nome.equals('Contanti'))).getSingle();

    final portafoglio = nuovoId();
    await db
        .into(db.portafogli)
        .insert(
          PortafogliCompanion.insert(
            id: portafoglio,
            aggiornatoIl: '1',
            tipoId: tipoContanti.id,
            nome: 'Contanti',
            valuta: 'EUR',
          ),
        );
    final movimento = nuovoId();
    await db
        .into(db.movimenti)
        .insert(
          MovimentiCompanion.insert(
            id: movimento,
            aggiornatoIl: '1',
            tipoId: tipoSpesa.id,
            portafoglioId: portafoglio,
            importoMinimo: 1200,
            valuta: 'EUR',
            data: '2026-10-10',
            descrizione: const Value('Pizzeria Da Mario'),
          ),
        );
    return movimento;
  }

  test('il file su disco è cifrato: nessun testo leggibile', () async {
    final dek = Cifratore(sodium).nuovaChiave();
    addTearDown(dek.dispose);

    final db = Archivio.apri(file, sodium, dek);
    await spesaPizzeria(db);
    await db.close();

    final byte = await file.readAsBytes();
    expect(byte, isNotEmpty);
    final testo = latin1.decode(byte);
    expect(testo, isNot(startsWith('SQLite format 3')));
    expect(testo, isNot(contains('Pizzeria')));
    expect(testo, isNot(contains('Contanti')));
  });

  test('si riapre con la stessa chiave e ritrova i dati', () async {
    final dek = Cifratore(sodium).nuovaChiave();
    addTearDown(dek.dispose);

    final db = Archivio.apri(file, sodium, dek);
    final id = await spesaPizzeria(db);
    await db.close();

    final riaperto = Archivio.apri(file, sodium, dek);
    addTearDown(riaperto.close);
    final movimento = await (riaperto.select(
      riaperto.movimenti,
    )..where((m) => m.id.equals(id))).getSingle();
    expect(movimento.importoMinimo, 1200);
    expect(movimento.descrizione, 'Pizzeria Da Mario');
  });

  test('con un\'altra chiave non si apre', () async {
    final dek = Cifratore(sodium).nuovaChiave();
    final altra = Cifratore(sodium).nuovaChiave();
    addTearDown(dek.dispose);
    addTearDown(altra.dispose);

    final db = Archivio.apri(file, sodium, dek);
    await spesaPizzeria(db);
    await db.close();

    expect(
      () => Archivio.apri(file, sodium, altra),
      throwsA(isA<DatiNonValidiException>()),
    );
  });

  group('struttura', () {
    late Archivio db;

    setUp(() => db = Archivio.inMemoria());
    tearDown(() => db.close());

    test('al primo avvio ci sono i tipi di sistema', () async {
      final tipi = await db.select(db.definizioniTipo).get();
      final movimento = tipi.where((t) => t.ambito == AmbitoTipo.movimento);
      final portafoglio = tipi.where((t) => t.ambito == AmbitoTipo.portafoglio);

      expect(movimento.map((t) => t.effetto), [
        EffettoSaldo.uscita,
        EffettoSaldo.entrata,
        EffettoSaldo.trasferimento,
      ]);
      expect(portafoglio, hasLength(4));
      expect(tipi.every((t) => t.diSistema), isTrue);
    });

    test('categorie ad albero senza limiti di profondità', () async {
      String? padre;
      for (var livello = 0; livello < 10; livello++) {
        final id = nuovoId();
        await db
            .into(db.categorie)
            .insert(
              CategorieCompanion.insert(
                id: id,
                aggiornatoIl: '1',
                nome: 'Livello $livello',
                padreId: Value(padre),
              ),
            );
        padre = id;
      }
      final foglia = await (db.select(
        db.categorie,
      )..where((c) => c.id.equals(padre!))).getSingle();
      expect(foglia.nome, 'Livello 9');
      expect(foglia.padreId, isNotNull);
    });

    test('vincoli: movimento con portafoglio inesistente rifiutato', () async {
      final tipo = await (db.select(
        db.definizioniTipo,
      )..where((t) => t.nome.equals('Spesa'))).getSingle();
      await expectLater(
        db
            .into(db.movimenti)
            .insert(
              MovimentiCompanion.insert(
                id: nuovoId(),
                aggiornatoIl: '1',
                tipoId: tipo.id,
                portafoglioId: 'inesistente',
                importoMinimo: 100,
                valuta: 'EUR',
                data: '2026-10-10',
              ),
            ),
        throwsA(anything),
      );
    });
  });

  test('id: UUID v4 validi e diversi', () {
    final ids = List.generate(1000, (_) => nuovoId());
    expect(ids.toSet(), hasLength(1000));
    final formato = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    expect(ids.every(formato.hasMatch), isTrue);
  });
}
