import 'package:flutter/material.dart';

/// Lightweight search results screen rendered as cards.
/// - Uses a static list of demo results for the UI.
/// - Surfaces quick filter chips at the top of the list.
/// - Shows a network image per item with a fallback.
class ExploreResultsPage extends StatelessWidget {
  final String query;
  ExploreResultsPage({super.key, required String query})
      : query = query.isEmpty ? 'Explore' : query;

  // Static seed data to keep the screen deterministic in demos/tests.
  final List<_ResultItem> _results = const [
    _ResultItem(
      title: 'Thames Eco Stay',
      location: 'London · Zone 2',
      meta: 'Local owned | Solar powered',
      price: 'from GBP120 / 2 nights',
      imageUrl:
          'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&w=1200&q=80',
    ),
    _ResultItem(
      title: 'Camden Green Hostel',
      location: 'London',
      meta: 'Vegan friendly | Free bikes',
      price: 'from GBP68 / night',
      imageUrl:
          'https://images.unsplash.com/photo-1433838552652-f9a46b332c40?auto=format&w=1200&q=80',
    ),
    _ResultItem(
      title: 'Cornwall Clifftop Cabin',
      location: 'Cornwall',
      meta: 'Sea view | Wood-fired hot tub',
      price: 'from GBP210 / 2 nights',
      imageUrl:
          'https://images.unsplash.com/photo-1505761671935-60b3a7427bad?auto=format&w=1200&q=80',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              query,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '12 eco-friendly results in UK',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
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
        ),
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
          child: Column(
            children: [
              // Filter chips row (non-interactive placeholder in this demo).
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _FilterChip(label: 'Train only'),
                    _FilterChip(label: '< GBP200'),
                    _FilterChip(label: 'Sort: Recommended'),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    // Render each result as a card with image + metadata.
                    return _ResultCard(item: item);
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

/// Simple pill-style filter chip used in the header row.
class _FilterChip extends StatelessWidget {
  final String label;
  const _FilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Data model for a single search result card.
class _ResultItem {
  final String title;
  final String location;
  final String meta;
  final String price;
  final String imageUrl;
  const _ResultItem({
    required this.title,
    required this.location,
    required this.meta,
    required this.price,
    required this.imageUrl,
  });
}

/// Card UI for a single search result.
class _ResultCard extends StatelessWidget {
  final _ResultItem item;
  const _ResultCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 3 / 2,
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                // Provide a local fallback icon when the image fails to load.
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.landscape, size: 48, color: Colors.grey),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.location,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.meta,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.price,
                  style: const TextStyle(
                    fontSize: 15,
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
