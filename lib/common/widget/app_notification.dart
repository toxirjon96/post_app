import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constant/theme_config.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  PUBLIC TYPES
// ═══════════════════════════════════════════════════════════════════════════

enum AppNotificationType { success, error, warning, info }

// ═══════════════════════════════════════════════════════════════════════════
//  ENTRY POINT
// ═══════════════════════════════════════════════════════════════════════════

/// Global notification / toast system.
///
/// Inserts an [OverlayEntry] above all other content.
/// Tap or swipe up to dismiss early.
///
/// ```dart
/// AppNotification.show(
///   context: context,
///   type: AppNotificationType.success,
///   title: 'Booking Confirmed',
///   message: 'Room 412 is reserved for 3 nights.',
///   images: ['https://…'],
/// );
/// ```
class AppNotification {
  const AppNotification._();

  static OverlayEntry? _current;

  static void show({
    required BuildContext context,
    required AppNotificationType type,
    required String title,
    String? message,
    List<String>? images, // up to 4
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    _current?.remove();
    _current = null;

    HapticFeedback.lightImpact();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => _NotificationWidget(
        type: type,
        title: title,
        message: message,
        images: images,
        duration: duration,
        onTap: onTap,
        onDismiss: () {
          entry.remove();
          if (_current == entry) _current = null;
        },
      ),
    );

    _current = entry;
    Overlay.of(context).insert(entry);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  NOTIFICATION WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class _NotificationWidget extends StatefulWidget {
  const _NotificationWidget({
    required this.type,
    required this.title,
    this.message,
    this.images,
    required this.duration,
    this.onTap,
    required this.onDismiss,
  });

  final AppNotificationType type;
  final String title;
  final String? message;
  final List<String>? images;
  final Duration duration;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  Timer? _timer;
  double _dragOffsetY = 0;
  bool _dismissing = false;

  // ── Per-type helpers ──────────────────────────────────────────────────
  static Color _color(AppNotificationType t) => switch (t) {
        AppNotificationType.success => AppColors.emerald,
        AppNotificationType.error   => AppColors.coral,
        AppNotificationType.warning => AppColors.amber,
        AppNotificationType.info    => AppColors.electricBlue,
      };

  static IconData _icon(AppNotificationType t) => switch (t) {
        AppNotificationType.success => Icons.check_circle_rounded,
        AppNotificationType.error   => Icons.error_rounded,
        AppNotificationType.warning => Icons.warning_rounded,
        AppNotificationType.info    => Icons.info_rounded,
      };

  // ── Lifecycle ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 540),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.45, curve: Curves.easeOut)),
    );

    _scaleAnim = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    _ctrl.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    _timer?.cancel();
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final delta = d.primaryDelta ?? 0;
    if (delta < 0) setState(() => _dragOffsetY = (_dragOffsetY + delta).clamp(-120.0, 0.0));
  }

  void _onDragEnd(DragEndDetails d) {
    final velocity = d.primaryVelocity ?? 0;
    if (_dragOffsetY < -36 || velocity < -500) {
      _dismiss();
    } else {
      setState(() => _dragOffsetY = 0);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color  = _color(widget.type);
    final icon   = _icon(widget.type);
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final isLandscape = mq.orientation == Orientation.landscape;
    final screenWidth = mq.size.width;

    // ── Landscape: centered narrow toast (iOS / macOS notification style) ──
    // ── Portrait: full-width banner with 14px gutters ─────────────────────
    final double hInset;
    if (isLandscape) {
      final targetWidth = math.min(screenWidth * 0.56, 460.0);
      final sideGuard = math.max(mq.padding.left, mq.padding.right) + 10;
      hInset = math.max((screenWidth - targetWidth) / 2, sideGuard);
    } else {
      hInset = 14;
    }

    return Positioned(
      top: topPad + (isLandscape ? 6 : 10),
      left: hInset,
      right: hInset,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Transform.translate(
                offset: Offset(0, _dragOffsetY),
                child: GestureDetector(
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: _onDragEnd,
                  onTap: () {
                    widget.onTap?.call();
                    _dismiss();
                  },
                  child: _buildCard(isDark, color, icon),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(bool isDark, Color color, IconData icon) {
    final bg = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.97)
        : Colors.white.withValues(alpha: 0.98);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.09),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top accent bar ─────────────────────────────────────
              Container(
                height: 3.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),

              // ── Body ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pulsing icon
                    _PulsingIcon(color: color, icon: icon),
                    const SizedBox(width: 12),

                    // Text + images
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F1629),
                              fontFamily: 'Poppins',
                              height: 1.3,
                            ),
                          ),
                          if (widget.message != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.message!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.55)
                                    : const Color(0xFF4A5270),
                                height: 1.55,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                          if (widget.images?.isNotEmpty == true) ...[
                            const SizedBox(height: 10),
                            _NotificationImageRow(
                              images: widget.images!.take(4).toList(),
                              color: color,
                              isDark: isDark,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Dismiss button
                    GestureDetector(
                      onTap: _dismiss,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.close_rounded,
                          size: 17,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.35)
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Countdown progress bar ────────────────────────────
              _TimerBar(duration: widget.duration, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PULSING ICON
// ═══════════════════════════════════════════════════════════════════════════

class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon({required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.16).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, _) => Transform.scale(
        scale: _scale.value,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(
                    alpha: 0.28 * ((_scale.value - 1.0) / 0.16).clamp(0, 1)),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(widget.icon, color: widget.color, size: 20),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  COUNTDOWN TIMER BAR
// ═══════════════════════════════════════════════════════════════════════════

class _TimerBar extends StatefulWidget {
  const _TimerBar({required this.duration, required this.color});
  final Duration duration;
  final Color color;

  @override
  State<_TimerBar> createState() => _TimerBarState();
}

class _TimerBarState extends State<_TimerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => LinearProgressIndicator(
        value: 1.0 - _ctrl.value,
        minHeight: 2.5,
        backgroundColor: widget.color.withValues(alpha: 0.08),
        valueColor: AlwaysStoppedAnimation<Color>(widget.color),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  NOTIFICATION IMAGE ROW
// ═══════════════════════════════════════════════════════════════════════════

class _NotificationImageRow extends StatelessWidget {
  const _NotificationImageRow({
    required this.images,
    required this.color,
    required this.isDark,
  });

  final List<String> images;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: images.asMap().entries.map((e) {
          final isLast = e.key == images.length - 1;
          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.network(
                e.value,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.image_rounded,
                      color: color.withValues(alpha: 0.50), size: 18),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
