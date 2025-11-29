import 'package:flutter/material.dart';
import 'package:swe6301_group3_artefact/theme/app_styles.dart';

/// Home search bar is tappable-only (readOnly) so tests can tap the key and assert navigation.
class HomeSearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  const HomeSearchBar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('searchBar.input'),
      readOnly: onTap != null,
      onTap: onTap,
      style: const TextStyle(
        color: AppColors.highlight,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: AppColors.highlight,
      decoration: InputDecoration(
        hintText: 'Search eco-friendly trips',
        hintStyle: const TextStyle(
          color: AppColors.highlight,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        prefixIcon: const Icon(Icons.search, color: AppColors.highlight),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.14),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
