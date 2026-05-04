import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Grid tile entrance: fade + slight rise + settle scale (shop home).
class StaggerGridItem extends StatelessWidget {
  const StaggerGridItem({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ms = math.min(index, 20) * 24;
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + ms),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, t, child) {
        final curved = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: curved,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - curved)),
            child: Transform.scale(
              scale: 0.94 + 0.06 * curved,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
