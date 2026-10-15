import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';

/// Cambio di nome dell'app (ADR-018): su Windows la cartella dei dati cambia
/// e l'archivio di prima va copiato una volta, senza mai cancellarlo.
void main() {
  late Directory radice;

  setUp(() async {
    radice = await Directory.systemTemp.createTemp('deposito_test');
  });

  tearDown(() async {
    await radice.delete(recursive: true);
  });

  Directory cartella(String nome) => Directory('${radice.path}/$nome');

  Future<Directory> archivio(String nome, {String keyring = 'K'}) async {
    final c = cartella(nome)..createSync(recursive: true);
    await File('${c.path}/keyring.bin').writeAsString(keyring);
    await File('${c.path}/archivio.db').writeAsString('DB-$keyring');
    await File('${c.path}/sicurezza.json').writeAsString('{}');
    return c;
  }

  test('copia l\'archivio dal vecchio nome e lascia l\'originale', () async {
    final vecchia = await archivio('vecchia');
    final nuova = cartella('nuova');
    final copiato = await DepositoLocale.copiaArchivioPrecedente(
      destinazione: nuova,
      origini: [cartella('mai-esistita'), vecchia],
    );
    expect(copiato, isTrue);
    expect(File('${nuova.path}/keyring.bin').readAsStringSync(), 'K');
    expect(File('${nuova.path}/archivio.db').readAsStringSync(), 'DB-K');
    expect(File('${nuova.path}/sicurezza.json').existsSync(), isTrue);
    // L'originale resta dov'era.
    expect(File('${vecchia.path}/keyring.bin').existsSync(), isTrue);
    expect(Directory('${nuova.path}.copia').existsSync(), isFalse);
  });

  test('con un archivio già nella cartella nuova non tocca nulla', () async {
    final vecchia = await archivio('vecchia', keyring: 'VECCHIO');
    final nuova = await archivio('nuova', keyring: 'NUOVO');
    final copiato = await DepositoLocale.copiaArchivioPrecedente(
      destinazione: nuova,
      origini: [vecchia],
    );
    expect(copiato, isFalse);
    expect(File('${nuova.path}/keyring.bin').readAsStringSync(), 'NUOVO');
  });

  test('cartella nuova vuota: messa da parte, poi la copia', () async {
    final vecchia = await archivio('vecchia');
    final nuova = cartella('nuova')..createSync();
    expect(
      await DepositoLocale.copiaArchivioPrecedente(
        destinazione: nuova,
        origini: [vecchia],
      ),
      isTrue,
    );
    expect(File('${nuova.path}/keyring.bin').existsSync(), isTrue);
    expect(
      radice.listSync().map((e) => e.path).where((p) => p.contains('.vuota-')),
      hasLength(1),
    );
  });

  test('nessun archivio precedente: niente da copiare', () async {
    expect(
      await DepositoLocale.copiaArchivioPrecedente(
        destinazione: cartella('nuova'),
        origini: [cartella('vecchia')],
      ),
      isFalse,
    );
    expect(cartella('nuova').existsSync(), isFalse);
  });
}
