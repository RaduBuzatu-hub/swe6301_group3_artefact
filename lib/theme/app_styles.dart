import 'package:flutter/material.dart';

/// Centralized style tokens shared across the app for consistent look and feel.
/// Shared UI constants to keep screens aligned and easier to test across widgets/screens.
class AppSpacing {
  static const page = EdgeInsets.all(24);
  static const card = EdgeInsets.all(18);
  static const sectionGap = SizedBox(height: 24);
  static const itemGap = SizedBox(height: 12);
}

/// Shared radii used across cards, chips, and buttons.
class AppRadius {
  static const card = 18.0;
  static const chip = 12.0;
  static const button = 12.0;
}

/// Central color palette for consistency.
class AppColors {
  static const primary = Color(0xFF4A148C);
  static const accent = Color(0xFF7E57C2);
  static const highlight = Color(0xFFF7DFA5);
  static const textOnPrimary = Colors.white;
}

/// Common gradients reused on multiple screens.
class AppGradients {
  static const background = LinearGradient(
    colors: [
      Color(0xFFB388FF),
      Color(0xFF7E57C2),
      Color(0xFF5E35B1),
      Color(0xFF311B92),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Standard button styles so CTAs look/behave consistently in tests and UI.
class AppButtons {
  static ButtonStyle primaryElevated() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    );
  }

  static ButtonStyle primaryOutlined() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.textOnPrimary,
      side: BorderSide(color: AppColors.textOnPrimary.withValues(alpha: 0.5)),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    );
  }
}
