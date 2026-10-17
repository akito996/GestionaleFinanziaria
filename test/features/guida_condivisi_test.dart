import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestionale_finanziaria/features/condivisi/guida_condivisi.dart';

void main() {
  testWidgets('guida: passi per chi condivide e per chi è invitato', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => apriGuidaCondivisi(context),
                child: const Text('Apri'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();

    // Proprietario: i passi numerati, con il menu ☰ e l'ora per accettare.
    expect(find.text('Portafogli condivisi: come si fa'), findsOneWidget);
    expect(find.textContaining('Condividi con altre persone'), findsOneWidget);
    expect(find.textContaining('Copia il link d\'invito'), findsWidgets);
    expect(find.text('5'), findsOneWidget);

    // Membro: accettare e scegliere tutti i file.
    await tester.tap(find.text('Mi hanno invitato'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Accetta'), findsWidgets);
    expect(
      find.textContaining('seleziona tutti i file proposti'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Se qualcosa non va'), 300);
    expect(find.textContaining('Invita di nuovo'), findsOneWidget);
    // I grassetti: "**" non compare mai nel testo.
    expect(find.textContaining('**'), findsNothing);
  });
}
