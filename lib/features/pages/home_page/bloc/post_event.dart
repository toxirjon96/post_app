part of 'post_bloc.dart';

sealed class PostEvent {
  const PostEvent._();
}

final class PostFind$Event extends PostEvent {
  const PostFind$Event() : super._();
}
