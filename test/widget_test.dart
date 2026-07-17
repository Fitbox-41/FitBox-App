import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbox/src/app.dart';
import 'package:fitbox/src/presentation/widgets/glass.dart';

void main() {
  setUp(() {
    // No stored session, onboarding already seen → the app lands on login.
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'onboarding_seen': 'true',
    });
  });

  testWidgets('Signed-out start shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FitBoxApp()));

    // First frame is the splash (logo + spinner).
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Once the (empty) session is checked, it redirects to login.
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.widgetWithText(GlowButton, 'Log in'), findsOneWidget);
  });
}
