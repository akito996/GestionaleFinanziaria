import 'dart:convert';
import 'dart:typed_data';

/// Tipo di dato cifrato: entra nell'AAD, così un blob di un tipo non può essere
/// fatto passare per un altro (es. un allegato al posto di un pacchetto di modifiche).
enum TipoDato {
  evento(1),
  snapshot(2),
  allegato(3),
  manifest(4);

  const TipoDato(this.codice);

  /// Valore scritto nell'AAD: non cambiarlo mai per i tipi esistenti.
  final int codice;
}

/// Dati autenticati (AAD) = tipo | utente | dispositivo | sequenza (ADR-001).
///
/// Anti-manomissione e anti-replay: un blob decifra solo con lo stesso utente,
/// lo stesso dispositivo autore e lo stesso numero di sequenza.
/// Codifica senza ambiguità: ogni testo è preceduto dalla sua lunghezza.
Uint8List aadPer({
  required TipoDato tipo,
  required String utenteId,
  required String dispositivoId,
  required int sequenza,
}) {
  if (sequenza < 0) {
    throw ArgumentError.value(sequenza, 'sequenza', 'deve essere >= 0');
  }
  final numero = ByteData(8)..setUint64(0, sequenza);
  return (BytesBuilder(copy: false)
        ..addByte(tipo.codice)
        ..add(_conLunghezza(utenteId))
        ..add(_conLunghezza(dispositivoId))
        ..add(numero.buffer.asUint8List()))
      .toBytes();
}

Uint8List _conLunghezza(String testo) {
  final byte = utf8.encode(testo);
  if (byte.length > 0xFFFF) {
    throw ArgumentError.value(testo, 'testo', 'troppo lungo');
  }
  final lunghezza = ByteData(2)..setUint16(0, byte.length);
  return (BytesBuilder(copy: false)
        ..add(lunghezza.buffer.asUint8List())
        ..add(byte))
      .toBytes();
}
