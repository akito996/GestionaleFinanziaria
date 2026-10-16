import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/condivisi/accesso_drive_file.dart';
import 'package:gestionale_finanziaria/core/condivisi/drive_condiviso.dart';
import 'package:gestionale_finanziaria/features/condivisi/prova_condivisione_pagina.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Un Drive finto in memoria, condiviso fra "proprietario" e "membro".
class _DriveFinto {
  final file =
      <String, ({String nome, String? padre, String testo, bool cartella})>{};
  final condivisioni = <String>[];
  var _n = 0;

  http.Client client() => MockClient((r) async {
    final percorso = r.url.path;
    if (r.method == 'POST' && percorso == '/drive/v3/files') {
      final dati = jsonDecode(r.body) as Map<String, Object?>;
      final id = 'f${_n++}';
      file[id] = (
        nome: dati['name']! as String,
        padre: null,
        testo: '',
        cartella: dati['mimeType'] == 'application/vnd.google-apps.folder',
      );
      return http.Response(jsonEncode({'id': id}), 200);
    }
    if (r.method == 'POST' && percorso.endsWith('/permissions')) {
      condivisioni.add((jsonDecode(r.body) as Map)['emailAddress'] as String);
      return http.Response('{}', 200);
    }
    if (r.method == 'POST' && percorso == '/upload/drive/v3/files') {
      final parti = r.body.split('\r\n\r\n');
      final meta =
          jsonDecode(parti[1].split('\r\n').first) as Map<String, Object?>;
      final padre = (meta['parents']! as List).first as String;
      if (file[padre]?.cartella != true) {
        return http.Response('The specified parent is not a folder.', 403);
      }
      final id = 'f${_n++}';
      file[id] = (
        nome: meta['name']! as String,
        padre: padre,
        testo: parti[2].split('\r\n--').first,
        cartella: false,
      );
      return http.Response(jsonEncode({'id': id}), 200);
    }
    if (r.method == 'GET' && percorso == '/drive/v3/files') {
      final padre = RegExp(r"'([^']+)' in parents")
          .firstMatch(r.url.queryParameters['q']!)!
          .group(1);
      return http.Response(
        jsonEncode({
          'files': [
            for (final e in file.entries.where((e) => e.value.padre == padre))
              {
                'id': e.key,
                'name': e.value.nome,
                'owners': [
                  {'displayName': 'Prova'},
                ],
              },
          ],
        }),
        200,
      );
    }
    if (r.method == 'GET' && percorso.startsWith('/drive/v3/files/')) {
      final f = file[percorso.split('/').last]!;
      if (r.url.queryParameters['alt'] == 'media') {
        return http.Response.bytes(utf8.encode(f.testo), 200);
      }
      return http.Response(
        jsonEncode({
          'name': f.nome,
          'mimeType': f.cartella
              ? 'application/vnd.google-apps.folder'
              : 'text/plain',
        }),
        200,
      );
    }
    return http.Response('non previsto', 404);
  });
}

class _AccessoFinto implements AccessoDriveFile {
  _AccessoFinto(this.drive, {this.sceltaSbagliata = false});

  final _DriveFinto drive;

  /// Il membro sceglie un file invece della cartella.
  final bool sceltaSbagliata;

  @override
  Future<http.Client?> client() async => drive.client();

  @override
  Future<CartellaScelta> scegliCartella() async => (
    client: drive.client(),
    scelti: [
      drive.file.entries
          .firstWhere(
            (e) => sceltaSbagliata ? !e.value.cartella : e.value.cartella,
          )
          .key,
    ],
  );
}

void main() {
  test('DriveCondiviso: crea, condividi, scrivi, elenca, leggi', () async {
    final drive = _DriveFinto();
    final d = DriveCondiviso(drive.client());
    final cartella = await d.creaCartella('wallecy_share_GF-A');
    await d.condividi(cartella, 'membro@example.com');
    await d.scrivi(cartella, 'a.txt', 'ciao');
    final elenco = await d.elenca(cartella);
    expect(elenco.map((f) => f.nome), ['a.txt']);
    expect(await d.leggi(elenco.single.id), 'ciao');
    expect((await d.info(cartella)).cartella, isTrue);
    expect((await d.info(elenco.single.id)).cartella, isFalse);
    expect(drive.condivisioni, ['membro@example.com']);
  });

  Future<void> tocca(WidgetTester tester, Finder cosa) async {
    await tester.ensureVisible(cosa);
    await tester.tap(cosa);
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
  }

  /// Proprietario e membro uno accanto all'altro, sullo stesso Drive finto.
  Future<void> dueDispositivi(
    WidgetTester tester,
    _DriveFinto drive, {
    bool sceltaSbagliata = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            Expanded(
              child: ProvaCondivisionePagina(
                key: const Key('proprietario'),
                codice: 'GF-PROP',
                accesso: _AccessoFinto(drive),
              ),
            ),
            Expanded(
              child: ProvaCondivisionePagina(
                key: const Key('membro'),
                codice: 'GF-MEMB',
                accesso: _AccessoFinto(drive, sceltaSbagliata: sceltaSbagliata),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Finder su(String chi, Finder cosa) =>
      find.descendant(of: find.byKey(Key(chi)), matching: cosa);

  testWidgets('laboratorio: proprietario e membro sulla stessa cartella', (
    tester,
  ) async {
    final drive = _DriveFinto();
    await dueDispositivi(tester, drive);

    await tester.enterText(
      su('proprietario', find.byType(TextField)),
      'membro@example.com',
    );
    await tocca(
      tester,
      su('proprietario', find.text('Crea la cartella e condividila')),
    );
    expect(
      su('proprietario', find.textContaining('"wallecy_share_GF-PROP" creata')),
      findsOneWidget,
    );

    await tocca(
      tester,
      su('membro', find.text('Scegli la cartella condivisa')),
    );
    expect(
      su('membro', find.text('Cartella scelta: "wallecy_share_GF-PROP".')),
      findsOneWidget,
    );
    expect(
      su('membro', find.textContaining('Letto "wallecy_GF-PROP.txt"')),
      findsOneWidget,
    );
    expect(
      su('membro', find.textContaining('"wallecy_GF-MEMB.txt" scritto')),
      findsOneWidget,
    );

    await tocca(
      tester,
      su('proprietario', find.text('3 · Controlla il file del membro')),
    );
    expect(
      su('proprietario', find.text('Vedo il file del membro.')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('laboratorio: file scelto al posto della cartella', (
    tester,
  ) async {
    final drive = _DriveFinto();
    await dueDispositivi(tester, drive, sceltaSbagliata: true);
    await tester.enterText(
      su('proprietario', find.byType(TextField)),
      'membro@example.com',
    );
    await tocca(
      tester,
      su('proprietario', find.text('Crea la cartella e condividila')),
    );
    await tocca(
      tester,
      su('membro', find.text('Scegli la cartella condivisa')),
    );
    expect(
      su('membro', find.textContaining('Hai scelto il file')),
      findsOneWidget,
    );
    // Nessun errore di Drive: l'app si ferma prima e spiega cosa fare.
    expect(su('membro', find.textContaining('403')), findsNothing);
  });
}
