import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/util/extension/custom_context_extension.dart';
import '../bloc/controller/post_bloc_controller.dart';
import '../bloc/post_bloc.dart';
import 'post_list_view.dart';

class PostBlocVisualizer extends StatefulWidget {
  const PostBlocVisualizer({super.key});

  @override
  State<PostBlocVisualizer> createState() => _PostBlocVisualizerState();
}

class _PostBlocVisualizerState extends State<PostBlocVisualizer> {
  late final PostBloc _postBloc;

  @override
  void initState() {
    _postBloc = PostBloc(requestRepository: context.requestRepository);
    PostBlocController.findPosts(targetBloc: _postBloc);
    super.initState();
  }

  Future<void> _refresh() async {
    PostBlocController.findPosts(targetBloc: _postBloc);
    await _postBloc.stream.firstWhere(
      (s) => s is! PostLoading$State,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PostBloc>.value(
      value: _postBloc,
      child: BlocConsumer<PostBloc, PostState>(
        builder: (postContext, postState) {
          if (postState is PostLoading$State) {
            return const Center(child: CircularProgressIndicator());
          } else if (postState is PostError$State) {
            return _ErrorView(
              message: postState.message,
              onRetry: _refresh,
            );
          } else if (postState is PostListFindSuccess$State &&
              postState.resultList.isNotEmpty) {
            return PostListView(
              posts: postState.resultList,
              onRefresh: _refresh,
            );
          } else if (postState is PostListFindSuccess$State &&
              postState.resultList.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(
                    child: Text(
                      'Ma\'lumot topilmadi',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Text(
                'Tizimda xatolik',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            );
          }
        },
        listener: (postContext, postState) {
          if (postState is PostError$State) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  postState.message,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 3,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Text(
                  message,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}