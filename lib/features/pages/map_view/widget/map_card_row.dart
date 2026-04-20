import 'package:flutter/material.dart';

import '../model/map_item.dart';
import 'map_chip.dart';
import 'map_theme.dart';

class MapCardRow extends StatelessWidget {
  const MapCardRow({
    super.key,
    required this.rowIndex,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final int rowIndex;
  final MapItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: kMapBlue.withValues(alpha: 0.08),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
        decoration: BoxDecoration(
          color: isSelected ? kMapBlue.withValues(alpha: 0.13) : Colors.transparent,
          border: Border(
            left: isSelected ? const BorderSide(color: kMapBlue, width: 3) : BorderSide.none,
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 22, height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kMapBlue.withValues(alpha: 0.20)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '${rowIndex + 1}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? kMapBlue : kMapTextSec,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                MapChip(label: '#${item.id}', color: kMapBlue),
                const Spacer(),
                const Icon(Icons.calendar_today_rounded, size: 10, color: kMapHint),
                const SizedBox(width: 4),
                Text(fmtMapDate(item.createdAt), style: const TextStyle(fontSize: 11, color: kMapTextSec)),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              item.name,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? kMapText : kMapText.withValues(alpha: 0.88),
                height: 1.35,
              ),
              softWrap: true,
            ),
          ],
        ),
      ),
    );
  }
}