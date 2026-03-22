import 'package:flutter/material.dart';

import '../../../common/widget/scaffold_key_scope.dart';
import '../common/placeholder_body.dart';

class HotelsPage extends StatelessWidget {
  const HotelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => ScaffoldKeyScope.of(context).currentState?.openDrawer(),
        ),
        title: const Text('Hotels'),
        centerTitle: true,
      ),
      body: const PlaceholderBody(
        icon: Icons.hotel_rounded,
        color: Color(0xFFFF6B6B),
        title: 'Hotels',
        subtitle: 'Browse and book accommodation\nfor field workers and fleet drivers.',
      ),
    );
  }
}