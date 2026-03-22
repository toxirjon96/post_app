import 'package:flutter/material.dart';

extension ResponsiveContext on BuildContext {
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  bool get isTablet => MediaQuery.sizeOf(this).shortestSide >= 600;

  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Responsive value: returns [landscape] when in landscape, [portrait] otherwise.
  T responsive<T>({required T portrait, required T landscape}) =>
      isLandscape ? landscape : portrait;
}