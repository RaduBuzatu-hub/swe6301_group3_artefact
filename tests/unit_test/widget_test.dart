/// Widget test for the auth-required screen CTAs and key wiring.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swe6301_group3_artefact/screens/auth_required_page.dart';

void main() {
  testWidgets('Auth required page renders CTAs and benefits', (WidgetTester tester) async {
    var signInTapped = false;
    var registerTapped = false;

    // Fix viewport size so layout is deterministic for the test.
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: AuthRequiredPage(
          onSignIn: () => signInTapped = true,
          onRegister: () => registerTapped = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Ensure key elements are visible.
    expect(find.byKey(const Key('authRequired.title')), findsOneWidget);
    expect(find.byKey(const Key('authRequired.subtitle')), findsOneWidget);
    expect(find.byKey(const Key('authRequired.benefitCard')), findsOneWidget);
    expect(find.byKey(const Key('authRequired.signInButton')), findsOneWidget);
    expect(find.byKey(const Key('authRequired.registerButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('authRequired.signInButton')));
    await tester.tap(find.byKey(const Key('authRequired.registerButton')));

    expect(signInTapped, isTrue);
    expect(registerTapped, isTrue);
  });
}
