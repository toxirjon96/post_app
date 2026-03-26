import 'package:flutter/material.dart';

extension ResponsiveContext on BuildContext {
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  double get _shortestSide => MediaQuery.sizeOf(this).shortestSide;

  /// Phones: shortestSide < 600
  bool get isPhone => _shortestSide < 600;

  /// Tablets: shortestSide >= 600
  bool get isTablet => _shortestSide >= 600;

  /// Large tablets / small desktops: shortestSide >= 900
  bool get isLargeTablet => _shortestSide >= 900;

  double get screenWidth  => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  // ── Scale factors ────────────────────────────────────────────────────────
  // Calibrated for Samsung Tab S10 (~720 dp shortest side) and
  // Samsung Tab S6 / S8 (~800 dp shortest side).

  /// Multiplier for **font sizes**.
  double get _textSF {
    final ss = _shortestSide;
    if (ss >= 900) return 1.22;
    if (ss >= 780) return 1.16; // Tab S6, Tab S8, Tab S9
    if (ss >= 680) return 1.10; // Tab S10, Tab A9+
    if (ss >= 600) return 1.06; // 7-8" small tablets
    return 1.0;
  }

  /// Multiplier for **layout dimensions** (padding, gaps, icon sizes).
  double get _layoutSF {
    final ss = _shortestSide;
    if (ss >= 900) return 1.18;
    if (ss >= 780) return 1.12;
    if (ss >= 680) return 1.07;
    if (ss >= 600) return 1.04;
    return 1.0;
  }

  /// Scale a font size for the current device.
  /// Usage: `context.sp(14)` — returns 14 on phones, ~16.2 on Tab S6.
  double sp(double size) => size * _textSF;

  /// Scale a layout dimension (padding, icon size, gap) for the current device.
  /// Usage: `context.dp(16)` — returns 16 on phones, ~17.9 on Tab S6.
  double dp(double size) => size * _layoutSF;

  /// Responsive value: returns [landscape] when in landscape, [portrait] otherwise.
  T responsive<T>({required T portrait, required T landscape}) =>
      isLandscape ? landscape : portrait;

  /// Returns a value based on screen-size breakpoints.
  /// Uses [largeTablet] for shortestSide >= 900 (if provided),
  /// [tablet] for shortestSide >= 600, and [phone] otherwise.
  T responsiveSize<T>({required T phone, required T tablet, T? largeTablet}) {
    if (largeTablet != null && isLargeTablet) return largeTablet;
    if (isTablet) return tablet;
    return phone;
  }
}