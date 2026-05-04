import 'dart:ui';

import 'package:flutter/material.dart';

/// Glass-style panel. Use **blur sparingly** (app bar, hero, one CTA).
///
/// For dense lists / product grids use [blur] `false` — tint + border only.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.blur = true,
    this.sigma = 12,
    this.fillColor,
    this.borderColor,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  /// When `false`, skips [BackdropFilter] (lighter GPU / scroll-friendly).
  final bool blur;
  final double sigma;

  /// Frost tint; default ~15% white.
  final Color? fillColor;

  /// Edge highlight; default ~20% white.
  final Color? borderColor;

  static Color defaultFill(BuildContext context) =>
      Colors.white.withValues(alpha: 0.15);

  static Color defaultBorder(BuildContext context) =>
      Colors.white.withValues(alpha: 0.22);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final fill = fillColor ?? defaultFill(context);
    final stroke = borderColor ?? defaultBorder(context);

    final decorated = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: Border.all(color: stroke),
      ),
      child: child,
    );

    if (!blur) {
      return ClipRRect(borderRadius: radius, child: decorated);
    }

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: decorated,
      ),
    );
  }
}
