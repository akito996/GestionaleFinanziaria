import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/condivisi/identita_persona.dart';
import 'package:gestionale_finanziaria/core/condivisi/portafogli_condivisi.dart';
import 'package:gestionale_finanziaria/core/db/archivio.dart';
import 'package:gestionale_finanziaria/core/db/contabilita.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';
import 'package:sodium/sodium_sumo.dart';

import '../drive_finto.dart';

/// Una persona con il suo archivio, sul Drive finto condiviso.
class _Persona {
  _Persona(this.db, this.c, this.accesso, this.condivisi);

  final Archivio db;
  final Contabilita c;
  final AccessoFinto accesso;
  final PortafogliCondivisiServizio condivisi;

  Future<Movimento> movimento(String id) =>
      (db.select(db.movimenti)..where((m) => m.id.equals(id))).getSingle();

  Future<String> tipoSpesa() async =>
      (await c.tipi(AmbitoTipo.movimento))
          .firstWhere((t) => t.effetto == EffettoSaldo.uscita)
          .id;

  Future<void> cambiaImporto(String id, int importo, {String? nota}) async {
    final m = await movimento(id);
    await c.modificaMovimento(
      id,
      tipoId: m.tipoId,
      portafoglioId: m.portafoglioId,
      categoriaId: m.categoriaId,
      importo: importo,
      valuta: m.valuta,
      data: DateTime.parse(m.data),
      descrizione: nota ?? m.descrizione,
    );
  }
}

void main() {
  late SodiumSumo sodium;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    // Due archivi nello stesso test: proprietario e membro.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  Future<_Persona> persona(DriveFinto drive, String utente, int seme) async {
    final db = Archivio.inMemoria();
    addTearDown(db.close);
    final c = await Contabilita.apri(db);
    final io = IdentitaPersona.daChiaveDati(
      sodium,
      SecureKey.fromList(sodium, Uint8List.fromList(List.filled(32, seme))),
    );
    final accesso = AccessoFinto(drive, utente);
    return _Persona(
      db,
      c,
      accesso,
      PortafogliCondivisiServizio(
        db: db,
        contabilita: c,
        sodium: sodium,
        identita: () => io,
        accesso: accesso,
      ),
    );
  }

  /// Il proprietario con il portafoglio "Casa" (1.000 €) e una spesa.
  Future<({_Persona prop, String w, String pane})> conPortafoglio(
    DriveFinto drive,
  ) async {
    final prop = await persona(drive, 'prop', 1);
    final tipi = {
      for (final t in await prop.c.tipi(AmbitoTipo.portafoglio)) t.nome: t.id,
    };
    final w = await prop.c.creaPortafoglio(
      nome: 'Casa',
      tipoId: tipi['Conto corrente']!,
      valuta: 'EUR',
      saldoIniziale: 100000,
    );
    final albero = AlberoCategorie(
      await prop.db.select(prop.db.categorie).get(),
    );
    final spesa = albero.perId.values.firstWhere(
      (c) => albero.percorso(c.id) == 'Alimentari › Spesa',
    );
    final pane = await prop.c.registraMovimento(
      tipoId: await prop.tipoSpesa(),
      portafoglioId: w,
      categoriaId: spesa.id,
      importo: 1250,
      valuta: 'EUR',
      data: DateTime(2026, 10, 16),
      descrizione: 'Pane',
    );
    return (prop: prop, w: w, pane: pane);
  }

  test('invito, ingresso e movimenti nei due sensi, con i permessi', () async {
    final drive = DriveFinto();
    final (:prop, :w, :pane) = await conPortafoglio(drive);
    final memb = await persona(drive, 'memb', 2);

    // Invito: una volta sola per persona; non a sé stessi.
    expect(
      await prop.condivisi.invita(w, 'Memb@Example.com'),
      EsitoInvito.invitato,
    );
    expect(
      await prop.condivisi.invita(w, 'memb@example.com'),
      EsitoInvito.giaPresente,
    );
    expect(
      await prop.condivisi.invita(w, 'prop@example.com'),
      EsitoInvito.seiTu,
    );
    expect(drive.condivisioni.single.email, 'memb@example.com');
    expect(drive.condivisioni.single.messaggio, contains('Unisciti'));
    final cartella = drive
        .conNome(PortafogliCondivisiServizio.nomeCartella('Casa', w))
        .single;
    expect(drive.elementi[cartella]!.padre, drive.conNome('WalleCy').single);

    // Il membro sceglie tutti i file della cartella: aspetta la chiave.
    memb.accesso.sceglie = (e) => e.padre == cartella;
    expect(await memb.condivisi.unisciti(), EsitoIngresso.inAttesa);
    expect(
      await (memb.db.select(
        memb.db.portafogli,
      )..where((p) => p.id.equals(w))).getSingleOrNull(),
      isNull,
    );

    // Il proprietario consegna la chiave; il membro riceve tutto.
    await prop.condivisi.sincronizza();
    await memb.condivisi.sincronizza();
    final suo = await (memb.db.select(
      memb.db.portafogli,
    )..where((p) => p.id.equals(w))).getSingle();
    expect(suo.nome, 'Casa');
    expect(suo.saldoInizialeMinimo, 100000);
    final arrivato = await memb.movimento(pane);
    expect(arrivato.importoMinimo, 1250);
    expect(arrivato.descrizione, 'Pane');
    expect(
      AlberoCategorie(await memb.db.select(memb.db.categorie).get())
          .percorso(arrivato.categoriaId!),
      'Alimentari › Spesa',
    );
    final persone = await prop.condivisi.membri(w);
    final idProp = persone
        .firstWhere((m) => m.ruolo == RuoloMembro.proprietario)
        .id;
    final idMemb = persone.firstWhere((m) => m.ruolo == RuoloMembro.membro).id;
    expect(arrivato.inseritoDa, idProp);
    expect(persone.firstWhere((m) => m.id == idMemb).stato, StatoMembro.attivo);

    // Il membro aggiunge una spesa: arriva al proprietario, con l'autore.
    final farmacia = await memb.c.registraMovimento(
      tipoId: await memb.tipoSpesa(),
      portafoglioId: w,
      importo: 3000,
      valuta: 'EUR',
      data: DateTime(2026, 10, 17),
      descrizione: 'Farmacia',
    );
    await memb.condivisi.sincronizza();
    await prop.condivisi.sincronizza();
    final daMembro = await prop.movimento(farmacia);
    expect(daMembro.importoMinimo, 3000);
    expect(daMembro.inseritoDa, idMemb);

    // Il membro non può cambiare la spesa del proprietario...
    await memb.cambiaImporto(pane, 1);
    await memb.condivisi.sincronizza();
    await prop.condivisi.sincronizza();
    expect((await prop.movimento(pane)).importoMinimo, 1250);

    // ...il proprietario può cambiare quella del membro.
    await prop.cambiaImporto(farmacia, 3500, nota: 'Farmacia e ricetta');
    await prop.condivisi.sincronizza();
    await memb.condivisi.sincronizza();
    final cambiata = await memb.movimento(farmacia);
    expect(cambiata.importoMinimo, 3500);
    expect(cambiata.descrizione, 'Farmacia e ricetta');
    expect(cambiata.inseritoDa, idMemb);
    expect(cambiata.modificatoDa, idProp);

    // Il codice di sicurezza è lo stesso sui due schermi.
    final perProp = prop.condivisi.codiceSicurezza(
      (await prop.condivisi.membri(w)).firstWhere((m) => m.id == idMemb),
    );
    final perMemb = memb.condivisi.codiceSicurezza(
      (await memb.condivisi.membri(w)).firstWhere((m) => m.id == idProp),
    );
    expect(perProp, isNotNull);
    expect(perProp, perMemb);
  });

  test('ingresso: file mancanti, non invitato, scelta annullata', () async {
    final drive = DriveFinto();
    final (:prop, :w, pane: _) = await conPortafoglio(drive);
    await prop.condivisi.invita(w, 'memb@example.com');
    final memb = await persona(drive, 'memb', 2);
    final altro = await persona(drive, 'altro', 3);

    // Solo il registro: manca il proprio file.
    memb.accesso.sceglie = (e) =>
        e.nome == PortafogliCondivisiServizio.nomeRegistro;
    expect(await memb.condivisi.unisciti(), EsitoIngresso.fileMancanti);

    // Un account che non è stato invitato.
    altro.accesso.sceglie = (e) => e.nome.startsWith('wallecy_');
    expect(await altro.condivisi.unisciti(), EsitoIngresso.nonInvitato);

    // Nessuna scelta.
    memb.accesso.sceglie = (_) => false;
    expect(await memb.condivisi.unisciti(), EsitoIngresso.annullato);
  });

  test('senza consenso in sottofondo non si chiede niente', () async {
    final drive = DriveFinto();
    final (:prop, :w, pane: _) = await conPortafoglio(drive);
    await prop.condivisi.invita(w, 'memb@example.com');
    prop.accesso.consenso = false;
    final prima = drive.richieste;
    await prop.condivisi.sincronizza();
    expect(drive.richieste, prima);
  });

  test('JSON canonico: le chiavi in ordine, a ogni livello', () {
    expect(
      canonico({
        'b': 1,
        'a': [
          {'z': null, 'y': 'x'},
        ],
      }),
      '{"a":[{"y":"x","z":null}],"b":1}',
    );
  });
}
