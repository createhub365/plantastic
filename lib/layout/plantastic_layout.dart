import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared breakpoints for shop + admin (browser / window resize).
abstract final class PlantasticLayout {
  PlantasticLayout._();

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double heightOf(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  /// Side inset for page content (scales with viewport).
  static double gutter(BuildContext context) =>
      (widthOf(context) * 0.035).clamp(12.0, 48.0);

  /// Horizontal padding scales slightly with viewport (mobile → ultra-wide).
  static EdgeInsets pageHorizontalPadding(BuildContext context) {
    final h = gutter(context);
    return EdgeInsets.symmetric(horizontal: h);
  }

  /// Readable column on tablets / desktop; full-bleed on narrow phones.
  static double contentMaxWidth(BuildContext context) {
    final w = widthOf(context);
    if (w < 600) return w;
    return (w * 0.92).clamp(520.0, 1040.0);
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

  /// Shop catalogue: spacing between the two tiles in each row ([Row]),
  /// and vertical space between successive rows ([SliverList]).
  static const double shopGridCrossSpacing = 12.0;
  static const double shopGridMainSpacing = 12.0;

  /// Detail hero **square** side (logical px): content column width − gutters.
  /// Uploaded images are normalized to a 1080×1080 px square canvas in code.
  static double detailHeroSquareSide(BuildContext context) {
    final g = gutter(context);
    final w = widthOf(context);
    final cap = contentMaxWidth(context);
    final usable = math.min(w, cap) - 2 * g;
    return usable.clamp(160.0, 1200.0);
  }
}
