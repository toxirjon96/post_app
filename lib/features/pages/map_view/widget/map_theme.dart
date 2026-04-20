import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../common/constant/theme_config.dart';

// ── Design tokens shared across map view widgets ──────────────────────────────
const kMapBg      = AppColors.darkBg;
const kMapSurface = AppColors.darkSurface;
const kMapCard    = AppColors.darkCard;
const kMapElev    = AppColors.darkElevated;
const kMapBlue    = AppColors.electricBlue;
const kMapTeal    = AppColors.teal;
const kMapText    = Color(0xFFECF0FA);
const kMapTextSec = Color(0xFF6B7FA0);
const kMapHint    = Color(0xFF415070);
const kMapField   = Color(0xFF111E36);
const kMapError   = AppColors.coral;

const kOsmStyle = '''
{
  "version": 8,
  "sources": {
    "osm": {
      "type": "raster",
      "tiles": ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
      "tileSize": 256,
      "attribution": "© OpenStreetMap"
    }
  },
  "layers": [{"id":"osm","type":"raster","source":"osm","minzoom":0,"maxzoom":19}]
}
''';

Widget mapGlass({
  required Widget child,
  double radius = 20,
  double opacity = 0.80,
  EdgeInsetsGeometry? padding,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: kMapBg.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 0.8),
        ),
        child: child,
      ),
    ),
  );
}