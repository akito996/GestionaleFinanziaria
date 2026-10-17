import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/condivisi/invito.dart';

/// Link d'invito ai portafogli condivisi (ADR-019).
void main() {
  final invito = InvitoCondiviso(
    cartellaId: 'cartella_1',
    registroId: 'registro-2',
    fileId: 'file3',
    portafoglio: 'Casa e spese',
    da: 'prop@example.com',
    scadenza: DateTime.utc(2026, 10, 17, 13),
  );

  test('link della pagina: i dati dopo il "#", si rileggono uguali', () {
    final link = invito.link;
    expect(link.toString(), startsWith('${InvitoCondiviso.pagina}#'));
    expect(link.query, isEmpty); // niente dati al server
    final letto = InvitoCondiviso.daLink(link.toString())!;
    expect(letto.cartellaId, 'cartella_1');
    expect(letto.registroId, 'registro-2');
    expect(letto.fileId, 'file3');
    expect(letto.portafoglio, 'Casa e spese');
    expect(letto.da, 'prop@example.com');
    expect(letto.scadenza, DateTime.utc(2026, 10, 17, 13));
  });

  test('link dell\'app (wallecy://invito) e testo incollato con spazi', () {
    final app = invito.linkApp.toString();
    expect(app, startsWith('wallecy://invito?'));
    expect(InvitoCondiviso.daLink('  $app \n')!.registroId, 'registro-2');
  });

  test('link non validi: niente invito', () {
    for (final testo in [
      '',
      'ciao',
      'https://example.com/',
      '${InvitoCondiviso.pagina}#c=solo-cartella',
      '${InvitoCondiviso.pagina}#c=a/b&r=x',
      'wallecy://invito?c=uno&r=due%27%20OR%201',
    ]) {
      expect(InvitoCondiviso.daLink(testo), isNull, reason: testo);
    }
  });

  test('scadenza', () {
    expect(invito.scadutoAlle(DateTime.utc(2026, 10, 17, 12, 59)), isFalse);
    expect(invito.scadutoAlle(DateTime.utc(2026, 10, 17, 13)), isTrue);
  });
}
