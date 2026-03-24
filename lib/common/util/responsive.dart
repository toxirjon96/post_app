import 'package:flutter/material.dart';

extension ResponsiveContext on BuildContext {
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  /// Phones: shortestSide < 600
  bool get isPhone => MediaQuery.sizeOf(this).shortestSide < 600;

  /// Tablets: shortestSide >= 600
  bool get isTablet => MediaQuery.sizeOf(this).shortestSide >= 600;

  /// Large tablets / small desktops: shortestSide >= 900
  bool get isLargeTablet => MediaQuery.sizeOf(this).shortestSide >= 900;

  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

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