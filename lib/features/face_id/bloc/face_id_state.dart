part of 'face_id_bloc.dart';

sealed class FaceIdState {
  const FaceIdState._();
}

final class FaceIdInitial extends FaceIdState {
  const FaceIdInitial() : super._();
}

final class FaceIdPermissionDenied extends FaceIdState {
  const FaceIdPermissionDenied() : super._();
}

final class FaceIdRunning extends FaceIdState {
  const FaceIdRunning({
    required this.currentTask,
    required this.completedTasks,
    required this.faceDetected,
  }) : super._();

  final LivenessTask currentTask;
  final List<LivenessTask> completedTasks;
  final bool faceDetected;

  FaceIdRunning copyWith({
    LivenessTask? currentTask,
    List<LivenessTask>? completedTasks,
    bool? faceDetected,
  }) =>
      FaceIdRunning(
        currentTask: currentTask ?? this.currentTask,
        completedTasks: completedTasks ?? this.completedTasks,
        faceDetected: faceDetected ?? this.faceDetected,
      );
}

final class FaceIdAllTasksDone extends FaceIdState {
  const FaceIdAllTasksDone() : super._();
}

final class FaceIdDone extends FaceIdState {
  const FaceIdDone({required this.imagePath}) : super._();
  final String imagePath;
}