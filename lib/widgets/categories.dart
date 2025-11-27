import 'package:flutter/material.dart';

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

class CategoryPill extends StatelessWidget {
  final CategoryItem category;
  final double width;
  const CategoryPill({
    super.key,
    required this.category,
    this.width = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            category.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
