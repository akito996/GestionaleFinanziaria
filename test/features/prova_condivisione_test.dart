import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/condivisi/drive_condiviso.dart';
import 'package:gestionale_finanziaria/features/condivisi/prova_condivisione_pagina.dart';

import '../drive_finto.dart';

void main() {
  test('DriveCondiviso: tutto dentro «WalleCy», niente doppioni', () async {
    final drive = DriveFinto();
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

    // Spostata dall'utente in un'altra cartella: resta lì.
    final famiglia = await d.creaCartella('Famiglia');
    final mia = await d.cartellaDentroWalleCy('wallecy_share_GF-C');
    await d.sposta(mia.id, famiglia, [walleCy]);
    expect(await d.cartellaDentroWalleCy('wallecy_share_GF-C'), (
      id: mia.id,
      origine: Origine.altrove,
    ));
    expect(drive.elementi[mia.id]!.padre, famiglia);

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
  Future<AccessoFinto> dueDispositivi(
    WidgetTester tester,
    DriveFinto drive, {
    required bool Function(ElementoFinto e) sceltaMembro,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1800, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final proprietario = AccessoFinto(drive, 'prop');
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
                accesso: AccessoFinto(drive, 'memb', sceglie: sceltaMembro),
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
    final drive = DriveFinto(aperto: true);
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

  testWidgets('laboratorio: come la prova vera, il membro sceglie il file e il '
      'proprietario lo apre dalla segnalazione', (tester) async {
    final drive = DriveFinto(aperto: false);
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
    // Come nella prova vera: scrive nella cartella anche senza averla scelta.
    expect(
      su('membro', find.textContaining('scritto nella cartella condivisa')),
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
    expect(
      drive.elementi[fileMembro]!.padre,
      drive.conNome('wallecy_share_GF-PROP').single,
    );

    // Il proprietario ripete il passo 1 con la stessa email: stessa
    // cartella, nessun nuovo invito, avviso "Persona già presente".
    await tocca(
      tester,
      su('proprietario', find.text('Crea la cartella e condividila')),
    );
    expect(
      su('proprietario', find.textContaining('già presente: la riuso')),
      findsOneWidget,
    );
    expect(find.text('Persona già presente'), findsOneWidget);
    await tocca(tester, find.text('OK'));
    expect(drive.conNome('wallecy_share_GF-PROP'), hasLength(1));
    expect(
      drive.condivisioni.where((c) => c.email == 'memb@example.com'),
      hasLength(1),
    );

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
