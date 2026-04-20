import 'package:flutter/material.dart';

class MapTapIcon extends StatelessWidget {
  const MapTapIcon({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 32,
    this.iconSize = 18,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Icon(icon, size: iconSize, color: Colors.white),
      ),
    );
  }
}