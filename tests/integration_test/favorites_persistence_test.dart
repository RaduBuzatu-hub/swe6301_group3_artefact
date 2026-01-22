/// Integration test verifying saved trips persist across app restarts.
/// - Exercises LocalDb save/remove flows across widget rebuilds.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:swe6301_group3_artefact/data/eco_locations.dart';
import 'package:swe6301_group3_artefact/data/local_db.dart';
import 'package:swe6301_group3_artefact/models/trip_entry.dart';
import 'package:swe6301_group3_artefact/screens/explore_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('favorites persist across app restart', (tester) async {
    const uid = 'integration-user';
    const title = 'Cornwall Clifftop Cabin';
    const location = 'Cornwall';

    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await LocalDb.instance.init();
    await _clearSaved(uid);

    await tester.pumpWidget(_FavoritesTestApp(uid: uid));
    await tester.pumpAndSettle();

    await _openLocationDetail(tester, title);
    final saveButton = find.widgetWithText(OutlinedButton, 'Save to trips');
    expect(saveButton, findsOneWidget);

    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    final savedButton = find.widgetWithText(OutlinedButton, 'Saved');
    expect(savedButton, findsOneWidget);

    final savedRows = await LocalDb.instance.getTrips(uid: uid, saved: true);
    expect(
      savedRows.any(
        (row) =>
            (row['title'] as String? ?? '') == title &&
            (row['location'] as String? ?? '') == location,
      ),
      isTrue,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(_FavoritesTestApp(uid: uid));
    await tester.pumpAndSettle();

    await _openLocationDetail(tester, title);
    expect(savedButton, findsOneWidget);

    await tester.ensureVisible(savedButton);
    await tester.tap(savedButton);
    await tester.pumpAndSettle();
    expect(saveButton, findsOneWidget);

    final savedAfterRemoval = await LocalDb.instance.getTrips(uid: uid, saved: true);
    expect(savedAfterRemoval, isEmpty);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(_FavoritesTestApp(uid: uid));
    await tester.pumpAndSettle();

    await _openLocationDetail(tester, title);
    expect(saveButton, findsOneWidget);
  });
}

// Clear any saved activities before running the test.
Future<void> _clearSaved(String uid) async {
  final saved = await LocalDb.instance.getTrips(uid: uid, saved: true);
  for (final row in saved) {
    final title = row['title'] as String? ?? '';
    final location = row['location'] as String? ?? '';
    if (title.isEmpty || location.isEmpty) continue;
    await LocalDb.instance.deleteSavedActivity(
      uid: uid,
      title: title,
      location: location,
    );
  }
}

// Scroll to and open a location detail card by title.
Future<void> _openLocationDetail(WidgetTester tester, String title) async {
  final titleFinder = find.text(title);
  expect(titleFinder, findsWidgets);
  await tester.ensureVisible(titleFinder.first);
  await tester.pumpAndSettle();
  await tester.tap(titleFinder.first);
  await tester.pumpAndSettle();
}

/// Minimal app wrapper for the favorites persistence test.
class _FavoritesTestApp extends StatelessWidget {
  final String uid;
  const _FavoritesTestApp({required this.uid});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _FavoritesHome(uid: uid),
    );
  }
}

/// Home screen that wires ExplorePage to LocalDb save state.
class _FavoritesHome extends StatefulWidget {
  final String uid;
  const _FavoritesHome({required this.uid});

  @override
  State<_FavoritesHome> createState() => _FavoritesHomeState();
}

class _FavoritesHomeState extends State<_FavoritesHome> {
  bool _loading = true;
  final List<TripEntry> _saved = [];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  // Load saved trips from local storage into state.
  Future<void> _loadSaved() async {
    final rows = await LocalDb.instance.getTrips(uid: widget.uid, saved: true);
    if (!mounted) return;
    setState(() {
      _saved
        ..clear()
        ..addAll(rows.map(_mapToTrip));
      _loading = false;
    });
  }

  // Bridge ExplorePage save callbacks to local DB updates.
  void _handleToggleSave(EcoLocation location) {
    _toggleSave(location);
  }

  // Add/remove a saved trip and persist changes.
  Future<void> _toggleSave(EcoLocation location) async {
    final key = _tripKey(location.title, location.location);
    final existingIndex = _saved.indexWhere((t) => _tripKey(t.title, t.location) == key);
    if (existingIndex >= 0) {
      setState(() {
        _saved.removeAt(existingIndex);
      });
      await LocalDb.instance.deleteSavedActivity(
        uid: widget.uid,
        title: location.title,
        location: location.location,
      );
      return;
    }
    final trip = TripEntry(
      title: location.title,
      subtitle: location.meta,
      location: location.location,
      price: location.price,
      imageUrl: location.imageUrl,
      assetPath: null,
      date: null,
      isPast: false,
    );
    setState(() {
      _saved.add(trip);
    });
    await LocalDb.instance.upsertTrip(
      uid: widget.uid,
      data: _tripToMap(trip),
      saved: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(key: Key('favorites.loading')),
        ),
      );
    }
    final savedKeys = _saved.map((e) => _tripKey(e.title, e.location)).toSet();
    return ExplorePage(
      savedKeys: savedKeys,
      bookedKeys: const {},
      onToggleSave: _handleToggleSave,
      onBookStay: (_, _) {},
      onUnbookStay: (_) {},
    );
  }
}

// Rebuild a TripEntry from LocalDb row data.
TripEntry _mapToTrip(Map<String, dynamic> map) {
  return TripEntry(
    title: map['title'] as String? ?? '',
    subtitle: map['subtitle'] as String? ?? '',
    location: map['location'] as String? ?? '',
    price: map['price'] as String? ?? '',
    imageUrl: map['image_url'] as String?,
    assetPath: map['asset_path'] as String?,
    date: (map['date_iso'] as String?)?.isNotEmpty == true
        ? DateTime.tryParse(map['date_iso'] as String)
        : null,
    endDate: (map['end_date_iso'] as String?)?.isNotEmpty == true
        ? DateTime.tryParse(map['end_date_iso'] as String)
        : null,
    isPast: (map['is_past'] ?? 0) == 1,
  );
}

// Convert a TripEntry into a map for LocalDb.
Map<String, dynamic> _tripToMap(TripEntry trip) {
  return {
    'title': trip.title,
    'subtitle': trip.subtitle,
    'location': trip.location,
    'price': trip.price,
    'image_url': trip.imageUrl,
    'asset_path': trip.assetPath,
    'date_iso': trip.date?.toIso8601String() ?? '',
    'end_date_iso': trip.endDate?.toIso8601String() ?? '',
    'is_past': trip.isPast ? 1 : 0,
  };
}

// Stable key for deduping trips by title+location.
String _tripKey(String title, String location) =>
    '${title.toLowerCase()}|${location.toLowerCase()}';
