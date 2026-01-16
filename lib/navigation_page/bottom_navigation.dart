import 'dart:async';

import 'package:flutter/material.dart';
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
class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _index = 0;
  String? _exploreQuery;
  final List<TripEntry> _trips = [];
  final List<TripEntry> _savedActivities = [];
  StreamSubscription<User?>? _authSub;

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
    super.dispose();
  }

  String _tripKey(String title, String location) =>
      '${title.toLowerCase()}|${location.toLowerCase()}';

  void _handleSearchSubmit(String query) {
    setState(() {
      _exploreQuery = query;
      _index = 1; // switch to Explore tab
    });
  }

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

  void _toggleSavedActivity(EcoLocation location) {
    if (!_isSignedIn()) {
      _promptSignInForSaves();
      return;
    }
    final key = _tripKey(location.title, location.location);
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

  Future<void> _loadUserData(User? user) async {
    if (user == null) {
      setState(() {
        _trips.clear();
        _savedActivities.clear();
      });
      return;
    }
    // Pull trips/saved items from local DB when user logs in.
    final tripsRows = await LocalDb.instance.getTrips(uid: user.uid, saved: false);
    final savedRows = await LocalDb.instance.getTrips(uid: user.uid, saved: true);
    setState(() {
      _trips
        ..clear()
        ..addAll(tripsRows.map(_mapToTrip));
      _savedActivities
        ..clear()
        ..addAll(savedRows.map(_mapToTrip));
    });
  }

  Map<String, dynamic> _tripToMap(TripEntry trip) {
    return {
      'title': trip.title,
      'subtitle': trip.subtitle,
      'location': trip.location,
      'price': trip.price,
      'image_url': trip.imageUrl,
      'asset_path': trip.assetPath,
      'date_iso': trip.date?.toIso8601String() ?? '',
      'is_past': trip.isPast ? 1 : 0,
    };
  }

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
  }

  Future<void> _persistSavedRemoval(EcoLocation location) async {
    final uid = _uid;
    if (uid == null) return;
    // Remove saved trip for this user.
    await LocalDb.instance.deleteSavedActivity(
      uid: uid,
      title: location.title,
      location: location.location,
    );
  }

  Future<void> _promptSignInForSaves() async {
    final theme = Theme.of(context).colorScheme;
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

  void _bookLocation(EcoLocation location) {
    final key = _tripKey(location.title, location.location);
    final exists = _trips.any((t) => _tripKey(t.title, t.location) == key);
    if (exists) return;
    setState(() {
      _trips.add(
        TripEntry(
          title: location.title,
          subtitle: location.meta,
          location: location.location,
          price: location.price,
          imageUrl: location.imageUrl,
          assetPath: null,
          date: DateTime.now(),
          isPast: false,
        ),
      );
      _persistTrip(_trips.last, saved: false);
    });
  }

  void _rebookTrip(TripEntry trip) {
    final key = _tripKey(trip.title, trip.location);
    final exists = _trips.any((t) => _tripKey(t.title, t.location) == key);
    if (exists) return;
    setState(() {
      _trips.add(trip);
      _persistTrip(trip, saved: false);
    });
  }

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

  void _unbookLocation(EcoLocation location) {
    _removeTripByKey(title: location.title, location: location.location);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    final pages = [
      HomePage(
        onSearchSubmit: _handleSearchSubmit,
        onJoinTrip: _handleJoinTrip,
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
                    onBook: () => _rebookTrip(trip),
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
                  ),
                ),
              );
            },
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
