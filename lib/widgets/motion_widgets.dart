import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../layout/responsive.dart';
import '../theme/app_motion.dart';

/// Desktop-only subtle hover lift (pointer devices); no-op on mobile/tablet.
class DesktopHoverScale extends StatefulWidget {
  const DesktopHoverScale({
    super.key,
    required this.child,
    this.hoverScale = 1.05,
    this.duration = const Duration(milliseconds: 150),
  });

  final Widget child;
  final double hoverScale;
  final Duration duration;

  @override
  State<DesktopHoverScale> createState() => _DesktopHoverScaleState();
}

class _DesktopHoverScaleState extends State<DesktopHoverScale> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    if (!Responsive.isDesktop(context)) return widget.child;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? widget.hoverScale : 1,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Press-down scale around shop grid cards (pairs with [ProductShopCard] ink splash).
class ScaleTap extends StatefulWidget {
  const ScaleTap({
    super.key,
    required this.child,
    this.pressedScale = 0.96,
    this.duration = AppMotion.tap,
  });

  final Widget child;
  final double pressedScale;
  final Duration duration;

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => setState(() => _scale = widget.pressedScale),
      onPointerUp: (_) => setState(() => _scale = 1),
      onPointerCancel: (_) => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: widget.duration,
        curve: AppMotion.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Grid tile entrance: fade + slight rise + settle scale (shop home).
class StaggerGridItem extends StatelessWidget {
  const StaggerGridItem({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ms = math.min(index, 20) * 22;
    final baseMs = AppMotion.pageLoad.inMilliseconds;
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: baseMs + ms),
      curve: AppMotion.easeOut,
      tween: Tween(begin: 0, end: 1),
      builder: (context, t, child) {
        final curved = AppMotion.easeOut.transform(t);
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
