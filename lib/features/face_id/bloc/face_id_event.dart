part of 'face_id_bloc.dart';

sealed class FaceIdEvent {
  const FaceIdEvent._();
}

final class FaceIdStarted extends FaceIdEvent {
  const FaceIdStarted() : super._();
}

final class FaceIdPermissionResult extends FaceIdEvent {
  const FaceIdPermissionResult({required this.granted}) : super._();
  final bool granted;
}

final class FaceIdFaceUpdated extends FaceIdEvent {
  const FaceIdFaceUpdated({this.face}) : super._();
  final Face? face;
}

final class FaceIdSelfieCapture extends FaceIdEvent {
  const FaceIdSelfieCapture({required this.imagePath}) : super._();
  final String imagePath;
}

final class FaceIdRetry extends FaceIdEvent {
  const FaceIdRetry() : super._();
}