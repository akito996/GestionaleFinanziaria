import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/features/comuni/avvisi.dart';

void main() {
  testWidgets('avviso con "Annulla": sparisce da solo dopo 5 secondi', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          snackBarTheme: const SnackBarThemeData(showCloseIcon: true),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                avviso(
                  content: const Text('Movimento eliminato'),
                  action: SnackBarAction(label: 'Annulla', onPressed: () {}),
                ),
              ),
              child: const Text('Elimina'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Elimina'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Movimento eliminato'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget); // si chiude anche a mano

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Movimento eliminato'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Movimento eliminato'), findsNothing);
  });
}
