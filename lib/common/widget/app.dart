import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/face_id/widget/face_id_page.dart';
import '../../features/pages/home_page/custom_riverpod/post_notifier.dart';
import '../constant/theme_config.dart';
import '../dependency/dependencies.dart';
import '../dependency/scope/dependency_scope.dart';

class App extends StatelessWidget {
  const App({super.key, required this.dependencies});

  final Dependencies dependencies;

  void run() => runApp(this);

  @override
  Widget build(BuildContext context) {
    return DependencyScope(
      dependencies: dependencies,
      child: Builder(
        builder: (context) {
          return ProviderScope(
            overrides: [
              requestRepositoryProvider.overrideWithValue(
                DependencyScope.of(context).requestRepository,
              ),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Postlar',
              theme: ThemeConfig.theme,
              home: const FaceIdPage(),
            ),
          );
        },
      ),
    );
  }
}