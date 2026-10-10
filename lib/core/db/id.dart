import 'dart:math';

final Random _casuale = Random.secure();

/// UUID v4 (RFC 9562) da generatore crittografico.
String nuovoId() {
  final b = List<int>.generate(16, (_) => _casuale.nextInt(256));
  b[6] = (b[6] & 0x0F) | 0x40;
  b[8] = (b[8] & 0x3F) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}
