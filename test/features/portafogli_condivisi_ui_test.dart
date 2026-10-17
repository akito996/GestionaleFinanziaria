import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/app.dart';
import 'package:gestionale_finanziaria/core/condivisi/identita_persona.dart';
import 'package:gestionale_finanziaria/core/condivisi/portafogli_condivisi.dart';
import 'package:gestionale_finanziaria/core/crypto/derivazione.dart';
import 'package:gestionale_finanziaria/core/db/archivio.dart';
import 'package:gestionale_finanziaria/core/db/contabilita.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';
import 'package:gestionale_finanziaria/core/sessione.dart';
import 'package:sodium/sodium_sumo.dart';

import '../drive_finto.dart';

/// Portafogli condivisi nell'app (ADR-019): il proprietario usa l'app vera,
/// il membro solo il motore, sullo stesso Drive finto.
void main() {
  late SodiumSumo sodium;
  late Directory cartella;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() async {
    cartella = await Directory.systemTemp.createTemp('condivisi_ui_test');
  });

  tearDown(() async {
    try {
      await cartella.delete(recursive: true);
    } on FileSystemException {
      // archivio ancora in chiusura
    }
  });

  Future<void> attendi(WidgetTester tester, Finder cosa) async {
    for (var i = 0; i < 200 && cosa.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(cosa, findsWidgets);
  }

  Future<void> tocca(WidgetTester tester, Finder cosa) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(cosa.first);
    await tester.pump();
    await tester.tap(cosa.first);
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Finder nelDialogo(Finder f) =>
      find.descendant(of: find.byType(AlertDialog), matching: f);

  testWidgets(
    'portafoglio condiviso dal modulo, persone, codice di sicurezza',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (_) async => null,
      );
      final drive = DriveFinto();
      final sessione = Sessione(
        sodium: sodium,
        deposito: DepositoLocale(cartella),
        costoArgon2: (
          ops: ParametriArgon2.opsMinimo,
          mem: ParametriArgon2.memMinima,
        ),
        accessoDriveFile: AccessoFinto(drive, 'prop'),
      );
      await tester.runAsync(() async {
        await sessione.avvia();
        await sessione.preparaNuovoArchivio('Password-Lunga-1');
        await sessione.confermaNuovoArchivio();
      });
      sessione.avviso = null;
      await tester.pumpWidget(GestionaleApp(sessione: sessione));
      await attendi(tester, find.text('Crea il tuo primo portafoglio'));

      // Nuovo portafoglio "Condiviso" con l'email della persona.
      await tocca(tester, find.text('Conto corrente'));
      await attendi(tester, nelDialogo(find.text('Tipo')));
      await tester.enterText(
        nelDialogo(find.byType(TextFormField)).first,
        '500',
      );
      await tocca(tester, nelDialogo(find.text('Condiviso')));
      await tester.enterText(
        nelDialogo(
          find.widgetWithText(
            TextFormField,
            'Email Google della persona da invitare',
          ),
        ),
        'memb@example.com',
      );
      await tocca(tester, nelDialogo(find.text('Crea')));
      await attendi(tester, find.textContaining('Invito mandato a'));
      expect(drive.condivisioni.single.email, 'memb@example.com');

      // Nel dettaglio: la scheda delle persone, il membro da confermare.
      await tocca(tester, find.text('Conto corrente'));
      await attendi(tester, find.text('Portafoglio condiviso'));
      expect(find.text('memb@example.com (da confermare)'), findsOneWidget);
      // Avviso: si aspetta la risposta, con l'ora entro cui accettare.
      expect(
        find.textContaining('In attesa di risposta da memb@example.com'),
        findsOneWidget,
      );

      // Di nuovo la stessa persona: "Persona già presente".
      await tocca(tester, find.byTooltip('Condividi con altre persone'));
      await tester.enterText(
        nelDialogo(find.byType(TextFormField)),
        'memb@example.com',
      );
      await tocca(tester, nelDialogo(find.text('Invita')));
      await attendi(tester, find.text('Persona già presente'));
      expect(find.textContaining('le ho rimandato'), findsOneWidget);
      await tocca(tester, find.text('OK'));
      expect(drive.condivisioni, hasLength(2));

      // Il membro entra (solo il motore) e il proprietario si sincronizza.
      final w = (await tester.runAsync(
        () => sessione.contabilita.osservaPortafogli().first,
      ))!.single.portafoglio.id;
      await tester.runAsync(() async {
        final db = Archivio.inMemoria();
        final c = await Contabilita.apri(db);
        final io = IdentitaPersona.daChiaveDati(
          sodium,
          SecureKey.fromList(sodium, Uint8List.fromList(List.filled(32, 9))),
        );
        final membro = PortafogliCondivisiServizio(
          db: db,
          contabilita: c,
          sodium: sodium,
          identita: () => io,
          accesso: AccessoFinto(drive, 'memb')
            ..sceglie = (e) => e.nome.startsWith('wallecy_'),
        );
        expect(await membro.unisciti(), EsitoIngresso.inAttesa);
        await sessione.condivisi.sincronizza();
        await membro.sincronizza();
        expect(
          (await (db.select(
            db.portafogli,
          )..where((p) => p.id.equals(w))).getSingle()).saldoInizialeMinimo,
          50000,
        );
        await db.close();
      });
      await attendi(tester, find.text('memb@example.com'));
      expect(
        find.text('Membro · tocca per verificare il codice di sicurezza'),
        findsOneWidget,
      );

      // Codice di sicurezza con il QR: "I codici coincidono".
      await tocca(tester, find.text('memb@example.com'));
      await attendi(tester, find.text('Codice di sicurezza'));
      expect(nelDialogo(find.byType(CustomPaint)), findsWidgets);
      await tocca(tester, find.text('I codici coincidono'));
      await attendi(
        tester,
        find.text('Membro · codice di sicurezza verificato'),
      );
      final membri = await tester.runAsync(() => sessione.condivisi.membri(w));
      expect(
        membri!.firstWhere((m) => m.ruolo == RuoloMembro.membro).verificato,
        isTrue,
      );

      sessione.blocca().ignore();
      await attendi(tester, find.text('Archivio bloccato'));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('condivisione non riuscita: avviso, il portafoglio resta', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    final drive = DriveFinto()..rifiutaCondivisione = true;
    final sessione = Sessione(
      sodium: sodium,
      deposito: DepositoLocale(cartella),
      costoArgon2: (
        ops: ParametriArgon2.opsMinimo,
        mem: ParametriArgon2.memMinima,
      ),
      accessoDriveFile: AccessoFinto(drive, 'prop'),
    );
    await tester.runAsync(() async {
      await sessione.avvia();
      await sessione.preparaNuovoArchivio('Password-Lunga-1');
      await sessione.confermaNuovoArchivio();
    });
    sessione.avviso = null;
    await tester.pumpWidget(GestionaleApp(sessione: sessione));
    await attendi(tester, find.text('Crea il tuo primo portafoglio'));

    await tocca(tester, find.text('Conto corrente'));
    await attendi(tester, nelDialogo(find.text('Tipo')));
    await tester.enterText(nelDialogo(find.byType(TextFormField)).first, '10');
    await tocca(tester, nelDialogo(find.text('Condiviso')));
    await tester.enterText(
      nelDialogo(
        find.widgetWithText(
          TextFormField,
          'Email Google della persona da invitare',
        ),
      ),
      'memb@example.com',
    );
    await tocca(tester, nelDialogo(find.text('Crea')));
    await attendi(tester, find.text('Condivisione non riuscita'));
    expect(find.textContaining('si usa normalmente'), findsOneWidget);
    await tocca(tester, find.text('OK'));
    // Il portafoglio c'è, senza persone invitate.
    final portafogli = await tester.runAsync(
      () => sessione.contabilita.osservaPortafogli().first,
    );
    expect(portafogli!.single.portafoglio.nome, 'Conto corrente');
    final w = portafogli.single.portafoglio.id;
    final persone = await tester.runAsync(() => sessione.condivisi.membri(w));
    expect(persone!.where((m) => m.email == 'memb@example.com'), isEmpty);

    sessione.blocca().ignore();
    await attendi(tester, find.text('Archivio bloccato'));
    await tester.pumpWidget(const SizedBox());
  });
}
