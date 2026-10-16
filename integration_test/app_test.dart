// Test sull'app vera (in GitHub Actions: Windows, emulatori Android telefono e
// tablet): cartella dati reale, Argon2 a pieno costo, SQLCipher e libsodium
// compilati per la piattaforma, appunti di sistema veri.
// Eseguire con: flutter test integration_test -d windows
// (Android: flutter test integration_test --flavor prova -d <emulatore>)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/app.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';
import 'package:gestionale_finanziaria/core/foto/lettura_foto.dart';
import 'package:gestionale_finanziaria/core/foto/scontrino.dart';
import 'package:gestionale_finanziaria/core/sessione.dart';
import 'package:gestionale_finanziaria/core/sicurezza/cassaforte.dart';
import 'package:gestionale_finanziaria/features/sblocco/sblocco_pagina.dart';
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
    if (cosa.evaluate().isEmpty) {
      // Diagnostica: cosa c'è sullo schermo quando l'attesa fallisce.
      final testi = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
          .where((t) => t.trim().isNotEmpty)
          .join(' | ');
      debugPrint('SCHERMO: $testi');
      debugPrint(
        'FINESTRA: ${tester.view.physicalSize / tester.view.devicePixelRatio}',
      );
      for (final fab in find.byType(FloatingActionButton).evaluate()) {
        final box = fab.renderObject! as RenderBox;
        final centro = box.localToGlobal(box.size.center(Offset.zero));
        final colpiti = tester
            .hitTestOnBinding(centro)
            .path
            .take(6)
            .map((e) => e.target.runtimeType)
            .join(' > ');
        debugPrint('PULSANTE: $centro ${box.size} -> $colpiti');
      }
    }
    expect(cosa, findsWidgets);
  }

  /// Tocca [cosa] solo quando è davvero toccabile: sull'app vera i pulsanti
  /// compaiono con un'animazione e un tocco anticipato andrebbe a vuoto.
  Future<void> tocca(WidgetTester tester, Finder cosa) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(cosa);
    await tester.pump();
    for (var i = 0; i < 50; i++) {
      final oggetto = tester.renderObject(cosa.first);
      final centro = tester.getCenter(cosa.first);
      final colpito = tester
          .hitTestOnBinding(centro)
          .path
          .any((e) => e.target == oggetto);
      if (colpito) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(cosa.first);
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
      cassaforte: _SenzaSbloccoRapido(),
    );
    await tester.pumpWidget(GestionaleApp(sessione: sessione));
    await sessione.avvia();
    await attendi(tester, find.text('Benvenuto in WalleCy'));

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
    // Su Android 13+ dopo una copia compare l'anteprima di sistema degli
    // appunti: finché è aperta, l'app (senza il tocco di una persona) non può
    // leggerli. Si aspetta che sparisca e, se serve, si riprova.
    for (var tentativo = 1; tentativo <= 4; tentativo++) {
      if (Platform.isAndroid) {
        await Future<void>.delayed(const Duration(seconds: 3));
      }
      await tocca(tester, find.text('Incolla'));
      for (
        var i = 0;
        i < 30 && find.text('Secret Key valida').evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      if (find.text('Secret Key valida').evaluate().isNotEmpty) {
        break;
      }
      final appunti = await Clipboard.getData(Clipboard.kTextPlain);
      debugPrint(
        'APPUNTI (tentativo $tentativo): '
        '${appunti?.text == null
            ? 'vuoti'
            : appunti!.text == secretKey
            ? 'Secret Key giusta'
            : 'altro testo'}',
      );
    }
    // Solo negli emulatori Android senza schermo gli appunti possono restare
    // illeggibili (limite noto): si scrive la Secret Key e si verifica il resto
    // del percorso. Su Windows l'incolla resta verificato senza eccezioni.
    if (Platform.isAndroid &&
        find.text('Secret Key valida').evaluate().isEmpty) {
      debugPrint('APPUNTI: illeggibili nell\'emulatore, Secret Key scritta');
      await tester.enterText(
        find.widgetWithText(TextField, 'Secret Key'),
        secretKey,
      );
    }
    await attendi(tester, find.text('Secret Key valida'));
    await tocca(tester, find.text('Crea l\'archivio'));
    await attendi(tester, find.text('Crea il tuo primo portafoglio'));
    expect(deposito.fileKeyring.existsSync(), isTrue);
    expect(deposito.fileArchivio.existsSync(), isTrue);

    // Primo portafoglio e prima spesa: il saldo si aggiorna.
    Finder nelDialogo(Finder f) =>
        find.descendant(of: find.byType(AlertDialog), matching: f);
    await tocca(tester, find.text('Contanti'));
    await attendi(tester, nelDialogo(find.text('Tipo')));
    await tester.enterText(nelDialogo(find.byType(TextFormField)).first, '50');
    await tocca(tester, find.text('Crea'));
    await attendi(tester, find.text('50,00 €'));
    await tocca(tester, find.byTooltip('Nuovo movimento (Ctrl+N)'));
    await attendi(tester, nelDialogo(find.text('Importo')));
    await tester.enterText(
      nelDialogo(find.byType(TextFormField)).first,
      '12,5',
    );
    await tocca(tester, nelDialogo(find.text('Salva')));
    await attendi(tester, find.text('37,50 €'));

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
    // La schermata di sblocco resta sotto: si cerca solo in quella di recupero.
    Finder nelRecupero(Type tipo) => find.descendant(
      of: find.byType(RecuperoPagina),
      matching: find.byType(tipo),
    );
    await tester.enterText(nelRecupero(TextField), secretKey);
    await tester.pump();
    await tocca(tester, find.widgetWithText(FilledButton, 'Continua'));
    final nuovi = nelRecupero(TextFormField);
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

  // Il canale nativo dello sblocco rapido (Android Keystore / Windows Hello)
  // risponde. La verifica vera (impronta, PIN) richiede una persona.
  testWidgets('sblocco rapido: il canale nativo risponde', (tester) async {
    final risposta = await const MethodChannel('gestionale/sblocco_rapido')
        .invokeMapMethod<String, Object?>('disponibilita')
        .timeout(const Duration(seconds: 30));
    debugPrint('SBLOCCO: ${risposta?['stato']} (PIN: ${risposta?['pin']})');
    expect(
      risposta?['stato'],
      isIn(['pronta', 'nessunMetodo', 'nonSupportata']),
    );
    expect(
      await CassaforteDiPiattaforma().disponibilita(),
      isA<DisponibilitaCassaforte>(),
    );
  }, skip: !(Platform.isAndroid || Platform.isWindows));

  // Solo Android: Tesseract e il modello italiano dentro l'APK, la foto letta
  // sul telefono e lo "zoom" sui dati.
  testWidgets('lettura di uno scontrino con Tesseract (Android)', (
    tester,
  ) async {
    final png = await tester.runAsync<List<int>>(_scontrinoDiProva);
    final file = File('${Directory.systemTemp.path}/scontrino_prova.png');
    await file.writeAsBytes(png!);
    const lettore = LettoreFotoAndroid();
    final foto = await tester.runAsync(() => lettore.leggi(file.path));
    debugPrint('FOTO: ${foto!.righe.map((r) => r.testo).join(' | ')}');
    expect(foto.testo.toUpperCase(), contains('TOTALE'));
    final s = await tester.runAsync(
      () => LettoreScontrino.leggi(
        lettore,
        file.path,
        oggi: DateTime(2026, 10, 14),
      ),
    );
    debugPrint(
      'SCONTRINO: ${s!.negozio?.valore} · ${s.data?.valore} · '
      '${s.importo?.valore}',
    );
    expect(s.importo?.valore, 2340);
    expect(s.data?.valore, DateTime(2026, 10, 14));
    expect(s.importo?.immagine, isNotEmpty); // la zona ingrandita
    await tester.runAsync(lettore.chiudi);
    await file.delete();
  }, skip: !Platform.isAndroid);
}

/// Dispositivo senza sblocco rapido.
class _SenzaSbloccoRapido implements CassaforteDispositivo {
  @override
  bool get conPin => false;

  @override
  Future<DisponibilitaCassaforte> disponibilita() async =>
      DisponibilitaCassaforte.nonSupportata;

  @override
  Future<MaterialeCassaforte> attiva(Uint8List sfida) =>
      throw UnsupportedError('sblocco rapido');

  @override
  Future<Uint8List> leggi(Uint8List sfida, Uint8List dati) =>
      throw UnsupportedError('sblocco rapido');

  @override
  Future<void> disattiva() async {}
}

/// Uno scontrino disegnato (nero su bianco), come una foto ben fatta.
Future<List<int>> _scontrinoDiProva() async {
  const righe = [
    'SUPERMERCATO ROSSI',
    'DOCUMENTO COMMERCIALE',
    'PANE 2,10',
    'LATTE 1,29',
    'TOTALE COMPLESSIVO 23,40',
    'PAGAMENTO ELETTRONICO 23,40',
    '14-10-2026 10:21',
  ];
  const larghezza = 900.0;
  const alto = 70.0;
  final registratore = ui.PictureRecorder();
  final tela = Canvas(registratore)
    ..drawRect(
      Rect.fromLTWH(0, 0, larghezza, alto * righe.length + 80),
      Paint()..color = const Color(0xFFFFFFFF),
    );
  for (final (i, riga) in righe.indexed) {
    final paragrafo =
        (ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 40))
              ..pushStyle(ui.TextStyle(color: const Color(0xFF000000)))
              ..addText(riga))
            .build()
          ..layout(const ui.ParagraphConstraints(width: larghezza - 80));
    tela.drawParagraph(paragrafo, Offset(40, 40 + i * alto));
  }
  final immagine = await registratore.endRecording().toImage(
    larghezza.toInt(),
    (alto * righe.length + 80).toInt(),
  );
  final dati = await immagine.toByteData(format: ui.ImageByteFormat.png);
  return dati!.buffer.asUint8List();
}
