import 'package:flutter/material.dart';
import '../widgets/featured_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/section_title.dart';
import 'search_page.dart';
import 'event_detail_page.dart';
import '../models/trip_entry.dart';

class HomePage extends StatefulWidget {
  final ValueChanged<String>? onSearchSubmit;
  final ValueChanged<TripEntry>? onJoinTrip;
  const HomePage({super.key, this.onSearchSubmit, this.onJoinTrip});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _FeaturedEscape {
  final String title;
  final String subtitle;
  final String assetPath;
  final String location;
  final String price;
  const _FeaturedEscape({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.location,
    required this.price,
  });
}

class _CommunityCardData {
  final String title;
  final String subtitle;
  final String assetPath;
  const _CommunityCardData({
    required this.title,
    required this.subtitle,
    required this.assetPath,
  });
}

class _HomePageState extends State<HomePage> {
  final PageController _featuredController = PageController(viewportFraction: 0.9);

  final List<_FeaturedEscape> _featuredEscapes = const [
    _FeaturedEscape(
      title: 'Seaside Escape',
      subtitle: '5 nights',
      assetPath: 'lib/screens/assets/seaside_photo.jpeg',
      location: 'Cornwall',
      price: 'from GBP210 / 2 nights',
    ),
    _FeaturedEscape(
      title: 'Mountain Retreat',
      subtitle: '3 nights',
      assetPath: 'lib/screens/assets/mountain_retreat.jpeg',
      location: 'Swiss Alps',
      price: 'from GBP320 / 3 nights',
    ),
    _FeaturedEscape(
      title: 'Island Hideaway',
      subtitle: '7 nights',
      assetPath: 'lib/screens/assets/island_hideaway.jpeg',
      location: 'Bali',
      price: 'from GBP580 / 5 nights',
    ),
  ];

  final List<_CommunityCardData> _communityCards = const [
    _CommunityCardData(
      title: 'Forest Replanting',
      subtitle: 'Dartmoor',
      assetPath: 'lib/screens/assets/mountain_retreat.jpeg',
    ),
    _CommunityCardData(
      title: 'Eco Cooking Workshop',
      subtitle: 'EUR 10 - 2 hrs',
      assetPath: 'lib/screens/assets/island_hideaway.jpeg',
    ),
    _CommunityCardData(
      title: 'Eco Cooking Workshop',
      subtitle: 'Online',
      assetPath: 'lib/screens/assets/seaside_photo.jpeg',
    ),
  ];

  @override
  void dispose() {
    _featuredController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: const Offset(-8, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 160,
                  width: 260,
                  child: Image.asset(
                    'lib/screens/assets/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Transform.translate(
            offset: const Offset(0, 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Sign in',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/screens/assets/home_page_background.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xCC2D1B6B),
                    Color(0xCC311B92),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          HomeSearchBar(
                            onTap: () async {
                              final result = await Navigator.of(context).push<String>(
                                MaterialPageRoute(
                                  builder: (_) => const SearchPage(),
                                ),
                              );
                              if (result != null && result.trim().isNotEmpty) {
                                widget.onSearchSubmit?.call(result.trim());
                              }
                            },
                          ),
                          const SizedBox(height: 18),
                          const SectionTitle('Featured Eco Escape'),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 140,
                            child: PageView.builder(
                              controller: _featuredController,
                              padEnds: false,
                              itemCount: _featuredEscapes.length,
                              itemBuilder: (context, index) {
                                final escape = _featuredEscapes[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: GestureDetector(
                                    onTap: () => widget.onSearchSubmit?.call(escape.location),
                                    child: FeaturedCard(
                                      title: escape.title,
                                      subtitle: escape.subtitle,
                                      location: escape.location,
                                      price: escape.price,
                                      image: Image.asset(
                                        escape.assetPath,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          const SectionTitle('Eco Activities & Events'),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    height: 120,
                                    width: 150,
                                    child: Image.asset(
                                      'lib/screens/assets/seaside_photo.jpeg',
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
                                        'Beach Clean-Up - Saturday',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: const Color(0xFFF7DFA5),
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Falmouth - 10:00-13:00',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: const Color(0xFFF7DFA5),
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Free',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: const Color(0xFFF7DFA5),
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFA49CD7),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 10,
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => EventDetailPage(
                                                  onJoin: () {
                                                    widget.onJoinTrip?.call(
                                                      TripEntry(
                                                        title: 'Beach Clean-Up - Saturday',
                                                        subtitle: 'Falmouth',
                                                        location: 'Falmouth',
                                                        price: 'Free - 10:00-13:00',
                                                        assetPath: 'lib/screens/assets/seaside_photo.jpeg',
                                                        date: DateTime(2025, 10, 20, 10, 0),
                                                        isPast: false,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            'Join',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 36),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _communityCards.map((card) {
                              return Container(
                                width: 116,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Image.asset(
                                          card.assetPath,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black.withValues(alpha: 0.25),
                                            Colors.black.withValues(alpha: 0.45),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                              card.title,
                                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                    color: const Color(0xFFF7DFA5),
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                  ),
                                            ),
                                            const SizedBox(height: 7),
                                            Text(
                                              card.subtitle,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: const Color(0xFFF7DFA5),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12.5,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
