import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Riquadro in pixel della foto (già raddrizzata).
@immutable
class Riquadro {
  const Riquadro(this.sinistra, this.sopra, this.destra, this.sotto);

  final int sinistra;
  final int sopra;
  final int destra;
  final int sotto;

  int get altezza => sotto - sopra;
  int get larghezza => destra - sinistra;

  /// Allargato di un margine (per non tagliare le lettere), dentro la foto.
  Riquadro allargato({
    required int larghezzaFoto,
    required int altezzaFoto,
    double verticale = 0.35,
    double orizzontale = 0.02,
    bool tuttaLaRiga = false,
  }) {
    final dy = (altezza * verticale).round();
    final dx = (larghezzaFoto * orizzontale).round();
    return Riquadro(
      tuttaLaRiga ? 0 : (sinistra - dx).clamp(0, larghezzaFoto),
      (sopra - dy).clamp(0, altezzaFoto),
      tuttaLaRiga ? larghezzaFoto : (destra + dx).clamp(0, larghezzaFoto),
      (sotto + dy).clamp(0, altezzaFoto),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Riquadro &&
      other.sinistra == sinistra &&
      other.sopra == sopra &&
      other.destra == destra &&
      other.sotto == sotto;

  @override
  int get hashCode => Object.hash(sinistra, sopra, destra, sotto);
}

/// Una riga di testo letta, con la sua posizione e quanto è affidabile (0-100).
@immutable
class RigaLetta {
  const RigaLetta(this.testo, this.riquadro, {this.affidabilita = 0});

  final String testo;
  final Riquadro riquadro;
  final double affidabilita;
}

/// Prima lettura: tutta la foto.
@immutable
class FotoLetta {
  const FotoLetta({
    required this.larghezza,
    required this.altezza,
    required this.righe,
  });

  final int larghezza;
  final int altezza;
  final List<RigaLetta> righe;

  /// Tutto il testo, una riga per riga.
  String get testo => [for (final r in righe) r.testo].join('\n');
}

/// Seconda lettura: una zona ingrandita (lo "zoom"), con la sua immagine.
@immutable
class ZonaLetta {
  const ZonaLetta({
    required this.testo,
    required this.affidabilita,
    this.immagine,
  });

  final String testo;
  final double affidabilita;

  /// La zona ritagliata (PNG), per mostrarla all'utente.
  final Uint8List? immagine;
}

/// Legge il testo dalle foto, tutto sul dispositivo.
abstract interface class LettoreFoto {
  Future<FotoLetta> leggi(String percorso);

  /// Rilegge [zona] ingrandita. [riga] = una sola riga di testo.
  Future<ZonaLetta> zona(String percorso, Riquadro zona, {bool riga = true});

  /// Libera memoria e motore quando non servono più.
  Future<void> chiudi();
}

/// Su Android: Tesseract (open source) nell'app, vedi `LetturaFoto.kt`.
class LettoreFotoAndroid implements LettoreFoto {
  const LettoreFotoAndroid({this.modello});

  static const _canale = MethodChannel('gestionale/lettura_foto');

  /// La cartella del modello preciso, se c'è (altrimenti quello veloce
  /// dell'APK). Con `attesa` aspetta un po' uno scaricamento già partito.
  final Future<String?> Function({Duration attesa})? modello;

  @override
  Future<FotoLetta> leggi(String percorso) async {
    final cartella = await modello?.call(attesa: const Duration(seconds: 8));
    final r = (await _canale.invokeMapMethod<String, Object?>('leggi', {
      'percorso': percorso,
      'modello': ?cartella,
    }))!;
    return FotoLetta(
      larghezza: r['larghezza']! as int,
      altezza: r['altezza']! as int,
      righe: [
        for (final riga in (r['righe']! as List).cast<Map<Object?, Object?>>())
          RigaLetta(
            riga['testo']! as String,
            Riquadro(
              riga['sinistra']! as int,
              riga['sopra']! as int,
              riga['destra']! as int,
              riga['sotto']! as int,
            ),
            affidabilita: (riga['affidabilita']! as num).toDouble(),
          ),
      ],
    );
  }

  @override
  Future<ZonaLetta> zona(
    String percorso,
    Riquadro zona, {
    bool riga = true,
  }) async {
    final cartella = await modello?.call(attesa: Duration.zero);
    final r = (await _canale.invokeMapMethod<String, Object?>('zona', {
      'percorso': percorso,
      'modello': ?cartella,
      'sinistra': zona.sinistra,
      'sopra': zona.sopra,
      'destra': zona.destra,
      'sotto': zona.sotto,
      'riga': riga,
    }))!;
    return ZonaLetta(
      testo: r['testo']! as String,
      affidabilita: (r['affidabilita']! as num).toDouble(),
      immagine: r['immagine'] as Uint8List?,
    );
  }

  @override
  Future<void> chiudi() => _canale.invokeMethod<void>('chiudi');
}
