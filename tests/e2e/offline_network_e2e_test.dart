/// E2E smoke test for offline activity fetch and booking retry handling.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _networkDelay = Duration(milliseconds: 300);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('offline/poor network handling', (tester) async {
    await tester.pumpWidget(const _OfflineNetworkApp());
    await tester.pump();
    await tester.pump(_networkDelay);
    await tester.pump();

    // Initial state shows cached activities and offline banner.
    expect(find.byKey(const Key('activity.offlineMessage')), findsOneWidget);
    expect(find.text('Coastal Clean-Up Experience'), findsOneWidget);
    expect(find.text('Forest Replanting'), findsOneWidget);
    expect(find.text('Pop-up Beach Cleanup'), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'Retry activities'));
    await tester.pump();
    await tester.pump(_networkDelay);
    await tester.pump();

    // After retry, new data appears and banner disappears.
    expect(find.byKey(const Key('activity.offlineMessage')), findsNothing);
    expect(find.text('Pop-up Beach Cleanup'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Book this stay'));
    await tester.pump();
    await tester.pump(_networkDelay);
    await tester.pump();

    // Booking fails while offline.
    expect(find.byKey(const Key('booking.error')), findsOneWidget);
    expect(find.text('Booking failed. Check connection and try again.'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Retry booking'));
    await tester.pump();
    await tester.pump(_networkDelay);
    await tester.pump();

    // Booking succeeds after retry.
    expect(find.byKey(const Key('booking.error')), findsNothing);
    expect(find.byKey(const Key('booking.success')), findsOneWidget);
  });
}

/// Minimal app wrapper for offline network tests.
class _OfflineNetworkApp extends StatelessWidget {
  const _OfflineNetworkApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: _OfflineNetworkHome(),
    );
  }
}

/// Home screen that simulates activity fetch and booking flows.
class _OfflineNetworkHome extends StatefulWidget {
  const _OfflineNetworkHome();

  @override
  State<_OfflineNetworkHome> createState() => _OfflineNetworkHomeState();
}

class _OfflineNetworkHomeState extends State<_OfflineNetworkHome> {
  static const _cachedActivities = [
    'Coastal Clean-Up Experience',
    'Forest Replanting',
  ];

  static const _freshActivities = [
    'Coastal Clean-Up Experience',
    'Forest Replanting',
    'Pop-up Beach Cleanup',
  ];

  bool _activityOnline = false;
  bool _bookingOnline = false;
  bool _loadingActivities = true;
  bool _bookingInFlight = false;
  bool _bookingConfirmed = false;
  String? _activityMessage;
  String? _bookingMessage;
  List<String> _activities = const [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  // Load activities, falling back to cached results on timeout.
  Future<void> _loadActivities() async {
    setState(() {
      _loadingActivities = true;
    });
    try {
      final result = await _fetchActivities();
      if (!mounted) return;
      setState(() {
        _activities = result;
        _activityMessage = null;
        _loadingActivities = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _activities = _cachedActivities;
        _activityMessage = 'Offline: showing cached activities.';
        _loadingActivities = false;
      });
    }
  }

  // Fake network fetch with a configurable offline toggle.
  Future<List<String>> _fetchActivities() async {
    await Future.delayed(_networkDelay);
    if (!_activityOnline) {
      throw TimeoutException('Offline');
    }
    return _freshActivities;
  }

  // Retry activities by switching to online state.
  Future<void> _retryActivities() async {
    setState(() {
      _activityOnline = true;
    });
    await _loadActivities();
  }

  // Simulate a booking attempt with possible offline error.
  Future<void> _submitBooking() async {
    setState(() {
      _bookingInFlight = true;
      _bookingConfirmed = false;
      _bookingMessage = null;
    });
    await Future.delayed(_networkDelay);
    if (!mounted) return;
    if (!_bookingOnline) {
      setState(() {
        _bookingInFlight = false;
        _bookingMessage = 'Booking failed. Check connection and try again.';
      });
      return;
    }
    setState(() {
      _bookingInFlight = false;
      _bookingConfirmed = true;
      _bookingMessage = null;
    });
  }

  // Retry the booking by toggling online state.
  Future<void> _retryBooking() async {
    setState(() {
      _bookingOnline = true;
    });
    await _submitBooking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline handling smoke')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Activities',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (_activityMessage != null)
            Container(
              key: const Key('activity.offlineMessage'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(_activityMessage!)),
                  TextButton(
                    onPressed: _retryActivities,
                    child: const Text('Retry activities'),
                  ),
                ],
              ),
            ),
          if (_activityMessage != null) const SizedBox(height: 12),
          if (_loadingActivities)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(key: Key('activity.loading')),
              ),
            ),
          if (!_loadingActivities)
            ..._activities.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(item),
              ),
            ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          const Text(
            'Booking',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (_bookingMessage != null)
            Text(
              _bookingMessage!,
              key: const Key('booking.error'),
              style: const TextStyle(color: Colors.red),
            ),
          if (_bookingConfirmed)
            const Text(
              'Booking confirmed',
              key: Key('booking.success'),
              style: TextStyle(color: Colors.green),
            ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _bookingInFlight ? null : _submitBooking,
            child: _bookingInFlight
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Book this stay'),
          ),
          if (_bookingMessage != null)
            TextButton(
              onPressed: _retryBooking,
              child: const Text('Retry booking'),
            ),
        ],
      ),
    );
  }
}
