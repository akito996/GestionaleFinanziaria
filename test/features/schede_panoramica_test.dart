import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/features/home/schede_panoramica.dart';

void main() {
  test("predefinita: tutte le schede, nell'ordine standard", () {
    final c = ConfigurazionePanoramica.leggi(null);
    expect(c.visibili, SchedaPanoramica.values);
  });

  test('ordine e schede nascoste si salvano e si rileggono', () {
    final c = ConfigurazionePanoramica(
      [
        SchedaPanoramica.movimenti,
        ...SchedaPanoramica.values.where(
          (s) => s != SchedaPanoramica.movimenti,
        ),
      ],
      {SchedaPanoramica.flusso},
    );
    final testo = c.scrivi();
    expect(testo, startsWith('movimenti,'));
    expect(testo, contains('-flusso'));
    final riletta = ConfigurazionePanoramica.leggi(testo);
    expect(riletta.ordine, c.ordine);
    expect(riletta.visibili, isNot(contains(SchedaPanoramica.flusso)));
  });

  test('schede sconosciute ignorate, schede nuove in fondo e visibili', () {
    final c = ConfigurazionePanoramica.leggi(
      'spese,vecchia_scheda,-costo_vita',
    );
    expect(c.ordine.first, SchedaPanoramica.spese);
    expect(c.ordine[1], SchedaPanoramica.costoVita);
    expect(c.nascoste, {SchedaPanoramica.costoVita});
    expect(c.ordine, hasLength(SchedaPanoramica.values.length));
    expect(c.visibili, contains(SchedaPanoramica.entrateUscite));
  });
}
