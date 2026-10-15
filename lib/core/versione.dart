import 'package:flutter/services.dart' show appFlavor;

/// Versione dell'app, mostrata come firma in ogni schermata.
abstract final class Versione {
  /// Deve coincidere con `version` di `pubspec.yaml` (lo verifica un test).
  static const numero = '0.9.0';

  /// Commit della build, passato dalla CI con `--dart-define=GF_COMMIT=<sha>`;
  /// vuoto nelle build locali e nei test.
  static const commit = String.fromEnvironment('GF_COMMIT');

  /// Variante Android "prova" (installabile accanto a quella ufficiale).
  static bool get prova => appFlavor == 'prova';

  /// "v0.9.0 · 211d16a" (o solo "v0.9.0" senza commit), "· prova" nella
  /// variante di prova.
  static String get firma => [
    'v$numero',
    if (commit.isNotEmpty) commit.length > 7 ? commit.substring(0, 7) : commit,
    if (prova) 'prova',
  ].join(' · ');
}
