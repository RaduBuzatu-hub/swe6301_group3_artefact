import 'package:flutter/material.dart';
import '../data/eco_locations.dart';

class LocationDetailPage extends StatefulWidget {
  final EcoLocation location;
  final bool isSaved;
  final bool isBooked;
  final VoidCallback onToggleSave;
  final VoidCallback onBook;
  final VoidCallback? onViewTrips;
  const LocationDetailPage({
    super.key,
    required this.location,
    required this.isSaved,
    required this.isBooked,
    required this.onToggleSave,
    required this.onBook,
    this.onViewTrips,
  });

  @override
  State<LocationDetailPage> createState() => _LocationDetailPageState();
}

class _LocationDetailPageState extends State<LocationDetailPage> {
  late bool _saved;
  late bool _booked;

  @override
  void initState() {
    super.initState();
    _saved = widget.isSaved;
    _booked = widget.isBooked;
  }

  void _handleToggleSave() {
    widget.onToggleSave();
    setState(() {
      _saved = !_saved;
    });
  }

  void _handleBook() {
    if (_booked) return;
    final wasSaved = _saved;
    widget.onBook();
    setState(() {
      _booked = true;
      _saved = true;
    });
    if (!wasSaved) {
      widget.onToggleSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.location;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF512DA8),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_saved ? Icons.favorite : Icons.favorite_border, color: Colors.white),
            onPressed: _handleToggleSave,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 3 / 2,
              child: Image.network(
                l.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.landscape, size: 48, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF2E2A68),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.location,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _TagChip(label: l.meta),
                      _TagChip(label: l.price),
                      for (final tag in l.tags) _TagChip(label: tag),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'About this stay',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Discover an eco-friendly stay that aligns with low-impact travel. Enjoy local experiences, support sustainable hosts, and explore nearby nature spots.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(_booked ? Icons.check_circle : Icons.favorite_border),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A148C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: _handleBook,
                        label: Text(
                          _booked ? 'Booked' : 'Book this stay',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        icon: Icon(_saved ? Icons.favorite : Icons.favorite_border),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4A148C),
                          side: const BorderSide(color: Color(0xFF4A148C), width: 1.4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _handleToggleSave,
                        label: Text(
                          _saved ? 'Saved' : 'Save to trips',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                      if (_booked && widget.onViewTrips != null) ...[
                        const SizedBox(height: 10),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4A148C),
                            side: const BorderSide(color: Color(0xFF4A148C), width: 1.4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: widget.onViewTrips,
                          child: const Text(
                            'View in Trips',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2E2A68),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
