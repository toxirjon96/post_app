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
          _isFaceProperlyPositioned(event.face!, event.imageSize, event.imageRotationDegrees);

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
    final centered = _isFaceCentered(face, event.imageSize, event.imageRotationDegrees);
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
  /// roughly forward-facing, AND centred inside the on-screen guide oval.
  bool _isFaceProperlyPositioned(Face face, Size imageSize, int rotationDegrees) {
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

    // ── Face must be inside the guide oval ────────────────────────────────
    // Use the standard ellipse equation (dx/a)² + (dy/b)² ≤ 1 for a proper
    // oval test — rectangular abs() checks incorrectly pass faces sitting in
    // the rectangle's corners but outside the ellipse.
    //
    // Two tiers:
    //   • Face CENTRE must be strictly inside the oval (t = 1.0).
    //   • All four bounding-box CORNERS must be within a 1.12× enlarged oval.
    //     ML Kit's bounding box includes a small margin beyond the face
    //     geometry, so a tight oval would reject valid centred positions.
    if (imageSize != Size.zero) {
      final isPortrait = rotationDegrees == 90 || rotationDegrees == 270;
      final ovalCx    = isPortrait ? 0.50 : 0.38;
      final ovalCy    = isPortrait ? 0.37 : 0.50;
      final ovalHalfW = isPortrait ? 0.36 : 0.16;
      final ovalHalfH = isPortrait ? 0.23 : 0.45;

      // Maps a camera-pixel (px, py) to screen-normalised [0..1] space using
      // the same rotation logic as _isFaceCentered.
      (double, double) toScreen(double px, double py) {
        final cw = imageSize.width;
        final ch = imageSize.height;
        return switch (rotationDegrees) {
          90  => ((ch - py) / ch, px / cw),
          270 => (py / ch,        (cw - px) / cw),
          180 => (1.0 - px / cw,  1.0 - py / ch),
          _   => (px / cw,        py / ch),
        };
      }

      // Centre check (strict oval).
      final faceCx = box.left + box.width  / 2;
      final faceCy = box.top  + box.height / 2;
      final (sx, sy) = toScreen(faceCx, faceCy);
      final ddx = (sx - ovalCx) / ovalHalfW;
      final ddy = (sy - ovalCy) / ovalHalfH;
      if (ddx * ddx + ddy * ddy > 1.0) return false;

      // Corner check (1.12× enlarged oval).
      const t = 1.12;
      for (final (px, py) in [
        (box.left,  box.top),
        (box.right, box.top),
        (box.left,  box.bottom),
        (box.right, box.bottom),
      ]) {
        final (bsx, bsy) = toScreen(px, py);
        final dx = (bsx - ovalCx) / (ovalHalfW * t);
        final dy = (bsy - ovalCy) / (ovalHalfH * t);
        if (dx * dx + dy * dy > 1.0) return false;
      }
    }

    return true;
  }

  /// Returns true when the face centre falls inside the on-screen oval and the
  /// face is adequately sized.  Head angle is NOT checked so that turn tasks
  /// (turnLeft / turnRight) are still gated by centering.
  ///
  /// Containment uses the standard ellipse equation (dx/a)² + (dy/b)² ≤ 1
  /// so that faces at the corners of the bounding rectangle — which are outside
  /// the actual ellipse — are correctly rejected.
  ///
  /// [rotationDegrees] is the clockwise rotation used to map the raw camera
  /// frame to the current display orientation (0 / 90 / 180 / 270).
  /// Portrait display = 90° or 270°; landscape display = 0° or 180°.
  ///
  /// Oval constants mirror liveness_overlay.dart:
  ///   Portrait  → center (0.50, 0.37), size (72 %, 46 %)
  ///   Landscape → center (0.38, 0.50), size (32 %, 90 %)
  bool _isFaceCentered(Face face, Size imageSize, int rotationDegrees) {
    final box = face.boundingBox;

    if (imageSize == Size.zero) return box.width >= 90;

    // Face bounding-box must be fully inside the camera frame.
    if (box.left   < 0              ||
        box.top    < 0              ||
        box.right  > imageSize.width ||
        box.bottom > imageSize.height) {
      return false;
    }

    // Face must fill at least 18 % of the smaller image dimension.
    final minDim = min(imageSize.width, imageSize.height);
    if (box.width < minDim * 0.18) return false;

    final cx = box.left + box.width  / 2;
    final cy = box.top  + box.height / 2;
    final cw = imageSize.width;
    final ch = imageSize.height;

    // ── Transform face centre from camera-image space → screen-normalised ──
    // The mapping depends on how many degrees the image is rotated CW to reach
    // the display orientation.
    double screenX, screenY; // both in [0, 1] screen-normalised space
    switch (rotationDegrees) {
      case 90:
        // Camera X → display Y; camera Y → display X (flipped).
        screenX = (ch - cy) / ch;
        screenY = cx / cw;
      case 270:
        // Camera X → display Y (flipped); camera Y → display X.
        screenX = cy / ch;
        screenY = (cw - cx) / cw;
      case 180:
        screenX = 1.0 - cx / cw;
        screenY = 1.0 - cy / ch;
      default: // 0°
        screenX = cx / cw;
        screenY = cy / ch;
    }

    // ── Oval bounds in screen-normalised space ────────────────────────────
    final isPortrait = rotationDegrees == 90 || rotationDegrees == 270;
    final ovalCx    = isPortrait ? 0.50 : 0.38;
    final ovalCy    = isPortrait ? 0.37 : 0.50;
    final ovalHalfW = isPortrait ? 0.36 : 0.16; // 72 %/2 or 32 %/2
    final ovalHalfH = isPortrait ? 0.23 : 0.45; // 46 %/2 or 90 %/2

    final dx = (screenX - ovalCx) / ovalHalfW;
    final dy = (screenY - ovalCy) / ovalHalfH;
    return dx * dx + dy * dy <= 1.0;
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