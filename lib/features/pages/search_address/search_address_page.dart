import 'package:flutter/material.dart';

import '../../../common/widget/scaffold_key_scope.dart';
import '../common/placeholder_body.dart';

class SearchAddressPage extends StatelessWidget {
  const SearchAddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => ScaffoldKeyScope.of(context).currentState?.openDrawer(),
        ),
        title: const Text('Search Address'),
        centerTitle: true,
      ),
      body: const PlaceholderBody(
        icon: Icons.location_on_rounded,
        color: Color(0xFF00E5CC),
        title: 'Search Address',
        subtitle: 'Find locations, routes and GPS coordinates\nacross the DUONET fleet network.',
      ),
    );
  }
}