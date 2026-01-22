import 'package:flutter/material.dart';
import 'package:swe6301_group3_artefact/theme/app_styles.dart';

/// Reusable section heading used across the app's list and card sections.
/// - Uses the theme titleLarge style and the app highlight color.
/// - Accepts an optional key to simplify widget tests.
class SectionTitle extends StatelessWidget {
  final String text;
  final Key? testKey;
  const SectionTitle(this.text, {super.key, this.testKey});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      key: testKey,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.highlight,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
