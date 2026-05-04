import 'package:flutter/material.dart';

/// App-wide motion timings — short = premium.
abstract final class AppMotion {
  /// Tap / press micro-feedback (scale, ripples).
  static const Duration tap = Duration(milliseconds: 120);

  /// Stack route transitions (detail push/pop).
  static const Duration transition = Duration(milliseconds: 250);

  /// Content reveal after load (opacity, stagger base).
  static const Duration pageLoad = Duration(milliseconds: 450);

  /// Content acknowledgement (e.g. added to cart).
  static const Duration snackBarShort = Duration(milliseconds: 850);

  static const Curve easeOut = Curves.easeOutCubic;
}
