import 'package:flutter/material.dart';
import 'package:swe6301_group3_artefact/theme/app_styles.dart';

/// Simple data holder for a category name and icon.
/// Used by the home category rail and filter taps.
class CategoryItem {
  final String label;
  final IconData icon;
  const CategoryItem({required this.label, required this.icon});
}

/// Default category list shown on the home screen.
const List<CategoryItem> kCategories = [
  CategoryItem(label: 'Eco Stays', icon: Icons.home_work),
  CategoryItem(label: 'Local Tours', icon: Icons.location_on),
  CategoryItem(label: 'Activities', icon: Icons.checklist_rtl),
  CategoryItem(label: 'Nature', icon: Icons.park),
];

/// Displays a tappable pill for a given [CategoryItem].
/// Highlights itself when [selected] is true and forwards [onTap].
class CategoryPill extends StatelessWidget {
  final CategoryItem category;
  final double width;
  final double height;
  final bool selected;
  final VoidCallback? onTap;
  const CategoryPill({
    super.key,
    required this.category,
    this.width = 72,
    this.height = 74,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Selected state uses a stronger background and border.
    final baseColor = Colors.white.withValues(alpha: selected ? 0.24 : 0.12);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        key: Key('category.${category.label}'),
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: selected
              ? Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
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
      ),
    );
  }
}
