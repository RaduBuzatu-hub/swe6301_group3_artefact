import 'package:flutter/material.dart';
import 'package:swe6301_group3_artefact/theme/app_styles.dart';

/// Simple data holder for a category name and icon.
class CategoryItem {
  final String label;
  final IconData icon;
  const CategoryItem({required this.label, required this.icon});
}

const List<CategoryItem> kCategories = [
  CategoryItem(label: 'Eco Stays', icon: Icons.home_work),
  CategoryItem(label: 'Local Tours', icon: Icons.location_on),
  CategoryItem(label: 'Activities', icon: Icons.checklist_rtl),
  CategoryItem(label: 'Nature', icon: Icons.park),
];

/// Displays a tappable pill for a given [CategoryItem].
class CategoryPill extends StatelessWidget {
  final CategoryItem category;
  final double width;
  final double height;
  const CategoryPill({
    super.key,
    required this.category,
    this.width = 72,
    this.height = 86,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('category.${category.label}'),
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, color: Colors.white, size: 24),
          const SizedBox(height: 6),
          Text(
            category.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.highlight,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
