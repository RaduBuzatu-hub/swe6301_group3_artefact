import 'package:flutter/material.dart';
import '../screens/home_page.dart';
import '../screens/explore_page.dart';
import '../screens/trips_page.dart';
import '../screens/profile_page.dart';
import '../models/trip_entry.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _index = 0;
  String? _exploreQuery;
  final List<TripEntry> _trips = [];

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    final pages = [
      HomePage(
        onSearchSubmit: _handleSearchSubmit,
        onJoinTrip: _handleJoinTrip,
      ),
      ExplorePage(query: _exploreQuery),
      TripsPage(trips: _trips),
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
              color: theme.shadow.withOpacity(0.25),
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
