import 'package:flutter/material.dart';

import '../../../common/widget/scaffold_key_scope.dart';
import '../common/placeholder_body.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => ScaffoldKeyScope.of(context).currentState?.openDrawer(),
        ),
        title: const Text('Favorites'),
        centerTitle: true,
      ),
      body: const PlaceholderBody(
        icon: Icons.favorite_rounded,
        color: Color(0xFFFF4081),
        title: 'Favorites',
        subtitle: 'Your saved locations, vehicles and\nfrequently accessed resources.',
      ),
    );
  }
}