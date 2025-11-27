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
  const _FeaturedEscape({
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
    ),
    _FeaturedEscape(
      title: 'Mountain Retreat',
      subtitle: '3 nights',
      assetPath: 'lib/screens/assets/mountain_retreat.jpeg',
    ),
    _FeaturedEscape(
      title: 'Island Hideaway',
      subtitle: '7 nights',
      assetPath: 'lib/screens/assets/island_hideaway.jpeg',
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
        title: Text(
          'GreenGetaway',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
        ),
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
                          const SizedBox(height: 24),
                          const SectionTitle('Categories'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: kCategories
                                .map((cat) => CategoryPill(category: cat))
                                .toList(),
                          ),
                          const SizedBox(height: 24),
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
                                  child: FeaturedCard(
                                    title: escape.title,
                                    subtitle: escape.subtitle,
                                    image: Image.asset(
                                      escape.assetPath,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
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
