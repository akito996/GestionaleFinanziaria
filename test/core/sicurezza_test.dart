import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/crypto/cifratura.dart';
import 'package:gestionale_finanziaria/core/crypto/derivazione.dart';
import 'package:gestionale_finanziaria/core/db/deposito_locale.dart';
import 'package:gestionale_finanziaria/core/sessione.dart';
import 'package:gestionale_finanziaria/core/sicurezza/cassaforte.dart';
import 'package:gestionale_finanziaria/core/sicurezza/sicurezza_dispositivo.dart';
import 'package:sodium/sodium_sumo.dart';

import '../cassaforte_finta.dart';

void main() {
  late SodiumSumo sodium;
  late Directory cartella;
  late File file;
  late CassaforteFinta cassaforte;
  var adesso = DateTime(2026, 10, 15, 9);

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() async {
    cartella = await Directory.systemTemp.createTemp('sicurezza_test');
    file = File('${cartella.path}/sicurezza.json');
    cassaforte = CassaforteFinta();
    adesso = DateTime(2026, 10, 15, 9);
  });

  tearDown(() async {
    try {
      await cartella.delete(recursive: true);
    } on FileSystemException {
      // ignorato
    }
  });

  SicurezzaDispositivo nuova() => SicurezzaDispositivo(
    sodium: sodium,
    file: file,
    cassaforte: cassaforte,
    adesso: () => adesso,
  );

  Uint8List byte(SecureKey chiave) => chiave.extractBytes();

  group('sblocco rapido', () {
    test(
      'attivato, riapre l\'archivio con la stessa chiave dei dati',
      () async {
        final sicurezza = nuova();
        await sicurezza.carica();
        expect(sicurezza.proponibile, isTrue);
        final dek = Cifratore(sodium).nuovaChiave();
        await sicurezza.attivaRapido(dek, 'GF-AAAA-BBBB');
        expect(sicurezza.rapidoPronto, isTrue);
        expect(sicurezza.proponibile, isFalse);

        // Come dopo un riavvio dell'app: si rilegge il file.
        final dopo = nuova();
        await dopo.carica();
        expect(dopo.rapidoPronto, isTrue);
        final riaperta = await dopo.apriRapido('GF-AAAA-BBBB');
        expect(byte(riaperta!), byte(dek));
      },
    );

    test('il file non contiene la chiave dei dati in chiaro', () async {
      final sicurezza = nuova();
      await sicurezza.carica();
      final dek = Cifratore(sodium).nuovaChiave();
      await sicurezza.attivaRapido(dek, 'GF-AAAA-BBBB');
      final testo = await file.readAsString();
      expect(testo, isNot(contains(base64.encode(byte(dek)))));
    });

    test('ogni 14 giorni serve la password', () async {
      final sicurezza = nuova();
      await sicurezza.carica();
      await sicurezza.passwordUsata();
      await sicurezza.attivaRapido(
        Cifratore(sodium).nuovaChiave(),
        'GF-AAAA-BBBB',
      );
      adesso = adesso.add(const Duration(days: 13, hours: 23));
      expect(sicurezza.rapidoPronto, isTrue);
      adesso = adesso.add(const Duration(hours: 1));
      expect(sicurezza.passwordDaChiedere, isTrue);
      expect(sicurezza.rapidoPronto, isFalse);
      await sicurezza.passwordUsata();
      expect(sicurezza.rapidoPronto, isTrue);
      expect(
        sicurezza.prossimaPassword,
        adesso.add(SicurezzaDispositivo.intervalloPassword),
      );
    });

    test('verifica annullata: resta attivo, nessuna chiave', () async {
      final sicurezza = nuova();
      await sicurezza.carica();
      await sicurezza.attivaRapido(
        Cifratore(sodium).nuovaChiave(),
        'GF-AAAA-BBBB',
      );
      cassaforte.annulla = true;
      expect(await sicurezza.apriRapido('GF-AAAA-BBBB'), isNull);
      expect(sicurezza.rapidoAttivo, isTrue);
    });

    test(
      'chiave annullata dal sistema: si spegne e lo spiega una volta',
      () async {
        final sicurezza = nuova();
        await sicurezza.carica();
        await sicurezza.attivaRapido(
          Cifratore(sodium).nuovaChiave(),
          'GF-AAAA-BBBB',
        );
        cassaforte.chiaveAnnullata = true;
        await expectLater(
          sicurezza.apriRapido('GF-AAAA-BBBB'),
          throwsA(isA<ChiaveDispositivoAnnullata>()),
        );
        expect(sicurezza.rapidoAttivo, isFalse);
        expect(sicurezza.prendiAvviso(), contains('password'));
        expect(sicurezza.prendiAvviso(), isNull);
      },
    );

    test('archivio diverso: la chiave non si apre e si spegne', () async {
      final sicurezza = nuova();
      await sicurezza.carica();
      await sicurezza.attivaRapido(
        Cifratore(sodium).nuovaChiave(),
        'GF-AAAA-BBBB',
      );
      await expectLater(
        sicurezza.apriRapido('GF-CCCC-DDDD'),
        throwsA(isA<ChiaveDispositivoAnnullata>()),
      );
      expect(sicurezza.rapidoAttivo, isFalse);
    });

    test('proposta fatta: non si propone più', () async {
      final sicurezza = nuova();
      await sicurezza.carica();
      await sicurezza.segnaPropostaFatta();
      final dopo = nuova();
      await dopo.carica();
      expect(dopo.proponibile, isFalse);
    });

    test('dispositivo senza impronta né PIN: non si propone', () async {
      cassaforte.stato = DisponibilitaCassaforte.nessunMetodo;
      final sicurezza = nuova();
      await sicurezza.carica();
      expect(sicurezza.proponibile, isFalse);
    });
  });

  test('blocco automatico: 5 minuti, poi la scelta resta', () async {
    final sicurezza = nuova();
    await sicurezza.carica();
    expect(sicurezza.bloccoAutomatico, const Duration(minutes: 5));
    await sicurezza.impostaBloccoAutomatico(null);
    var dopo = nuova();
    await dopo.carica();
    expect(dopo.bloccoAutomatico, isNull);
    await dopo.impostaBloccoAutomatico(Duration.zero);
    dopo = nuova();
    await dopo.carica();
    expect(dopo.bloccoAutomatico, Duration.zero);
  });

  test('file danneggiato: si riparte con la password', () async {
    await file.writeAsString('{non è json');
    final sicurezza = nuova();
    await sicurezza.carica();
    expect(sicurezza.rapidoAttivo, isFalse);
    expect(sicurezza.bloccoAutomatico, SicurezzaDispositivo.bloccoPredefinito);
  });

  group('sessione', () {
    Sessione nuovaSessione() => Sessione(
      sodium: sodium,
      deposito: DepositoLocale(cartella),
      costoArgon2: (
        ops: ParametriArgon2.opsMinimo,
        mem: ParametriArgon2.memMinima,
      ),
      cassaforte: cassaforte,
    );

    test('sblocco rapido dopo il blocco e dopo il riavvio', () async {
      final sessione = nuovaSessione();
      await sessione.avvia();
      await sessione.preparaNuovoArchivio('Password-Lunga-1');
      await sessione.confermaNuovoArchivio();
      expect(sessione.prendiPropostaAttivazione(), isTrue);
      expect(sessione.prendiPropostaAttivazione(), isFalse);
      await sessione.attivaSbloccoRapido();

      // Lucchetto toccato a mano: la verifica non parte da sola.
      await sessione.blocca();
      expect(sessione.prendiAvvioSbloccoRapido(), isFalse);
      expect(await sessione.sbloccaRapido(), isTrue);
      expect(sessione.fase, FaseSessione.sbloccata);

      // Blocco automatico: parte da sola.
      await sessione.blocca(automatico: true);
      expect(sessione.prendiAvvioSbloccoRapido(), isTrue);
      await sessione.blocca();
      sessione.dispose();

      // Riavvio dell'app.
      final riavviata = nuovaSessione();
      await riavviata.avvia();
      expect(riavviata.fase, FaseSessione.bloccata);
      expect(riavviata.prendiAvvioSbloccoRapido(), isTrue);
      expect(riavviata.sicurezza.rapidoPronto, isTrue);
      expect(await riavviata.sbloccaRapido(), isTrue);
      expect(riavviata.fase, FaseSessione.sbloccata);
      // Con lo sblocco rapido attivo non si propone di attivarlo.
      expect(riavviata.prendiPropostaAttivazione(), isFalse);
      await riavviata.blocca();
      riavviata.dispose();
    });

    test('con la password si azzera il conto dei 14 giorni', () async {
      final sessione = nuovaSessione();
      await sessione.avvia();
      await sessione.preparaNuovoArchivio('Password-Lunga-1');
      await sessione.confermaNuovoArchivio();
      await sessione.attivaSbloccoRapido();
      await sessione.blocca();
      await sessione.sblocca('Password-Lunga-1');
      expect(sessione.sicurezza.rapidoPronto, isTrue);
      await sessione.blocca();
      sessione.dispose();
    });
  });
}
