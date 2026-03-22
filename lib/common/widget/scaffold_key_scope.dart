import 'package:flutter/material.dart';

class ScaffoldKeyScope extends InheritedWidget {
  const ScaffoldKeyScope({
    super.key,
    required this.scaffoldKey,
    required super.child,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  static GlobalKey<ScaffoldState>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ScaffoldKeyScope>()?.scaffoldKey;

  static GlobalKey<ScaffoldState> of(BuildContext context) =>
      maybeOf(context) ??
      (throw FlutterError('ScaffoldKeyScope not found in widget tree'));

  @override
  bool updateShouldNotify(ScaffoldKeyScope old) =>
      scaffoldKey != old.scaffoldKey;
}