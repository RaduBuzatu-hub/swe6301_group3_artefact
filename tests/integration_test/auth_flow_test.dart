/// Integration tests for sign-in/sign-up flows using mock auth responses.
/// - Covers success paths and common FirebaseAuth errors.
/// - Uses a lightweight in-test app shell for navigation.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:swe6301_group3_artefact/screens/sign_in_page.dart';
import 'package:swe6301_group3_artefact/screens/sign_up_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sign-in success returns to home', (tester) async {
    final auth = MockFirebaseAuth(
      signedIn: false,
      mockUser: MockUser(uid: 'user-1', email: 'user@example.com'),
    );

    await tester.pumpWidget(_AuthTestApp(auth: auth));
    await _openSignIn(tester);

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth.home')), findsOneWidget);
  });

  testWidgets('sign-in invalid credentials show error message', (tester) async {
    final auth = MockFirebaseAuth(signedIn: false);
    // Simulate Firebase throwing a known auth error for invalid credentials.
    whenCalling(
      Invocation.method(
        #signInWithEmailAndPassword,
        null,
        {#email: anything, #password: anything},
      ),
    ).on(auth).thenThrow(FirebaseAuthException(code: 'wrong-password'));

    await tester.pumpWidget(_AuthTestApp(auth: auth));
    await _openSignIn(tester);

    await tester.enterText(find.byType(TextField).at(0), 'wrong@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'badpass');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets('sign-in network failure shows retry message', (tester) async {
    final auth = MockFirebaseAuth(signedIn: false);
    // Simulate connectivity failures during sign-in.
    whenCalling(
      Invocation.method(
        #signInWithEmailAndPassword,
        null,
        {#email: anything, #password: anything},
      ),
    ).on(auth).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

    await tester.pumpWidget(_AuthTestApp(auth: auth));
    await _openSignIn(tester);

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(
      find.text('No network connection. Check your internet and try again.'),
      findsOneWidget,
    );
  });

  testWidgets('sign-up success returns to home', (tester) async {
    final auth = MockFirebaseAuth(signedIn: false);

    await tester.pumpWidget(_AuthTestApp(auth: auth));
    await _openSignUp(tester);

    await tester.enterText(find.byType(TextField).at(0), 'Test User');
    await tester.enterText(find.byType(TextField).at(1), 'new@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth.home')), findsOneWidget);
  });

  testWidgets('sign-up duplicate email shows error message', (tester) async {
    final auth = MockFirebaseAuth(signedIn: false);
    // Simulate Firebase throwing a duplicate-email error on sign-up.
    whenCalling(
      Invocation.method(
        #createUserWithEmailAndPassword,
        null,
        {#email: anything, #password: anything},
      ),
    ).on(auth).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

    await tester.pumpWidget(_AuthTestApp(auth: auth));
    await _openSignUp(tester);

    await tester.enterText(find.byType(TextField).at(0), 'Test User');
    await tester.enterText(find.byType(TextField).at(1), 'dup@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();

    expect(
      find.text('An account already exists for that email.'),
      findsOneWidget,
    );
  });
}

// Helper to open the sign-in page via the test home UI.
Future<void> _openSignIn(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('auth.openSignIn')));
  await tester.pumpAndSettle();
  expect(find.widgetWithText(ElevatedButton, 'Sign in'), findsOneWidget);
}

// Helper to open the sign-up page via the test home UI.
Future<void> _openSignUp(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('auth.openSignUp')));
  await tester.pumpAndSettle();
  expect(find.text('Create account'), findsOneWidget);
}

/// Minimal app wrapper used by auth integration tests.
class _AuthTestApp extends StatelessWidget {
  final FirebaseAuth auth;
  const _AuthTestApp({required this.auth});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _AuthHome(auth: auth),
    );
  }
}

/// Home screen for tests with buttons to open auth pages.
class _AuthHome extends StatelessWidget {
  final FirebaseAuth auth;
  const _AuthHome({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auth Test Home')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Auth Test Home', key: Key('auth.home')),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const Key('auth.openSignIn'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SignInPage(auth: auth),
                  ),
                );
              },
              child: const Text('Open Sign In'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const Key('auth.openSignUp'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SignUpPage(auth: auth),
                  ),
                );
              },
              child: const Text('Open Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
