import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/sessione.dart';
import 'features/home/home_pagina.dart';
import 'features/primo_avvio/primo_avvio_pagina.dart';
import 'features/sblocco/sblocco_pagina.dart';

/// Radice dell'app: tema, lingua italiana e schermata in base allo stato della [sessione].
class GestionaleApp extends StatelessWidget {
  const GestionaleApp({super.key, required this.sessione});

  final Sessione sessione;

  static const _colore = Color(0xFF1B6E5A);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GestionaleFinanziaria',
      debugShowCheckedModeBanner: false,
      locale: const Locale('it', 'IT'),
      supportedLocales: const [Locale('it', 'IT')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(colorSchemeSeed: _colore, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: _colore,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: ListenableBuilder(
        listenable: sessione,
        builder: (context, _) => switch (sessione.fase) {
          FaseSessione.caricamento => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          FaseSessione.primoAvvio => PrimoAvvioPagina(sessione: sessione),
          FaseSessione.bloccata => SbloccoPagina(sessione: sessione),
          FaseSessione.sbloccata => HomePagina(sessione: sessione),
        },
      ),
    );
  }
}
