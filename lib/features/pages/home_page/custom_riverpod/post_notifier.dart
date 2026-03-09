import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../common/constant/api_config.dart';
import '../../../../common/repository/request_repository.dart';
import '../../../../common/service/request_service.dart';
import '../model/post_response.dart';
import '../service/post_service.dart';

class PostNotifier extends StateNotifier<AsyncValue<List<PostResponse>>> {
  PostNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchPosts();
  }

  final PostService _service;

  Future<void> fetchPosts() async {
    try {
      state = const AsyncValue.loading();
      final posts = await _service.findPosts();
      state = AsyncValue.data(posts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final postsProvider =
    StateNotifierProvider<PostNotifier, AsyncValue<List<PostResponse>>>((ref) {
      final service = ref.watch(postServiceProvider);
      return PostNotifier(service);
    });

final postServiceProvider = Provider<PostService>((ref) {
  final requestRepository = ref.watch(requestRepositoryProvider);
  return PostService(requestRepository: requestRepository);
});

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json', 'User-Agent': 'FlutterApp'},
    ),
  );
  return RequestServiceImpl(dio);
});
