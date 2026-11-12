import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balkan_connect/auth_page.dart';

void main() {
  testWidgets('Invalid email is rejected before contacting the server', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthPage()));
    await tester.enterText(find.byType(TextField).at(0), 'invalid-email');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });
  testWidgets('Password visibility can be toggled', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthPage()));
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      isFalse,
    );
  });
}
