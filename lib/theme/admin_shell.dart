import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Admin surfaces aligned with shopper [HomeScreen]: mint gradient backdrop +
/// light [AppTheme.light] typography and controls.
abstract final class AdminShell {
  static const double horizontalPadding = 14;

  /// Same soft gradient as the shopper scaffold.
  static BoxDecoration get shopperBackground =>
      const BoxDecoration(gradient: AppTheme.scaffoldGradient);

  /// Transparent scaffold + shopper-like tab/FAB tweaks on top of [AppTheme.light].
  static ThemeData themeShopperChrome() {
    final base = AppTheme.light();
    final scheme = base.colorScheme;
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          borderSide: BorderSide(color: scheme.primary, width: 3),
          insets: const EdgeInsets.symmetric(horizontal: 10),
        ),
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant.withValues(alpha: 0.82),
        labelStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 0.06,
          color: scheme.primary,
        ),
        unselectedLabelStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.04,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.78),
        ),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppTheme.mintGlow.withValues(alpha: 0.2);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppTheme.mintGlow.withValues(alpha: 0.1);
          }
          return null;
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppTheme.forestBright,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
