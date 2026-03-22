import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/face_id_bloc.dart';
import '../model/liveness_task.dart';

class LivenessOverlay extends StatefulWidget {
  const LivenessOverlay({super.key, required this.onSelfiePressed});
  final VoidCallback onSelfiePressed;

  @override
  State<LivenessOverlay> createState() => _LivenessOverlayState();
}

class _LivenessOverlayState extends State<LivenessOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  late final AnimationController _taskController;
  late final Animation<Offset> _taskSlideAnim;
  late final Animation<double> _taskFadeAnim;
  late final AnimationController _successController;
  late final Animation<double> _successScaleAnim;
  late final Animation<double> _successOpacityAnim;

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
      duration: const Duration(milliseconds: 450),
    )..forward();
    _taskSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _taskController, curve: Curves.easeOut));
    _taskFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _taskController, curve: Curves.easeOut),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    _successOpacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _taskController.dispose();
    _successController.dispose();
    super.dispose();
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
        }
      },
      builder: (context, state) {
        return Stack(
          fit: StackFit.expand,
          children: [
            _FaceOvalPainterWidget(state: state, pulseAnim: _pulseAnim),
            // Top progress bar — only shown during active task execution
            if (state is FaceIdRunning || state is FaceIdPermissionDenied)
              _buildTopProgressBar(state),
            if (state is FaceIdRunning)
              _buildTaskCard(state),
            if (state is FaceIdAllTasksDone)
              _buildSelfiePanel(state),
            if (state is FaceIdPermissionDenied)
              _buildPermissionDenied(context),
            if (state is FaceIdInitial)
              const Center(child: CircularProgressIndicator(color: Colors.white)),
          ],
        );
      },
    );
  }

  Widget _buildTopProgressBar(FaceIdState state) {
    final completedTasks =
        state is FaceIdRunning ? state.completedTasks : <LivenessTask>[];
    final currentTask =
        state is FaceIdRunning ? state.currentTask : null;
    final tasks =
        state is FaceIdRunning ? state.tasks : <LivenessTask>[];

    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 24,
      right: 24,
      child: Column(
        children: [
          const Text(
            'Face Verification',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: tasks.map((task) {
              final isCompleted = completedTasks.contains(task);
              final isCurrent = currentTask == task;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: isCurrent ? 36 : 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? task.color
                      : isCurrent
                          ? task.color.withOpacity(0.25)
                          : Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCompleted || isCurrent
                        ? task.color
                        : Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isCompleted ? Icons.check_rounded : task.icon,
                  color: isCompleted
                      ? Colors.white
                      : isCurrent
                          ? task.color
                          : Colors.white.withOpacity(0.3),
                  size: 16,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(FaceIdRunning state) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _taskSlideAnim,
        child: FadeTransition(
          opacity: _taskFadeAnim,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    28, 28, 28, 28 + MediaQuery.of(context).padding.bottom),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(
                        color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        key: ValueKey(state.currentTask),
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: state.currentTask.color.withOpacity(0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: state.currentTask.color.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(state.currentTask.icon,
                                color: state.currentTask.color, size: 30),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            state.currentTask.instruction,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.currentTask.hint,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            height: 4,
                            width: state.faceDetected ? 120 : 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: state.faceDetected
                                    ? [
                                        state.currentTask.color,
                                        state.currentTask.color.withOpacity(0.4)
                                      ]
                                    : [
                                        Colors.white.withOpacity(0.2),
                                        Colors.white.withOpacity(0.05)
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.faceDetected
                                ? 'Face detected — perform the action'
                                : 'Position your face in the oval',
                            style: TextStyle(
                              color: state.faceDetected
                                  ? state.currentTask.color.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.4),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

  Widget _buildSelfiePanel(FaceIdAllTasksDone state) {
    final facePresent = state.facePresent;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ScaleTransition(
        scale: _successScaleAnim,
        child: FadeTransition(
          opacity: _successOpacityAnim,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    28, 28, 28, 28 + MediaQuery.of(context).padding.bottom),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(
                        color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D68F), Color(0xFF00C9E4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D68F).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Verification Complete!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      facePresent
                          ? 'Face detected — ready to take selfie'
                          : 'Center your face in the oval to take a selfie',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: facePresent
                            ? const Color(0xFF00D68F).withOpacity(0.9)
                            : Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Face presence indicator bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: 3,
                      width: facePresent ? 100 : 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: facePresent
                              ? [const Color(0xFF00D68F), const Color(0xFF00C9E4)]
                              : [Colors.white12, Colors.white.withOpacity(0.04)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Selfie button — disabled when no face
                    GestureDetector(
                      onTap: facePresent ? widget.onSelfiePressed : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: facePresent
                              ? const LinearGradient(
                                  colors: [Color(0xFF7C6FF7), Color(0xFF00C9E4)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.08),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: facePresent
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF7C6FF7).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : [],
                          border: facePresent
                              ? null
                              : Border.all(color: Colors.white12, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              color: facePresent
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Take Selfie',
                              style: TextStyle(
                                color: facePresent
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildPermissionDenied(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined,
                color: Colors.white60, size: 64),
            const SizedBox(height: 20),
            const Text(
              'Camera Permission Required',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Please allow camera access in your device settings to use Face ID.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => context.read<FaceIdBloc>().add(const FaceIdRetry()),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text('Retry',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaceOvalPainterWidget extends AnimatedWidget {
  const _FaceOvalPainterWidget({
    required this.state,
    required Animation<double> pulseAnim,
  }) : super(listenable: pulseAnim);

  final FaceIdState state;

  @override
  Widget build(BuildContext context) {
    final pulse = (listenable as Animation<double>).value;
    final Color borderColor;
    final bool showGlow;

    if (state is FaceIdRunning) {
      final running = state as FaceIdRunning;
      borderColor = running.faceDetected
          ? running.currentTask.color
          : Colors.white.withOpacity(0.5);
      showGlow = running.faceDetected;
    } else if (state is FaceIdAllTasksDone) {
      final done = state as FaceIdAllTasksDone;
      borderColor = done.facePresent
          ? const Color(0xFF00D68F)
          : Colors.white.withOpacity(0.4);
      showGlow = done.facePresent;
    } else {
      borderColor = Colors.white.withOpacity(0.3);
      showGlow = false;
    }

    return CustomPaint(
      painter: _OvalOverlayPainter(
        borderColor: borderColor,
        glowIntensity: showGlow ? pulse : 0,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _OvalOverlayPainter extends CustomPainter {
  const _OvalOverlayPainter({
    required this.borderColor,
    required this.glowIntensity,
  });

  final Color borderColor;
  final double glowIntensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.40);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.72,
      height: size.height * 0.48,
    );

    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(bgPath, Paint()..color = Colors.black.withOpacity(0.62));

    if (glowIntensity > 0) {
      canvas.drawOval(
        ovalRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..color = borderColor.withOpacity(0.18 * glowIntensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    canvas.drawOval(
      ovalRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = borderColor,
    );
  }

  @override
  bool shouldRepaint(_OvalOverlayPainter old) =>
      old.borderColor != borderColor || old.glowIntensity != glowIntensity;
}