import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/app.dart';
import 'package:gestionale_finanziaria/core/crypto/derivazione.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';
import 'package:gestionale_finanziaria/core/db/tabelle.dart';
import 'package:gestionale_finanziaria/core/sessione.dart';
import 'package:gestionale_finanziaria/core/sync/accesso_google.dart';
import 'package:gestionale_finanziaria/core/sync/backend_memoria.dart';
import 'package:gestionale_finanziaria/core/sync/sincronizzatore.dart';
import 'package:gestionale_finanziaria/core/sync/sincronizzazione.dart';
import 'package:http/http.dart' as http;
import 'package:sodium/sodium_sumo.dart';

/// Google finto: il consenso c'è sempre (i dati vanno in [BackendInMemoria]).
class _AccessoFinto implements AccessoGoogle {
  @override
  bool get disponibile => true;

  @override
  Future<http.Client?> client({required bool interattivo}) async =>
      http.Client();

  @override
  Future<void> invalida() async {}

  @override
  Future<void> esci() async {}
}

void main() {
  late SodiumSumo sodium;
  late BackendInMemoria drive;
  final cartelle = <Directory>[];

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() => drive = BackendInMemoria());

  tearDown(() async {
    for (final c in cartelle) {
      try {
        await c.delete(recursive: true);
      } on FileSystemException {
        // archivio ancora in chiusura
      }
    }
    cartelle.clear();
  });

  Future<Sessione> dispositivo() async {
    final cartella = await Directory.systemTemp.createTemp('sync_ui_test');
    cartelle.add(cartella);
    return Sessione(
      sodium: sodium,
      deposito: DepositoLocale(cartella),
      costoArgon2: (
        ops: ParametriArgon2.opsMinimo,
        mem: ParametriArgon2.memMinima,
      ),
      accessoGoogle: _AccessoFinto(),
      creaBackend: (_) => drive,
    );
  }

  /// Archivio nuovo con un portafoglio.
  Future<Sessione> conArchivio(String portafoglio) async {
    final s = await dispositivo();
    await s.avvia();
    await s.preparaNuovoArchivio('Password-Lunga-1');
    await s.confermaNuovoArchivio();
    final tipo = (await s.contabilita.tipi(AmbitoTipo.portafoglio))
        .firstWhere((t) => t.nome == 'Conto corrente');
    await s.contabilita.creaPortafoglio(
      nome: portafoglio,
      tipoId: tipo.id,
      valuta: 'EUR',
    );
    return s;
  }

  Future<void> attendi(WidgetTester tester, Finder cosa) async {
    for (var i = 0; i < 300 && cosa.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(cosa, findsWidgets);
  }

  Future<void> tocca(WidgetTester tester, Finder cosa) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(cosa);
    await tester.pump();
    await tester.tap(cosa);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> prepara(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
  }

  Future<void> chiudi(WidgetTester tester, Sessione s) async {
    if (s.fase == FaseSessione.sbloccata) {
      s.blocca().ignore();
      await attendi(tester, find.text('Archivio bloccato'));
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('accendere la sincronizzazione dalla nuvola', (tester) async {
    await prepara(tester);
    final pc = (await tester.runAsync(() => conArchivio('Conto di casa')))!;
    pc.avviso = null;
    await tester.pumpWidget(GestionaleApp(sessione: pc));
    await attendi(tester, find.text('Portafogli'));

    await tocca(tester, find.byTooltip('Sincronizzazione spenta').first);
    await attendi(tester, find.text('Accendi con Google Drive'));
    await tocca(tester, find.text('Accendi con Google Drive'));
    await attendi(tester, find.textContaining('Sincronizzato'));
    expect(pc.sync.stato.value.fase, FaseSync.aggiornata);
    expect(
      await tester.runAsync(() => Sincronizzatore.idArchivioRemoto(drive)),
      pc.idArchivio,
    );
    await chiudi(tester, pc);
  });

  testWidgets('secondo dispositivo: "Ho già un archivio" e password', (
    tester,
  ) async {
    await prepara(tester);
    await tester.runAsync(() async {
      final pc = await conArchivio('Conto di casa');
      await pc.sync.accendi();
      await pc.blocca();
    });

    final telefono = (await tester.runAsync(dispositivo))!;
    await tester.pumpWidget(GestionaleApp(sessione: telefono));
    await tester.runAsync(telefono.avvia);
    await attendi(tester, find.text('Benvenuto in WalleCy'));
    await tocca(
      tester,
      find.text('Ho già un archivio su un altro dispositivo'),
    );
    await tocca(tester, find.text('Accedi a Google Drive'));
    await attendi(tester, find.text('Archivio trovato su Google Drive'));

    await tester.enterText(
      find.widgetWithText(TextField, 'Password dell\'archivio'),
      'Password-sbagliata',
    );
    await tocca(tester, find.text('Scarica e apri'));
    await attendi(tester, find.text('Password errata.'));

    await tester.enterText(
      find.widgetWithText(TextField, 'Password dell\'archivio'),
      'Password-Lunga-1',
    );
    await tocca(tester, find.text('Scarica e apri'));
    await attendi(tester, find.text('Conto di casa'));
    expect(telefono.sync.stato.value.fase, isNot(FaseSync.spenta));
    await chiudi(tester, telefono);
  });

  testWidgets('su Drive un altro archivio: scelta chiara, nulla si perde', (
    tester,
  ) async {
    await prepara(tester);
    await tester.runAsync(() async {
      final vecchio = await conArchivio('Archivio di prova');
      await vecchio.sync.accendi();
      await vecchio.blocca();
    });
    final pc = (await tester.runAsync(() => conArchivio('Conto vero')))!;
    pc.avviso = null;
    await tester.pumpWidget(GestionaleApp(sessione: pc));
    await attendi(tester, find.text('Portafogli'));

    await tocca(tester, find.byTooltip('Sincronizzazione spenta').first);
    await tocca(tester, find.text('Accendi con Google Drive'));
    await attendi(tester, find.textContaining('Su Google Drive c\'è già'));
    expect(
      find.text('Usa quello di Drive su questo dispositivo'),
      findsOneWidget,
    );

    await tocca(tester, find.text('Metti questo su Drive al suo posto'));
    await tocca(tester, find.text('Metti questo su Drive'));
    await attendi(tester, find.textContaining('Sincronizzato'));
    expect(
      await tester.runAsync(() => Sincronizzatore.idArchivioRemoto(drive)),
      pc.idArchivio,
    );
    // Il vecchio archivio è stato messo da parte, non cancellato.
    final file = (await tester.runAsync(drive.elenca))!;
    expect(file.where((f) => f.nome.startsWith('vecchio-')), isNotEmpty);
    await chiudi(tester, pc);
  });
}
