import 'package:flutter/material.dart';
import '../models/trip_entry.dart';

class TripsPage extends StatefulWidget {
  final List<TripEntry> trips;
  const TripsPage({super.key, required this.trips});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> with SingleTickerProviderStateMixin {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final upcoming = widget.trips.where((t) => !t.isPast).toList();
    final past = widget.trips.where((t) => t.isPast).toList();

    final cards = _tabIndex == 0 ? upcoming : past;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFB388FF),
            Color(0xFF7E57C2),
            Color(0xFF5E35B1),
            Color(0xFF311B92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Trips',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _TripsTabButton(
                    label: 'Upcoming',
                    selected: _tabIndex == 0,
                    onTap: () => setState(() => _tabIndex = 0),
                  ),
                  const SizedBox(width: 18),
                  _TripsTabButton(
                    label: 'Past',
                    selected: _tabIndex == 1,
                    onTap: () => setState(() => _tabIndex = 1),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: Colors.white.withOpacity(0.35)),
              const SizedBox(height: 16),
              Expanded(
                child: cards.isEmpty
                    ? Center(
                        child: Text(
                          _tabIndex == 0
                              ? 'No upcoming trips yet.\nJoin an activity to save it here.'
                              : 'No past trips yet.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                        ),
                      )
                    : ListView.separated(
                        itemCount: cards.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final trip = cards[index];
                          return _TripCard(trip: trip);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripsTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TripsTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 3,
            width: selected ? 68 : 0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripEntry trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 96,
              width: 96,
              child: Image.asset(
                trip.assetPath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFFF7DFA5),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  trip.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFF7DFA5),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  trip.location,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFF7DFA5),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  trip.price,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFF7DFA5),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
