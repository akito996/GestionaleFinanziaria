import 'dart:async';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/condivisi/drive_condiviso.dart';
import 'package:gestionale_finanziaria/core/condivisi/identita_persona.dart';
import 'package:gestionale_finanziaria/core/condivisi/invito.dart';
import 'package:gestionale_finanziaria/core/condivisi/portafogli_condivisi.dart';
import 'package:gestionale_finanziaria/core/db/archivio.dart';
import 'package:gestionale_finanziaria/core/db/contabilita.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

  Future<_Persona> persona(
    DriveFinto drive,
    String utente,
    int seme, {
    DateTime Function()? adesso,
  }) async {
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
        adesso: adesso,
      ),
    );
  }

  /// Il proprietario con il portafoglio "Casa" (1.000 €) e una spesa.
  Future<({_Persona prop, String w, String pane})> conPortafoglio(
    DriveFinto drive, {
    DateTime Function()? adesso,
  }) async {
    final prop = await persona(drive, 'prop', 1, adesso: adesso);
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
    // Ancora da confermare: l'invito si rimanda.
    expect(
      await prop.condivisi.invita(w, 'memb@example.com'),
      EsitoInvito.rimandato,
    );
    expect(
      await prop.condivisi.invita(w, 'prop@example.com'),
      EsitoInvito.seiTu,
    );
    expect(drive.condivisioni.map((c) => c.email), [
      'memb@example.com',
      'memb@example.com',
    ]);
    expect(drive.condivisioni.first.messaggio, contains('Unisciti'));
    // Nomi chiari: il file di ognuno porta il nome del suo account.
    expect(drive.conNome('wallecy_prop.json'), hasLength(1));
    expect(drive.conNome('wallecy_memb.json'), hasLength(1));
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
    // Entrata: ora è "già presente".
    expect(
      await prop.condivisi.invita(w, 'memb@example.com'),
      EsitoInvito.giaPresente,
    );

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

  test('invito interrotto: niente persona a metà, poi riesce', () async {
    final drive = DriveFinto();
    final (:prop, :w, pane: _) = await conPortafoglio(drive);
    drive.rifiutaCondivisione = true;
    await expectLater(
      prop.condivisi.invita(w, 'memb@example.com'),
      throwsA(isA<ErroreDriveCondiviso>()),
    );
    expect(
      (await prop.condivisi.membri(w))
          .where((m) => m.email == 'memb@example.com'),
      isEmpty,
    );
    expect(
      await prop.condivisi.invita(w, 'memb@example.com'),
      EsitoInvito.invitato,
    );
  });

  test('un\'ora per accettare: poi scade, avviso, si può reinvitare', () async {
    final drive = DriveFinto();
    var ora = DateTime.utc(2026, 10, 17, 12);
    final (:prop, :w, pane: _) = await conPortafoglio(drive, adesso: () => ora);
    final memb = await persona(drive, 'memb', 2, adesso: () => ora);
    final avvisi = <String>[];
    final ascolto = prop.condivisi.avvisi.listen(avvisi.add);
    addTearDown(ascolto.cancel);
    await prop.condivisi.invita(w, 'memb@example.com');
    final cartella = drive
        .conNome(PortafogliCondivisiServizio.nomeCartella('Casa', w))
        .single;
    Future<Membro> invitato() async =>
        (await prop.condivisi.membri(w))
            .firstWhere((m) => m.email == 'memb@example.com');

    // Entro l'ora: in attesa, con la scadenza.
    expect(
      prop.condivisi.scadenzaInvito(await invitato()),
      DateTime.utc(2026, 10, 17, 13),
    );
    ora = ora.add(const Duration(minutes: 59));
    await prop.condivisi.sincronizza();
    expect((await invitato()).stato, StatoMembro.invitato);

    // Dopo l'ora: scaduto, cartella non più condivisa, avviso.
    ora = ora.add(const Duration(minutes: 2));
    await prop.condivisi.sincronizza();
    await Future<void>.delayed(Duration.zero);
    expect((await invitato()).stato, StatoMembro.scaduto);
    expect(drive.permessi[cartella], isNot(contains('memb')));
    expect(avvisi.single, contains('nessuna risposta entro un\'ora'));
    memb.accesso.sceglie = (e) => e.padre == cartella;
    expect(await memb.condivisi.unisciti(), EsitoIngresso.scaduto);

    // Si reinvita: di nuovo un'ora. Il membro entra in tempo e resta dentro
    // anche se il proprietario si sincronizza più tardi.
    expect(
      await prop.condivisi.invita(w, 'memb@example.com'),
      EsitoInvito.rimandato,
    );
    expect((await invitato()).stato, StatoMembro.invitato);
    expect(drive.permessi[cartella], contains('memb'));
    expect(await memb.condivisi.unisciti(), EsitoIngresso.inAttesa);
    ora = ora.add(const Duration(hours: 3));
    await prop.condivisi.sincronizza();
    expect((await invitato()).stato, StatoMembro.attivo);
  });

  test('link d\'invito: nell\'email, nei Nuovi inviti, Accetta', () async {
    final drive = DriveFinto();
    final (:prop, :w, pane: _) = await conPortafoglio(drive);
    final memb = await persona(drive, 'memb', 2);
    await prop.condivisi.invita(w, 'memb@example.com');

    // Il link è nel messaggio dell'email di Google.
    final messaggio = drive.condivisioni.single.messaggio!;
    final link = RegExp(r'https://\S+').firstMatch(messaggio)!.group(0)!;
    final invito = InvitoCondiviso.daLink(link)!;
    expect(invito.portafoglio, 'Casa');
    expect(invito.da, 'prop@example.com');
    expect(invito.fileId, drive.conNome('wallecy_memb.json').single);
    expect(invito.scadenza, isNotNull);

    // Lo stesso link si copia dal portafoglio.
    final invitato = (await prop.condivisi.membri(w))
        .firstWhere((m) => m.email == 'memb@example.com');
    expect(
      (await prop.condivisi.invitoPer(w, invitato))!.registroId,
      invito.registroId,
    );

    // Il membro lo riceve: "Nuovi inviti".
    expect(await memb.condivisi.aggiungiInvito(invito), isTrue);
    expect(
      (await memb.condivisi.osservaInviti().first).single.portafoglio,
      'Casa',
    );

    // "Accetta": la finestra di Google prova a mostrare solo i file giusti.
    expect(
      await memb.condivisi.unisciti(invito: invito),
      EsitoIngresso.inAttesa,
    );
    expect(memb.accesso.richiesteSoloId.last, [
      invito.registroId,
      invito.fileId,
    ]);
    expect(await memb.condivisi.osservaInviti().first, isEmpty);

    // Già entrato: lo stesso invito non si aggiunge più.
    expect(await memb.condivisi.aggiungiInvito(invito), isFalse);
  });

  test('Google Drive che non risponde: errore dopo il tempo massimo', () async {
    final appesa = MockClient((_) => Completer<http.Response>().future);
    final drive = DriveCondiviso(
      appesa,
      attesa: const Duration(milliseconds: 50),
    );
    await expectLater(
      drive.info('x'),
      throwsA(isA<ErroreDriveCondiviso>().having((e) => e.stato, 'stato', 408)),
    );
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
