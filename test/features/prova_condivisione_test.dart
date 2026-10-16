import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/condivisi/accesso_drive_file.dart';
import 'package:gestionale_finanziaria/core/condivisi/drive_condiviso.dart';
import 'package:gestionale_finanziaria/features/condivisi/prova_condivisione_pagina.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _tipoCartella = 'application/vnd.google-apps.folder';

class _Elemento {
  _Elemento(
    this.nome,
    this.padre,
    this.proprietario, {
    this.cartella = false,
    this.testo = '',
  });

  final String nome;
  String padre;
  final String proprietario;
  final bool cartella;
  String testo;
}

/// Un Drive finto in memoria, condiviso da più account.
///
/// Con [aperto] scegliere una cartella dà accesso anche ai file che contiene;
/// senza, come `drive.file` alla lettera, l'app vede solo ciò che ha creato
/// o che l'utente ha scelto (e non può scrivere in cartelle che non vede).
class _DriveFinto {
  _DriveFinto({this.aperto = true});

  final bool aperto;
  final elementi = <String, _Elemento>{};
  final accessi = <String, Set<String>>{};
  final condivisioni = <({String id, String email, String? messaggio})>[];
  var _n = 0;

  String radice(String utente) => 'root:$utente';

  bool vede(String utente, String id) {
    final mie = accessi[utente] ?? const <String>{};
    if (mie.contains(id)) {
      return true;
    }
    final padre = elementi[id]?.padre;
    return aperto && padre != null && mie.contains(padre);
  }

  void concedi(String utente, String id) => (accessi[utente] ??= {}).add(id);

  String crea(String utente, _Elemento e) {
    final id = 'f${_n++}';
    elementi[id] = e;
    concedi(utente, id);
    return id;
  }

  Iterable<String> conNome(String nome) => [
    for (final e in elementi.entries)
      if (e.value.nome == nome) e.key,
  ];

  static http.Response _ok([Object? json]) =>
      http.Response(jsonEncode(json ?? {}), 200);
  static http.Response get _manca => http.Response('File not found', 404);

  http.Client client(String utente) => MockClient((r) async {
    final percorso = r.url.path;
    final q = r.url.queryParameters;
    final id = percorso.split('/').last;
    switch (r.method) {
      case 'POST' when percorso == '/drive/v3/files':
        final dati = jsonDecode(r.body) as Map<String, Object?>;
        final padre = (dati['parents'] as List<Object?>?)?.first as String?;
        if (padre != null && !vede(utente, padre)) {
          return _manca;
        }
        final nuovo = _Elemento(
          dati['name']! as String,
          padre ?? radice(utente),
          utente,
          cartella: dati['mimeType'] == _tipoCartella,
        );
        return _ok({'id': crea(utente, nuovo)});
      case 'POST' when percorso.endsWith('/permissions'):
        condivisioni.add((
          id: percorso.split('/')[4],
          email: (jsonDecode(r.body) as Map)['emailAddress'] as String,
          messaggio: q['emailMessage'],
        ));
        return _ok();
      case 'POST' when percorso == '/upload/drive/v3/files':
        final parti = r.body.split('\r\n\r\n');
        final meta =
            jsonDecode(parti[1].split('\r\n').first) as Map<String, Object?>;
        final padre = (meta['parents']! as List).first as String;
        if (!vede(utente, padre)) {
          return _manca;
        }
        if (elementi[padre]?.cartella != true) {
          return http.Response('The specified parent is not a folder.', 403);
        }
        final nuovo = _Elemento(
          meta['name']! as String,
          padre,
          utente,
          testo: parti[2].split('\r\n--').first,
        );
        return _ok({'id': crea(utente, nuovo)});
      case 'PATCH' when !vede(utente, id):
        return _manca;
      case 'PATCH' when percorso.startsWith('/upload/'):
        elementi[id]!.testo = r.body;
        return _ok();
      case 'PATCH':
        elementi[id]!.padre = q['addParents']!;
        return _ok();
      case 'GET' when percorso == '/drive/v3/files':
        final filtro = q['q']!;
        final nome = RegExp(r"name = '([^']+)'").firstMatch(filtro)?.group(1);
        var padre = RegExp(r"'([^']+)' in parents")
            .firstMatch(filtro)
            ?.group(1);
        if (padre == 'root') {
          padre = radice(utente);
        }
        final soloCartelle = filtro.contains("mimeType = '$_tipoCartella'");
        return _ok({
          'files': [
            for (final e in elementi.entries)
              if (vede(utente, e.key) &&
                  (nome == null || e.value.nome == nome) &&
                  (padre == null || e.value.padre == padre) &&
                  (!soloCartelle || e.value.cartella))
                {
                  'id': e.key,
                  'name': e.value.nome,
                  'parents': [e.value.padre],
                  'owners': [
                    {'displayName': e.value.proprietario},
                  ],
                },
          ],
        });
      case 'GET' when !vede(utente, id):
        return _manca;
      case 'GET' when q['alt'] == 'media':
        return http.Response.bytes(utf8.encode(elementi[id]!.testo), 200);
      case 'GET':
        final e = elementi[id]!;
        return _ok({
          'name': e.nome,
          'mimeType': e.cartella ? _tipoCartella : 'text/plain',
          'parents': [e.padre],
          'owners': [
            {'emailAddress': '${e.proprietario}@example.com'},
          ],
        });
    }
    return http.Response('non previsto', 404);
  });
}

/// La finestra di Google finta: l'utente sceglie gli elementi che
/// soddisfano [sceglie], oppure tutti quelli mostrati con `soloId`.
class _AccessoFinto implements AccessoDriveFile {
  _AccessoFinto(this.drive, this.utente, {this.sceglie});

  final _DriveFinto drive;
  final String utente;
  final bool Function(_Elemento e)? sceglie;
  final richiesteSoloId = <List<String>>[];

  @override
  Future<http.Client?> client() async => drive.client(utente);

  @override
  Future<ElementiScelti> scegli({List<String> soloId = const []}) async {
    richiesteSoloId.add(soloId);
    final scelti = soloId.isNotEmpty
        ? soloId
        : [
            for (final e in drive.elementi.entries)
              if (sceglie?.call(e.value) ?? false) e.key,
          ];
    for (final id in scelti) {
      drive.concedi(utente, id);
    }
    return (client: drive.client(utente), scelti: scelti);
  }
}

void main() {
  test('DriveCondiviso: tutto dentro «WalleCy», niente doppioni', () async {
    final drive = _DriveFinto();
    final d = DriveCondiviso(drive.client('prop'));
    // Una cartella della versione precedente, nella radice del Drive.
    final vecchia = await d.creaCartella('wallecy_share_GF-A');

    final prima = await d.cartellaDentroWalleCy('wallecy_share_GF-A');
    expect(prima, (id: vecchia, origine: Origine.spostata));
    final walleCy = drive.conNome('WalleCy').single;
    expect(drive.elementi[walleCy]!.padre, drive.radice('prop'));
    expect(drive.elementi[vecchia]!.padre, walleCy);

    final seconda = await d.cartellaDentroWalleCy('wallecy_share_GF-A');
    expect(seconda, (id: vecchia, origine: Origine.trovata));
    final nuova = await d.cartellaDentroWalleCy('wallecy_share_GF-B');
    expect(nuova.origine, Origine.creata);
    expect(drive.conNome('WalleCy'), hasLength(1));

    final file = await d.scrivi(vecchia, 'a.txt', 'ciao');
    expect(await d.scrivi(vecchia, 'a.txt', 'ciao di nuovo'), file);
    expect((await d.elenca(vecchia)).map((f) => f.nome), ['a.txt']);
    expect(await d.leggi(file), 'ciao di nuovo');

    await d.condividi(vecchia, 'membro@example.com', messaggio: 'Benvenuto');
    expect(drive.condivisioni.single.messaggio, 'Benvenuto');
    final info = await d.info(file);
    expect(info.cartella, isFalse);
    expect(info.padri, [vecchia]);
    expect(info.emailProprietario, 'prop@example.com');
  });

  Future<void> tocca(WidgetTester tester, Finder cosa) async {
    await tester.ensureVisible(cosa);
    await tester.tap(cosa);
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
  }

  /// Proprietario e membro uno accanto all'altro, sullo stesso Drive finto.
  Future<_AccessoFinto> dueDispositivi(
    WidgetTester tester,
    _DriveFinto drive, {
    required bool Function(_Elemento e) sceltaMembro,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1800, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final proprietario = _AccessoFinto(drive, 'prop');
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            Expanded(
              child: ProvaCondivisionePagina(
                key: const Key('proprietario'),
                codice: 'GF-PROP',
                accesso: proprietario,
              ),
            ),
            Expanded(
              child: ProvaCondivisionePagina(
                key: const Key('membro'),
                codice: 'GF-MEMB',
                accesso: _AccessoFinto(drive, 'memb', sceglie: sceltaMembro),
              ),
            ),
          ],
        ),
      ),
    );
    return proprietario;
  }

  Finder su(String chi, Finder cosa) =>
      find.descendant(of: find.byKey(Key(chi)), matching: cosa);

  Future<void> creaECondividi(WidgetTester tester) async {
    await tester.enterText(
      su('proprietario', find.byType(TextField)),
      'memb@example.com',
    );
    await tocca(
      tester,
      su('proprietario', find.text('Crea la cartella e condividila')),
    );
  }

  testWidgets('laboratorio: il membro sceglie la cartella e ci scrive', (
    tester,
  ) async {
    final drive = _DriveFinto();
    await dueDispositivi(
      tester,
      drive,
      sceltaMembro: (e) => e.nome == 'wallecy_share_GF-PROP',
    );

    await creaECondividi(tester);
    expect(
      su(
        'proprietario',
        find.textContaining('"WalleCy/wallecy_share_GF-PROP" creata'),
      ),
      findsOneWidget,
    );
    expect(drive.condivisioni.single.email, 'memb@example.com');
    expect(drive.condivisioni.single.messaggio, contains('Laboratorio'));

    await tocca(
      tester,
      su('membro', find.text('Scegli la cartella o il file condiviso')),
    );
    expect(
      su(
        'membro',
        find.text('Hai scelto la cartella "wallecy_share_GF-PROP".'),
      ),
      findsOneWidget,
    );
    expect(
      su('membro', find.textContaining('Letto: Ciao dal proprietario GF-PROP')),
      findsOneWidget,
    );
    expect(
      su('membro', find.textContaining('scritto nella cartella condivisa')),
      findsOneWidget,
    );

    await tocca(
      tester,
      su('proprietario', find.text('3 · Controlla il file del membro')),
    );
    expect(
      su('proprietario', find.text('Vedo il file del membro nella cartella.')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('laboratorio: drive.file alla lettera, il membro sceglie il '
      'file e il proprietario lo apre dalla segnalazione', (tester) async {
    final drive = _DriveFinto(aperto: false);
    final proprietario = await dueDispositivi(
      tester,
      drive,
      sceltaMembro: (e) => e.nome == 'wallecy_GF-PROP.txt',
    );

    await creaECondividi(tester);
    await tocca(
      tester,
      su('membro', find.text('Scegli la cartella o il file condiviso')),
    );
    expect(
      su('membro', find.text('Hai scelto il file "wallecy_GF-PROP.txt".')),
      findsOneWidget,
    );
    expect(
      su('membro', find.textContaining('Letto: Ciao dal proprietario GF-PROP')),
      findsOneWidget,
    );
    expect(
      su('membro', find.textContaining('Non posso scrivere nella cartella')),
      findsOneWidget,
    );
    expect(
      su('membro', find.textContaining('condiviso con prop@example.com')),
      findsOneWidget,
    );
    expect(
      su(
        'membro',
        find.text('Segnalato il tuo file nel file del proprietario.'),
      ),
      findsOneWidget,
    );
    final fileMembro = drive.conNome('wallecy_GF-MEMB.txt').single;
    expect(drive.elementi[fileMembro]!.padre, drive.conNome('WalleCy').last);

    // Il proprietario ripete il passo 1: la segnalazione resta.
    await tocca(
      tester,
      su('proprietario', find.text('Crea la cartella e condividila')),
    );
    expect(
      su('proprietario', find.textContaining('già presente: la riuso')),
      findsOneWidget,
    );
    expect(drive.conNome('wallecy_share_GF-PROP'), hasLength(1));

    await tocca(
      tester,
      su('proprietario', find.text('3 · Controlla il file del membro')),
    );
    expect(
      su('proprietario', find.textContaining('ha segnalato il suo file')),
      findsOneWidget,
    );

    await tocca(
      tester,
      su('proprietario', find.text('4 · Apri il file del membro')),
    );
    expect(proprietario.richiesteSoloId.last, [fileMembro]);
    expect(
      su(
        'proprietario',
        find.textContaining('Letto "wallecy_GF-MEMB.txt": Ciao dal membro'),
      ),
      findsOneWidget,
    );
  });
}
