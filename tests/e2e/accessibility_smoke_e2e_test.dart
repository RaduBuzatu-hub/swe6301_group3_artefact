/// Accessibility smoke E2E: text scaling, button contrast, and overflow checks.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:swe6301_group3_artefact/data/eco_locations.dart';
import 'package:swe6301_group3_artefact/models/trip_entry.dart';
import 'package:swe6301_group3_artefact/screens/activity_detail_page.dart';
import 'package:swe6301_group3_artefact/screens/explore_page.dart';
import 'package:swe6301_group3_artefact/screens/location_detail_page.dart';
import 'package:swe6301_group3_artefact/screens/sign_in_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('accessibility text resize + contrast smoke', (tester) async {
    final overflowErrors = <FlutterErrorDetails>[];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      // Capture overflow errors to surface layout regressions under scaling.
      if (_isOverflowError(details)) {
        overflowErrors.add(details);
      }
      originalOnError?.call(details);
    };
    addTearDown(() {
      FlutterError.onError = originalOnError;
    });

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final auth = MockFirebaseAuth(
      signedIn: false,
      mockUser: MockUser(uid: 'a11y-user', email: 'a11y@example.com'),
    );

    await tester.pumpWidget(
      _AccessibilityApp(
        auth: auth,
        textScaleFactor: 1.4,
      ),
    );
    await tester.pumpAndSettle();

    // Validate contrast for the sign-in CTA before auth.
    await _expectButtonContrast(
      tester,
      find.ancestor(
        of: find.text('Sign in'),
        matching: _buttonStyleButton(),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'a11y@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pumpAndSettle();

    // Exercise stay detail flow and verify button contrast.
    expect(find.text('Explore'), findsWidgets);

    await tester.tap(find.byKey(const Key('e2e.openStay')));
    await tester.pumpAndSettle();
    expect(find.byType(LocationDetailPage), findsOneWidget);
    expect(find.text('Book this stay'), findsOneWidget);

    await _expectButtonContrast(
      tester,
      find.ancestor(
        of: find.text('Book this stay'),
        matching: _buttonStyleButton(),
      ),
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('e2e.openActivity')));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityDetailPage), findsOneWidget);
    expect(find.text('Join this activity'), findsOneWidget);

    // Verify activity join button contrast too.
    await _expectButtonContrast(
      tester,
      find.ancestor(
        of: find.text('Join this activity'),
        matching: _buttonStyleButton(),
      ),
    );

    expect(
      overflowErrors,
      isEmpty,
      reason: _formatOverflowErrors(overflowErrors),
    );
  });
}

// Identify layout overflow errors from Flutter's error text.
bool _isOverflowError(FlutterErrorDetails details) {
  final message = details.exceptionAsString().toLowerCase();
  return message.contains('overflowed') || message.contains('renderflex');
}

// Render overflow errors in a readable form for test output.
String _formatOverflowErrors(List<FlutterErrorDetails> errors) {
  if (errors.isEmpty) return '';
  return errors.map((e) => e.exceptionAsString()).join('\n\n');
}

// Compute contrast ratio and assert minimum WCAG-ish threshold.
Future<void> _expectButtonContrast(
  WidgetTester tester,
  Finder finder, {
  double minRatio = 4.5,
}) async {
  expect(finder, findsOneWidget);
  // Compute contrast from resolved button colors against WCAG-like threshold.
  final element = tester.element(finder);
  final button = tester.widget<ButtonStyleButton>(finder);
  final style = button.style;
  final states = <WidgetState>{};
  final background = style?.backgroundColor?.resolve(states) ??
      Theme.of(element).colorScheme.primary;
  final foreground = style?.foregroundColor?.resolve(states) ??
      Theme.of(element).colorScheme.onPrimary;
  final ratio = _contrastRatio(background, foreground);
  expect(
    ratio,
    greaterThanOrEqualTo(minRatio),
    reason: 'Contrast ratio $ratio is below $minRatio.',
  );
}

// Finder helper for ButtonStyleButton widgets.
Finder _buttonStyleButton() {
  return find.byWidgetPredicate((widget) => widget is ButtonStyleButton);
}

// Compute contrast ratio based on luminance.
double _contrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance() + 0.05;
  final l2 = b.computeLuminance() + 0.05;
  return l1 > l2 ? l1 / l2 : l2 / l1;
}

/// App wrapper that inflates text scale for a11y smoke tests.
class _AccessibilityApp extends StatelessWidget {
  final FirebaseAuth auth;
  final double textScaleFactor;
  const _AccessibilityApp({
    required this.auth,
    required this.textScaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          // Inflate text size to stress layout and contrast handling.
          data: media.copyWith(textScaler: TextScaler.linear(textScaleFactor)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _AuthGate(auth: auth),
    );
  }
}

/// Simple auth gate used to route into Explore flow.
class _AuthGate extends StatelessWidget {
  final FirebaseAuth auth;
  const _AuthGate({required this.auth});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) {
          return SignInPage(auth: auth);
        }
        return _ExploreFlow();
      },
    );
  }
}

/// Explore screen wrapper with buttons to open detail pages.
class _ExploreFlow extends StatelessWidget {
  static const _activityTitle = 'Coastal Clean-Up Experience';
  static const _activityLocation = 'Falmouth Beach, Cornwall';

  EcoLocation _stayLocation() {
    return kEcoLocations.firstWhere(
      (item) => item.title == 'Cornwall Clifftop Cabin',
      orElse: () => kEcoLocations.first,
    );
  }

  TripEntry _activityEntry() {
    return const TripEntry(
      title: _activityTitle,
      subtitle: _activityLocation,
      location: _activityLocation,
      price: 'Free',
      assetPath: 'lib/screens/assets/beach_clean_up.png',
      imageUrl: null,
      date: null,
      isPast: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stay = _stayLocation();
    final activity = _activityEntry();
    return Stack(
      children: [
        ExplorePage(
          savedKeys: const {},
          bookedKeys: const {},
          onToggleSave: (_) {},
          onBookStay: (_, _) {},
          onUnbookStay: (_) {},
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                key: const Key('e2e.openStay'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LocationDetailPage(
                        location: stay,
                        isSaved: false,
                        isBooked: false,
                        onToggleSave: () {},
                        onBook: (_) {},
                        onUnbook: () {},
                      ),
                    ),
                  );
                },
                child: const Text('Open stay'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('e2e.openActivity'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ActivityDetailPage(
                        entry: activity,
                        tagPrimary: 'beach',
                        tagSecondary: 'cornwall',
                        dateRangePicker: _selectFirstRange,
                      ),
                    ),
                  );
                },
                child: const Text('Open activity'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Deterministic date range selection for the test.
Future<DateTimeRange?> _selectFirstRange(
  BuildContext context,
  List<DateTime> availableDates,
) async {
  if (availableDates.isEmpty) return null;
  final start = availableDates.first;
  final end = availableDates.length > 1 ? availableDates[1] : availableDates.first;
  return DateTimeRange(start: start, end: end);
}
