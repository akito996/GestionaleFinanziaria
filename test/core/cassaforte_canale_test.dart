import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/sicurezza/cassaforte.dart';

/// Il canale con Android e Windows (ADR-016). Sul dispositivo vero i byte
/// che arrivano dal sistema sono di sola lettura: cancellarli dopo l'uso
/// fermava l'attivazione dello sblocco rapido ("Cannot modify an
/// unmodifiable list", 16/10/2026).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const nome = 'gestionale/sblocco_rapido';
  final messaggero =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    // Risposta del "sistema" in sola lettura, come sul dispositivo.
    messaggero.setMockMessageHandler(nome, (_) async {
      final risposta = const StandardMethodCodec().encodeSuccessEnvelope({
        'materiale': Uint8List.fromList(List.filled(32, 7)),
        'dati': Uint8List.fromList([1, 2, 3]),
      });
      return risposta.asUnmodifiableView();
    });
  });

  tearDown(() => messaggero.setMockMessageHandler(nome, null));

  test('i byte del sistema arrivano in sola lettura', () async {
    final grezzo = await const MethodChannel(nome)
        .invokeMapMethod<String, Object?>('attiva');
    final materiale = grezzo!['materiale']! as Uint8List;
    expect(() => materiale.fillRange(0, 1, 0), throwsUnsupportedError);
  });

  test('la cassaforte li copia: si possono cancellare dopo l\'uso', () async {
    final cassaforte = CassaforteDiPiattaforma();
    final attivata = await cassaforte.attiva(Uint8List(32));
    expect(attivata.materiale, List.filled(32, 7));
    attivata.materiale.fillRange(0, 32, 0);
    expect(attivata.materiale, List.filled(32, 0));

    final letto = await cassaforte.leggi(Uint8List(32), attivata.dati);
    letto.fillRange(0, letto.length, 0);
    expect(letto, List.filled(32, 0));
  });
}
