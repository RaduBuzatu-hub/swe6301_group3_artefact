import 'package:flutter/material.dart';
import 'package:swe6301_group3_artefact/theme/app_styles.dart';

/// Reusable section heading that matches the app's highlight color.
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
