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
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
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
              color: Color(0xFFF7DFA5),
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
