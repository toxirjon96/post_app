import 'package:flutter/material.dart';

import 'map_theme.dart';

class MapPageNum extends StatelessWidget {
  const MapPageNum({
    super.key,
    required this.page,
    required this.current,
    required this.onTap,
  });

  final int page;
  final int current;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final active = page == current;
    return GestureDetector(
      onTap: () => onTap(page),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 26, height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? kMapBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: active ? null : Border.all(color: Colors.white.withValues(alpha: 0.14)),
          boxShadow: active
              ? [BoxShadow(color: kMapBlue.withValues(alpha: 0.32), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          '${page + 1}',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : kMapTextSec,
          ),
        ),
      ),
    );
  }
}