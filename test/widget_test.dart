// Basic Flutter widget test for CardVault app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:card_vault/features/auth/login_page.dart';

void main() {
  testWidgets('Login page builds and shows CardVault and Login button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );

    expect(find.text('CardVault'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
