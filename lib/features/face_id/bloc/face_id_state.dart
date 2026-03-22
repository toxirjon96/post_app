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
    required this.tasks,
    required this.currentTask,
    required this.completedTasks,
    required this.faceDetected,
  }) : super._();

  final List<LivenessTask> tasks;
  final LivenessTask currentTask;
  final List<LivenessTask> completedTasks;
  final bool faceDetected;

  FaceIdRunning copyWith({
    List<LivenessTask>? tasks,
    LivenessTask? currentTask,
    List<LivenessTask>? completedTasks,
    bool? faceDetected,
  }) =>
      FaceIdRunning(
        tasks: tasks ?? this.tasks,
        currentTask: currentTask ?? this.currentTask,
        completedTasks: completedTasks ?? this.completedTasks,
        faceDetected: faceDetected ?? this.faceDetected,
      );
}

final class FaceIdAllTasksDone extends FaceIdState {
  const FaceIdAllTasksDone({this.facePresent = false}) : super._();
  final bool facePresent;

  FaceIdAllTasksDone copyWith({bool? facePresent}) =>
      FaceIdAllTasksDone(facePresent: facePresent ?? this.facePresent);
}

final class FaceIdDone extends FaceIdState {
  const FaceIdDone({required this.imagePath}) : super._();
  final String imagePath;
}