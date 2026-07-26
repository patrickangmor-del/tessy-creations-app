import 'package:flutter_test/flutter_test.dart';

import 'package:tessy_creations/main.dart';

void main() {
  testWidgets('App launches showing the four Phase 1 tabs', (tester) async {
    await tester.pumpWidget(const TessyApp());
    await tester.pumpAndSettle();

    expect(find.text('Tessy Creations'), findsOneWidget);
    expect(find.text('Customers'), findsWidgets);
    expect(find.text('Orders'), findsWidgets);
    expect(find.text('Calendar'), findsWidgets);
    expect(find.text('Finances'), findsWidgets);
  });

  testWidgets('Tapping a nav destination switches tabs', (tester) async {
    await tester.pumpWidget(const TessyApp());
    await tester.pumpAndSettle();

    expect(find.text('Orders module coming up next'), findsNothing);
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(find.text('Orders module coming up next'), findsOneWidget);
  });
}
