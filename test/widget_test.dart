// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ninja_clicker/main.dart';

void main() {
  testWidgets('shows firebase error screen when init fails',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MyApp(firebaseInitialized: false, firebaseError: 'Erreur mock'),
    );

    expect(find.text('Erreur d\'initialisation Firebase'), findsOneWidget);
    expect(find.textContaining('Erreur mock'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
