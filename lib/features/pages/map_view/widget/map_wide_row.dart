import 'package:flutter/material.dart';

import '../model/map_item.dart';
import 'map_chip.dart';
import 'map_theme.dart';

class MapWideRow extends StatelessWidget {
  const MapWideRow({
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
    final even = rowIndex % 2 == 0;
    return InkWell(
      onTap: onTap,
      splashColor: kMapBlue.withValues(alpha: 0.08),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 44),
        decoration: BoxDecoration(
          color: isSelected
              ? kMapBlue.withValues(alpha: 0.13)
              : even ? Colors.transparent : Colors.white.withValues(alpha: 0.03),
          border: Border(
            left: isSelected ? const BorderSide(color: kMapBlue, width: 3) : BorderSide.none,
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Text(
                    '${rowIndex + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? kMapBlue : kMapTextSec,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: MapChip(label: '#${item.id}', color: kMapBlue),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? kMapText : kMapText.withValues(alpha: 0.82),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      height: 1.4,
                    ),
                    softWrap: true,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 10, color: kMapHint),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          fmtMapDate(item.createdAt),
                          style: const TextStyle(fontSize: 11.5, color: kMapTextSec, height: 1.35),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}