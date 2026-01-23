/// Integration test covering activity list, detail, and booking selection.
/// - Verifies date range picker handoff and TripEntry creation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:swe6301_group3_artefact/models/trip_entry.dart';
import 'package:swe6301_group3_artefact/screens/explore_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('activities list -> detail -> booking handoff', (tester) async {
    TripEntry? joinedTrip;

    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ExplorePage(
          query: 'activities',
          savedKeys: const {},
          bookedKeys: const {},
          onToggleSave: (_) {},
          onBookStay: (_, _) {},
          onUnbookStay: (_) {},
          onJoinTrip: (trip) => joinedTrip = trip,
          activityDateRangePicker: _selectFirstRange,
        ),
      ),
    );
    await tester.pumpAndSettle();

    const activityTitle = 'Coastal Clean-Up Experience';
    const activityLocation = 'Falmouth Beach, Cornwall';

    final titleFinder = find.text(activityTitle);
    expect(titleFinder, findsWidgets);
    await tester.ensureVisible(titleFinder.first);
    await tester.pumpAndSettle();
    await tester.tap(titleFinder.first);
    await tester.pumpAndSettle();

    final joinButton = find.widgetWithText(ElevatedButton, 'Join this activity');
    expect(joinButton, findsOneWidget);
    expect(find.text(activityLocation), findsOneWidget);

    await tester.ensureVisible(joinButton);
    await tester.pumpAndSettle();
    await tester.tap(joinButton);
    await tester.pumpAndSettle();

    expect(joinedTrip, isNotNull);
    expect(joinedTrip!.title, activityTitle);
    expect(joinedTrip!.location, activityLocation);
    expect(joinedTrip!.date, isNotNull);
    expect(joinedTrip!.endDate, isNotNull);
  });
}

// Deterministic date range picker for tests.
Future<DateTimeRange?> _selectFirstRange(
  BuildContext context,
  List<DateTime> availableDates,
) async {
  if (availableDates.isEmpty) return null;
  final start = availableDates.first;
  final end = availableDates.length > 1 ? availableDates[1] : availableDates.first;
  return DateTimeRange(start: start, end: end);
}
