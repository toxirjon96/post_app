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

  // ─────────────────────────────────────────────────────────────────────────
  //  Oval geometry — mirrors liveness_overlay.dart exactly.
  //  All values are in SCREEN-normalised [0..1] space (cx/cy = centre,
  //  hw/hh = half-axes as fractions of screen width / height respectively).
  //
  //  These match the painter fractions directly, e.g. portrait phone
  //  ovalWidthFraction=0.72 → hw = 0.36.
  // ─────────────────────────────────────────────────────────────────────────

  // Portrait — phone  (ovalW=0.72·sW, ovalH=0.46·sH)
  static const _kPOvalCx = 0.50; static const _kPOvalCy = 0.37;
  static const _kPOvalHw = 0.36; static const _kPOvalHh = 0.23;

  // Portrait — tablet  (ovalW=0.55·sW, ovalH=0.44·sH  — narrower to stay face-shaped)
  static const _kPTabletOvalHw = 0.275; static const _kPTabletOvalHh = 0.22;

  // Landscape — phone  (ovalW=0.32·sW, ovalH=0.90·sH)
  static const _kLOvalCx = 0.38; static const _kLOvalCy = 0.50;
  static const _kLOvalHw = 0.16; static const _kLOvalHh = 0.45;

  // Landscape — tablet  (ovalW=0.42·sW, ovalH=0.86·sH; centre shifted for wider camera area)
  static const _kLTabletOvalCx = 0.41;
  static const _kLTabletOvalHw = 0.21; static const _kLTabletOvalHh = 0.43;

  // ── Face ellipse estimation ───────────────────────────────────────────────
  //
  // IMPORTANT — why bounding-box only (no IOD-based sizing):
  //
  // Screen-normalised space is NOT equal-scale: X values are fractions of the
  // screen WIDTH, Y values are fractions of the screen HEIGHT.  On a typical
  // portrait phone (390 × 844 px) one Y-unit represents 844/390 ≈ 2.16 ×
  // the physical length of one X-unit.  Biometric IOD multipliers (e.g.
  // "faceHeight = IOD × 3.7") are derived in pixel/metric space where X = Y
  // scale; applying them directly to mixed-unit normalised IOD inflates the
  // face half-height by ~2 ×, which pushes top/bottom perimeter points outside
  // the oval even when the face is correctly centred.
  //
  // The bounding-box corners, by contrast, are each normalised along their own
  // axis (left/right → X, top/bottom → Y), so the resulting half-axes are
  // already in the correct per-axis units and no aspect-ratio correction is
  // needed.
  //
  // What the scale factors represent:
  //   ML Kit's bbox includes roughly 20-28 % extra margin beyond the
  //   visible face on each axis (forehead / hair at the top, chin/neck at the
  //   bottom, temples at the sides).  A scale factor of 0.72 shrinks the bbox
  //   to the "inner face features" ellipse — the region that spans from eye
  //   outer corner to eye outer corner horizontally, and from high-forehead to
  //   lower-chin vertically.  The check then verifies that this inner region
  //   sits inside the guide oval, which is the perceptually correct criterion
  //   (the user's features must be inside the oval, not merely the face centre).
  static const _kBboxEllipseWidthRatio  = 0.72;
  static const _kBboxEllipseHeightRatio = 0.72;

  // ── Perimeter sampling ────────────────────────────────────────────────────
  static const _kPerimeterSamples = 16;

  // ── Oval inset factors ────────────────────────────────────────────────────
  //
  // The test oval is inset from the display oval so there is a small buffer
  // between "detected as inside" and the visible oval edge.
  //   0.95 → 5 % inset during liveness (allows normal head movement).
  //   0.90 → 10 % inset for the selfie check (face must be well-centred).
  static const _kInsetLiveness = 0.95;
  static const _kInsetSelfie   = 0.90;

  // ── Coverage ratio bounds ─────────────────────────────────────────────────
  //
  // face-features ellipse area / oval area must be within [min, max].
  //   Too small → face is too far away (low resolution, poor quality).
  //   Too large → face is extremely close (geometry distortion).
  static const _kMinCoverageLiveness = 0.15;
  static const _kMinCoverageSelfie   = 0.22;
  static const _kMaxCoverage         = 0.85;

  // ── Selfie head-pose limits ───────────────────────────────────────────────
  static const _kSelfieMaxYaw   = 15.0; // degrees
  static const _kSelfieMaxPitch = 15.0; // degrees

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
          _isFaceProperlyPositioned(
              event.face!, event.imageSize, event.imageRotationDegrees, event.screenSize);

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
    final centered = _isFaceCentered(
        face, event.imageSize, event.imageRotationDegrees, event.screenSize);
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

  // ═══════════════════════════════════════════════════════════════════════════
  //  Face-in-oval containment — core algorithm
  // ═══════════════════════════════════════════════════════════════════════════

  /// Converts a raw camera-image pixel (px, py) to a TRUE screen-normalised
  /// point in [0..1] × [0..1] space.
  ///
  /// Two-step transform:
  ///  1. Rotate the image pixel into display-image space using [rot] (CW degrees):
  ///       0°  → identity (landscape sensor already aligned with display)
  ///      90°  → 90° CW (rear camera portrait)
  ///     180°  → 180° rotation
  ///     270°  → 270° CW / 90° CCW with horizontal mirror for front cameras
  ///  2. Apply the same BoxFit.cover scale + centre-crop that the camera preview
  ///     widget uses, so the returned value lands in screen pixels / screen size.
  ///
  /// This is the only correct way to compare ML Kit coordinates (which live in
  /// the raw camera-image pixel space) against the visual oval (which is drawn
  /// in screen space). Without step 2 the normalised half-width would differ
  /// from the drawn oval whenever the aspect ratios of the camera image and
  /// screen differ (which they always do with BoxFit.cover).
  (double, double) _toScreenNorm(
      double px, double py, Size img, int rot, Size screen) {
    final w = img.width, h = img.height;

    // ── Step 1: camera pixel → display pixel ─────────────────────────────
    // Display image size after rotation
    final dW = (rot == 90 || rot == 270) ? h : w;
    final dH = (rot == 90 || rot == 270) ? w : h;

    // Pixel position inside the (possibly rotated) display image.
    // The 270° case mirrors the X axis, aligning with the front-camera
    // mirror that the camera preview applies for selfie mode.
    final (dpx, dpy) = switch (rot) {
      90  => (h - py, px),
      270 => (py,     w - px),
      180 => (w - px, h - py),
      _   => (px,     py),
    };

    // ── Step 2: BoxFit.cover → screen-normalised ──────────────────────────
    // Scale so the larger axis fills the screen; the smaller axis overflows
    // and is cropped symmetrically (same as FittedBox with BoxFit.cover).
    final scale = max(screen.width / dW, screen.height / dH);
    final xOff  = (dW * scale - screen.width)  / 2; // left-crop in pixels
    final yOff  = (dH * scale - screen.height) / 2; // top-crop in pixels

    final sx = ((dpx * scale - xOff) / screen.width ).clamp(0.0, 1.0);
    final sy = ((dpy * scale - yOff) / screen.height).clamp(0.0, 1.0);
    return (sx, sy);
  }

  /// Unified face-in-oval containment check.
  ///
  /// Three-tier pipeline:
  ///
  /// **Tier 1 – Frame sanity**
  ///   Bbox fully inside camera frame; face at least 15 % of smaller dimension.
  ///
  /// **Tier 2 – Ellipse-in-ellipse perimeter sampling**
  ///   Estimates the "inner face features" ellipse from the ML Kit bounding box
  ///   (scaled by [_kBboxEllipseWidthRatio] / [_kBboxEllipseHeightRatio]).
  ///   The face centre is the eye-landmark midpoint when available, otherwise
  ///   the bbox centre.  16 uniformly-spaced perimeter points are then tested
  ///   against the *inset* guide oval; all must lie inside.
  ///
  ///   WHY bbox-only for size (not IOD):
  ///   Screen-normalised X and Y are in different physical units (fractions of
  ///   width vs fractions of height), so biometric IOD multipliers — derived in
  ///   equal-scale pixel space — produce incorrect face heights in this space.
  ///   Bbox corners, on the other hand, are normalised per-axis, so the
  ///   resulting half-axes are already in correct per-axis units.
  ///
  /// **Tier 3 – Coverage ratio gate**
  ///   face-features area / oval area in [minCoverageRatio, [_kMaxCoverage]].
  bool _isFaceInOval(
    Face face,
    Size imageSize,
    int rotationDegrees,
    Size screenSize, {
    required double insetFactor,
    required double minCoverageRatio,
  }) {
    final box = face.boundingBox;

    // ── Tier 1: frame sanity ──────────────────────────────────────────────
    if (imageSize == Size.zero || screenSize == Size.zero) {
      return box.width >= 90;
    }

    if (box.left < 0 || box.top < 0 ||
        box.right > imageSize.width || box.bottom > imageSize.height) {
      return false;
    }
    final minDim = min(imageSize.width, imageSize.height);
    if (box.width < minDim * 0.15) return false;

    // ── Oval parameters (screen-normalised space) ─────────────────────────
    // Use the physical screen orientation (not the rotation value, which can
    // differ across devices / tablet sensors).
    final isPortrait = screenSize.width < screenSize.height;
    final isTablet   = screenSize.shortestSide >= 600;

    final double oCx, oCy, oHw, oHh;
    if (isPortrait) {
      oCx = _kPOvalCx; oCy = _kPOvalCy;
      oHw = isTablet ? _kPTabletOvalHw : _kPOvalHw;
      oHh = isTablet ? _kPTabletOvalHh : _kPOvalHh;
    } else {
      oCx = isTablet ? _kLTabletOvalCx : _kLOvalCx;
      oCy = _kLOvalCy;
      oHw = isTablet ? _kLTabletOvalHw : _kLOvalHw;
      oHh = isTablet ? _kLTabletOvalHh : _kLOvalHh;
    }
    final iHw = oHw * insetFactor;
    final iHh = oHh * insetFactor;

    // Convenience wrapper: camera pixel → screen-norm (accounts for rotation
    // AND the BoxFit.cover crop the preview widget applies).
    (double, double) ts(double px, double py) =>
        _toScreenNorm(px, py, imageSize, rotationDegrees, screenSize);

    // ── Face features ellipse ─────────────────────────────────────────────
    // Transform opposing bbox corners to screen-normalised space; the
    // axis-aligned extents give us face half-axes already in screen-norm
    // units (X = fraction of screenW, Y = fraction of screenH).
    final (x0, y0) = ts(box.left,  box.top);
    final (x1, y1) = ts(box.right, box.bottom);
    final bMinX = min(x0, x1), bMaxX = max(x0, x1);
    final bMinY = min(y0, y1), bMaxY = max(y0, y1);

    final faceHw = (bMaxX - bMinX) / 2 * _kBboxEllipseWidthRatio;
    final faceHh = (bMaxY - bMinY) / 2 * _kBboxEllipseHeightRatio;

    // Centre: eye midpoint when available; bbox centre otherwise.
    double faceCx, faceCy;
    final leftEyeLm  = face.landmarks[FaceLandmarkType.leftEye];
    final rightEyeLm = face.landmarks[FaceLandmarkType.rightEye];

    if (leftEyeLm != null && rightEyeLm != null) {
      final (lex, ley) = ts(
          leftEyeLm.position.x.toDouble(), leftEyeLm.position.y.toDouble());
      final (rex, rey) = ts(
          rightEyeLm.position.x.toDouble(), rightEyeLm.position.y.toDouble());
      faceCx = (lex + rex) / 2;
      faceCy = (ley + rey) / 2;
    } else {
      faceCx = (bMinX + bMaxX) / 2;
      faceCy = (bMinY + bMaxY) / 2;
    }

    // ── Tier 2: 16-point perimeter containment ────────────────────────────
    for (int i = 0; i < _kPerimeterSamples; i++) {
      final angle = 2 * pi * i / _kPerimeterSamples;
      final px = faceCx + faceHw * cos(angle);
      final py = faceCy + faceHh * sin(angle);
      final dx = (px - oCx) / iHw;
      final dy = (py - oCy) / iHh;
      if (dx * dx + dy * dy > 1.0) return false;
    }

    // ── Tier 3: coverage ratio ────────────────────────────────────────────
    final coverage = (faceHw * faceHh) / (oHw * oHh);
    if (coverage < minCoverageRatio || coverage > _kMaxCoverage) return false;

    return true;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Public-facing check methods (called from _onFaceUpdated)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns `true` when the face is well-positioned inside the guide oval and
  /// adequately sized for liveness-task checking.
  ///
  /// Head-angle is intentionally **not** tested here so that turn-left /
  /// turn-right tasks are still permitted while the face is centred; the yaw
  /// change for those tasks is what [_isTaskSatisfied] detects.
  ///
  /// Delegates to [_isFaceInOval] with the liveness inset (0.92 = 8% margin)
  /// and a minimum coverage ratio of 20 %.
  bool _isFaceCentered(
          Face face, Size imageSize, int rotationDegrees, Size screenSize) =>
      _isFaceInOval(
        face,
        imageSize,
        rotationDegrees,
        screenSize,
        insetFactor: _kInsetLiveness,
        minCoverageRatio: _kMinCoverageLiveness,
      );

  bool _isFaceProperlyPositioned(
      Face face, Size imageSize, int rotationDegrees, Size screenSize) {
    final yaw   = (face.headEulerAngleY ?? 0).abs();
    final pitch = (face.headEulerAngleX ?? 0).abs();
    if (yaw > _kSelfieMaxYaw || pitch > _kSelfieMaxPitch) return false;

    return _isFaceInOval(
      face,
      imageSize,
      rotationDegrees,
      screenSize,
      insetFactor: _kInsetSelfie,
      minCoverageRatio: _kMinCoverageSelfie,
    );
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