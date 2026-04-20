import 'package:flutter/material.dart';

import 'map_theme.dart';

class MapSearchField extends StatelessWidget {
  const MapSearchField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: kMapText, fontSize: 13.5),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: kMapHint),
          hintText: 'Search by name…',
          hintStyle: const TextStyle(color: kMapHint, fontSize: 13.5),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (ctx, val, _) => val.text.isNotEmpty
                ? GestureDetector(
                    onTap: controller.clear,
                    child: const Icon(Icons.close_rounded, size: 16, color: kMapHint),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}