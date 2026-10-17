import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Il modello preciso per leggere le foto in italiano (ADR-012, scelta
/// Prestazione del 17/10/2026). Nell'app c'è quello veloce (2,7 MB), che
/// funziona subito anche senza Internet; quello preciso (8,9 MB) si scarica
/// la prima volta che si legge una foto e da lì si usa sempre.
///
/// Si scarica da una versione fissata di Tesseract su GitHub e si installa
/// solo se l'impronta SHA-256 è quella attesa.
class ModelloPreciso {
  ModelloPreciso({
    required this._cartella,
    http.Client Function()? client,
    this.impronta = improntaUfficiale,
  }) : _client = client ?? http.Client.new;

  static final indirizzo = Uri.https(
    'raw.githubusercontent.com',
    '/tesseract-ocr/tessdata_best/4.1.0/ita.traineddata',
  );
  static const improntaUfficiale =
      '8df9c89176fb93f56bf4b2d4ede04c01c1f31d4b7697fbd76cc336df700f3f38';

  /// SHA-256 atteso (diverso solo nei test).
  final String impronta;

  /// Peso da scaricare, per i messaggi.
  static const pesoMb = 8.9;

  final Future<Directory> Function() _cartella;
  final http.Client Function() _client;

  Future<void>? _scaricamento;
  bool _pronto = false;

  /// Già installato (dopo [pronto] o [prepara]).
  bool get disponibile => _pronto;

  /// In corso di scaricamento.
  bool get inArrivo => _scaricamento != null;

  Future<Directory> _radice() async =>
      Directory('${(await _cartella()).path}/modello_lettura');

  Future<File> _file() async =>
      File('${(await _radice()).path}/tessdata/ita.traineddata');

  /// La cartella del modello (con dentro `tessdata/ita.traineddata`), o
  /// `null` se non c'è ancora. Con [attesa] aspetta un po' uno scaricamento
  /// già partito.
  Future<String?> pronto({Duration attesa = Duration.zero}) async {
    final inCorso = _scaricamento;
    if (inCorso != null && attesa > Duration.zero) {
      await inCorso.timeout(attesa, onTimeout: () {});
    }
    try {
      if (!_pronto && (await _file()).existsSync()) {
        _pronto = true;
      }
      return _pronto ? (await _radice()).path : null;
    } on Object {
      return null;
    }
  }

  /// Scarica e installa il modello, se manca. Una volta sola anche se
  /// chiamato più volte; gli errori (niente rete, impronta diversa) non
  /// fermano niente: si riprova alla prossima foto.
  Future<void> prepara() {
    if (_pronto) {
      return Future.value();
    }
    return _scaricamento ??= _scarica().whenComplete(
      () => _scaricamento = null,
    );
  }

  Future<void> _scarica() async {
    try {
      final file = await _file();
      if (file.existsSync()) {
        _pronto = true;
        return;
      }
      await file.parent.create(recursive: true);
      // Le versioni precedenti dell'app avevano questo stesso modello
      // nell'APK e lo copiavano qui: si riusa senza scaricarlo.
      final vecchio = File(
        '${(await _cartella()).path}/tesseract/tessdata/ita.traineddata',
      );
      final dati =
          vecchio.existsSync() &&
              sha256.convert(await vecchio.readAsBytes()).toString() == impronta
          ? await vecchio.readAsBytes()
          : await _daInternet();
      if (dati == null) {
        return;
      }
      final temporaneo = File('${file.path}.tmp');
      await temporaneo.writeAsBytes(dati, flush: true);
      await temporaneo.rename(file.path);
      _pronto = true;
    } on Object catch (e) {
      debugPrint('Modello di lettura preciso non installato: $e');
    }
  }

  /// I byte scaricati, solo se l'impronta è quella attesa.
  Future<Uint8List?> _daInternet() async {
    final client = _client();
    try {
      final risposta = await client
          .get(indirizzo)
          .timeout(const Duration(minutes: 3));
      if (risposta.statusCode != 200) {
        debugPrint('Modello di lettura: risposta ${risposta.statusCode}');
        return null;
      }
      final dati = risposta.bodyBytes;
      if (sha256.convert(dati).toString() != impronta) {
        debugPrint('Modello di lettura: impronta diversa, scartato');
        return null;
      }
      return dati;
    } finally {
      client.close();
    }
  }
}
