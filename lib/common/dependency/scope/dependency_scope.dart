import 'package:flutter/material.dart';

import '../dependencies.dart';

class DependencyScope extends InheritedWidget {
  const DependencyScope({
    super.key,
    required super.child,
    required this.dependencies,
  });

  final Dependencies dependencies;

  static DependencyScope? maybeOf(BuildContext context,
          {bool listen = false}) =>
      listen
          ? context.dependOnInheritedWidgetOfExactType<DependencyScope>()
          : (context
              .getElementForInheritedWidgetOfExactType<DependencyScope>()
              ?.widget as DependencyScope?);

  static Never _notFoundInheritedWidgetOfExactType() => throw ArgumentError(
        'Out of scope, not found inherited widget '
            'a DependenciesScope of the exact type',
        'out_of_scope',
      );

  static Dependencies of(BuildContext context, {bool listen = false}) =>
      maybeOf(context, listen: listen)?.dependencies ??
      _notFoundInheritedWidgetOfExactType();

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
