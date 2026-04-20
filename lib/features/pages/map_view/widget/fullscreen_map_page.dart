import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'map_tap_icon.dart';
import 'map_theme.dart';

class FullscreenMapPage extends StatefulWidget {
  const FullscreenMapPage({super.key});

  @override
  State<FullscreenMapPage> createState() => _FullscreenMapPageState();
}

class _FullscreenMapPageState extends State<FullscreenMapPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      children: [
        MapLibreMap(
          styleString: kOsmStyle,
          initialCameraPosition: const CameraPosition(
            target: LatLng(41.3775, 64.5853),
            zoom: 5.2,
          ),
          compassEnabled: true,
          myLocationEnabled: false,
          trackCameraPosition: false,
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: MapTapIcon(
              icon: Icons.fullscreen_exit_rounded,
              size: 40,
              iconSize: 20,
              onTap: () => Navigator.pop(context),
            ),
          ),
        ),
      ],
    ),
  );
}