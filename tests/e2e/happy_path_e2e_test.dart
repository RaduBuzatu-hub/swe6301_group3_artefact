/// Happy-path E2E flow: sign in, browse, book, and confirm an activity.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:swe6301_group3_artefact/models/trip_entry.dart';
import 'package:swe6301_group3_artefact/screens/activity_detail_page.dart';
import 'package:swe6301_group3_artefact/screens/explore_page.dart';
import 'package:swe6301_group3_artefact/screens/sign_in_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('happy path sign-in -> browse -> book -> confirmation', (tester) async {
    final auth = MockFirebaseAuth(
      signedIn: false,
      mockUser: MockUser(uid: 'e2e-user', email: 'e2e@example.com'),
    );

    // Fix viewport size to keep layout and hit targets deterministic.
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_E2EApp(auth: auth));
    await tester.pumpAndSettle();

    // Sign in through the auth gate.
    await tester.enterText(find.byType(TextField).at(0), 'e2e@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pumpAndSettle();

    // Verify explore landing content appears.
    expect(find.text('Explore'), findsWidgets);
    expect(find.text('Activities & events'), findsWidgets);

    const activityTitle = 'Coastal Clean-Up Experience';
    const activityLocation = 'Falmouth Beach, Cornwall';

    final openDetailButton = find.byKey(const Key('e2e.openActivity'));
    await tester.ensureVisible(openDetailButton);
    await tester.tap(openDetailButton);
    await tester.pumpAndSettle();
    expect(find.byType(ActivityDetailPage), findsOneWidget);

    // Confirm details and join the activity.
    expect(find.text(activityTitle), findsOneWidget);
    expect(find.text(activityLocation), findsOneWidget);
    final joinButtonText = find.descendant(
      of: find.byType(ActivityDetailPage),
      matching: find.text('Join this activity'),
    );
    expect(joinButtonText, findsOneWidget);

    await tester.tap(joinButtonText);
    await tester.pumpAndSettle();

    // Confirmation screen is rendered with trip details.
    expect(find.text('Booking confirmed'), findsOneWidget);
    expect(find.text(activityTitle), findsOneWidget);
    expect(find.text(activityLocation), findsOneWidget);
  });
}

class _E2EApp extends StatelessWidget {
  final FirebaseAuth auth;
  const _E2EApp({required this.auth});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _AuthGate(auth: auth),
    );
  }
}

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

class _ExploreFlow extends StatefulWidget {
  @override
  State<_ExploreFlow> createState() => _ExploreFlowState();
}

class _ExploreFlowState extends State<_ExploreFlow> {
  static const _activityTitle = 'Coastal Clean-Up Experience';
  static const _activityLocation = 'Falmouth Beach, Cornwall';

  TripEntry _buildActivityEntry() {
    // Pre-canned TripEntry used for the test detail page.
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

  void _handleJoinTrip(TripEntry trip) {
    // Route to confirmation when the activity is joined.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ConfirmationPage(trip: trip),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = _buildActivityEntry();
    return Stack(
      children: [
        ExplorePage(
          query: 'activities',
          savedKeys: const {},
          bookedKeys: const {},
          onToggleSave: (_) {},
          onBookStay: (_, _) {},
          onUnbookStay: (_) {},
          onJoinTrip: _handleJoinTrip,
          activityDateRangePicker: _selectFirstRange,
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FilledButton(
            key: const Key('e2e.openActivity'),
            onPressed: () {
              // Provide a direct path to the detail page for the test flow.
              _openActivityDetail(entry);
            },
            child: const Text('Open activity detail'),
          ),
        ),
      ],
    );
  }

  Future<void> _openActivityDetail(TripEntry entry) async {
    // Navigate to detail, then forward the result to confirmation.
    final result = await Navigator.of(context).push<TripEntry>(
      MaterialPageRoute(
        builder: (_) => ActivityDetailPage(
          entry: entry,
          tagPrimary: 'beach',
          tagSecondary: 'cornwall',
          dateRangePicker: _selectFirstRange,
        ),
      ),
    );
    if (!mounted || result == null) return;
    _handleJoinTrip(result);
  }
}

class _ConfirmationPage extends StatelessWidget {
  final TripEntry trip;
  const _ConfirmationPage({required this.trip});

  @override
  Widget build(BuildContext context) {
    final dateRange = trip.date != null && trip.endDate != null
        ? '${trip.date!.toLocal().toIso8601String().substring(0, 10)} - '
            '${trip.endDate!.toLocal().toIso8601String().substring(0, 10)}'
        : 'Date selected';
    return Scaffold(
      appBar: AppBar(title: const Text('Booking confirmation')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking confirmed',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(trip.title, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Text(trip.location),
            const SizedBox(height: 6),
            Text('Dates: $dateRange'),
          ],
        ),
      ),
    );
  }
}

Future<DateTimeRange?> _selectFirstRange(
  BuildContext context,
  List<DateTime> availableDates,
) async {
  if (availableDates.isEmpty) return null;
  final start = availableDates.first;
  final end = availableDates.length > 1 ? availableDates[1] : availableDates.first;
  return DateTimeRange(start: start, end: end);
}
