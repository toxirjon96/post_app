import 'package:flutter/material.dart';

import '../../../common/widget/scaffold_key_scope.dart';
import '../common/placeholder_body.dart';

class OrganizationsPage extends StatelessWidget {
  const OrganizationsPage({super.key});

  Future<void> _handleRefresh() => Future.delayed(const Duration(milliseconds: 800));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => ScaffoldKeyScope.of(context).currentState?.openDrawer(),
        ),
        title: const Text('Organizations'),
        centerTitle: true,
      ),
      body: PlaceholderBody(
        icon: Icons.corporate_fare_rounded,
        color: const Color(0xFF00D68F),
        title: 'Organizations',
        subtitle: 'Manage partner organizations, branches\nand fleet management companies.',
        onRefresh: _handleRefresh,
      ),
    );
  }
}