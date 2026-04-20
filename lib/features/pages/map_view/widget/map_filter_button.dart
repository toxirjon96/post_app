import 'package:flutter/material.dart';

import 'map_theme.dart';

class MapFilterButton extends StatelessWidget {
  const MapFilterButton({
    super.key,
    required this.icon,
    required this.label,
    required this.filled,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: filled
              ? LinearGradient(colors: [color, color.withValues(alpha: 0.70)])
              : null,
          color: filled ? null : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: filled ? null : Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: filled
              ? [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: filled ? Colors.white : kMapTextSec),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : kMapTextSec,
              ),
            ),
          ],
        ),
      ),
    );
  }
}