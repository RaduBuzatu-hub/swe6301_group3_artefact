import 'package:flutter/material.dart';
import '../widgets/categories.dart';
import '../widgets/featured_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/section_title.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  final ValueChanged<String>? onSearchSubmit;
  const HomePage({super.key, this.onSearchSubmit});

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
                          const SectionTitle('Categories'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: kCategories
                                .map((cat) => CategoryPill(category: cat))
                                .toList(),
                          ),
                          // more sections (featured cards, trips) can follow...
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
