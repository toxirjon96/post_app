import 'dart:math';
import 'dart:ui' show Size;

import 'package:bloc/bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../model/liveness_task.dart';

part 'face_id_event.dart';
part 'face_id_state.dart';

class FaceIdBloc extends Bloc<FaceIdEvent, FaceIdState> {
  FaceIdBloc() : super(const FaceIdInitial()) {
    _tasks = _generateTasks();
    on<FaceIdStarted>(_onStarted);
    on<FaceIdPermissionResult>(_onPermissionResult);
    on<FaceIdFaceUpdated>(_onFaceUpdated);
    on<FaceIdSelfieCapture>(_onSelfieCapture);
    on<FaceIdRetry>(_onRetry);
  }

  late List<LivenessTask> _tasks;

  // ── Liveness task frame counter ───────────────────────────────────────────
  static const _requiredFrames = 3;
  int _consecutiveFrames = 0;

  // ── Selfie-ready hysteresis counters ─────────────────────────────────────
  // Require multiple consecutive "good" frames before enabling the button, and
  // more "bad" frames before disabling it. This prevents rapid flickering.
  static const _selfieEnableFrames  = 6;   // frames to enable  button
  static const _selfieDisableFrames = 14;  // frames to disable button (more lag = less flicker)
  int _selfieGoodFrames = 0;
  int _selfieBadFrames  = 0;

  static List<LivenessTask> _generateTasks() {
    final pool = List<LivenessTask>.from(LivenessTask.values)..shuffle(Random());
    final count = 2 + Random().nextInt(2);
    return pool.take(count).toList();
  }

  void _onStarted(FaceIdStarted event, Emitter<FaceIdState> emit) {
    emit(FaceIdRunning(
      tasks: _tasks,
      currentTask: _tasks.first,
      completedTasks: const [],
      faceDetected: false,
    ));
  }

  void _onPermissionResult(FaceIdPermissionResult event, Emitter<FaceIdState> emit) {
    if (!event.granted) {
      emit(const FaceIdPermissionDenied());
      return;
    }
    emit(FaceIdRunning(
      tasks: _tasks,
      currentTask: _tasks.first,
      completedTasks: const [],
      faceDetected: false,
    ));
  }

  void _onFaceUpdated(FaceIdFaceUpdated event, Emitter<FaceIdState> emit) {
    final currentState = state;

    // ── All tasks done: gate "Take Selfie" behind quality + hysteresis ───────
    if (currentState is FaceIdAllTasksDone) {
      final faceGood = event.face != null &&
          _isFaceProperlyPositioned(event.face!, event.imageSize);

      if (faceGood) {
        _selfieGoodFrames++;
        _selfieBadFrames = 0;
        if (!currentState.facePresent &&
            _selfieGoodFrames >= _selfieEnableFrames) {
          emit(currentState.copyWith(facePresent: true));
        }
      } else {
        _selfieBadFrames++;
        _selfieGoodFrames = 0;
        if (currentState.facePresent &&
            _selfieBadFrames >= _selfieDisableFrames) {
          emit(currentState.copyWith(facePresent: false));
        }
      }
      return;
    }

    if (currentState is! FaceIdRunning) return;

    final face = event.face;
    if (face == null) {
      _consecutiveFrames = 0;
      if (currentState.faceDetected) {
        emit(currentState.copyWith(faceDetected: false));
      }
      return;
    }

    // A face is only considered "detected" (ready for task checks) when it is
    // centred inside the on-screen oval.  Faces detected anywhere in the frame
    // are ignored until the user moves into position.
    final centered = _isFaceCentered(face, event.imageSize);
    if (currentState.faceDetected != centered) {
      _consecutiveFrames = 0;
      emit(currentState.copyWith(faceDetected: centered));
    }
    if (!centered) return;

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
            tasks: _tasks,
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

  /// Returns true only when the face is large enough, fully inside the frame,
  /// and roughly forward-facing — i.e. the user's face properly fills the oval.
  bool _isFaceProperlyPositioned(Face face, Size imageSize) {
    final box = face.boundingBox;

    // ── Face must be fully inside the camera frame ────────────────────────
    if (imageSize != Size.zero) {
      if (box.left   < 0              ||
          box.top    < 0              ||
          box.right  > imageSize.width ||
          box.bottom > imageSize.height) {
        return false;
      }
      // Face bounding-box width must be ≥ 18% of the smaller image dimension
      // (guards against detecting a tiny or edge-cropped face).
      final minDim = min(imageSize.width, imageSize.height);
      if (box.width < minDim * 0.18) return false;
    } else {
      // Fallback when imageSize is unknown: require a minimum pixel width.
      if (box.width < 90) return false;
    }

    // ── Head must be roughly forward-facing ───────────────────────────────
    // Yaw (left/right): allow ±20°
    // Pitch (up/down):  allow ±20°
    final yaw   = (face.headEulerAngleY ?? 0).abs();
    final pitch = (face.headEulerAngleX ?? 0).abs();
    if (yaw > 20 || pitch > 20) return false;

    return true;
  }

  /// Returns true when the face bounding-box centre is within the central 60%
  /// of both image dimensions and the face is adequately sized.
  /// Head angle is intentionally NOT checked here so that tasks which require
  /// head rotation (turnLeft / turnRight) can still be gated by centering.
  bool _isFaceCentered(Face face, Size imageSize) {
    final box = face.boundingBox;

    if (imageSize != Size.zero) {
      if (box.left   < 0              ||
          box.top    < 0              ||
          box.right  > imageSize.width ||
          box.bottom > imageSize.height) {
        return false;
      }
      final minDim = min(imageSize.width, imageSize.height);
      if (box.width < minDim * 0.18) return false;

      final normX = (box.left + box.width  / 2) / imageSize.width  - 0.5;
      final normY = (box.top  + box.height / 2) / imageSize.height - 0.5;
      if (normX.abs() > 0.30 || normY.abs() > 0.30) return false;
    } else {
      if (box.width < 90) return false;
    }
    return true;
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
    _selfieGoodFrames  = 0;
    _selfieBadFrames   = 0;
    _tasks = _generateTasks();
    emit(FaceIdRunning(
      tasks: _tasks,
      currentTask: _tasks.first,
      completedTasks: const [],
      faceDetected: false,
    ));
  }
}