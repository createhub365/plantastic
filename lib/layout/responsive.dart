import 'package:flutter/material.dart';

import 'screen_breakpoints.dart';

/// Breakpoint helpers + spacing/grid tuning for adaptive shop UI.
abstract final class Responsive {
  Responsive._();

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < ScreenBreakpoints.mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= ScreenBreakpoints.mobile && w < ScreenBreakpoints.tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= ScreenBreakpoints.tablet;

  /// Section / grid gaps — desktop gets more breathing room.
  static double sectionGap(BuildContext context) {
    if (isDesktop(context)) return 24;
    if (isTablet(context)) return 18;
    return 16;
  }

  /// Shop grid columns: 1 (narrow), 2 (mobile), 3 (tablet), 5 (desktop).
  static int shopCrossAxisCount(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < ScreenBreakpoints.narrowShop) return 1;
    if (w < ScreenBreakpoints.mobile) return 2;
    if (w < ScreenBreakpoints.tablet) return 3;
    return 5;
  }
}
