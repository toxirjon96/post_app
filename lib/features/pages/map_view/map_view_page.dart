import 'package:flutter/material.dart';

import '../../../common/widget/scaffold_key_scope.dart';
import '../common/placeholder_body.dart';

class MapViewPage extends StatelessWidget {
  const MapViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => ScaffoldKeyScope.of(context).currentState?.openDrawer(),
        ),
        title: const Text('Map'),
        centerTitle: true,
      ),
      body: const PlaceholderBody(
        icon: Icons.map_rounded,
        color: Color(0xFF4CAF50),
        title: 'Fleet Map',
        subtitle: 'Live map view of all active vehicles,\nworkers and delivery routes.',
      ),
    );
  }
}