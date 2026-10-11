import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/db/archivio.dart';
import 'package:gestionale_finanziaria/core/db/contabilita.dart';
import 'package:gestionale_finanziaria/core/db/statistiche.dart';

void main() {
  // Regressione: cambiando la larghezza della finestra la scheda "Costo della
  // vita" restava in caricamento, perché il widget ricreato si iscriveva allo
  // stesso stream mentre il vecchio era ancora iscritto.
  test(
    'chi si iscrive mentre un altro è iscritto riceve subito i dati',
    () async {
      final db = Archivio.inMemoria();
      addTearDown(db.close);
      await Contabilita.apri(db);
      final stream = StatisticheServizio(db)
          .osservaSpesePerCategoria(DateTime(2026), DateTime(2026, 12, 31));

      final primo = Completer<void>();
      final iscrizione = stream.listen((_) {
        if (!primo.isCompleted) {
          primo.complete();
        }
      });
      addTearDown(iscrizione.cancel);
      await primo.future;

      final secondo = await stream.first.timeout(const Duration(seconds: 5));
      expect(secondo, isEmpty);
    },
  );
}
