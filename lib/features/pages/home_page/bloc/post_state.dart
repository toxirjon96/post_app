part of 'post_bloc.dart';

sealed class PostState {
  const PostState._();
}

final class PostInitial$State extends PostState {
  const PostInitial$State() : super._();
}

final class PostLoading$State extends PostState {
  const PostLoading$State() : super._();
}

final class PostListFindSuccess$State extends PostState {
  const PostListFindSuccess$State({required this.resultList}) : super._();

  final List<PostResponse> resultList;
}

final class PostError$State extends PostState {
  const PostError$State({required this.message, this.statusCode}) : super._();

  final String message;
  final int? statusCode;
}