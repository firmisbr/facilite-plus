import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:facilite_plus/features/splash/presentation/pages/splash_page.dart';

void main() {
  testWidgets('Splash exibe título do app', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashPage()),
    );

    expect(find.text('Facilite Plus'), findsOneWidget);
  });
}
