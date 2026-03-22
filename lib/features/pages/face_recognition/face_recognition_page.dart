import 'package:flutter/material.dart';

import '../../../common/widget/scaffold_key_scope.dart';
import '../common/placeholder_body.dart';

class FaceRecognitionPage extends StatelessWidget {
  const FaceRecognitionPage({super.key});

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
      body: const PlaceholderBody(
        icon: Icons.face_rounded,
        color: Color(0xFF7C6FF7),
        title: 'Face Recognition',
        subtitle: 'Identify and verify workers using\nAI-powered facial recognition technology.',
      ),
    );
  }
}