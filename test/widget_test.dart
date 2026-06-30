import 'package:flutter_test/flutter_test.dart';

import 'package:fitbox/src/app.dart';

void main() {
  testWidgets('App shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(const FitBoxApp());

    expect(find.text('FitBox'), findsOneWidget);
  });
}
