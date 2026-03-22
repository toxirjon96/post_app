import 'package:flutter/material.dart';

import '../../../common/widget/scaffold_key_scope.dart';
import '../common/placeholder_body.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  Future<void> _handleRefresh() => Future.delayed(const Duration(milliseconds: 800));

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
      body: PlaceholderBody(
        icon: Icons.favorite_rounded,
        color: const Color(0xFFFF4081),
        title: 'Favorites',
        subtitle: 'Your saved locations, vehicles and\nfrequently accessed resources.',
        onRefresh: _handleRefresh,
      ),
    );
  }
}