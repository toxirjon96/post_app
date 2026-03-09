import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../custom_riverpod/post_notifier.dart';
import 'post_list_view.dart';

class PostRiverpodVisualizer extends ConsumerWidget {
  const PostRiverpodVisualizer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsState = ref.watch(postsProvider);

    return postsState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Tizim xatoligi!')),
      data: (posts) => PostListView(posts: posts),
    );
  }
}