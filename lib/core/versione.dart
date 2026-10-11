/// Versione dell'app, mostrata come firma in ogni schermata.
abstract final class Versione {
  /// Deve coincidere con `version` di `pubspec.yaml` (lo verifica un test).
  static const numero = '0.1.0';

  /// Commit della build, passato dalla CI con `--dart-define=GF_COMMIT=<sha>`;
  /// vuoto nelle build locali e nei test.
  static const commit = String.fromEnvironment('GF_COMMIT');

  /// "v0.1.0 · 211d16a" (o solo "v0.1.0" senza commit).
  static String get firma => commit.isEmpty
      ? 'v$numero'
      : 'v$numero · ${commit.length > 7 ? commit.substring(0, 7) : commit}';
}
