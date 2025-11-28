import 'package:flutter/material.dart';

class FeaturedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? location;
  final String? price;
  final Widget? image; // e.g., Image.asset or Image.network
  const FeaturedCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.location,
    this.price,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              height: 96,
              width: 96,
              child: image ??
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF86A8E7), Color(0xFF7F7FD5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.landscape, color: Colors.white, size: 40),
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFFF7DFA5),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFF7DFA5),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (location != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    location!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFF7DFA5),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                if (price != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    price!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFF7DFA5),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
