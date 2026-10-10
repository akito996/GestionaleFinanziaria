import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/db/archivio.dart';
import 'package:gestionale_finanziaria/core/db/id.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

void main() {
  test(
    'migrazione v1 → v3: dati conservati, nuove tabelle e categorie',
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
      expect(grezzo.userVersion, 3);
    },
  );
}
