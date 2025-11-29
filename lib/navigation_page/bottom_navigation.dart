import 'package:flutter/material.dart';
import '../screens/home_page.dart';
import '../screens/explore_page.dart';
import '../screens/trips_page.dart';
import '../screens/profile_page.dart';
import '../models/trip_entry.dart';
import '../data/eco_locations.dart';
import '../screens/location_detail_page.dart';

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
      }
      _index = 2; // go to Trips tab
    });
  }

  void _toggleSavedActivity(EcoLocation location) {
    final key = _tripKey(location.title, location.location);
    final existingIndex =
        _savedActivities.indexWhere((t) => _tripKey(t.title, t.location) == key);

    setState(() {
      if (existingIndex >= 0) {
        _savedActivities.removeAt(existingIndex);
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
      }
    });
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    final pages = [
      HomePage(
        onSearchSubmit: _handleSearchSubmit,
        onJoinTrip: _handleJoinTrip,
      ),
      ExplorePage(
        query: _exploreQuery,
        savedKeys: _savedActivities
            .map((e) => _tripKey(e.title, e.location))
            .toSet(),
        onToggleSave: _toggleSavedActivity,
        bookedKeys: _trips.map((e) => _tripKey(e.title, e.location)).toSet(),
        onBookStay: _bookLocation,
        onJoinTrip: _handleJoinTrip,
        onViewTrips: () {
          Navigator.of(context).pop();
          setState(() {
            _index = 2;
          });
        },
      ),
      TripsPage(
        trips: _trips,
        savedActivities: _savedActivities,
        onOpenTrip: (trip) {
          final location = EcoLocation(
            title: trip.title,
            location: trip.location,
            meta: trip.subtitle,
            price: trip.price,
            imageUrl: trip.imageUrl ?? '',
            tags: const [],
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LocationDetailPage(
                location: location,
                isSaved: true,
                isBooked: true,
                onToggleSave: () {},
                onBook: () {},
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
