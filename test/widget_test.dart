import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbox/src/app.dart';

void main() {
  testWidgets('App boots to the Home tab', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FitBoxApp()));

    // The Home app bar renders immediately (before mock data resolves).
    expect(find.text('FitBox'), findsOneWidget);

    // Let the mocked futures complete so no timers stay pending.
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
