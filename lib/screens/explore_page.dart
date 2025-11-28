import 'package:flutter/material.dart';
import '../data/eco_locations.dart';

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
            Text(
              query,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
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
          child: Column(
            children: [
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
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
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
