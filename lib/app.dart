import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Radice dell'app: tema, lingua italiana e prima schermata.
class GestionaleApp extends StatelessWidget {
  const GestionaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GestionaleFinanziaria',
      debugShowCheckedModeBanner: false,
      locale: const Locale('it', 'IT'),
      supportedLocales: const [Locale('it', 'IT')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B6E5A),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B6E5A),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const _Benvenuto(),
    );
  }
}

class _Benvenuto extends StatelessWidget {
  const _Benvenuto();

  @override
  Widget build(BuildContext context) {
    final testo = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 64),
              const SizedBox(height: 16),
              Text('GestionaleFinanziaria', style: testo.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'I tuoi conti, cifrati e solo tuoi.',
                style: testo.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
