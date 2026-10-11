import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/app.dart';
import 'package:gestionale_finanziaria/core/crypto/derivazione.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';
import 'package:gestionale_finanziaria/core/sessione.dart';
import 'package:gestionale_finanziaria/core/versione.dart';
import 'package:gestionale_finanziaria/features/comuni/icone.dart';
import 'package:sodium/sodium_sumo.dart';

void main() {
  late SodiumSumo sodium;
  late Directory cartella;
  late Sessione sessione;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() async {
    cartella = await Directory.systemTemp.createTemp('primo_avvio_test');
    sessione = Sessione(
      sodium: sodium,
      deposito: DepositoLocale(cartella),
      costoArgon2: (
        ops: ParametriArgon2.opsMinimo,
        mem: ParametriArgon2.memMinima,
      ),
    );
  });

  tearDown(() async {
    // L'archivio può essere ancora in chiusura dopo il blocco: la cartella
    // temporanea, se occupata, la ripulisce il sistema.
    try {
      await cartella.delete(recursive: true);
    } on FileSystemException {
      // ignorato
    }
  });

  /// Aspetta il lavoro vero (isolate, file) finché compare [cosa].
  Future<void> attendi(WidgetTester tester, Finder cosa) async {
    for (var i = 0; i < 200 && cosa.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    expect(cosa, findsWidgets);
  }

  Future<void> tocca(WidgetTester tester, Finder cosa) async {
    await tester.ensureVisible(cosa);
    await tester.pump();
    await tester.tap(cosa);
    await tester.pump();
  }

  Future<void> avviaApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // Appunti di sistema simulati.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    await tester.runAsync(sessione.avvia);
    await tester.pumpWidget(GestionaleApp(sessione: sessione));
  }

  /// Dal benvenuto alla schermata della Secret Key; restituisce la Secret Key mostrata.
  Future<String> finoAllaSecretKey(WidgetTester tester) async {
    await avviaApp(tester);
    expect(find.text('Benvenuto in GestionaleFinanziaria'), findsOneWidget);
    await tocca(tester, find.text('Inizia'));

    final campi = find.byType(TextFormField);
    await tester.enterText(campi.at(0), 'Password-Lunga-1');
    await tester.enterText(campi.at(1), 'Password-Lunga-1');
    await tocca(tester, find.text('Continua'));
    await attendi(tester, find.text('La tua Secret Key'));

    final testo = tester
        .widget<SelectableText>(find.byKey(const Key('secret-key')))
        .data!;
    expect(testo, startsWith('GF1-'));
    return testo;
  }

  testWidgets('regole della password', (tester) async {
    await avviaApp(tester);
    await tocca(tester, find.text('Inizia'));
    final campi = find.byType(TextFormField);

    await tester.enterText(campi.at(0), 'corta');
    await tocca(tester, find.text('Continua'));
    expect(find.text('Servono almeno 12 caratteri.'), findsOneWidget);

    await tester.enterText(campi.at(0), 'Password-Lunga-1');
    await tester.enterText(campi.at(1), 'Password-Lunga-2');
    await tocca(tester, find.text('Continua'));
    expect(find.text('Le due password non coincidono.'), findsOneWidget);
  });

  testWidgets('percorso completo: crea, blocca, sblocca, recupera', (
    tester,
  ) async {
    final secretKey = await finoAllaSecretKey(tester);

    // "Continua" resta disattivato finché la Secret Key non è salvata o copiata.
    final continua = find.widgetWithText(FilledButton, 'Continua');
    expect(tester.widget<FilledButton>(continua).onPressed, isNull);
    await tocca(tester, find.text('Copia'));
    await attendi(tester, find.textContaining('Copiata'));
    await tocca(tester, continua);

    // Verifica: Secret Key incollata (qui scritta nel campo).
    await tester.enterText(find.byType(TextField), secretKey);
    await tester.pump();
    expect(find.text('Secret Key valida'), findsOneWidget);
    await tocca(tester, find.text('Crea l\'archivio'));
    await attendi(tester, find.text('Crea il tuo primo portafoglio'));
    await tester.pump();
    expect(find.text('Archivio creato'), findsOneWidget);
    expect(find.byType(LucchettoAperto), findsWidgets);

    // Blocco e sblocco con conferma visibile.
    await tocca(tester, find.byTooltip('Archivio aperto: tocca per bloccarlo'));
    await attendi(tester, find.text('Archivio bloccato'));
    expect(find.text(Versione.firma), findsOneWidget); // firma anche qui
    await tester.enterText(find.byType(TextField), 'Password-Lunga-1');
    await tocca(tester, find.text('Sblocca'));
    await attendi(tester, find.text('Archivio sbloccato'));

    // Password dimenticata: Secret Key → nuova password.
    await tocca(tester, find.byTooltip('Archivio aperto: tocca per bloccarlo'));
    await attendi(tester, find.text('Archivio bloccato'));
    await tocca(tester, find.text('Ho dimenticato la password'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Secret Key:  $secretKey');
    await tester.pump();
    await tocca(tester, find.widgetWithText(FilledButton, 'Continua'));
    final campi = find.byType(TextFormField);
    await tester.enterText(campi.at(0), 'Nuova-Password-2');
    await tester.enterText(campi.at(1), 'Nuova-Password-2');
    await tocca(tester, find.text('Recupera l\'archivio'));
    await attendi(
      tester,
      find.text('Nuova password impostata: archivio sbloccato'),
    );
    await tocca(tester, find.byTooltip('Archivio aperto: tocca per bloccarlo'));
    await attendi(tester, find.text('Archivio bloccato'));
  });

  testWidgets('verifica con una Secret Key diversa: archivio non creato', (
    tester,
  ) async {
    final secretKey = await finoAllaSecretKey(tester);
    await tocca(tester, find.text('Copia'));
    await attendi(tester, find.textContaining('Copiata'));
    await tocca(tester, find.widgetWithText(FilledButton, 'Continua'));

    // Formato non valido: pulsante disattivato e messaggio immediato.
    await tester.enterText(find.byType(TextField), 'GF1-123');
    await tester.pump();
    expect(find.textContaining('incompleta'), findsOneWidget);

    // Secret Key valida ma di un altro archivio.
    final altra = await tester.runAsync(
      () => Sessione(
        sodium: sodium,
        deposito: DepositoLocale(cartella),
        costoArgon2: (
          ops: ParametriArgon2.opsMinimo,
          mem: ParametriArgon2.memMinima,
        ),
      ).preparaNuovoArchivio('Altra-Password-9'),
    );
    expect(altra!.secretKey, isNot(secretKey));
    await tester.enterText(find.byType(TextField), altra.secretKey);
    await tester.pump();
    await tocca(tester, find.text('Crea l\'archivio'));
    expect(
      find.textContaining('non è la Secret Key appena creata'),
      findsOneWidget,
    );
    expect(await DepositoLocale(cartella).esisteKeyring(), isFalse);
    sessione.annullaNuovoArchivio();
  });
}
