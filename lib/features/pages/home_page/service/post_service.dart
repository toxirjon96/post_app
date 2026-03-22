import '../../../../common/constant/api_url.dart';
import '../../../../common/repository/request_repository.dart';
import '../model/post_response.dart';
import '../repository/post_repository.dart';

class PostService implements PostRepository {
  const PostService({required RequestRepository requestRepository})
      : _requestRepository = requestRepository;

  final RequestRepository _requestRepository;

  @override
  Future<List<PostResponse>> findPosts() => _requestRepository.get(
        ApiUrl.posts,
        (json) => (json as List)
            .map((e) => PostResponse.fromJson(e as Map<String, Object?>))
            .toList(),
      );
}