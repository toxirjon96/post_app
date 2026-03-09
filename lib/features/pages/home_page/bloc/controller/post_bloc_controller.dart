import '../post_bloc.dart';

class PostBlocController {
  const PostBlocController._();

  static void findPosts({required PostBloc targetBloc}) {
    targetBloc.add(PostFind$Event());
  }
}
