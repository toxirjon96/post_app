import 'package:bloc/bloc.dart';

import '../../../../common/exception/request_exception.dart';
import '../../../../common/exception/response_format_exception.dart';
import '../../../../common/exception/status_code_exception.dart';
import '../../../../common/exception/unknown_exception.dart';
import '../../../../common/repository/request_repository.dart';
import '../../../../common/util/logger.dart';
import '../model/post_response.dart';
import '../repository/post_repository.dart';
import '../service/post_service.dart';

part 'post_event.dart';
part 'post_state.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  PostBloc({required RequestRepository requestRepository})
    : _postRepository = PostService(requestRepository: requestRepository),
      super(PostInitial$State()) {
    on<PostEvent>(
      (event, emit) => switch (event) {
        PostFind$Event _ => _findPosts(event, emit),
      },
    );
  }

  final PostRepository _postRepository;

  void _findPosts(PostFind$Event event, Emitter<PostState> emit) async {
    try {
      emit(PostLoading$State());
      final rList = await _postRepository.findPosts();
      emit(PostListFindSuccess$State(resultList: rList));
    } on StatusCodeException catch (e) {
      warning(e);
      emit(
        PostError$State(
          message:
              'API bilan bog\'liq muammo mavjud! Administrator bilan bog\'laning!',
        ),
      );
    } on RequestException catch (e) {
      warning(e);
      emit(
        PostError$State(
          message:
              'So\'rov jo\'natishda xatolik! Administrator bilan bog\'laning!',
        ),
      );
    } on UnknownException catch (e) {
      warning(e);
      emit(
        PostError$State(
          message: 'Noma\'lum xatolik! Administrator bilan bog\'laning!',
        ),
      );
    } on ResponseFormatException catch (e) {
      warning(e);
      emit(
        PostError$State(
          message:
              'Response formatida xatolik! Administrator bilan bog\'laning!',
        ),
      );
    }
  }
}
