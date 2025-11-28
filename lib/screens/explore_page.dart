import 'package:flutter/material.dart';
import '../data/eco_locations.dart';
import 'search_page.dart';

class ExplorePage extends StatelessWidget {
  final String query;
  ExplorePage({super.key, String? query})
      : query = (query ?? '').isEmpty ? 'Explore' : query!;

  List<EcoLocation> _filterResults() {
    final q = query.toLowerCase().trim();
    if (q.isEmpty || q == 'explore') return kEcoLocations;

    final tokens = q.split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty).toList();

    bool matches(EcoLocation item) {
      final title = item.title.toLowerCase();
      final loc = item.location.toLowerCase();
      final tags = item.tags.map((t) => t.toLowerCase());
      final tagString = item.tags.map((t) => t.toLowerCase()).join(' ');

      // full query match (either direction)
      if (title.contains(q) || loc.contains(q) || tagString.contains(q) || q.contains(loc)) {
        return true;
      }

      // token match
      for (final token in tokens) {
        if (title.contains(token) || loc.contains(token) || tags.any((t) => t.contains(token))) {
          return true;
        }
      }
      return false;
    }

    return kEcoLocations.where(matches).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterResults();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Explore',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(
              '${filtered.length} eco-friendly results',
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchPage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Search eco-friendly trips',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                const SizedBox(height: 16),
                if (filtered.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ResultCard(item: filtered.first, isFullWidth: true),
                  ),
                if (filtered.length > 1)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final item in filtered.skip(1))
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 12 * 3) / 2,
                          child: _ResultCard(item: item, isFullWidth: false),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

class _ResultCard extends StatelessWidget {
  final EcoLocation item;
  final bool isFullWidth;
  const _ResultCard({required this.item, this.isFullWidth = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isFullWidth ? 18 : 16),
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
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(isFullWidth ? 18 : 16)),
            child: AspectRatio(
              aspectRatio: isFullWidth ? 3 / 2 : 1.1,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.landscape, size: 48, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _Badge(label: item.tags.isNotEmpty ? item.tags.first : 'Eco stay'),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_border, color: Colors.white),
                    ),
                  ),
                ],
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
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetaBullet(text: item.meta),
                    _MetaBullet(text: item.price),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaBullet extends StatelessWidget {
  final String text;
  const _MetaBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
