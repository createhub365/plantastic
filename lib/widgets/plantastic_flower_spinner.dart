import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const double _kTwoPi = 6.283185307179586;

/// Tilt each direction (~±42°): left rock then right rock, no full spin.
const double _kSwingAmpRad = math.pi / 4.25;
Shader _flowerSweepShader(Rect bounds, double tau) {
  return SweepGradient(
    center: Alignment.center,
    startAngle: -0.35,
    endAngle: tau - 0.35,
    colors: const [
      Color(0xFFFF5FA2),
      Color(0xFFFF8A65),
      Color(0xFFFFD54F),
      Color(0xFF69F0AE),
      Color(0xFF40C4FF),
      Color(0xFFB388FF),
      Color(0xFFFF5FA2),
    ],
    stops: const [0.0, 0.16, 0.33, 0.5, 0.66, 0.83, 1.0],
  ).createShader(bounds);
}

/// Multicolour flower that **rocks left and right** (no continuous spin).
class PlantasticFlowerSpinner extends StatefulWidget {
  const PlantasticFlowerSpinner({
    super.key,
    this.size = 36,
    this.showSoftDisk = false,
    this.duration = const Duration(milliseconds: 920),
  });

  /// Visual size of the flower’s rotation box.
  final double size;

  /// Optional frosted pill behind the flower (catalog overlay / admin busy).
  final bool showSoftDisk;

  final Duration duration;

  @override
  State<PlantasticFlowerSpinner> createState() =>
      _PlantasticFlowerSpinnerState();
}

class _PlantasticFlowerSpinnerState extends State<PlantasticFlowerSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant PlantasticFlowerSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _spin.duration = widget.duration;
      if (_spin.isAnimating) _spin.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.size * (widget.showSoftDisk ? 0.34 : 1.0);
    final disk = widget.showSoftDisk ? widget.size * 1.9 : widget.size;

    final flower = AnimatedBuilder(
      animation: _spin,
      builder: (context, child) {
        return Transform.rotate(
          angle: _kSwingAmpRad * math.sin(_spin.value * _kTwoPi),
          child: child,
        );
      },
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => _flowerSweepShader(bounds, _kTwoPi),
        child: Icon(
          Icons.local_florist_rounded,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );

    if (!widget.showSoftDisk) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(child: flower),
      );
    }

    return SizedBox(
      width: disk,
      height: disk,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.92),
              const Color(0xFFE8F9EF),
              Color.lerp(
                    const Color(0xFFF2FFF6),
                    AppTheme.mintGlow.withValues(alpha: 0.22),
                    0.62,
                  ) ??
                  Colors.white,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.forest.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 6),
              spreadRadius: -3,
            ),
            BoxShadow(
              color: AppTheme.forestBright.withValues(alpha: 0.14),
              blurRadius: 12,
              offset: Offset.zero,
              spreadRadius: -4,
            ),
          ],
          border: Border.all(
            color: AppTheme.forestBright.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
        child: Center(child: flower),
      ),
    );
  }
}
