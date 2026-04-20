import 'package:flutter/material.dart';

import '../model/map_item.dart';
import 'map_theme.dart';

class MapDateTile extends StatelessWidget {
  const MapDateTile({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final DateTime? value;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final has = value != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: has ? accent.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: has ? accent.withValues(alpha: 0.50) : Colors.white.withValues(alpha: 0.10),
            width: has ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: has ? accent : kMapHint),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: has ? accent : kMapHint,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    has ? fmtMapDateTime(value!) : 'Select…',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: has ? kMapText : kMapHint,
                      fontWeight: has ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.expand_more_rounded, size: 14, color: has ? accent : kMapHint),
          ],
        ),
      ),
    );
  }
}