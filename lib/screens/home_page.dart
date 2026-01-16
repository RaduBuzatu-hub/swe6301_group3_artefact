import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swe6301_group3_artefact/theme/app_styles.dart';
import '../widgets/featured_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/section_title.dart';
import '../widgets/categories.dart';
import 'search_page.dart';
import 'event_detail_page.dart';
import 'activity_detail_page.dart';
import 'sign_in_page.dart';
import 'sign_up_page.dart';
import '../models/trip_entry.dart';
import '../data/local_db.dart';

/// Main landing screen showing featured escapes, filters, and activities.
/// Host can hook into [onSearchSubmit], [onJoinTrip], and [onOpenProfile] for navigation.
class HomePage extends StatefulWidget {
  final ValueChanged<String>? onSearchSubmit;
  final ValueChanged<TripEntry>? onJoinTrip;
  final VoidCallback? onOpenProfile;
  const HomePage({super.key, this.onSearchSubmit, this.onJoinTrip, this.onOpenProfile});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// View-model for featured carousel items.
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

/// View-model for activities rendered in the grid cards.
class _ActivityCardData {
  final String title;
  final String location;
  final String tagPrimary;
  final String tagSecondary;
  final String assetPath;
  final String priceDisplay;
  const _ActivityCardData({
    required this.title,
    required this.location,
    required this.tagPrimary,
    required this.tagSecondary,
    required this.assetPath,
    required this.priceDisplay,
  });
}

/// Splits the HomePage UI into small builders to ease testing and readability.
class _HomePageState extends State<HomePage> {
  final PageController _featuredController = PageController(viewportFraction: 0.9);
  String _activityFilter = 'All';
  String? _selectedCategory;
  // Filters used to drive ChoiceChips; also double as locator labels.
  static const List<String> _filters = ['All', 'Outdoor', 'Workshop', 'Online'];

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
      assetPath: 'lib/screens/assets/forest_replanting.png',
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

  final List<_ActivityCardData> _activities = const [
    _ActivityCardData(
      title: 'Forest Replanting',
      location: 'Dartmoor',
      tagPrimary: 'Outdoor',
      tagSecondary: 'Half-day',
      assetPath: 'lib/screens/assets/forest_replanting.png',
      priceDisplay: 'Free',
    ),
    _ActivityCardData(
      title: 'Eco Cooking Workshop',
      location: 'Lisbon',
      tagPrimary: 'Workshop',
      tagSecondary: 'EUR 10',
      assetPath: 'lib/screens/assets/island_hideaway.jpeg',
      priceDisplay: 'EUR 10',
    ),
    _ActivityCardData(
      title: 'Eco Cooking Workshop',
      location: 'Online',
      tagPrimary: 'Online',
      tagSecondary: '2 hrs',
      assetPath: 'lib/screens/assets/beach_clean_up.png',
      priceDisplay: 'Free',
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
        title: Transform.translate(
          offset: const Offset(-8, 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 140,
                width: 200,
                child: Image.asset(
                  'lib/screens/assets/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 14),
            child: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  );
                }
                final user = snapshot.data;
                if (user == null) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SignInPage()),
                          );
                        },
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SignUpPage()),
                          );
                        },
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  );
                }
                return FutureBuilder<LocalProfile?>(
                  future: LocalDb.instance.getProfile(user.uid),
                  builder: (context, profileSnap) {
                    final name = profileSnap.data?.displayName?.trim();
                    final display = (name != null && name.isNotEmpty)
                        ? name
                        : (user.email ?? 'Logged in');
                    final initial = (display.isNotEmpty ? display[0] : 'U').toUpperCase();
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: widget.onOpenProfile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.22),
                              Colors.white.withValues(alpha: 0.12),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Color(0xFF4A148C),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                            const SizedBox(width: 8),
                            Text(
                              display,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
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
                      padding: AppSpacing.page,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          _buildSearchBar(context),
                          const SizedBox(height: 18),
                          _buildCategoriesSection(),
                          const SizedBox(height: 18),
                          _buildFeaturedCarousel(),
                          const SizedBox(height: 24),
                          _buildActivitiesSection(),
                          const SizedBox(height: 12),
                          _buildEventHighlight(context),
                          const SizedBox(height: 20),
                          _buildActivitiesGrid(),
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

  Widget _buildSearchBar(BuildContext context) {
    return HomeSearchBar(
      onTap: () async {
        // Route to search page and bubble a result back up to parent when selected.
        final result = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (_) => const SearchPage(),
          ),
        );
        if (result != null && result.trim().isNotEmpty) {
          widget.onSearchSubmit?.call(result.trim());
        }
      },
    );
  }

  Widget _buildFeaturedCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Featured Eco Escape', testKey: Key('home.featured.title')),
        AppSpacing.itemGap,
        SizedBox(
          height: 140,
          child: PageView.builder(
            key: const Key('home.featured.carousel'),
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
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Browse by category', testKey: Key('home.categories.title')),
        AppSpacing.itemGap,
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = kCategories[index];
              return CategoryPill(
                category: category,
                selected: _selectedCategory == category.label,
                onTap: () {
                  setState(() {
                    _selectedCategory = category.label;
                  });
                  widget.onSearchSubmit?.call(category.label);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Eco Activities & Events', testKey: Key('home.activities.title')),
        AppSpacing.itemGap,
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _filters
              .map(
                (filter) => ChoiceChip(
                  key: Key('home.filter.$filter'),
                  label: Text(
                    filter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  selected: _activityFilter == filter,
                  showCheckmark: true,
                  checkmarkColor: Colors.white,
                  selectedColor: AppColors.accent,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.72),
                  onSelected: (_) {
                    setState(() {
                      _activityFilter = filter;
                    });
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildEventHighlight(BuildContext context) {
    return Container(
      key: const Key('home.eventHighlight'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
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
                      assetPath: 'lib/screens/assets/beach_clean_up.png',
                      date: DateTime(2025, 10, 20, 10, 0),
                      isPast: false,
                    ),
                  );
                },
              ),
            ),
          );
        },
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 120,
                width: 150,
                child: Image.asset(
                  'lib/screens/assets/beach_clean_up.png',
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
                          color: AppColors.highlight,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Falmouth - 10:00-13:00',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.highlight,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Free',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.highlight,
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
                                    assetPath: 'lib/screens/assets/beach_clean_up.png',
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
    );
  }

  Widget _buildActivitiesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 24) / 2;
        final filtered = _activities.where((a) {
          if (_activityFilter == 'All') return true;
          return a.tagPrimary.toLowerCase() == _activityFilter.toLowerCase();
        }).toList();
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: filtered.map((card) {
            return GestureDetector(
              onTap: () async {
                final result = await Navigator.of(context).push<TripEntry>(
                  MaterialPageRoute(
                    builder: (_) => ActivityDetailPage(
                      entry: TripEntry(
                        title: card.title,
                        subtitle: card.location,
                        location: card.location,
                        price: '${card.priceDisplay} - ${card.tagSecondary}',
                        assetPath: card.assetPath,
                        date: null,
                        isPast: false,
                      ),
                      tagPrimary: card.tagPrimary,
                      tagSecondary: card.tagSecondary,
                    ),
                  ),
                );
                if (result != null) {
                  widget.onJoinTrip?.call(result);
                }
              },
              child: Container(
                key: Key('home.activity.${card.title}.${card.location}'),
                width: cardWidth,
                height: cardWidth * 0.75,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
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
                                Colors.black.withValues(alpha: 0.05),
                                Colors.black.withValues(alpha: 0.55),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              card.location,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _ActivityTag(card.tagPrimary),
                                _ActivityTag(card.tagSecondary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ActivityTag extends StatelessWidget {
  final String label;
  const _ActivityTag(this.label);

  @override
  Widget build(BuildContext context) {
    // Tag is keyed so tests can assert presence of primary/secondary labels.
    return Container(
      key: Key('home.tag.$label'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
