import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Admin surfaces: mint gradient backdrop + [AppTheme.light] controls — cards, motion,
/// and contrast tuned for long sessions.
abstract final class AdminShell {
  static const double horizontalPadding = 14;

  /// Neutral dashboard canvas — distinct from shopper mint gradient.
  static const Color dashboardCanvas = Color(0xFFF5F7FA);

  static const double sidebarWidth = 250;

  static const Curve motionCurve = Curves.easeOutCubic;
  static const Duration motionMedium = Duration(milliseconds: 320);

  static const double cardRadius = 16;
  static const double cardRadiusSm = 14;

  static BoxDecoration get shopperBackground =>
      const BoxDecoration(gradient: AppTheme.scaffoldGradient);

  static BoxDecoration get dashboardBackdrop =>
      const BoxDecoration(color: dashboardCanvas);

  /// Standard elevated admin surface — white frost + forest-tint shadow.
  static BoxDecoration cardDecoration(
    ColorScheme scheme, {
    bool elevated = true,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.97),
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: scheme.outline.withValues(alpha: 0.38)),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: AppTheme.forest.withValues(alpha: 0.065),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  /// Theme layered on shopper [AppTheme.light] inside admin flows.
  static ThemeData themeShopperChrome() {
    final base = AppTheme.light();
    final scheme = base.colorScheme;
    final tt = base.textTheme;

    final tabDecoration = TabBarThemeData(
      dividerColor: Colors.transparent,
      dividerHeight: 0,
      indicatorSize: TabBarIndicatorSize.label,
      indicatorAnimation: TabIndicatorAnimation.linear,
      splashFactory: InkSparkle.splashFactory,
      indicator: UnderlineTabIndicator(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        borderSide: BorderSide(color: scheme.primary, width: 3.2),
        insets: const EdgeInsets.symmetric(horizontal: 12),
      ),
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant.withValues(alpha: 0.84),
      labelStyle: tt.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        letterSpacing: 0.05,
      ),
      unselectedLabelStyle: tt.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        letterSpacing: 0.03,
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
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.32),
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white.withValues(alpha: 0.99),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: const Color(0xFF2A3830),
        contentTextStyle: tt.bodyMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.96),
          height: 1.38,
          fontWeight: FontWeight.w500,
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: tt.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.12,
          color: scheme.onSurface,
        ),
        subtitleTextStyle: tt.bodyMedium?.copyWith(
          height: 1.42,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.93),
          fontWeight: FontWeight.w500,
        ),
        iconColor: scheme.primary.withValues(alpha: 0.9),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        expandedAlignment: Alignment.centerLeft,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        childrenPadding: EdgeInsets.zero,
        iconColor: scheme.primary,
        collapsedIconColor: scheme.onSurfaceVariant.withValues(alpha: 0.75),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        color: Colors.white.withValues(alpha: 0.985),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
        ),
      ),
      tabBarTheme: tabDecoration,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppTheme.forestBright,
        foregroundColor: Colors.white,
        elevation: 3,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  /// Admin dashboard / editor — neutral grey field, white panels, green accents only on CTAs.
  static ThemeData themeDashboardChrome() {
    final base = themeShopperChrome();
    final scheme = base.colorScheme;
    final neutralText = const Color(0xFF2D3748);

    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.28),
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: neutralText,
        displayColor: neutralText,
      ),
      listTileTheme: base.listTileTheme.copyWith(
        titleTextStyle: base.listTileTheme.titleTextStyle?.copyWith(
          color: neutralText,
        ),
      ),
    );
  }
}
