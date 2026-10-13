import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/db/archivio.dart';
import 'package:gestionale_finanziaria/core/db/id.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

void main() {
  test(
    'migrazione v1 → v11: dati conservati, nuove tabelle e categorie',
    () async {
      // Lo schema delle tabelle già presenti in v1 non è cambiato: si crea un archivio
      // attuale e lo si riporta com'era in v1 (senza le aggiunte della v2).
      final grezzo = sql.sqlite3.openInMemory();

      // 1) Crea un archivio "v2" e lo riporta com'era in v1.
      final v2 = Archivio.conEsecutore(
        NativeDatabase.opened(grezzo, closeUnderlyingOnClose: false),
      );
      final tipo = (await v2.select(v2.definizioniTipo).get()).firstWhere(
        (t) => t.nome == 'Contanti',
      );
      await v2
          .into(v2.portafogli)
          .insert(
            PortafogliCompanion.insert(
              id: nuovoId(),
              aggiornatoIl: '1',
              tipoId: tipo.id,
              nome: 'I miei contanti',
              valuta: 'EUR',
              saldoInizialeMinimo: const Value(4200),
            ),
          );
      await v2.close();
      grezzo
        ..execute('ALTER TABLE portafogli DROP COLUMN gruppo')
        ..execute('ALTER TABLE portafogli DROP COLUMN preferito')
        ..execute('DROP TABLE report')
        ..execute('DROP TABLE versamenti')
        ..execute('DROP TABLE partecipanti')
        ..execute('DROP TABLE obiettivi')
        ..execute('DROP TABLE prestiti')
        ..execute('DROP TABLE carte_credito')
        ..execute(
          "DELETE FROM definizioni_tipo WHERE nome = 'Carta di credito'",
        )
        ..execute('DROP INDEX movimenti_pianificati_unici')
        ..execute('ALTER TABLE movimenti DROP COLUMN pianificazione_id')
        ..execute('ALTER TABLE movimenti DROP COLUMN data_prevista')
        ..execute('DROP TABLE pianificazioni')
        ..execute('DROP TABLE variazioni_mese')
        ..execute('DROP TABLE importi_voce')
        ..execute('DROP TABLE voci_costo')
        ..execute('DELETE FROM categorie')
        ..userVersion = 1;

      // 2) Riapre con l'app attuale: parte la migrazione.
      final db = Archivio.conEsecutore(NativeDatabase.opened(grezzo));
      addTearDown(db.close);

      final portafogli = await db.select(db.portafogli).get();
      expect(portafogli.single.nome, 'I miei contanti');
      expect(portafogli.single.saldoInizialeMinimo, 4200);
      expect(await db.select(db.vociCosto).get(), isEmpty);
      final categorie = await db.select(db.categorie).get();
      expect(
        categorie.map((c) => c.nome),
        containsAll(['Casa', 'Bollette', 'Spesa']),
      );
      expect(await db.select(db.pianificazioni).get(), isEmpty);
      expect(await db.select(db.carteCredito).get(), isEmpty);
      expect(
        (await db.select(db.definizioniTipo).get()).map((t) => t.nome),
        contains('Carta di credito'),
      );
      expect(await db.select(db.prestiti).get(), isEmpty);
      expect(categorie.map((c) => c.nome), contains('Finanziamenti'));
      expect(await db.select(db.obiettivi).get(), isEmpty);
      expect(portafogli.single.preferito, isFalse);
      expect(portafogli.single.gruppo, isNull);
      expect(grezzo.userVersion, 11);
    },
  );

  test(
    'migrazione v7 → v11: spese ripartite, maxi rata, entrate previste, report',
    () async {
      final grezzo = sql.sqlite3.openInMemory();
      final v8 = Archivio.conEsecutore(
        NativeDatabase.opened(grezzo, closeUnderlyingOnClose: false),
      );
      await v8
          .into(v8.vociCosto)
          .insert(
            VociCostoCompanion.insert(
              id: nuovoId(),
              aggiornatoIl: '1',
              nome: 'Assicurazione auto',
              tipo: 'fissa',
            ),
          );
      await v8.close();
      grezzo
        ..execute('ALTER TABLE voci_costo DROP COLUMN ripartita')
        ..execute('ALTER TABLE voci_costo DROP COLUMN natura')
        ..execute('DROP TABLE report')
        ..execute('ALTER TABLE prestiti DROP COLUMN maxi_rata_minimo')
        ..execute('ALTER TABLE prestiti DROP COLUMN spese_rata_minimo')
        ..execute('ALTER TABLE prestiti DROP COLUMN decisione_maxi')
        ..execute('ALTER TABLE prestiti DROP COLUMN maxi_rimandata_il')
        ..userVersion = 7;

      final db = Archivio.conEsecutore(NativeDatabase.opened(grezzo));
      addTearDown(db.close);
      final voce = (await db.select(db.vociCosto).get()).single;
      expect(voce.nome, 'Assicurazione auto');
      expect(voce.ripartita, isFalse);
      expect(voce.natura, NaturaVoce.spesa); // le voci esistenti sono spese
      expect(await db.select(db.report).get(), isEmpty);
      expect(await db.select(db.prestiti).get(), isEmpty);
      expect(grezzo.userVersion, 11);
    },
  );
}
