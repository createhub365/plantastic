import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'responsive.dart';
import 'screen_breakpoints.dart';

/// Shared breakpoints for shop + admin (browser / window resize).
abstract final class PlantasticLayout {
  PlantasticLayout._();

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double heightOf(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  /// Narrow phones (~iPhone SE) — tighter UI, single-column shop grid helpers.
  static const double breakpointCompactPhone = 380;

  /// Below this width the shop catalogue uses **one column** cards.
  static double get breakpointShopSingleColumn =>
      ScreenBreakpoints.narrowShop.toDouble();

  static bool compactPhone(BuildContext context) =>
      widthOf(context) < breakpointCompactPhone;

  static bool tabletOrWider(BuildContext context) =>
      widthOf(context) >= 720;

  /// Shop catalogue columns — uses [Responsive.shopCrossAxisCount].
  static int shopGridCrossAxisCount(BuildContext context) =>
      Responsive.shopCrossAxisCount(context);

  /// Side inset for page content (scales with viewport — tighter on small phones).
  static double gutter(BuildContext context) {
    final w = widthOf(context);
    if (w < 340) return 10.0;
    if (w < breakpointCompactPhone) return 12.0;
    return (w * 0.035).clamp(12.0, 48.0);
  }

  static double shopGridCrossSpacing(BuildContext context) =>
      compactPhone(context) ? 10.0 : Responsive.sectionGap(context);

  /// Vertical gap between catalogue grid rows.
  static double shopGridMainSpacing(BuildContext context) =>
      compactPhone(context) ? 10.0 : Responsive.sectionGap(context);

  /// Horizontal padding scales slightly with viewport (mobile → ultra-wide).
  static EdgeInsets pageHorizontalPadding(BuildContext context) {
    final h = gutter(context);
    return EdgeInsets.symmetric(horizontal: h);
  }

  /// Readable column on tablets / desktop; full-bleed on narrow phones.
  static double contentMaxWidth(BuildContext context) {
    final w = widthOf(context);
    if (Responsive.isMobile(context)) return w;
    if (Responsive.isTablet(context)) {
      return (w * 0.92).clamp(520.0, 960.0);
    }
    return (w * 0.95).clamp(520.0, 1200.0);
  }

  /// Wraps [child] in a centered column capped at [contentMaxWidth].
  static Widget constrainedBody(BuildContext context, {required Widget child}) {
    final maxW = contentMaxWidth(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: child,
      ),
    );
  }

  /// Uploaded images are normalized to a 1080×1080 px square canvas in code.
  static double detailHeroSquareSide(BuildContext context) {
    final g = gutter(context);
    final w = widthOf(context);
    final cap = contentMaxWidth(context);
    final usable = math.min(w, cap) - 2 * g;
    return usable.clamp(160.0, 1200.0);
  }
}
