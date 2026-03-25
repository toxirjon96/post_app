import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/face_id_bloc.dart';
import '../model/liveness_task.dart';

// ── Face alignment hint messages (cycling) ───────────────────────────────────

const _kAlignmentHints = [
  'Position your face inside the oval',
  'Move the phone to eye level',
  'Make sure your face is well-lit',
  'Look straight ahead at the camera',
  'Remove glasses or move to better light',
];

// ═════════════════════════════════════════════════════════════════════════════
//  LivenessOverlay
// ═════════════════════════════════════════════════════════════════════════════

class LivenessOverlay extends StatefulWidget {
  const LivenessOverlay({super.key, required this.onSelfiePressed});
  final VoidCallback onSelfiePressed;

  @override
  State<LivenessOverlay> createState() => _LivenessOverlayState();
}

class _LivenessOverlayState extends State<LivenessOverlay>
    with TickerProviderStateMixin {
  // ── Existing animations ────────────────────────────────────────────
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  late final AnimationController _taskController;
  late final Animation<Offset> _taskSlideAnim;
  late final Animation<double> _taskFadeAnim;
  late final AnimationController _successController;
  late final Animation<double> _successScaleAnim;
  late final Animation<double> _successOpacityAnim;

  // ── New animations ─────────────────────────────────────────────────
  /// Rotating scan arc around the oval during liveness tasks
  late final AnimationController _scanController;

  /// Inward-pulse arrows when face is not aligned
  late final AnimationController _arrowController;
  late final Animation<double> _arrowPulse;

  /// Spring-bounce for selfie button entering enabled state
  late final AnimationController _readyController;
  late final Animation<double> _readyScale;

  /// Shimmer sweep across the selfie button when enabled
  late final AnimationController _shimmerController;

  // ── State ──────────────────────────────────────────────────────────
  int _hintIndex = 0;
  Timer? _hintTimer;
  bool _wasReady = false;

  // ── Oval layout constants ──────────────────────────────────────────
  //
  // Portrait: oval is 72% of screen width and 46% of screen height.
  //   Example 390×844: 281×389 px → ratio 0.72 (taller than wide ✓)
  //
  // Landscape: the screen is now wide and short. If we keep the same fractions
  //   the oval becomes nearly square or wider-than-tall (e.g. 844×390 at 0.42×0.78
  //   = 354×304 px → slightly wider → face looks oblong).
  //   Fix: use narrower width and taller height fractions so the oval stays
  //   portrait-shaped even in landscape.
  //   Example 844×390: 0.32×0.90 = 270×351 px → ratio 0.77 (taller ✓)
  static const double _ovalWidthFraction          = 0.72;
  static const double _ovalWidthFractionLandscape = 0.32;
  static const double _ovalHeightFractionPortrait  = 0.46;
  static const double _ovalHeightFractionLandscape = 0.90;
  // Center X offset in landscape (fraction of screen width) — shifted left of
  // the side panel to keep the oval centred in the visible camera area.
  static const double _ovalCenterXLandscape = 0.38;
  static const double _ovalCenterYPortrait  = 0.37;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _taskController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..forward();
    _taskSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.7),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _taskController, curve: Curves.easeOutCubic));
    _taskFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _taskController, curve: Curves.easeOut),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOutCubic),
    );
    _successOpacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeIn),
    );

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _arrowPulse = CurvedAnimation(
      parent: _arrowController,
      curve: Curves.easeInOut,
    );

    _readyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _readyScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _readyController, curve: Curves.elasticOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _taskController.dispose();
    _successController.dispose();
    _scanController.dispose();
    _arrowController.dispose();
    _readyController.dispose();
    _shimmerController.dispose();
    _hintTimer?.cancel();
    super.dispose();
  }

  void _startHintCycle() {
    _hintTimer ??= Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (mounted) {
        setState(
            () => _hintIndex = (_hintIndex + 1) % _kAlignmentHints.length);
      }
    });
  }

  void _stopHintCycle() {
    _hintTimer?.cancel();
    _hintTimer = null;
  }

  void _onFaceReadyTransition(bool facePresent) {
    if (facePresent && !_wasReady) {
      _wasReady = true;
      _readyController.forward(from: 0);
      HapticFeedback.mediumImpact();
      _stopHintCycle();
    } else if (!facePresent && _wasReady) {
      _wasReady = false;
      _readyController.reverse();
      _startHintCycle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FaceIdBloc, FaceIdState>(
      listenWhen: (prev, curr) {
        final taskChanged = prev is FaceIdRunning &&
            curr is FaceIdRunning &&
            prev.currentTask != curr.currentTask;
        final allDone =
            prev is! FaceIdAllTasksDone && curr is FaceIdAllTasksDone;
        return taskChanged || allDone;
      },
      listener: (context, state) {
        if (state is FaceIdRunning) {
          _taskController.forward(from: 0);
        } else if (state is FaceIdAllTasksDone) {
          _successController.forward(from: 0);
          if (!state.facePresent) _startHintCycle();
        }
      },
      builder: (context, state) {
        // Track face-ready transition for button animation
        if (state is FaceIdAllTasksDone) {
          _onFaceReadyTransition(state.facePresent);
        }

        final isLandscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;
        final size = MediaQuery.sizeOf(context);
        final isTablet = size.shortestSide >= 600;

        return Stack(
          fit: StackFit.expand,
          children: [
            // ── Camera oval overlay with scan arc ──────────────────────
            _FaceOvalPainterWidget(
              state: state,
              pulseAnim: _pulseAnim,
              scanAnim: _scanController,
              arrowAnim: _arrowPulse,
              isLandscape: isLandscape,
            ),

            // ── Top progress header ────────────────────────────────────
            if (state is FaceIdRunning || state is FaceIdAllTasksDone)
              _buildHeader(state, isLandscape, isTablet),

            // ── Task instruction card ──────────────────────────────────
            if (state is FaceIdRunning)
              _buildTaskCard(state, isLandscape, isTablet),

            // ── Selfie panel ───────────────────────────────────────────
            if (state is FaceIdAllTasksDone)
              _buildSelfiePanel(state, isLandscape, isTablet),

            // ── Permission denied ──────────────────────────────────────
            if (state is FaceIdPermissionDenied)
              _buildPermissionDenied(context),

            // ── Loading spinner ────────────────────────────────────────
            if (state is FaceIdInitial)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          ],
        );
      },
    );
  }

  // ── Header / top progress bar ────────────────────────────────────────────

  Widget _buildHeader(
      FaceIdState state, bool isLandscape, bool isTablet) {
    final tasks =
        state is FaceIdRunning ? state.tasks : <LivenessTask>[];
    final completedTasks =
        state is FaceIdRunning ? state.completedTasks : <LivenessTask>[];
    final currentTask =
        state is FaceIdRunning ? state.currentTask : null;
    final allDone = state is FaceIdAllTasksDone;

    final topPad = MediaQuery.of(context).padding.top;
    final fontSize = isTablet ? 17.0 : (isLandscape ? 14.0 : 16.0);
    final dotSize = isTablet ? 32.0 : (isLandscape ? 26.0 : 28.0);

    return Positioned(
      top: topPad + (isLandscape ? 10 : 16),
      left: isLandscape ? 16 : 24,
      right: isLandscape ? (isTablet ? 220 : 196) : 24,
      child: Column(
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF00D68F),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                allDone ? 'All Steps Complete' : 'Face Verification',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  shadows: const [
                    Shadow(
                        color: Colors.black38,
                        blurRadius: 6,
                        offset: Offset(0, 1))
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isLandscape ? 8 : 12),
          // Step dots
          if (tasks.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(tasks.length, (i) {
                final task = tasks[i];
                final done = completedTasks.contains(task);
                final current = currentTask == task;
                return _StepDot(
                  task: task,
                  isDone: done,
                  isCurrent: current,
                  size: dotSize,
                );
              }),
            )
          else if (allDone)
            _AllDoneStepsRow(
              tasks: LivenessTask.values,
              size: dotSize,
            ),
        ],
      ),
    );
  }

  // ── Liveness task card ────────────────────────────────────────────────────

  Widget _buildTaskCard(
      FaceIdRunning state, bool isLandscape, bool isTablet) {
    return isLandscape
        ? _buildTaskCardLandscape(state, isTablet)
        : _buildTaskCardPortrait(state, isTablet);
  }

  Widget _buildTaskCardPortrait(FaceIdRunning state, bool isTablet) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final cardPad = isTablet ? 28.0 : 22.0;
    final iconSize = isTablet ? 72.0 : 60.0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _taskSlideAnim,
        child: FadeTransition(
          opacity: _taskFadeAnim,
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    cardPad, 22, cardPad, 22 + bottomPad),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(
                      color: state.currentTask.color.withValues(alpha: 0.40),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _TaskContent(
                        key: ValueKey(state.currentTask),
                        task: state.currentTask,
                        faceDetected: state.faceDetected,
                        iconSize: iconSize,
                        isLandscape: false,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCardLandscape(FaceIdRunning state, bool isTablet) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final panelWidth = isTablet ? 220.0 : 190.0;

    return Positioned(
      top: topPad + 8,
      bottom: bottomPad + 8,
      right: 0,
      width: panelWidth,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
            parent: _taskController, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: _taskFadeAnim,
          child: ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 18 : 14, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(24)),
                  border: Border(
                    left: BorderSide(
                      color: state.currentTask.color.withValues(alpha: 0.40),
                      width: 1.5,
                    ),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  child: _TaskContent(
                    key: ValueKey(state.currentTask),
                    task: state.currentTask,
                    faceDetected: state.faceDetected,
                    iconSize: 50,
                    isLandscape: true,
                    isTablet: isTablet,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Selfie panel ──────────────────────────────────────────────────────────

  Widget _buildSelfiePanel(
      FaceIdAllTasksDone state, bool isLandscape, bool isTablet) {
    return isLandscape
        ? _buildSelfiePanelLandscape(state, isTablet)
        : _buildSelfiePanelPortrait(state, isTablet);
  }

  Widget _buildSelfiePanelPortrait(
      FaceIdAllTasksDone state, bool isTablet) {
    final facePresent = state.facePresent;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final cardPad = isTablet ? 28.0 : 22.0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ScaleTransition(
        scale: _successScaleAnim,
        alignment: Alignment.bottomCenter,
        child: FadeTransition(
          opacity: _successOpacityAnim,
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    cardPad, 20, cardPad, 20 + bottomPad),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(
                      color: facePresent
                          ? const Color(0xFF00D68F).withValues(alpha: 0.50)
                          : Colors.white.withValues(alpha: 0.12),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: isTablet ? 22 : 18),

                    // Success badge
                    _SuccessBadge(isTablet: isTablet),
                    SizedBox(height: isTablet ? 16 : 12),

                    // Title
                    Text(
                      'Verification Complete!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 22 : 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Face alignment feedback
                    _FaceAlignmentFeedback(
                      facePresent: facePresent,
                      hintIndex: _hintIndex,
                      isTablet: isTablet,
                    ),
                    SizedBox(height: isTablet ? 20 : 16),

                    // Selfie button
                    _SelfieButton(
                      facePresent: facePresent,
                      readyScale: _readyScale,
                      shimmerAnim: _shimmerController,
                      onTap: facePresent ? widget.onSelfiePressed : null,
                      isTablet: isTablet,
                    ),

                    if (facePresent) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Keep still and look straight at the camera',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.40),
                          fontSize: isTablet ? 12.5 : 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelfiePanelLandscape(
      FaceIdAllTasksDone state, bool isTablet) {
    final facePresent = state.facePresent;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final panelWidth = isTablet ? 220.0 : 200.0;

    return Positioned(
      top: topPad + 8,
      bottom: bottomPad + 8,
      right: 0,
      width: panelWidth,
      child: ScaleTransition(
        scale: _successScaleAnim,
        alignment: Alignment.centerRight,
        child: FadeTransition(
          opacity: _successOpacityAnim,
          child: ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 18 : 14, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(24)),
                  border: Border(
                    left: BorderSide(
                      color: facePresent
                          ? const Color(0xFF00D68F).withValues(alpha: 0.50)
                          : Colors.white.withValues(alpha: 0.12),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SuccessBadge(isTablet: isTablet, compact: true),
                    const SizedBox(height: 8),
                    Text(
                      'All Done!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _FaceAlignmentFeedback(
                      facePresent: facePresent,
                      hintIndex: _hintIndex,
                      isTablet: isTablet,
                      compact: true,
                    ),
                    const SizedBox(height: 12),
                    _SelfieButton(
                      facePresent: facePresent,
                      readyScale: _readyScale,
                      shimmerAnim: _shimmerController,
                      onTap: facePresent ? widget.onSelfiePressed : null,
                      isTablet: isTablet,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Permission denied ─────────────────────────────────────────────────────

  Widget _buildPermissionDenied(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.60),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.35)),
                    ),
                    child: const Icon(Icons.no_photography_outlined,
                        color: Color(0xFFFF6B6B), size: 34),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Camera Access Required',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Please enable camera access in your\ndevice settings to use Face ID.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: isTablet ? 14 : 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () =>
                        context.read<FaceIdBloc>().add(const FaceIdRetry()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B8EF8), Color(0xFF4C5FD5)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B8EF8).withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Text(
                        'Open Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Sub-widgets
// ═════════════════════════════════════════════════════════════════════════════

// ── Step dot ─────────────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.task,
    required this.isDone,
    required this.isCurrent,
    required this.size,
  });

  final LivenessTask task;
  final bool isDone;
  final bool isCurrent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: isCurrent ? size * 1.25 : size,
      height: size,
      decoration: BoxDecoration(
        color: isDone
            ? task.color
            : isCurrent
                ? task.color.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: isDone || isCurrent
              ? task.color
              : Colors.white.withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: isDone
            ? [
                BoxShadow(
                  color: task.color.withValues(alpha: 0.40),
                  blurRadius: 8,
                )
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          isDone ? Icons.check_rounded : task.icon,
          color: isDone
              ? Colors.white
              : isCurrent
                  ? task.color
                  : Colors.white.withValues(alpha: 0.25),
          size: size * 0.52,
        ),
      ),
    );
  }
}

// ── All-done steps row ───────────────────────────────────────────────────────

class _AllDoneStepsRow extends StatelessWidget {
  const _AllDoneStepsRow({required this.tasks, required this.size});
  final List<LivenessTask> tasks;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: tasks.map((task) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: task.color,
            borderRadius: BorderRadius.circular(size / 2),
            boxShadow: [
              BoxShadow(
                  color: task.color.withValues(alpha: 0.50), blurRadius: 8)
            ],
          ),
          child: Icon(Icons.check_rounded,
              color: Colors.white, size: size * 0.52),
        );
      }).toList(),
    );
  }
}

// ── Task content ──────────────────────────────────────────────────────────────

class _TaskContent extends StatelessWidget {
  const _TaskContent({
    super.key,
    required this.task,
    required this.faceDetected,
    required this.iconSize,
    required this.isLandscape,
    required this.isTablet,
  });

  final LivenessTask task;
  final bool faceDetected;
  final double iconSize;
  final bool isLandscape;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                task.color.withValues(alpha: 0.28),
                task.color.withValues(alpha: 0.08),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: task.color.withValues(alpha: faceDetected ? 0.70 : 0.35),
              width: 2,
            ),
            boxShadow: faceDetected
                ? [
                    BoxShadow(
                      color: task.color.withValues(alpha: 0.30),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: Icon(task.icon, color: task.color, size: iconSize * 0.48),
        ),
        SizedBox(height: isLandscape ? 10 : 14),

        // Instruction
        Text(
          task.instruction,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet
                ? (isLandscape ? 14.0 : 20.0)
                : (isLandscape ? 13.0 : 18.0),
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        SizedBox(height: isLandscape ? 4 : 6),

        // Hint
        Text(
          task.hint,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.50),
            fontSize: isTablet
                ? (isLandscape ? 12.0 : 14.0)
                : (isLandscape ? 11.0 : 13.0),
          ),
        ),
        SizedBox(height: isLandscape ? 12 : 16),

        // Face detection status bar
        _FaceDetectionBar(
          faceDetected: faceDetected,
          color: task.color,
          isCompact: isLandscape,
        ),
      ],
    );
  }
}

// ── Face detection status bar ─────────────────────────────────────────────────

class _FaceDetectionBar extends StatelessWidget {
  const _FaceDetectionBar({
    required this.faceDetected,
    required this.color,
    required this.isCompact,
  });
  final bool faceDetected;
  final Color color;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated bar
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          height: 3.5,
          width: faceDetected ? (isCompact ? 100.0 : 140.0) : 60.0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: faceDetected
                  ? [color, color.withValues(alpha: 0.35)]
                  : [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.04)
                    ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 7),
        // Status text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            faceDetected
                ? '✓ Face detected — now perform the action'
                : '⊙ Position your face in the oval',
            key: ValueKey(faceDetected),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: faceDetected
                  ? color
                  : Colors.white.withValues(alpha: 0.38),
              fontSize: isCompact ? 10 : 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Success badge ─────────────────────────────────────────────────────────────

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge({required this.isTablet, this.compact = false});
  final bool isTablet;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 44.0 : (isTablet ? 68.0 : 58.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D68F), Color(0xFF00C9E4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D68F).withValues(alpha: 0.45),
            blurRadius: compact ? 14 : 22,
            spreadRadius: compact ? 1 : 3,
          ),
        ],
      ),
      child: Icon(Icons.check_rounded,
          color: Colors.white, size: size * 0.52),
    );
  }
}

// ── Face alignment feedback ───────────────────────────────────────────────────

class _FaceAlignmentFeedback extends StatelessWidget {
  const _FaceAlignmentFeedback({
    required this.facePresent,
    required this.hintIndex,
    required this.isTablet,
    this.compact = false,
  });
  final bool facePresent;
  final int hintIndex;
  final bool isTablet;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (facePresent) {
      return Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF00D68F).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00D68F).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00D68F),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'Face detected — ready!',
                  style: TextStyle(
                    color: const Color(0xFF00D68F),
                    fontSize: compact ? 11 : (isTablet ? 13 : 12),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // No face — show guidance
    return Column(
      children: [
        // Arrow guide row
        if (!compact)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GuideArrow(direction: _ArrowDir.left),
                const SizedBox(width: 10),
                _GuideArrow(direction: _ArrowDir.up),
                const SizedBox(width: 6),
                // Center target
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(Icons.face_outlined,
                      color: Colors.white.withValues(alpha: 0.35),
                      size: 18),
                ),
                const SizedBox(width: 6),
                _GuideArrow(direction: _ArrowDir.down),
                const SizedBox(width: 10),
                _GuideArrow(direction: _ArrowDir.right),
              ],
            ),
          ),

        // Cycling hint text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position:
                  Tween(begin: const Offset(0, 0.4), end: Offset.zero)
                      .animate(anim),
              child: child,
            ),
          ),
          child: Container(
            key: ValueKey(hintIndex),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Text(
              _kAlignmentHints[hintIndex % _kAlignmentHints.length],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.60),
                fontSize: compact ? 10.5 : (isTablet ? 13 : 12),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Guide arrow ───────────────────────────────────────────────────────────────

enum _ArrowDir { up, down, left, right }

class _GuideArrow extends StatefulWidget {
  const _GuideArrow({required this.direction});
  final _ArrowDir direction;

  @override
  State<_GuideArrow> createState() => _GuideArrowState();
}

class _GuideArrowState extends State<_GuideArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  static const _icons = {
    _ArrowDir.up: Icons.keyboard_arrow_up_rounded,
    _ArrowDir.down: Icons.keyboard_arrow_down_rounded,
    _ArrowDir.left: Icons.keyboard_arrow_left_rounded,
    _ArrowDir.right: Icons.keyboard_arrow_right_rounded,
  };

  static const _offsets = {
    _ArrowDir.up: Offset(0, -3),
    _ArrowDir.down: Offset(0, 3),
    _ArrowDir.left: Offset(-3, 0),
    _ArrowDir.right: Offset(3, 0),
  };

  // Stagger each arrow slightly based on direction
  static const _delays = {
    _ArrowDir.up: 0,
    _ArrowDir.right: 150,
    _ArrowDir.down: 300,
    _ArrowDir.left: 450,
  };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(
        Duration(milliseconds: _delays[widget.direction] ?? 0),
        () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseOffset = _offsets[widget.direction] ?? Offset.zero;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Transform.translate(
        offset: baseOffset * _anim.value,
        child: Opacity(
          opacity: 0.25 + 0.55 * _anim.value,
          child: child,
        ),
      ),
      child: Icon(
        _icons[widget.direction],
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

// ── Selfie button ──────────────────────────────────────────────────────────────

class _SelfieButton extends StatelessWidget {
  const _SelfieButton({
    required this.facePresent,
    required this.readyScale,
    required this.shimmerAnim,
    required this.onTap,
    required this.isTablet,
    this.compact = false,
  });

  final bool facePresent;
  final Animation<double> readyScale;
  final AnimationController shimmerAnim;
  final VoidCallback? onTap;
  final bool isTablet;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 46.0 : (isTablet ? 60.0 : 54.0);
    final fontSize = compact ? 13.0 : (isTablet ? 17.0 : 15.0);
    final iconSize = compact ? 17.0 : (isTablet ? 22.0 : 20.0);

    return GestureDetector(
      onTap: facePresent ? onTap : null,
      child: facePresent
          ? ScaleTransition(
              scale: readyScale,
              child: _EnabledSelfieBtn(
                shimmerAnim: shimmerAnim,
                height: height,
                fontSize: fontSize,
                iconSize: iconSize,
              ),
            )
          : _DisabledSelfieBtn(
              height: height,
              fontSize: fontSize,
              iconSize: iconSize,
            ),
    );
  }
}

class _EnabledSelfieBtn extends StatelessWidget {
  const _EnabledSelfieBtn({
    required this.shimmerAnim,
    required this.height,
    required this.fontSize,
    required this.iconSize,
  });
  final AnimationController shimmerAnim;
  final double height;
  final double fontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerAnim,
      builder: (context, child) {
        final shimmerX = -1.5 + shimmerAnim.value * 3.0;
        return Container(
          height: height,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C6FF7), Color(0xFF1B8EF8), Color(0xFF00C9E4)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C6FF7).withValues(alpha: 0.45),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shimmer layer
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Transform.translate(
                  offset: Offset(shimmerX * height * 2, 0),
                  child: Container(
                    width: height * 0.6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.16),
                          Colors.white.withValues(alpha: 0),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ),
              // Content
              Center(
                child: child,
              ),
            ],
          ),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_rounded,
              color: Colors.white, size: iconSize),
          const SizedBox(width: 10),
          Text(
            'Take Selfie',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisabledSelfieBtn extends StatelessWidget {
  const _DisabledSelfieBtn({
    required this.height,
    required this.fontSize,
    required this.iconSize,
  });
  final double height;
  final double fontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1.5,
          // Dashed border style via custom painter would be ideal, but
          // solid muted border clearly communicates the disabled state.
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined,
              color: Colors.white.withValues(alpha: 0.25),
              size: iconSize),
          const SizedBox(width: 10),
          Text(
            'Position Face First',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.28),
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Oval overlay painter with scan arc + corner brackets + alignment arrows
// ═════════════════════════════════════════════════════════════════════════════

class _FaceOvalPainterWidget extends StatelessWidget {
  const _FaceOvalPainterWidget({
    required this.state,
    required Animation<double> pulseAnim,
    required this.scanAnim,
    required this.arrowAnim,
    required this.isLandscape,
  }) : _pulseAnim = pulseAnim;

  final FaceIdState state;
  final Animation<double> _pulseAnim;
  final AnimationController scanAnim;
  final Animation<double> arrowAnim;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnim, scanAnim, arrowAnim]),
      builder: (context, child) {
        final pulse = _pulseAnim.value;
        final scan = scanAnim.value;
        final arrow = arrowAnim.value;

        Color borderColor;
        bool showGlow;
        bool showScanArc;
        Color scanColor;
        bool showAlignmentArrows;
        bool showAlignmentTarget;

        if (state is FaceIdRunning) {
          final running = state as FaceIdRunning;
          borderColor = running.faceDetected
              ? running.currentTask.color
              : Colors.white.withValues(alpha: 0.45);
          showGlow = running.faceDetected;
          showScanArc = true;
          scanColor = running.currentTask.color;
          showAlignmentArrows = !running.faceDetected;
          showAlignmentTarget = !running.faceDetected;
        } else if (state is FaceIdAllTasksDone) {
          final done = state as FaceIdAllTasksDone;
          borderColor = done.facePresent
              ? const Color(0xFF00D68F)
              : Colors.white.withValues(alpha: 0.35);
          showGlow = done.facePresent;
          showScanArc = false;
          scanColor = Colors.transparent;
          showAlignmentArrows = !done.facePresent;
          showAlignmentTarget = !done.facePresent;
        } else {
          borderColor = Colors.white.withValues(alpha: 0.25);
          showGlow = false;
          showScanArc = false;
          scanColor = Colors.transparent;
          showAlignmentArrows = false;
          showAlignmentTarget = false;
        }

        return CustomPaint(
          painter: _OvalOverlayPainter(
            borderColor: borderColor,
            glowIntensity: showGlow ? pulse : 0,
            scanProgress: showScanArc ? scan : -1,
            scanColor: scanColor,
            showAlignmentArrows: showAlignmentArrows,
            showAlignmentTarget: showAlignmentTarget,
            arrowPulse: arrow,
            isLandscape: isLandscape,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _OvalOverlayPainter extends CustomPainter {
  const _OvalOverlayPainter({
    required this.borderColor,
    required this.glowIntensity,
    required this.scanProgress,
    required this.scanColor,
    required this.showAlignmentArrows,
    required this.showAlignmentTarget,
    required this.arrowPulse,
    required this.isLandscape,
  });

  final Color borderColor;
  final double glowIntensity;
  final double scanProgress; // -1 = hidden, 0-1 = rotating
  final Color scanColor;
  final bool showAlignmentArrows;
  final bool showAlignmentTarget;
  final double arrowPulse;
  final bool isLandscape;

  @override
  void paint(Canvas canvas, Size size) {
    // ── Compute oval geometry ────────────────────────────────────────
    // In landscape: shift oval left so it sits in the camera-preview area
    // (the right side is occupied by the task/selfie panel).
    final centerX = isLandscape
        ? size.width  * _LivenessOverlayState._ovalCenterXLandscape
        : size.width  * 0.50;
    final centerY = isLandscape
        ? size.height * 0.50
        : size.height * _LivenessOverlayState._ovalCenterYPortrait;

    // Landscape oval: narrow width + tall height → portrait-shaped oval so the
    // face is never distorted regardless of device orientation.
    final ovalW = isLandscape
        ? size.width  * _LivenessOverlayState._ovalWidthFractionLandscape
        : size.width  * _LivenessOverlayState._ovalWidthFraction;
    final ovalH = isLandscape
        ? size.height * _LivenessOverlayState._ovalHeightFractionLandscape
        : size.height * _LivenessOverlayState._ovalHeightFractionPortrait;

    final center = Offset(centerX, centerY);
    final ovalRect =
        Rect.fromCenter(center: center, width: ovalW, height: ovalH);

    // ── Dark overlay with oval cutout ────────────────────────────────
    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(bgPath,
        Paint()..color = Colors.black.withValues(alpha: 0.65));

    // ── Outer glow when face detected ────────────────────────────────
    if (glowIntensity > 0) {
      canvas.drawOval(
        ovalRect.inflate(6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..color = borderColor.withValues(alpha: 0.16 * glowIntensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    // ── Corner bracket guides (Apple Face ID style) ──────────────────
    _drawCornerBrackets(canvas, ovalRect, borderColor);

    // ── Rotating scan arc (during tasks) ────────────────────────────
    if (scanProgress >= 0) {
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = scanColor.withValues(alpha: 0.80);
      final startAngle = scanProgress * math.pi * 2 - math.pi / 2;
      canvas.drawArc(
        ovalRect,
        startAngle,
        math.pi * 0.55, // arc length ≈ quarter of oval
        false,
        arcPaint,
      );
      // Second trailing arc (dimmer)
      canvas.drawArc(
        ovalRect,
        startAngle - math.pi * 0.30,
        math.pi * 0.28,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = scanColor.withValues(alpha: 0.25),
      );
    }

    // ── Oval border ──────────────────────────────────────────────────
    canvas.drawOval(
      ovalRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = borderColor,
    );

    // ── Alignment target (face-center crosshair) ─────────────────────
    if (showAlignmentTarget) {
      final alpha = 0.18 + 0.18 * arrowPulse;
      final crossSize = ovalW * 0.08;
      final crossPaint = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      // Horizontal
      canvas.drawLine(
        Offset(center.dx - crossSize, center.dy),
        Offset(center.dx + crossSize, center.dy),
        crossPaint,
      );
      // Vertical
      canvas.drawLine(
        Offset(center.dx, center.dy - crossSize),
        Offset(center.dx, center.dy + crossSize),
        crossPaint,
      );
      // Center dot
      canvas.drawCircle(
        center,
        3,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha + 0.10)
          ..style = PaintingStyle.fill,
      );
    }

    // ── Alignment arrows (pointing toward center) ────────────────────
    if (showAlignmentArrows) {
      final arrowDist = ovalH * 0.38; // distance from center to arrow
      final arrowOffset = 6 * arrowPulse; // inward pulse distance
      final arrowAlpha = 0.30 + 0.40 * arrowPulse;

      _drawArrow(canvas, center,
          Offset(center.dx, center.dy - arrowDist + arrowOffset),
          arrowAlpha, false); // top → down
      _drawArrow(canvas, center,
          Offset(center.dx, center.dy + arrowDist - arrowOffset),
          arrowAlpha, false); // bottom → up
      final arrowDistH = ovalW * 0.40;
      _drawArrow(canvas, center,
          Offset(center.dx - arrowDistH + arrowOffset, center.dy),
          arrowAlpha, true); // left → right
      _drawArrow(canvas, center,
          Offset(center.dx + arrowDistH - arrowOffset, center.dy),
          arrowAlpha, true); // right → left
    }
  }

  void _drawCornerBrackets(
      Canvas canvas, Rect ovalRect, Color color) {
    const bracketLen = 22.0;
    const bracketWidth = 2.5;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.90)
      ..strokeWidth = bracketWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Top-left
    _drawLBracket(canvas, ovalRect.topLeft, bracketLen, 0, 0, paint);
    // Top-right
    _drawLBracket(canvas, ovalRect.topRight, bracketLen, 1, 0, paint);
    // Bottom-left
    _drawLBracket(canvas, ovalRect.bottomLeft, bracketLen, 0, 1, paint);
    // Bottom-right
    _drawLBracket(canvas, ovalRect.bottomRight, bracketLen, 1, 1, paint);
  }

  void _drawLBracket(Canvas canvas, Offset corner, double len,
      int hDir, int vDir, Paint paint) {
    // hDir: 0=right, 1=left; vDir: 0=down, 1=up
    final hSign = hDir == 0 ? 1.0 : -1.0;
    final vSign = vDir == 0 ? 1.0 : -1.0;
    canvas.drawLine(
        corner, corner + Offset(hSign * len, 0), paint);
    canvas.drawLine(
        corner, corner + Offset(0, vSign * len), paint);
  }

  void _drawArrow(Canvas canvas, Offset center, Offset tip,
      double alpha, bool horizontal) {
    // Draw a small chevron arrow pointing TOWARD center from tip
    final dir = (center - tip);
    final norm = dir / dir.distance;
    final arrowHeadLen = 10.0;
    final arrowAngle = 0.55; // radians for arrowhead spread

    final p1 = tip +
        Offset(
          norm.dx * arrowHeadLen * math.cos(arrowAngle) -
              norm.dy * arrowHeadLen * math.sin(arrowAngle),
          norm.dy * arrowHeadLen * math.cos(arrowAngle) +
              norm.dx * arrowHeadLen * math.sin(arrowAngle),
        );
    final p2 = tip +
        Offset(
          norm.dx * arrowHeadLen * math.cos(-arrowAngle) -
              norm.dy * arrowHeadLen * math.sin(-arrowAngle),
          norm.dy * arrowHeadLen * math.cos(-arrowAngle) +
              norm.dx * arrowHeadLen * math.sin(-arrowAngle),
        );

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(tip, p1, paint);
    canvas.drawLine(tip, p2, paint);
  }

  @override
  bool shouldRepaint(_OvalOverlayPainter old) =>
      old.borderColor        != borderColor        ||
      old.glowIntensity      != glowIntensity      ||
      old.scanProgress       != scanProgress       ||
      old.scanColor          != scanColor          ||
      old.showAlignmentArrows != showAlignmentArrows ||
      old.showAlignmentTarget != showAlignmentTarget ||
      old.arrowPulse         != arrowPulse         ||
      old.isLandscape        != isLandscape;        // orientation change
}