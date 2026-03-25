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
  const FaceIdFaceUpdated({this.face, this.imageSize = Size.zero}) : super._();
  final Face? face;
  /// Native camera image dimensions — used for face-position quality checks.
  final Size imageSize;
}

final class FaceIdSelfieCapture extends FaceIdEvent {
  const FaceIdSelfieCapture({required this.imagePath}) : super._();
  final String imagePath;
}

final class FaceIdRetry extends FaceIdEvent {
  const FaceIdRetry() : super._();
}