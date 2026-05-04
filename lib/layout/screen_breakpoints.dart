/// Canonical width breakpoints for shop layout (mobile / tablet / desktop).
abstract final class ScreenBreakpoints {
  ScreenBreakpoints._();

  static const int mobile = 600;
  static const int tablet = 1024;

  /// Very narrow viewports: force a single-column shop grid (readable cards).
  static const int narrowShop = 360;
}
