import 'package:flutter/material.dart';

import 'map_theme.dart';

class MapEmptyState extends StatelessWidget {
  const MapEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? kMapError : kMapBlue;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.22), width: 1.5),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(color: kMapText, fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kMapTextSec, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}