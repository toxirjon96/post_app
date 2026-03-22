import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/dependency/scope/dependency_scope.dart';
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
    _postBloc = PostBloc(
      requestRepository: context.requestRepository,
    );
    PostBlocController.findPosts(targetBloc: _postBloc);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PostBloc>.value(
      value: _postBloc,
      child: BlocConsumer<PostBloc, PostState>(
        builder: (postContext, postState) {
          if (postState is PostLoading$State) {
            return Center(child: CircularProgressIndicator());
          } else if (postState is PostError$State) {
            return Center(
              child: Text(
                postState.message,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 3,
              ),
            );
          } else if (postState is PostListFindSuccess$State &&
              postState.resultList.isNotEmpty) {
            final posts = postState.resultList;
            return PostListView(posts: posts);
          } else if (postState is PostListFindSuccess$State &&
              postState.resultList.isEmpty) {
            return Center(
              child: Text(
                'Ma\'lumot topilmadi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 3,
              ),
            );
          } else {
            return Center(
              child: Text(
                'Tizimda xatolik',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 3,
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
