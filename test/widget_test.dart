import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbox/src/app.dart';

void main() {
  setUp(() {
    // No stored session → the app should land on the login screen.
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  testWidgets('Signed-out start shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FitBoxApp()));

    // First frame is the splash (logo + spinner).
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Once the (empty) session is checked, it redirects to login.
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
  });
}
