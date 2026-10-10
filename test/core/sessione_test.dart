import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/crypto/derivazione.dart';
import 'package:gestionale_finanziaria/core/crypto/eccezioni.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';
import 'package:gestionale_finanziaria/core/sessione.dart';
import 'package:sodium/sodium_sumo.dart';

void main() {
  late SodiumSumo sodium;
  late Directory cartella;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() async {
    cartella = await Directory.systemTemp.createTemp('sessione_test');
  });

  tearDown(() async {
    await cartella.delete(recursive: true);
  });

  Sessione nuovaSessione() => Sessione(
    sodium: sodium,
    deposito: DepositoLocale(cartella),
    costoArgon2: (
      ops: ParametriArgon2.opsMinimo,
      mem: ParametriArgon2.memMinima,
    ),
  );

  test('percorso completo: primo avvio, blocco, sblocco, recupero', () async {
    final sessione = nuovaSessione();
    await sessione.avvia();
    expect(sessione.fase, FaseSessione.primoAvvio);

    // Primo avvio: nulla su disco finché la Recovery Key non è verificata.
    final parole = await sessione.preparaNuovoArchivio('Password-Lunga-1');
    expect(parole, hasLength(24));
    expect(await DepositoLocale(cartella).esisteKeyring(), isFalse);

    await sessione.confermaNuovoArchivio();
    expect(sessione.fase, FaseSessione.sbloccata);
    expect(
      await sessione.archivio.select(sessione.archivio.definizioniTipo).get(),
      isNotEmpty,
    );

    await sessione.blocca();
    expect(sessione.fase, FaseSessione.bloccata);

    // Riavvio dell'app.
    final riavvio = nuovaSessione();
    await riavvio.avvia();
    expect(riavvio.fase, FaseSessione.bloccata);
    await expectLater(
      riavvio.sblocca('sbagliata'),
      throwsA(isA<PasswordErrataException>()),
    );
    await riavvio.sblocca('Password-Lunga-1');
    expect(riavvio.fase, FaseSessione.sbloccata);
    await riavvio.blocca();

    // Password dimenticata: Recovery Key + nuova password.
    await expectLater(
      riavvio.recupera('abaco abaco', 'Nuova-Password-2'),
      throwsA(isA<RecoveryKeyNonValidaException>()),
    );
    await riavvio.recupera(parole.join(' '), 'Nuova-Password-2');
    expect(riavvio.fase, FaseSessione.sbloccata);
    await riavvio.blocca();

    await expectLater(
      riavvio.sblocca('Password-Lunga-1'),
      throwsA(isA<PasswordErrataException>()),
    );
    await riavvio.sblocca('Nuova-Password-2');
    expect(riavvio.fase, FaseSessione.sbloccata);
    await riavvio.blocca();
  });

  test('primo avvio annullato: non resta nulla su disco', () async {
    final sessione = nuovaSessione();
    await sessione.avvia();
    await sessione.preparaNuovoArchivio('Password-Lunga-1');
    sessione.annullaNuovoArchivio();

    expect(await DepositoLocale(cartella).esisteKeyring(), isFalse);
    await expectLater(
      sessione.confermaNuovoArchivio(),
      throwsA(isA<StateError>()),
    );
  });

  test('database senza keyring: messo da parte, mai cancellato', () async {
    final deposito = DepositoLocale(cartella);
    await cartella.create(recursive: true);
    await deposito.fileArchivio.writeAsString('vecchio archivio');

    final sessione = nuovaSessione();
    await sessione.avvia();
    await sessione.preparaNuovoArchivio('Password-Lunga-1');
    await sessione.confermaNuovoArchivio();
    await sessione.blocca();

    final orfani = cartella
        .listSync()
        .where((f) => f.path.contains('archivio.db.orfano-'))
        .toList();
    expect(orfani, hasLength(1));
    expect(await File(orfani.single.path).readAsString(), 'vecchio archivio');
  });
}
