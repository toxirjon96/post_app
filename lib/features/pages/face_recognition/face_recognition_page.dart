import 'package:flutter/material.dart';

import '../../../common/widget/scaffold_key_scope.dart';
import '../common/placeholder_body.dart';

class FaceRecognitionPage extends StatelessWidget {
  const FaceRecognitionPage({super.key});

  Future<void> _handleRefresh() => Future.delayed(const Duration(milliseconds: 800));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => ScaffoldKeyScope.of(context).currentState?.openDrawer(),
        ),
        title: const Text('Face Recognition'),
        centerTitle: true,
      ),
      body: PlaceholderBody(
        icon: Icons.face_rounded,
        color: const Color(0xFF7C6FF7),
        title: 'Face Recognition',
        subtitle: 'Identify and verify workers using\nAI-powered facial recognition technology.',
        onRefresh: _handleRefresh,
      ),
    );
  }
}