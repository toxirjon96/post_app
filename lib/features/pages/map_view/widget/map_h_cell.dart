import 'package:flutter/material.dart';

import 'map_theme.dart';

class MapHCell extends StatelessWidget {
  const MapHCell({super.key, required this.label, required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: kMapTextSec,
          letterSpacing: 0.9,
        ),
      ),
    ),
  );
}
