import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/core/versione.dart';
import 'package:gestionale_finanziaria/features/comuni/errori.dart';

void main() {
  testWidgets('errore imprevisto: i dettagli dicono la versione', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => mostraErroreImprevisto(
              context,
              StateError('prova'),
              StackTrace.current,
            ),
            child: const Text('Apri'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    expect(find.text('Qualcosa è andato storto'), findsOneWidget);
    await tester.tap(find.text('Dettagli tecnici'));
    await tester.pumpAndSettle();
    // Servono per decodificare l'elenco delle chiamate con i simboli giusti.
    expect(
      find.textContaining('GestionaleFinanziaria ${Versione.firma}'),
      findsOneWidget,
    );
    expect(find.textContaining('StateError'), findsOneWidget);
  });
}
