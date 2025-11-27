import 'package:flutter/material.dart';
import '../widgets/categories.dart';
import '../widgets/featured_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/section_title.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
      body: Container(
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
                        const HomeSearchBar(),
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
                        const FeaturedCard(
                          title: 'Mountain Retreat',
                          subtitle: '3 nights',
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
      ),
    );
  }
}
