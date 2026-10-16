import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Cosa offre il dispositivo per lo sblocco rapido.
enum DisponibilitaCassaforte {
  /// Impronta, viso o PIN (Android) / Windows Hello pronti.
  pronta,

  /// Il dispositivo lo permette ma non c'è nulla di configurato (nessuna
  /// impronta né blocco schermo, Windows Hello spento).
  nessunMetodo,

  /// Il dispositivo non lo permette (o piattaforma senza sblocco rapido).
  nonSupportata,
}

/// Materiale segreto rilasciato dal dispositivo dopo la verifica dell'utente,
/// più i dati da conservare per la volta successiva (vuoti su Windows).
typedef MaterialeCassaforte = ({Uint8List materiale, Uint8List dati});

/// Verifica annullata dall'utente: si resta sulla password.
final class VerificaAnnullata implements Exception {
  const VerificaAnnullata();
}

/// Troppi tentativi sbagliati: il dispositivo ha bloccato la verifica.
final class VerificaBloccata implements Exception {
  const VerificaBloccata();
}

/// La chiave del dispositivo non c'è più (es. blocco schermo tolto, impronte
/// cambiate): serve la password e poi si riattiva lo sblocco rapido.
final class ChiaveDispositivoAnnullata implements Exception {
  const ChiaveDispositivoAnnullata();
}

/// Altro errore del dispositivo, con il dettaglio tecnico.
final class ErroreCassaforte implements Exception {
  const ErroreCassaforte(this.dettaglio);

  final String dettaglio;

  @override
  String toString() => 'Sblocco rapido: $dettaglio';
}

/// La "cassaforte" del dispositivo (ADR-016): Android Keystore con impronta,
/// viso o PIN del telefono; Windows Hello sul PC. Rilascia un segreto solo
/// dopo la verifica dell'utente: l'app ne ricava la chiave che apre
/// l'archivio.
abstract interface class CassaforteDispositivo {
  Future<DisponibilitaCassaforte> disponibilita();

  /// `true` se oltre a impronta e viso vale anche il PIN del dispositivo.
  bool get conPin;

  /// Crea una chiave nuova (al posto della vecchia) e restituisce il segreto.
  /// [sfida]: dati casuali che Windows Hello firma (Android li ignora).
  Future<MaterialeCassaforte> attiva(Uint8List sfida);

  /// Lo stesso segreto di [attiva], dopo una nuova verifica.
  Future<Uint8List> leggi(Uint8List sfida, Uint8List dati);

  Future<void> disattiva();
}

/// Implementazione nativa: `SbloccoRapido.kt` (Android) e
/// `windows/runner/sblocco_rapido.cpp` (Windows).
class CassaforteDiPiattaforma implements CassaforteDispositivo {
  CassaforteDiPiattaforma();

  static const _canale = MethodChannel('gestionale/sblocco_rapido');

  static bool get _supportata =>
      !kIsWeb && (Platform.isAndroid || Platform.isWindows);

  bool _conPin = true;

  @override
  bool get conPin => _conPin;

  @override
  Future<DisponibilitaCassaforte> disponibilita() async {
    if (!_supportata) {
      return DisponibilitaCassaforte.nonSupportata;
    }
    try {
      // Il sistema risponde subito; se non lo fa, niente sblocco rapido.
      final risposta = await _canale
          .invokeMapMethod<String, Object?>('disponibilita')
          .timeout(const Duration(seconds: 10));
      _conPin = risposta?['pin'] != false;
      return switch (risposta?['stato']) {
        'pronta' => DisponibilitaCassaforte.pronta,
        'nessunMetodo' => DisponibilitaCassaforte.nessunMetodo,
        _ => DisponibilitaCassaforte.nonSupportata,
      };
    } on MissingPluginException {
      return DisponibilitaCassaforte.nonSupportata;
    } on PlatformException {
      return DisponibilitaCassaforte.nonSupportata;
    } on TimeoutException {
      return DisponibilitaCassaforte.nonSupportata;
    }
  }

  // I byte che arrivano dal canale sono di sola lettura: se ne fa una copia
  // normale, che chi la usa può cancellare dopo l'uso.
  @override
  Future<MaterialeCassaforte> attiva(Uint8List sfida) async {
    final risposta = await _chiama('attiva', {'sfida': sfida});
    return (
      materiale: Uint8List.fromList(risposta['materiale']! as Uint8List),
      dati: Uint8List.fromList(risposta['dati']! as Uint8List),
    );
  }

  @override
  Future<Uint8List> leggi(Uint8List sfida, Uint8List dati) async {
    final risposta = await _chiama('leggi', {'sfida': sfida, 'dati': dati});
    return Uint8List.fromList(risposta['materiale']! as Uint8List);
  }

  @override
  Future<void> disattiva() async {
    if (!_supportata) {
      return;
    }
    try {
      await _canale.invokeMethod<void>('disattiva');
    } on PlatformException catch (e) {
      debugPrint('Sblocco rapido non disattivato: $e');
    }
  }

  Future<Map<String, Object?>> _chiama(
    String metodo,
    Map<String, Object?> argomenti,
  ) async {
    try {
      final risposta = await _canale.invokeMapMethod<String, Object?>(
        metodo,
        argomenti,
      );
      if (risposta == null) {
        throw const ErroreCassaforte('nessuna risposta');
      }
      return risposta;
    } on PlatformException catch (e) {
      throw switch (e.code) {
        'annullato' => const VerificaAnnullata(),
        'bloccato' => const VerificaBloccata(),
        'invalidata' => const ChiaveDispositivoAnnullata(),
        _ => ErroreCassaforte(e.message ?? e.code),
      };
    }
  }
}
