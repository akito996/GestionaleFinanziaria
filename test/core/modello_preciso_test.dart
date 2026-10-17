import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/foto/modello_preciso.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Directory cartella;
  final dati = utf8.encode('modello di prova');
  final giusta = sha256.convert(dati).toString();

  setUp(() async {
    cartella = await Directory.systemTemp.createTemp('modello_');
  });
  tearDown(() => cartella.delete(recursive: true));

  ModelloPreciso modello(http.Client Function() client, {String? impronta}) =>
      ModelloPreciso(
        cartella: () async => cartella,
        client: client,
        impronta: impronta ?? giusta,
      );

  test('si scarica una volta sola e poi si usa', () async {
    var richieste = 0;
    final m = modello(
      () => MockClient((r) async {
        richieste++;
        expect(r.url, ModelloPreciso.indirizzo);
        return http.Response.bytes(dati, 200);
      }),
    );
    expect(await m.pronto(), isNull);
    // Più richieste insieme: un solo scaricamento.
    await Future.wait([m.prepara(), m.prepara(), m.prepara()]);
    expect(richieste, 1);
    expect(m.disponibile, isTrue);
    final percorso = await m.pronto();
    expect(File('$percorso/tessdata/ita.traineddata').readAsBytesSync(), dati);
    await m.prepara();
    expect(richieste, 1);
  });

  test('impronta diversa o rete assente: non si installa niente', () async {
    final sbagliato = modello(
      () => MockClient((_) async => http.Response.bytes([1, 2, 3], 200)),
    );
    await sbagliato.prepara();
    expect(await sbagliato.pronto(), isNull);

    final senzaRete = modello(
      () => MockClient((_) async => throw const SocketException('offline')),
    );
    await senzaRete.prepara();
    expect(await senzaRete.pronto(), isNull);
    expect(senzaRete.inArrivo, isFalse);
  });

  test('il modello delle versioni precedenti si riusa', () async {
    final vecchio = File('${cartella.path}/tesseract/tessdata/ita.traineddata')
      ..createSync(recursive: true)
      ..writeAsBytesSync(dati);
    final m = modello(() => MockClient((_) async => fail('niente rete')));
    await m.prepara();
    expect(await m.pronto(), isNotNull);
    expect(vecchio.existsSync(), isTrue);
  });

  test('la lettura aspetta un po\' uno scaricamento già partito', () async {
    final m = modello(
      () => MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response.bytes(dati, 200);
      }),
    );
    m.prepara().ignore();
    expect(m.inArrivo, isTrue);
    expect(await m.pronto(attesa: const Duration(seconds: 5)), isNotNull);
  });
}
