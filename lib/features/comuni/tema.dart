import 'package:flutter/material.dart';

/// Tema "Blu fedele all'icona" (scelta dell'utente, proposta 1): i tre blu
/// dell'icona. Blu scuro sui pulsanti nel tema chiaro, azzurro in quello
/// scuro; schede bianche (o blu notte) con un bordo sottile.
abstract final class TemaWalleCy {
  /// I colori dell'icona.
  static const azzurroChiaro = Color(0xFF54C5F8);
  static const azzurro = Color(0xFF29B6F6);
  static const bluScuro = Color(0xFF01579B);

  static ThemeData chiaro() => _tema(
    ColorScheme.fromSeed(seedColor: bluScuro).copyWith(
      primary: bluScuro,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE1F3FD),
      onPrimaryContainer: bluScuro,
      secondary: const Color(0xFF0277BD),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFE1F3FD),
      onSecondaryContainer: bluScuro,
      surface: const Color(0xFFF6FAFE),
      onSurface: const Color(0xFF0B1D2B),
      onSurfaceVariant: const Color(0xFF4A6375),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Colors.white,
      surfaceContainer: const Color(0xFFEEF5FB),
      surfaceContainerHigh: const Color(0xFFE6F0F8),
      surfaceContainerHighest: const Color(0xFFDDE9F3),
      outline: const Color(0xFF8AA3B8),
      outlineVariant: const Color(0xFFD6E4EF),
    ),
  );

  static ThemeData scuro() => _tema(
    ColorScheme.fromSeed(
      seedColor: azzurroChiaro,
      brightness: Brightness.dark,
    ).copyWith(
      primary: azzurroChiaro,
      onPrimary: const Color(0xFF03263F),
      primaryContainer: const Color(0xFF1C3A52),
      onPrimaryContainer: const Color(0xFF9FDDFB),
      secondary: azzurro,
      onSecondary: const Color(0xFF03263F),
      secondaryContainer: const Color(0xFF1C3A52),
      onSecondaryContainer: const Color(0xFF9FDDFB),
      surface: const Color(0xFF0E1A24),
      onSurface: const Color(0xFFE3EEF7),
      onSurfaceVariant: const Color(0xFFA9C0D2),
      surfaceContainerLowest: const Color(0xFF0A141C),
      surfaceContainerLow: const Color(0xFF16283A),
      surfaceContainer: const Color(0xFF1A2E42),
      surfaceContainerHigh: const Color(0xFF1F3549),
      surfaceContainerHighest: const Color(0xFF253D53),
      outline: const Color(0xFF5E7A91),
      outlineVariant: const Color(0xFF23415A),
    ),
  );

  static ThemeData _tema(ColorScheme schema) => ThemeData(
    colorScheme: schema,
    useMaterial3: true,
    scaffoldBackgroundColor: schema.surface,
    // Schede piatte con un bordo sottile, come nella proposta.
    cardTheme: CardThemeData(
      elevation: 0,
      color: schema.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: schema.outlineVariant),
      ),
    ),
    // Ogni avviso in basso si può chiudere a mano con la "x".
    snackBarTheme: const SnackBarThemeData(showCloseIcon: true),
  );
}
