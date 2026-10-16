import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/sessione.dart';
import 'features/comuni/navigazione.dart';
import 'features/primo_avvio/primo_avvio_pagina.dart';
import 'features/sblocco/sblocco_pagina.dart';
import 'features/comuni/firma_versione.dart';
import 'core/identita.dart';

/// Radice dell'app: tema, lingua italiana e schermata in base allo stato della [sessione].
class GestionaleApp extends StatefulWidget {
  const GestionaleApp({super.key, required this.sessione});

  final Sessione sessione;

  @override
  State<GestionaleApp> createState() => _GestionaleAppState();
}

class _GestionaleAppState extends State<GestionaleApp> {
  static const _colore = Color(0xFF1B6E5A);
  final _navigatore = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    widget.sessione.addListener(_alCambioFase);
  }

  @override
  void dispose() {
    widget.sessione.removeListener(_alCambioFase);
    super.dispose();
  }

  /// Archivio bloccato: si chiudono tutte le pagine aperte sopra la principale
  /// (dettagli, moduli), così nessun dato resta visibile sopra lo sblocco.
  void _alCambioFase() {
    if (widget.sessione.fase != FaseSessione.sbloccata) {
      _navigatore.currentState?.popUntil((rotta) => rotta.isFirst);
    }
  }

  /// Ogni avviso in basso si può chiudere a mano con la "x" (accanto ad
  /// "Annulla", se c'è).
  static const _avvisi = SnackBarThemeData(showCloseIcon: true);

  @override
  Widget build(BuildContext context) {
    final sessione = widget.sessione;
    return ListenableBuilder(
      listenable: sessione.preferenze,
      builder: (context, _) => _app(sessione),
    );
  }

  Widget _app(Sessione sessione) {
    return MaterialApp(
      navigatorKey: _navigatore,
      title: Identita.nome,
      debugShowCheckedModeBanner: false,
      // Chiaro, scuro o come il sistema (Impostazioni › Aspetto).
      themeMode: sessione.preferenze.tema,
      locale: const Locale('it', 'IT'),
      supportedLocales: const [Locale('it', 'IT')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorSchemeSeed: _colore,
        useMaterial3: true,
        snackBarTheme: _avvisi,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: _colore,
        brightness: Brightness.dark,
        useMaterial3: true,
        snackBarTheme: _avvisi,
      ),
      // La versione, come una firma, solo all'apertura (poi sfuma).
      builder: (context, child) => Stack(
        children: [
          ?child,
          Positioned.fill(child: FirmaIniziale(sessione: sessione)),
        ],
      ),
      home: ListenableBuilder(
        listenable: sessione,
        builder: (context, _) => switch (sessione.fase) {
          FaseSessione.caricamento => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          FaseSessione.primoAvvio => PrimoAvvioPagina(sessione: sessione),
          FaseSessione.bloccata => SbloccoPagina(sessione: sessione),
          FaseSessione.sbloccata => Guscio(sessione: sessione),
        },
      ),
    );
  }
}
