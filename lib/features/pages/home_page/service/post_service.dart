import 'dart:convert';

import '../../../../common/constant/api_url.dart';
import '../../../../common/exception/response_format_exception.dart';
import '../../../../common/repository/request_repository.dart';
import '../model/post_response.dart';
import '../repository/post_repository.dart';

class PostService implements PostRepository {
  const PostService({required RequestRepository requestRepository})
    : _requestRepository = requestRepository;

  final RequestRepository _requestRepository;

  @override
  Future<List<PostResponse>> findPosts() async {
    Object? response = await _requestRepository.get(ApiUrl.posts);
    if (response != null && response is String) {
      final resultJson = jsonDecode(response);
      if (resultJson != null && resultJson is List<Object?>) {
        return resultJson.map((post) {
          return PostResponse.fromJson(post as Map<String, Object?>);
        }).toList();
      }
      return [];
    } else {
      throw ResponseFormatException('Ma\'lumot noma\'lum formatda');
    }
  }
}