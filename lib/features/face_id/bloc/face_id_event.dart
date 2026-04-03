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
  const FaceIdFaceUpdated({
    this.face,
    this.imageSize = Size.zero,
    this.imageRotationDegrees = 0,
    this.screenSize = Size.zero,
  }) : super._();
  final Face? face;
  /// Native camera image dimensions — used for face-position quality checks.
  final Size imageSize;
  /// Clockwise rotation (0 / 90 / 180 / 270) applied to map the camera frame
  /// to the current display orientation.  Portrait = 90 or 270; Landscape = 0 or 180.
  final int imageRotationDegrees;
  /// Logical screen size — needed to apply the BoxFit.cover transform when
  /// mapping camera-pixel coordinates to screen-normalised space.
  final Size screenSize;
}

final class FaceIdSelfieCapture extends FaceIdEvent {
  const FaceIdSelfieCapture({required this.imagePath}) : super._();
  final String imagePath;
}

final class FaceIdRetry extends FaceIdEvent {
  const FaceIdRetry() : super._();
}