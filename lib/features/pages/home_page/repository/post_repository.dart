import '../model/post_response.dart';

abstract interface class PostRepository {
  Future<List<PostResponse>> findPosts();
}
