import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/crypto/derivazione.dart';
import 'package:gestionale_finanziaria/core/crypto/keyring.dart';
import 'package:gestionale_finanziaria/core/crypto/secret_key.dart';
import 'package:gestionale_finanziaria/core/db/archivio.dart';
import 'package:gestionale_finanziaria/core/db/contabilita.dart';
import 'package:gestionale_finanziaria/core/db/pianificatore.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';
import 'package:gestionale_finanziaria/core/ricorrenza.dart';
import 'package:gestionale_finanziaria/core/sync/backend_memoria.dart';
import 'package:gestionale_finanziaria/core/sync/righe.dart';
import 'package:gestionale_finanziaria/core/sync/sincronizzatore.dart';
import 'package:sodium/sodium_sumo.dart';

/// Un "dispositivo" in memoria: il suo archivio, il suo keyring e il
/// sincronizzatore verso lo spazio remoto condiviso.
class _Dispositivo {
  _Dispositivo._(this.db, this.contabilita, this.sync, this.keyring);

  static Future<_Dispositivo> nuovo(
    SodiumSumo sodium,
    SecureKey dek,
    Uint8List keyring,
    BackendInMemoria remoto,
  ) async {
    final db = Archivio.inMemoria();
    final contabilita = await Contabilita.apri(db);
    late _Dispositivo d;
    final sync = Sincronizzatore(
      db: db,
      orologio: contabilita.orologio,
      sodium: sodium,
      dek: dek,
      idArchivio: Keyring.deserializza(keyring).idArchivio,
      backend: remoto,
      leggiKeyring: () async => d.keyring,
      scriviKeyring: (nuovo) async => d.keyring = nuovo,
    );
    return d = _Dispositivo._(db, contabilita, sync, keyring);
  }

  final Archivio db;
  final Contabilita contabilita;
  final Sincronizzatore sync;
  Uint8List keyring;

  Future<List<Movimento>> movimenti() =>
      (db.select(db.movimenti)
            ..where((m) => m.eliminato.equals(false))
            ..orderBy([(m) => OrderingTerm(expression: m.descrizione)]))
          .get();

  Future<String> tipo(String nome) async => (await (db.select(
    db.definizioniTipo,
  )..where((t) => t.nome.equals(nome))).getSingle()).id;

  Future<void> chiudi() async {
    sync.chiudi();
    await db.close();
  }
}

void main() {
  late SodiumSumo sodium;
  late BackendInMemoria remoto;
  late ({Keyring keyring, SecureKey dek, SecretKey secretKey}) archivio;
  final dispositivi = <_Dispositivo>[];

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() {
    remoto = BackendInMemoria();
    archivio = Keyring.crea(
      sodium,
      'Password-Lunga-1',
      parametri: ParametriArgon2.nuovi(
        sodium,
        opsLimit: ParametriArgon2.opsMinimo,
        memLimit: ParametriArgon2.memMinima,
      ),
    );
  });

  tearDown(() async {
    for (final d in dispositivi) {
      await d.chiudi();
    }
    dispositivi.clear();
  });

  Future<_Dispositivo> dispositivo() async {
    final d = await _Dispositivo.nuovo(
      sodium,
      archivio.dek,
      archivio.keyring.serializza(),
      remoto,
    );
    dispositivi.add(d);
    return d;
  }

  Future<String> spesa(
    _Dispositivo d,
    String conto,
    String descrizione,
  ) async => d.contabilita.registraMovimento(
    tipoId: await d.tipo('Spesa'),
    portafoglioId: conto,
    importo: 1250,
    valuta: 'EUR',
    data: DateTime(2026, 10, 14),
    descrizione: descrizione,
  );

  Future<String> conto(_Dispositivo d) async => d.contabilita.creaPortafoglio(
    nome: 'Conto',
    tipoId: await d.tipo('Conto corrente'),
    valuta: 'EUR',
  );

  test('il primo carica, il secondo scarica tutto (senza doppioni)', () async {
    final pc = await dispositivo();
    final c = await conto(pc);
    await spesa(pc, c, 'Pizzeria');
    await pc.sync.sincronizza();

    final telefono = await dispositivo();
    expect(await telefono.sync.scaricaTutto(), greaterThan(0));
    expect((await telefono.movimenti()).single.descrizione, 'Pizzeria');
    // I tipi e le categorie iniziali del telefono non si sommano a quelli del PC.
    expect(
      (await telefono.db.select(telefono.db.definizioniTipo).get()).length,
      (await pc.db.select(pc.db.definizioniTipo).get()).length,
    );
    expect(
      (await telefono.db.select(telefono.db.categorie).get()).length,
      (await pc.db.select(pc.db.categorie).get()).length,
    );
    final saldi = await telefono.contabilita.osservaPortafogli().first;
    expect(saldi.single.saldo, -1250);
  });

  test(
    'modifiche nei due sensi; sulla stessa riga vince la più recente',
    () async {
      final pc = await dispositivo();
      final c = await conto(pc);
      final id = await spesa(pc, c, 'Spesa');
      await pc.sync.sincronizza();
      final telefono = await dispositivo();
      await telefono.sync.scaricaTutto();

      await spesa(telefono, c, 'Dal telefono');
      Future<void> rinomina(_Dispositivo d, String testo) async {
        final m = (await (d.db.select(
          d.db.movimenti,
        )..where((x) => x.id.equals(id))).getSingle());
        await d.contabilita.modificaMovimento(
          id,
          tipoId: m.tipoId,
          portafoglioId: m.portafoglioId,
          importo: m.importoMinimo,
          valuta: m.valuta,
          data: Contabilita.daGiorno(m.data),
          descrizione: testo,
        );
      }

      await rinomina(pc, 'Dal PC');
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await rinomina(telefono, 'Dal telefono, dopo'); // più recente

      for (final d in [pc, telefono, pc]) {
        await d.sync.sincronizza();
      }
      for (final d in [pc, telefono]) {
        expect(
          [for (final m in await d.movimenti()) m.descrizione],
          ['Dal telefono', 'Dal telefono, dopo'],
        );
      }
    },
  );

  test('le cancellazioni arrivano agli altri', () async {
    final pc = await dispositivo();
    final c = await conto(pc);
    final id = await spesa(pc, c, 'Da togliere');
    await pc.sync.sincronizza();
    final telefono = await dispositivo();
    await telefono.sync.scaricaTutto();

    await telefono.contabilita.eliminaMovimento(id);
    await telefono.sync.sincronizza();
    await pc.sync.sincronizza();
    expect(await pc.movimenti(), isEmpty);
  });

  test(
    'istantanea: via i pacchetti vecchi, un dispositivo nuovo parte da lì',
    () async {
      final pc = await dispositivo();
      final c = await conto(pc);
      await pc.sync.sincronizza();
      for (var i = 0; i < Sincronizzatore.pacchettiPerIstantanea + 2; i++) {
        await spesa(pc, c, 'Spesa ${i.toString().padLeft(2, '0')}');
        await pc.sync.sincronizza();
      }
      final file = await remoto.elenca();
      final pacchetti = file.where((f) => f.proprieta['tipo'] == 'eventi');
      expect(
        pacchetti.length,
        lessThan(Sincronizzatore.pacchettiPerIstantanea),
      );
      expect(
        file.where((f) => f.proprieta['tipo'] == 'istantanea'),
        hasLength(1),
      );

      final tablet = await dispositivo();
      await tablet.sync.scaricaTutto();
      expect(
        await tablet.movimenti(),
        hasLength(Sincronizzatore.pacchettiPerIstantanea + 2),
      );
    },
  );

  test('su Drive c\'è un altro archivio: non si mescolano', () async {
    final pc = await dispositivo();
    await pc.sync.sincronizza();
    final altro = Keyring.crea(
      sodium,
      'Altra-Password-2',
      parametri: ParametriArgon2.nuovi(
        sodium,
        opsLimit: ParametriArgon2.opsMinimo,
        memLimit: ParametriArgon2.memMinima,
      ),
    );
    final estraneo = await _Dispositivo.nuovo(
      sodium,
      altro.dek,
      altro.keyring.serializza(),
      remoto,
    );
    dispositivi.add(estraneo);
    expect(estraneo.sync.sincronizza, throwsA(isA<ArchivioRemotoDiverso>()));

    // Messo da parte quello su Drive (rinominato, non cancellato), si carica questo.
    await Sincronizzatore.metteDaParteRemoto(remoto);
    await estraneo.sync.sincronizza();
    expect(
      await Sincronizzatore.idArchivioRemoto(remoto),
      altro.keyring.idArchivio,
    );
    expect(
      (await remoto.elenca()).where((f) => f.nome.startsWith('vecchio-')),
      isNotEmpty,
    );
  });

  test('nuova password su un dispositivo: arriva anche sugli altri', () async {
    final pc = await dispositivo();
    await pc.sync.sincronizza();
    final telefono = await dispositivo();
    await telefono.sync.scaricaTutto();

    pc.keyring = archivio.keyring
        .conNuovaPassword(
          sodium,
          archivio.dek,
          'Nuova-Password-3',
          parametri: ParametriArgon2.nuovi(
            sodium,
            opsLimit: ParametriArgon2.opsMinimo,
            memLimit: ParametriArgon2.memMinima,
          ),
        )
        .serializza();
    await pc.sync.sincronizza();
    await telefono.sync.sincronizza();
    expect(telefono.keyring, pc.keyring);
    Keyring.deserializza(telefono.keyring)
        .apriConPassword(sodium, 'Nuova-Password-3')
        .dispose();
  });

  test(
    'stessa scadenza registrata da due dispositivi: una sola spesa',
    () async {
      final pc = await dispositivo();
      final c = await conto(pc);
      final oggi = DateTime(2026, 10, 14, 9);
      final piano = Pianificatore(
        pc.db,
        pc.contabilita.orologio,
        adesso: () => oggi,
      );
      await piano.salva(
        DatiPianificazione(
          origine: OriginePianificazione.costoVita,
          origineId: 'affitto',
          ricorrenza: Ricorrenza(inizio: DateTime(2026, 10, 14)),
          portafoglioId: c,
          descrizione: 'Affitto',
          importo: 70000,
        ),
      );
      await pc.sync.sincronizza();
      final telefono = await dispositivo();
      await telefono.sync.scaricaTutto();

      // Tutti e due registrano l'affitto di oggi, prima di sincronizzarsi.
      expect(await piano.registraScadute(), 1);
      expect(
        await Pianificatore(
          telefono.db,
          telefono.contabilita.orologio,
          adesso: () => oggi,
        ).registraScadute(),
        1,
      );
      for (final d in [pc, telefono, pc]) {
        await d.sync.sincronizza();
      }
      for (final d in [pc, telefono]) {
        expect(await d.movimenti(), hasLength(1));
      }
    },
  );

  test('su Drive solo dati cifrati', () async {
    final pc = await dispositivo();
    final c = await conto(pc);
    await spesa(pc, c, 'Farmacia Centrale');
    await pc.sync.sincronizza();
    for (final f in await remoto.elenca()) {
      if (f.nome == 'keyring.bin') {
        continue;
      }
      final testo = latin1.decode(await remoto.scarica(f.id));
      expect(testo, isNot(contains('Farmacia')));
      expect(testo, isNot(contains('Conto')));
    }
  });

  test(
    'tutte le tabelle con le colonne di sincronizzazione viaggiano',
    () async {
      final pc = await dispositivo();
      for (final t in pc.db.allTables) {
        final nomi = t.$columns.map((c) => c.name).toSet();
        final sincronizzata =
            nomi.containsAll(['id', 'aggiornato_il', 'eliminato']) &&
            !RigheSincronizzate.locali.contains(t.actualTableName);
        expect(
          RigheSincronizzate.tabelle.contains(t.actualTableName),
          sincronizzata,
          reason: t.actualTableName,
        );
      }
    },
  );
}
