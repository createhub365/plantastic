import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared card / panel shells — soft shadow, 16px radius.
abstract final class AppDecorations {
  static BoxDecoration premiumCard({
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.card,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Highlight / chip pill — light green fill.
  static BoxDecoration tagPill() {
    return BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(20),
    );
  }
}
