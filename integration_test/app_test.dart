// Test sull'app vera (Windows in GitHub Actions): cartella dati reale, Argon2 a pieno
// costo, SQLCipher e libsodium compilati per la piattaforma, appunti di sistema veri.
// Eseguire con: flutter test integration_test -d windows
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/app.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';
import 'package:gestionale_finanziaria/core/sessione.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sodium/sodium_sumo.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Attende (in tempo reale) che compaia [cosa], fino a [secondi].
  Future<void> attendi(
    WidgetTester tester,
    Finder cosa, {
    int secondi = 60,
  }) async {
    for (var i = 0; i < secondi * 10 && cosa.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(cosa, findsWidgets);
  }

  Future<void> tocca(WidgetTester tester, Finder cosa) async {
    await tester.ensureVisible(cosa);
    await tester.pump();
    await tester.tap(cosa);
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('primo avvio, blocco, sblocco e recupero sull\'app vera', (
    tester,
  ) async {
    final deposito = await DepositoLocale.predefinito();
    if (deposito.cartella.existsSync()) {
      deposito.cartella.deleteSync(recursive: true);
    }
    final sessione = Sessione(
      sodium: await SodiumSumoInit.init(),
      deposito: deposito,
    );
    await tester.pumpWidget(GestionaleApp(sessione: sessione));
    await sessione.avvia();
    await attendi(tester, find.text('Benvenuto in GestionaleFinanziaria'));

    // Primo avvio.
    await tocca(tester, find.text('Inizia'));
    final campi = find.byType(TextFormField);
    await tester.enterText(campi.at(0), 'Password-Lunga-1');
    await tester.enterText(campi.at(1), 'Password-Lunga-1');
    await tocca(tester, find.text('Continua'));
    await attendi(tester, find.text('La tua Secret Key'));
    final secretKey = tester
        .widget<SelectableText>(find.byKey(const Key('secret-key')))
        .data!;

    await tocca(tester, find.text('Copia'));
    await attendi(tester, find.textContaining('Copiata'));
    await tocca(tester, find.widgetWithText(FilledButton, 'Continua'));
    await tocca(tester, find.text('Incolla'));
    await attendi(tester, find.text('Secret Key valida'));
    await tocca(tester, find.text('Crea l\'archivio'));
    await attendi(tester, find.text('Archivio aperto'));
    expect(deposito.fileKeyring.existsSync(), isTrue);
    expect(deposito.fileArchivio.existsSync(), isTrue);

    // Blocco e sblocco.
    const lucchetto = 'Archivio aperto: tocca per bloccarlo';
    await tocca(tester, find.byTooltip(lucchetto));
    await attendi(tester, find.text('Archivio bloccato'));
    await tester.enterText(find.byType(TextField), 'Password-Lunga-1');
    await tocca(tester, find.text('Sblocca'));
    await attendi(tester, find.text('Archivio sbloccato'));

    // Password sbagliata: messaggio chiaro, nessun blocco dell'interfaccia.
    await tocca(tester, find.byTooltip(lucchetto));
    await attendi(tester, find.text('Archivio bloccato'));
    await tester.enterText(find.byType(TextField), 'password-sbagliata');
    await tocca(tester, find.text('Sblocca'));
    await attendi(tester, find.text('Password errata.'));

    // Recupero con la Secret Key.
    await tocca(tester, find.text('Ho dimenticato la password'));
    await attendi(tester, find.text('Secret Key (1 di 2)'));
    await tester.enterText(find.byType(TextField), secretKey);
    await tester.pump();
    await tocca(tester, find.widgetWithText(FilledButton, 'Continua'));
    final nuovi = find.byType(TextFormField);
    await tester.enterText(nuovi.at(0), 'Nuova-Password-2');
    await tester.enterText(nuovi.at(1), 'Nuova-Password-2');
    await tocca(tester, find.text('Recupera l\'archivio'));
    await attendi(
      tester,
      find.text('Nuova password impostata: archivio sbloccato'),
    );

    await tocca(tester, find.byTooltip(lucchetto));
    await attendi(tester, find.text('Archivio bloccato'));
    deposito.cartella.deleteSync(recursive: true);
  });
}
