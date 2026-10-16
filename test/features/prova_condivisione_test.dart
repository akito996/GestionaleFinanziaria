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
  final file = <String, ({String nome, String? padre, String testo})>{};
  final condivisioni = <String>[];
  var _n = 0;

  http.Client client() => MockClient((r) async {
    final percorso = r.url.path;
    if (r.method == 'POST' && percorso == '/drive/v3/files') {
      final dati = jsonDecode(r.body) as Map<String, Object?>;
      final id = 'f${_n++}';
      file[id] = (nome: dati['name']! as String, padre: null, testo: '');
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
      final testo = parti[2].split('\r\n--').first;
      final id = 'f${_n++}';
      file[id] = (
        nome: meta['name']! as String,
        padre: (meta['parents']! as List).first as String,
        testo: testo,
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
      final id = percorso.split('/').last;
      return http.Response.bytes(utf8.encode(file[id]!.testo), 200);
    }
    return http.Response('non previsto', 404);
  });
}

class _AccessoFinto implements AccessoDriveFile {
  _AccessoFinto(this.drive);

  final _DriveFinto drive;

  @override
  Future<http.Client?> client() async => drive.client();

  @override
  Future<CartellaScelta> scegliCartella() async => (
    client: drive.client(),
    scelti: [drive.file.entries.firstWhere((e) => e.value.padre == null).key],
  );
}

void main() {
  test('DriveCondiviso: crea, condividi, scrivi, elenca, leggi', () async {
    final drive = _DriveFinto();
    final d = DriveCondiviso(drive.client());
    final cartella = await d.creaCartella('Prova');
    await d.condividi(cartella, 'membro@example.com');
    await d.scrivi(cartella, 'a.txt', 'ciao');
    final elenco = await d.elenca(cartella);
    expect(elenco.map((f) => f.nome), ['a.txt']);
    expect(await d.leggi(elenco.single.id), 'ciao');
    expect(drive.condivisioni, ['membro@example.com']);
  });

  testWidgets('laboratorio: proprietario e membro sulla stessa cartella', (
    tester,
  ) async {
    // Alta abbastanza da mostrare tutte le righe del registro.
    await tester.binding.setSurfaceSize(const Size(900, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final drive = _DriveFinto();
    await tester.pumpWidget(
      MaterialApp(home: ProvaCondivisionePagina(accesso: _AccessoFinto(drive))),
    );
    Future<void> tocca(String testo) async {
      await tester.ensureVisible(find.text(testo));
      await tester.tap(find.text(testo));
      await tester.pump();
      // Fino alla fine del passo: i pulsanti tornano attivi.
      bool occupato() =>
          tester
              .widget<FilledButton>(
                find.widgetWithText(
                  FilledButton,
                  'Crea la cartella e condividila',
                ),
              )
              .onPressed ==
          null;
      for (var i = 0; i < 100 && occupato(); i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
      }
    }

    await tester.enterText(find.byType(TextField), 'membro@example.com');
    await tocca('Crea la cartella e condividila');
    expect(
      find.textContaining('Cartella condivisa con membro'),
      findsOneWidget,
    );

    await tocca('Scegli la cartella condivisa');
    expect(
      find.textContaining('Vedo 1 file: proprietario.txt'),
      findsOneWidget,
    );
    expect(find.textContaining('Letto "proprietario.txt"'), findsOneWidget);
    expect(find.textContaining('"membro.txt" scritto'), findsOneWidget);

    await tocca('3 · Controlla il file del membro');
    expect(find.text('Vedo il file del membro.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });
}
