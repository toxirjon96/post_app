import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../custom_riverpod/post_notifier.dart';
import 'post_list_view.dart';

class PostRiverpodVisualizer extends ConsumerWidget {
  const PostRiverpodVisualizer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsState = ref.watch(postsProvider);

    Future<void> refresh() =>
        ref.read(postsProvider.notifier).fetchPosts();

    return postsState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Center(
              child: Column(
                children: [
                  const Text('Tizim xatoligi!',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      data: (posts) => PostListView(posts: posts, onRefresh: refresh),
    );
  }
}