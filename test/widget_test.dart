import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbox/src/app.dart';

void main() {
  setUp(() {
    // No stored session, onboarding already seen → the app lands on the auth
    // landing (Sign In / Create Account).
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'onboarding_seen': 'true',
    });
  });

  testWidgets('Signed-out start shows the auth landing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FitBoxApp()));

    // First frame is the splash (logo + spinner).
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Let the (empty) session resolve and the router redirect. Pump without
    // settling — the hero carousel has an infinite auto-scroll timer, and we
    // stay under its 3s tick so it never starts an animation.
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
  });
}
