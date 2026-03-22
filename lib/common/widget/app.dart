import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/pages/home_page/custom_riverpod/post_notifier.dart';
import '../constant/theme_config.dart';
import '../dependency/dependencies.dart';
import '../dependency/scope/dependency_scope.dart';
import '../provider/theme_provider.dart';
import '../router/app_router.dart';

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
            child: const _AppRouter(),
          );
        },
      ),
    );
  }
}

class _AppRouter extends ConsumerWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'DUONET',
      theme: ThemeConfig.lightTheme,
      darkTheme: ThemeConfig.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}