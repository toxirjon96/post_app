import 'package:flutter/material.dart';

import 'map_theme.dart';

class MapPagBtn extends StatelessWidget {
  const MapPagBtn({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 28, height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: enabled
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Icon(
        icon,
        size: 18,
        color: enabled ? kMapText : kMapHint.withValues(alpha: 0.4),
      ),
    ),
  );
}