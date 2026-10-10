import 'package:flutter_test/flutter_test.dart';

import 'package:gestionale_finanziaria/app.dart';

void main() {
  testWidgets('la prima schermata mostra il nome dell\'app', (tester) async {
    await tester.pumpWidget(const GestionaleApp());

    expect(find.text('GestionaleFinanziaria'), findsOneWidget);
    expect(find.text('I tuoi conti, cifrati e solo tuoi.'), findsOneWidget);
  });
}
