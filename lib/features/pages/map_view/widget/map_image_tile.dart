import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../common/widget/app_image_viewer.dart';
import 'map_theme.dart';

class MapImageTile extends StatelessWidget {
  const MapImageTile({
    super.key,
    required this.url,
    required this.index,
    required this.allUrls,
    this.title,
  });

  final String url;
  final int index;
  final List<String> allUrls;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (ctx, _) => Container(
            color: kMapField,
            child: const Center(
              child: SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  valueColor: AlwaysStoppedAnimation<Color>(kMapBlue),
                ),
              ),
            ),
          ),
          errorWidget: (ctx, _, _) => Container(
            color: kMapField,
            child: const Icon(Icons.broken_image_outlined, size: 18, color: kMapHint),
          ),
        ),
        Positioned(
          top: 5, right: 5,
          child: GestureDetector(
            onTap: () => AppImageViewer.show(
              context,
              urls: allUrls,
              initialIndex: index,
              title: title,
            ),
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: const Icon(Icons.open_in_full_rounded, size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}