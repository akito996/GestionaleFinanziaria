import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/condivisi/identita_persona.dart';
import 'package:sodium/sodium_sumo.dart';

/// Chiavi della persona dei portafogli condivisi (ADR-019).
void main() {
  late SodiumSumo sodium;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  SecureKey chiaveDati(int byte) =>
      SecureKey.fromList(sodium, Uint8List.fromList(List.filled(32, byte)));

  test('stesse chiavi su ogni dispositivo dello stesso archivio', () {
    final pc = IdentitaPersona.daChiaveDati(sodium, chiaveDati(1));
    final telefono = IdentitaPersona.daChiaveDati(sodium, chiaveDati(1));
    final altro = IdentitaPersona.daChiaveDati(sodium, chiaveDati(2));
    expect(pc.pubblicaScambio, telefono.pubblicaScambio);
    expect(pc.pubblicaFirma, telefono.pubblicaFirma);
    expect(pc.pubblicaScambio, isNot(altro.pubblicaScambio));
    expect(pc.pubblicaFirma, isNot(altro.pubblicaFirma));
    expect(pc.pubblicaScambio, hasLength(32));
    expect(pc.pubblicaFirma, hasLength(32));
  });

  test('firma: valida solo per il messaggio e la persona giusti', () {
    final io = IdentitaPersona.daChiaveDati(sodium, chiaveDati(1));
    final altro = IdentitaPersona.daChiaveDati(sodium, chiaveDati(2));
    final messaggio = Uint8List.fromList(utf8.encode('pacchetto 1'));
    final firma = io.firma(messaggio);
    expect(
      IdentitaPersona.firmaValida(
        sodium,
        messaggio: messaggio,
        firma: firma,
        pubblicaFirma: io.pubblicaFirma,
      ),
      isTrue,
    );
    expect(
      IdentitaPersona.firmaValida(
        sodium,
        messaggio: Uint8List.fromList(utf8.encode('pacchetto 2')),
        firma: firma,
        pubblicaFirma: io.pubblicaFirma,
      ),
      isFalse,
    );
    expect(
      IdentitaPersona.firmaValida(
        sodium,
        messaggio: messaggio,
        firma: firma,
        pubblicaFirma: altro.pubblicaFirma,
      ),
      isFalse,
    );
  });

  test('chiave del portafoglio sigillata: la apre solo il destinatario', () {
    final membro = IdentitaPersona.daChiaveDati(sodium, chiaveDati(3));
    final intruso = IdentitaPersona.daChiaveDati(sodium, chiaveDati(4));
    final chiavePortafoglio = Uint8List.fromList(List.generate(32, (i) => i));
    final sigillata = IdentitaPersona.sigillaPer(
      sodium,
      segreto: chiavePortafoglio,
      pubblicaScambio: membro.pubblicaScambio,
    );
    expect(membro.apri(sigillata), chiavePortafoglio);
    expect(() => intruso.apri(sigillata), throwsA(isA<SodiumException>()));
  });

  test('codice di sicurezza: uguale per tutti e due, diverso con altri', () {
    final a = IdentitaPersona.daChiaveDati(sodium, chiaveDati(5));
    final b = IdentitaPersona.daChiaveDati(sodium, chiaveDati(6));
    final c = IdentitaPersona.daChiaveDati(sodium, chiaveDati(7));
    ({Uint8List scambio, Uint8List firma}) pubbliche(IdentitaPersona p) =>
        (scambio: p.pubblicaScambio, firma: p.pubblicaFirma);
    final ab = IdentitaPersona.codiceSicurezza(
      sodium,
      pubbliche(a),
      pubbliche(b),
    );
    final ba = IdentitaPersona.codiceSicurezza(
      sodium,
      pubbliche(b),
      pubbliche(a),
    );
    final ac = IdentitaPersona.codiceSicurezza(
      sodium,
      pubbliche(a),
      pubbliche(c),
    );
    expect(ab, ba);
    expect(ab, isNot(ac));
    expect(ab, matches(RegExp(r'^(\d{5} ){11}\d{5}$')));
  });
}
