import 'package:flutter/material.dart';

import '../../../common/widget/scaffold_key_scope.dart';
import '../common/placeholder_body.dart';

class SearchCarPage extends StatelessWidget {
  const SearchCarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => ScaffoldKeyScope.of(context).currentState?.openDrawer(),
        ),
        title: const Text('Search Car'),
        centerTitle: true,
      ),
      body: const PlaceholderBody(
        icon: Icons.directions_car_rounded,
        color: Color(0xFFF59E0B),
        title: 'Search Car',
        subtitle: 'Track vehicles, view status and assign\ncars to active workers in real time.',
      ),
    );
  }
}