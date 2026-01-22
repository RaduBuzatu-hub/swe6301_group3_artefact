import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/home_page.dart';
import '../screens/explore_page.dart';
import '../screens/trips_page.dart';
import '../screens/profile_page.dart';
import '../models/trip_entry.dart';
import '../data/eco_locations.dart';
import '../screens/location_detail_page.dart';
import '../screens/sign_in_page.dart';
import '../screens/sign_up_page.dart';
import '../screens/auth_required_page.dart';
import '../data/local_db.dart';

/// Root shell with four tabs (Home, Explore, Trips, Profile) and shared state.
/// - Coordinates navigation between tabs and detail pages.
/// - Keeps in-memory trip/save lists synchronized with local/remote data.
/// - Reacts to auth changes to refresh stored trips and bookings.
class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  // Current tab index for BottomNavigationBar.
  int _index = 0;
  // Query string passed into the Explore tab.
  String? _exploreQuery;
  // In-memory lists backing Trips and saved activities.
  final List<TripEntry> _trips = [];
  final List<TripEntry> _savedActivities = [];
  // Subscriptions for auth state and booking status updates.
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _bookingSub;

  // Convenience getter for the current UID (null if signed out).
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_loadUserData);
    _loadUserData(FirebaseAuth.instance.currentUser);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _bookingSub?.cancel();
    super.dispose();
  }

  // Lowercased composite key used to dedupe trips/saves.
  String _tripKey(String title, String location) =>
      '${title.toLowerCase()}|${location.toLowerCase()}';

  // Build a deterministic document ID for saved activities.
  String _savedDocId({
    required String uid,
    required String title,
    required String location,
  }) {
    final key = _tripKey(title, location);
    return Uri.encodeComponent('$uid|$key');
  }

  // Route the search query to the Explore tab.
  void _handleSearchSubmit(String query) {
    setState(() {
      _exploreQuery = query;
      _index = 1; // switch to Explore tab
    });
  }

  // Add a joined trip and switch to Trips tab.
  void _handleJoinTrip(TripEntry trip) {
    final exists = _trips.any((t) => t.title == trip.title && t.location == trip.location);
    setState(() {
      if (!exists) {
        _trips.add(trip);
        _persistTrip(trip, saved: false);
      }
      _index = 2; // go to Trips tab
    });
  }

  // Toggle save state for a location; requires sign-in.
  void _toggleSavedActivity(EcoLocation location) {
    final key = _tripKey(location.title, location.location);
    final isBooked = _trips.any((t) => _tripKey(t.title, t.location) == key);
    if (isBooked) return;
    if (!_isSignedIn()) {
      _promptSignInForSaves();
      return;
    }
    final existingIndex =
        _savedActivities.indexWhere((t) => _tripKey(t.title, t.location) == key);

    setState(() {
      if (existingIndex >= 0) {
        _savedActivities.removeAt(existingIndex);
        _persistSavedRemoval(location);
      } else {
        _savedActivities.add(
          TripEntry(
            title: location.title,
            subtitle: location.meta,
            location: location.location,
            price: location.price,
            imageUrl: location.imageUrl,
            assetPath: null,
            date: null,
            isPast: false,
          ),
        );
        _persistSavedAddition(location);
      }
    });
  }

  bool _isSignedIn() => FirebaseAuth.instance.currentUser != null;

  // Load trips/saves from local DB whenever auth changes.
  Future<void> _loadUserData(User? user) async {
    if (user == null) {
      await _bookingSub?.cancel();
      _bookingSub = null;
      setState(() {
        _trips.clear();
        _savedActivities.clear();
      });
      return;
    }
    // Pull trips/saved items from local DB when user logs in.
    final tripsRows = await LocalDb.instance.getTrips(uid: user.uid, saved: false);
    final savedRows = await LocalDb.instance.getTrips(uid: user.uid, saved: true);
    final bookedKeys = tripsRows
        .map((row) => _tripKey(row['title'] as String? ?? '', row['location'] as String? ?? ''))
        .toSet();
    final filteredSavedRows = <Map<String, dynamic>>[];
    for (final row in savedRows) {
      final title = row['title'] as String? ?? '';
      final location = row['location'] as String? ?? '';
      final key = _tripKey(title, location);
      // Drop saved items that are already booked.
      if (bookedKeys.contains(key)) {
        await LocalDb.instance.deleteSavedActivity(
          uid: user.uid,
          title: title,
          location: location,
        );
        await _deleteSavedActivityRemote(
          uid: user.uid,
          title: title,
          location: location,
        );
        continue;
      }
      filteredSavedRows.add(row);
    }
    setState(() {
      _trips
        ..clear()
        ..addAll(tripsRows.map(_mapToTrip));
      _savedActivities
        ..clear()
        ..addAll(filteredSavedRows.map(_mapToTrip));
    });
    _startBookingWatcher(user);
  }

  // Listen for remote booking cancellations to keep local trips consistent.
  void _startBookingWatcher(User user) {
    _bookingSub?.cancel();
    _bookingSub = FirebaseFirestore.instance
        .collection('bookings')
        .where('uid', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      for (final change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;
        final status = data['status'] as String? ?? 'paid';
        if (status != 'cancelled') continue;
        final title = data['title'] as String? ?? '';
        final location = data['location'] as String? ?? '';
        if (title.isEmpty || location.isEmpty) continue;
        _removeTripByKey(title: title, location: location);
      }
    });
  }

  Map<String, dynamic> _tripToMap(TripEntry trip) {
    // Normalize TripEntry for local DB storage.
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

  void _openWallet() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() {
      _index = 3;
    });
  }

  TripEntry _mapToTrip(Map<String, dynamic> map) {
    // Rebuild a TripEntry from stored map values.
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

  Future<void> _persistTrip(TripEntry trip, {required bool saved}) async {
    final uid = _uid;
    if (uid == null) return;
    // Upsert ensures we keep one row per (uid, title, location).
    await LocalDb.instance.upsertTrip(
      uid: uid,
      data: _tripToMap(trip),
      saved: saved,
    );
  }

  Future<void> _persistTripRemoval({
    required String title,
    required String location,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await LocalDb.instance.deleteTrip(uid: uid, title: title, location: location);
  }

  Future<void> _recordBookingPayment({
    required String uid,
    required TripEntry trip,
    required BookingDetails details,
  }) async {
    // Only record paid bookings with a positive total.
    if (details.total <= 0) return;
    try {
      await FirebaseFirestore.instance.collection('bookings').add(
        {
          'uid': uid,
          'title': trip.title,
          'location': trip.location,
          'price': trip.price,
          'amount_paid': details.total,
          'nightly_rate': details.nightlyRate,
          'nights': details.nights,
          'start_date_iso': details.range.start.toIso8601String(),
          'end_date_iso': details.range.end.toIso8601String(),
          'status': 'paid',
          'created_at': FieldValue.serverTimestamp(),
        },
      );
    } catch (_) {
      // Ignore remote failures; booking still succeeds locally.
    }
  }

  Future<void> _persistSavedAddition(EcoLocation location) async {
    final uid = _uid;
    if (uid == null) return;
    final map = _tripToMap(
      TripEntry(
        title: location.title,
        subtitle: location.meta,
        location: location.location,
        price: location.price,
        imageUrl: location.imageUrl,
        assetPath: null,
        date: null,
        isPast: false,
      ),
    );
    await LocalDb.instance.upsertTrip(uid: uid, data: map, saved: true);
    await _persistSavedAdditionRemote(
      uid: uid,
      location: location,
    );
  }

  Future<void> _persistSavedRemoval(EcoLocation location) async {
    await _persistSavedRemovalByKey(
      title: location.title,
      location: location.location,
    );
  }

  Future<void> _persistSavedRemovalByKey({
    required String title,
    required String location,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    // Remove saved trip for this user.
    await LocalDb.instance.deleteSavedActivity(
      uid: uid,
      title: title,
      location: location,
    );
    await _deleteSavedActivityRemote(
      uid: uid,
      title: title,
      location: location,
    );
  }

  Future<void> _persistSavedAdditionRemote({
    required String uid,
    required EcoLocation location,
  }) async {
    final docId = _savedDocId(
      uid: uid,
      title: location.title,
      location: location.location,
    );
    try {
      await FirebaseFirestore.instance.collection('saved_activities').doc(docId).set(
        {
          'uid': uid,
          'title': location.title,
          'location': location.location,
          'price': location.price,
          'saved_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Ignore remote save failures; local state is still updated.
    }
  }

  Future<void> _deleteSavedActivityRemote({
    required String uid,
    required String title,
    required String location,
  }) async {
    final docId = _savedDocId(uid: uid, title: title, location: location);
    try {
      await FirebaseFirestore.instance.collection('saved_activities').doc(docId).delete();
    } catch (_) {
      // Ignore remote delete failures; local state is still updated.
    }
  }

  Future<void> _promptSignInForSaves() async {
    final theme = Theme.of(context).colorScheme;
    // Show a modal prompting registration/sign-in before saving.
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.primaryContainer,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Sign in to save'),
          content: const Text('Create an account or sign in to save trips and view them later.'),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.onPrimaryContainer.withValues(alpha: 0.9),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe later'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.onPrimaryContainer,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignUpPage()),
                );
              },
              child: const Text('Register'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: theme.onPrimary,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignInPage()),
                );
              },
              child: const Text('Sign in'),
            ),
          ],
        );
      },
    );
  }

  // Convert a location booking into a TripEntry and persist it.
  void _bookLocation(EcoLocation location, BookingDetails details) {
    final range = details.range;
    final key = _tripKey(location.title, location.location);
    final exists = _trips.any((t) => _tripKey(t.title, t.location) == key);
    final isPast = range.end.isBefore(DateTime.now());
    final bookedTrip = TripEntry(
      title: location.title,
      subtitle: location.meta,
      location: location.location,
      price: location.price,
      imageUrl: location.imageUrl,
      assetPath: null,
      date: range.start,
      endDate: range.end,
      isPast: isPast,
    );
    var removedSaved = false;
    setState(() {
      if (!exists) {
        _trips.add(bookedTrip);
      }
      final savedIndex =
          _savedActivities.indexWhere((t) => _tripKey(t.title, t.location) == key);
      if (savedIndex >= 0) {
        _savedActivities.removeAt(savedIndex);
        removedSaved = true;
      }
    });
    if (!exists) {
      _persistTrip(bookedTrip, saved: false);
      final uid = _uid;
      if (uid != null) {
        _recordBookingPayment(
          uid: uid,
          trip: bookedTrip,
          details: details,
        );
      }
    }
    if (removedSaved) {
      _persistSavedRemovalByKey(
        title: location.title,
        location: location.location,
      );
    }
  }

  // Rebook an existing trip (used from Trips tab).
  void _rebookTrip(TripEntry trip, BookingDetails details) {
    final range = details.range;
    final key = _tripKey(trip.title, trip.location);
    final exists = _trips.any((t) => _tripKey(t.title, t.location) == key);
    final isPast = range.end.isBefore(DateTime.now());
    final updated = TripEntry(
      title: trip.title,
      subtitle: trip.subtitle,
      location: trip.location,
      price: trip.price,
      imageUrl: trip.imageUrl,
      assetPath: trip.assetPath,
      date: range.start,
      endDate: range.end,
      isPast: isPast,
    );
    var removedSaved = false;
    setState(() {
      if (!exists) {
        _trips.add(updated);
      }
      final savedIndex =
          _savedActivities.indexWhere((t) => _tripKey(t.title, t.location) == key);
      if (savedIndex >= 0) {
        _savedActivities.removeAt(savedIndex);
        removedSaved = true;
      }
    });
    if (!exists) {
      _persistTrip(updated, saved: false);
      final uid = _uid;
      if (uid != null) {
        _recordBookingPayment(
          uid: uid,
          trip: updated,
          details: details,
        );
      }
    }
    if (removedSaved) {
      _persistSavedRemovalByKey(
        title: trip.title,
        location: trip.location,
      );
    }
  }

  // Remove a trip by key and delete it from storage.
  void _removeTripByKey({required String title, required String location}) {
    final key = _tripKey(title, location);
    final existingIndex = _trips.indexWhere((t) => _tripKey(t.title, t.location) == key);
    if (existingIndex < 0) return;
    final removed = _trips[existingIndex];
    setState(() {
      _trips.removeAt(existingIndex);
    });
    _persistTripRemoval(title: removed.title, location: removed.location);
  }

  // Remove a trip from saved list and persist the removal.
  void _unsaveTrip(TripEntry trip) {
    final key = _tripKey(trip.title, trip.location);
    final existingIndex =
        _savedActivities.indexWhere((t) => _tripKey(t.title, t.location) == key);
    if (existingIndex < 0) return;
    final removed = _savedActivities[existingIndex];
    setState(() {
      _savedActivities.removeAt(existingIndex);
    });
    _persistSavedRemovalByKey(title: removed.title, location: removed.location);
  }

  void _unbookLocation(EcoLocation location) {
    _removeTripByKey(title: location.title, location: location.location);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    // Tab pages are built once per build based on current state.
    final pages = [
      HomePage(
        onSearchSubmit: _handleSearchSubmit,
        onJoinTrip: _handleJoinTrip,
        onOpenFeatured: (location) {
          final key = _tripKey(location.title, location.location);
          final isBooked = _trips.any((t) => _tripKey(t.title, t.location) == key);
          final isSaved =
              _savedActivities.any((t) => _tripKey(t.title, t.location) == key);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LocationDetailPage(
                location: location,
                isSaved: isSaved,
                isBooked: isBooked,
                onToggleSave: () => _toggleSavedActivity(location),
                onBook: (details) => _bookLocation(location, details),
                onUnbook: () => _unbookLocation(location),
                onViewTrips: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _index = 2;
                  });
                },
                onViewWallet: _openWallet,
              ),
            ),
          );
        },
        onOpenProfile: () {
          setState(() {
            _index = 3;
          });
        },
      ),
      ExplorePage(
        query: _exploreQuery,
        savedKeys: _savedActivities
            .map((e) => _tripKey(e.title, e.location))
            .toSet(),
        onToggleSave: _toggleSavedActivity,
        bookedKeys: _trips.map((e) => _tripKey(e.title, e.location)).toSet(),
        onBookStay: _bookLocation,
        onUnbookStay: _unbookLocation,
        onJoinTrip: _handleJoinTrip,
        onViewTrips: () {
          Navigator.of(context).pop();
          setState(() {
            _index = 2;
          });
        },
        onViewWallet: _openWallet,
      ),
      StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (user == null) {
            return AuthRequiredPage(
              onSignIn: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignInPage()),
                );
              },
              onRegister: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignUpPage()),
                );
              },
            );
          }
          return TripsPage(
            trips: _trips,
            savedActivities: _savedActivities,
            onOpenTrip: (trip) {
              final key = _tripKey(trip.title, trip.location);
              final location = EcoLocation(
                title: trip.title,
                location: trip.location,
                meta: trip.subtitle,
                price: trip.price,
                imageUrl: trip.imageUrl ?? '',
                tags: const [],
              );
              final isBooked =
                  _trips.any((t) => _tripKey(t.title, t.location) == key);
              final isSaved =
                  _savedActivities.any((t) => _tripKey(t.title, t.location) == key);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LocationDetailPage(
                    location: location,
                    isSaved: isSaved,
                    isBooked: isBooked,
                    onToggleSave: () => _toggleSavedActivity(location),
                    onBook: (details) => _rebookTrip(trip, details),
                    onUnbook: () => _removeTripByKey(
                      title: trip.title,
                      location: trip.location,
                    ),
                    onViewTrips: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _index = 2;
                      });
                    },
                    onViewWallet: _openWallet,
                  ),
                ),
              );
            },
            onUnbookTrip: (trip) =>
                _removeTripByKey(title: trip.title, location: trip.location),
            onUnsaveActivity: _unsaveTrip,
          );
        },
      ),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFB388FF),
              Color(0xFF7E57C2),
              Color(0xFF5E35B1),
              Color(0xFF311B92),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadow.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _index,
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          showUnselectedLabels: true,
          elevation: 0,
          onTap: (value) {
            setState(() {
              _index = value;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              label: 'Trips',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
