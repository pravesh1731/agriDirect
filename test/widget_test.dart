// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:agri_direct/main.dart';
import 'package:agri_direct/features/authentication/screens/login/signIn.dart';

void main() {
  testWidgets('App builds and shows sign-in', (WidgetTester tester) async {
    // Build app wrapped in ProviderScope (MyApp is a ConsumerWidget)
    await tester.pumpWidget(ProviderScope(child: MyApp(initialScreen: const SignInScreen())));

    // Basic smoke: Sign in header present
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
