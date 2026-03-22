import 'package:bloc/bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../model/liveness_task.dart';

part 'face_id_event.dart';
part 'face_id_state.dart';

class FaceIdBloc extends Bloc<FaceIdEvent, FaceIdState> {
  FaceIdBloc() : super(const FaceIdInitial()) {
    on<FaceIdStarted>(_onStarted);
    on<FaceIdPermissionResult>(_onPermissionResult);
    on<FaceIdFaceUpdated>(_onFaceUpdated);
    on<FaceIdSelfieCapture>(_onSelfieCapture);
    on<FaceIdRetry>(_onRetry);
  }

  static const _tasks = LivenessTask.values;
  static const _requiredFrames = 3;
  int _consecutiveFrames = 0;

  void _onStarted(FaceIdStarted event, Emitter<FaceIdState> emit) {
    emit(FaceIdRunning(
      currentTask: _tasks.first,
      completedTasks: const [],
      faceDetected: false,
    ));
  }

  void _onPermissionResult(
      FaceIdPermissionResult event, Emitter<FaceIdState> emit) {
    if (!event.granted) {
      emit(const FaceIdPermissionDenied());
      return;
    }
    emit(FaceIdRunning(
      currentTask: _tasks.first,
      completedTasks: const [],
      faceDetected: false,
    ));
  }

  void _onFaceUpdated(FaceIdFaceUpdated event, Emitter<FaceIdState> emit) {
    final currentState = state;
    if (currentState is! FaceIdRunning) return;

    final face = event.face;
    if (face == null) {
      _consecutiveFrames = 0;
      if (currentState.faceDetected) {
        emit(currentState.copyWith(faceDetected: false));
      }
      return;
    }

    if (!currentState.faceDetected) {
      emit(currentState.copyWith(faceDetected: true));
    }

    if (_isTaskSatisfied(face, currentState.currentTask)) {
      _consecutiveFrames++;
      if (_consecutiveFrames >= _requiredFrames) {
        _consecutiveFrames = 0;
        final completed = [...currentState.completedTasks, currentState.currentTask];
        final nextIndex = _tasks.indexOf(currentState.currentTask) + 1;
        if (nextIndex >= _tasks.length) {
          emit(const FaceIdAllTasksDone());
        } else {
          emit(FaceIdRunning(
            currentTask: _tasks[nextIndex],
            completedTasks: completed,
            faceDetected: true,
          ));
        }
      }
    } else {
      _consecutiveFrames = 0;
    }
  }

  bool _isTaskSatisfied(Face face, LivenessTask task) {
    return switch (task) {
      LivenessTask.blink =>
        (face.leftEyeOpenProbability ?? 1.0) < 0.2 &&
            (face.rightEyeOpenProbability ?? 1.0) < 0.2,
      LivenessTask.turnLeft => (face.headEulerAngleY ?? 0) > 22,
      LivenessTask.turnRight => (face.headEulerAngleY ?? 0) < -22,
      LivenessTask.smile => (face.smilingProbability ?? 0) > 0.75,
    };
  }

  void _onSelfieCapture(FaceIdSelfieCapture event, Emitter<FaceIdState> emit) {
    emit(FaceIdDone(imagePath: event.imagePath));
  }

  void _onRetry(FaceIdRetry event, Emitter<FaceIdState> emit) {
    _consecutiveFrames = 0;
    emit(FaceIdRunning(
      currentTask: _tasks.first,
      completedTasks: const [],
      faceDetected: false,
    ));
  }
}