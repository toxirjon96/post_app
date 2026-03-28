import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constant/theme_config.dart';
import '../util/responsive.dart';

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
/// Tap anywhere or swipe up to dismiss early.
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
      builder: (overlayCtx) => _NotificationWidget(
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
//  ADAPTIVE LAYOUT TOKENS
// ═══════════════════════════════════════════════════════════════════════════
//
//  Four layout modes resolved from MediaQuery at build time:
//
//   ┌─────────────────────┬────────────────────────────────────────────────┐
//   │ Phone  Portrait     │ Full-width banner, 14 px gutters, drag handle  │
//   │ Phone  Landscape    │ Centered slim toast, 62 % width, no handle     │
//   │ Tablet Portrait     │ Centered wide card, max 580 dp, drag handle    │
//   │ Tablet Landscape    │ Right-anchored card, fixed 400 dp, no handle   │
//   └─────────────────────┴────────────────────────────────────────────────┘

class _Tok {
  const _Tok({
    required this.left,
    required this.right,
    required this.top,
    required this.containerD,
    required this.iconSz,
    required this.titleSp,
    required this.msgSp,
    required this.badgeSp,
    required this.padH,
    required this.padV,
    required this.iconGap,
    required this.textGap,
    required this.thumbSz,
    required this.radius,
    required this.accentW,
    required this.timerH,
    required this.closeD,
    required this.dragHandle,
  });

  final double left;
  final double right;
  final double top;
  final double containerD; // icon circle diameter
  final double iconSz;
  final double titleSp;    // absolute font size (already scaled per tier)
  final double msgSp;
  final double badgeSp;
  final double padH;       // horizontal content padding
  final double padV;       // vertical content padding
  final double iconGap;    // gap between icon and text column
  final double textGap;    // gap between title / message
  final double thumbSz;    // image thumbnail side length
  final double radius;     // card corner radius
  final double accentW;    // left accent bar width
  final double timerH;     // timer progress bar height
  final double closeD;     // close button diameter
  final bool dragHandle;   // show drag-to-dismiss pill

  // ── Factory ─────────────────────────────────────────────────────────────

  static _Tok resolve(MediaQueryData mq, bool isTablet, bool isLargeTablet) {
    final isLandscape = mq.orientation == Orientation.landscape;
    final w      = mq.size.width;
    final topPad = mq.padding.top;
    final safeL  = mq.padding.left;
    final safeR  = mq.padding.right;

    // ── Tablet Landscape: right-anchored panel ─────────────────────────────
    if (isTablet && isLandscape) {
      const cardW  = 400.0;
      final rInset = math.max(safeR, 20.0);
      return _Tok(
        left:       w - cardW - rInset,
        right:      rInset,
        top:        topPad + 14,
        containerD: isLargeTablet ? 52 : 48,
        iconSz:     isLargeTablet ? 26 : 24,
        titleSp:    isLargeTablet ? 15.5 : 14.5,
        msgSp:      isLargeTablet ? 13.5 : 13,
        badgeSp:    isLargeTablet ? 10.5 : 10,
        padH:       16,
        padV:       14,
        iconGap:    13,
        textGap:    3,
        thumbSz:    60,
        radius:     20,
        accentW:    4.5,
        timerH:     3,
        closeD:     28,
        dragHandle: false,
      );
    }

    // ── Tablet Portrait: centered wide card ───────────────────────────────
    if (isTablet && !isLandscape) {
      final tW     = math.min(w - 48.0, 580.0);
      final hInset = (w - tW) / 2;
      return _Tok(
        left:       hInset,
        right:      hInset,
        top:        topPad + 16,
        containerD: isLargeTablet ? 56 : 52,
        iconSz:     isLargeTablet ? 28 : 26,
        titleSp:    isLargeTablet ? 17 : 16,
        msgSp:      isLargeTablet ? 14.5 : 14,
        badgeSp:    isLargeTablet ? 11 : 10.5,
        padH:       18,
        padV:       16,
        iconGap:    15,
        textGap:    5,
        thumbSz:    70,
        radius:     22,
        accentW:    5,
        timerH:     3.5,
        closeD:     32,
        dragHandle: true,
      );
    }

    // ── Phone Landscape: slim centered toast ──────────────────────────────
    if (!isTablet && isLandscape) {
      final tW     = math.min(w * 0.62, 440.0);
      final sideG  = math.max(safeL, safeR) + 8;
      final hInset = math.max((w - tW) / 2, sideG);
      return _Tok(
        left:       hInset,
        right:      hInset,
        top:        topPad + 6,
        containerD: 38,
        iconSz:     19,
        titleSp:    13,
        msgSp:      11.5,
        badgeSp:    9.5,
        padH:       12,
        padV:       9,
        iconGap:    10,
        textGap:    3,
        thumbSz:    48,
        radius:     16,
        accentW:    3.5,
        timerH:     2.5,
        closeD:     24,
        dragHandle: false,
      );
    }

    // ── Phone Portrait: full-width banner (default) ───────────────────────
    return _Tok(
      left:       14,
      right:      14,
      top:        topPad + 10,
      containerD: 44,
      iconSz:     22,
      titleSp:    14,
      msgSp:      12.5,
      badgeSp:    10,
      padH:       14,
      padV:       12,
      iconGap:    12,
      textGap:    4,
      thumbSz:    58,
      radius:     18,
      accentW:    4,
      timerH:     2.5,
      closeD:     26,
      dragHandle: true,
    );
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
  double _dragY    = 0;
  bool _dismissing = false;

  // ── Per-type helpers ─────────────────────────────────────────────────────

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

  static String _label(AppNotificationType t) => switch (t) {
    AppNotificationType.success => 'SUCCESS',
    AppNotificationType.error   => 'ERROR',
    AppNotificationType.warning => 'WARNING',
    AppNotificationType.info    => 'INFO',
  };

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
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

  // ── Dismiss ──────────────────────────────────────────────────────────────

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    _timer?.cancel();
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  // ── Swipe-up gesture ─────────────────────────────────────────────────────

  void _onDragUpdate(DragUpdateDetails d) {
    final delta = d.primaryDelta ?? 0;
    if (delta < 0) setState(() => _dragY = (_dragY + delta).clamp(-120.0, 0.0));
  }

  void _onDragEnd(DragEndDetails d) {
    final vel = d.primaryVelocity ?? 0;
    if (_dragY < -36 || vel < -500) {
      _dismiss();
    } else {
      setState(() => _dragY = 0);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq     = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tok    = _Tok.resolve(mq, context.isTablet, context.isLargeTablet);
    final color  = _color(widget.type);

    return Positioned(
      top:   tok.top,
      left:  tok.left,
      right: tok.right,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Transform.translate(
                offset: Offset(0, _dragY),
                child: GestureDetector(
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd:   _onDragEnd,
                  onTap: () {
                    widget.onTap?.call();
                    _dismiss();
                  },
                  child: _buildCard(isDark, color, tok),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Card ─────────────────────────────────────────────────────────────────

  Widget _buildCard(bool isDark, Color color, _Tok tok) {
    final bg    = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.97);
    final icon  = _icon(widget.type);
    final label = _label(widget.type);

    return ClipRRect(
      borderRadius: BorderRadius.circular(tok.radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(tok.radius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : color.withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color:      color.withValues(alpha: 0.22),
                blurRadius: 36,
                offset:     const Offset(0, 10),
              ),
              BoxShadow(
                color:      Colors.black.withValues(alpha: isDark ? 0.48 : 0.08),
                blurRadius: 22,
                offset:     const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // ── Subtle radial tint (type-color atmosphere) ─────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(tok.radius),
                    gradient: RadialGradient(
                      center:  const Alignment(-0.9, -1.0),
                      radius:  1.8,
                      colors: [
                        color.withValues(alpha: isDark ? 0.07 : 0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Left accent gradient bar ────────────────────────────────
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: Container(
                  width: tok.accentW,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end:   Alignment.bottomCenter,
                      colors: [
                        color,
                        color.withValues(alpha: 0.32),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft:    Radius.circular(tok.radius),
                      bottomLeft: Radius.circular(tok.radius),
                    ),
                  ),
                ),
              ),

              // ── Main content column ─────────────────────────────────────
              Padding(
                padding: EdgeInsets.only(left: tok.accentW),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag handle (portrait layouts only)
                    if (tok.dragHandle)
                      Center(
                        child: Container(
                          width: 34,
                          height: 3.5,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.16)
                                : Colors.black.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                    // Icon + text + close
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        tok.padH,
                        tok.dragHandle ? 8.0 : tok.padV,
                        tok.padH - 4,
                        tok.padV,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Pulsing icon ──────────────────────────────
                          _PulsingIcon(
                            color:      color,
                            icon:       icon,
                            containerD: tok.containerD,
                            iconSz:     tok.iconSz,
                          ),
                          SizedBox(width: tok.iconGap),

                          // ── Text column ───────────────────────────────
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Badge + close row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _TypeBadge(
                                      label:    label,
                                      color:    color,
                                      isDark:   isDark,
                                      fontSize: tok.badgeSp,
                                    ),
                                    const Spacer(),
                                    _CloseBtn(
                                      diameter: tok.closeD,
                                      isDark:   isDark,
                                      onTap:    _dismiss,
                                    ),
                                  ],
                                ),
                                SizedBox(height: tok.textGap + 2),

                                // Title
                                Text(
                                  widget.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize:     tok.titleSp,
                                    fontWeight:   FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0D1526),
                                    fontFamily:   'Poppins',
                                    height:        1.25,
                                    letterSpacing: -0.2,
                                  ),
                                ),

                                // Message
                                if (widget.message != null) ...[
                                  SizedBox(height: tok.textGap),
                                  Text(
                                    widget.message!,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize:   tok.msgSp,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.52)
                                          : const Color(0xFF4A5270),
                                      height:     1.5,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],

                                // Images
                                if (widget.images?.isNotEmpty == true) ...[
                                  SizedBox(height: tok.textGap + 6),
                                  _NotificationImageRow(
                                    images:    widget.images!.take(4).toList(),
                                    color:     color,
                                    isDark:    isDark,
                                    thumbSize: tok.thumbSz,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Countdown timer bar ─────────────────────────────
                    _TimerBar(
                      duration: widget.duration,
                      color:    color,
                      height:   tok.timerH,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  TYPE BADGE
// ═══════════════════════════════════════════════════════════════════════════

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({
    required this.label,
    required this.color,
    required this.isDark,
    required this.fontSize,
  });

  final String label;
  final Color color;
  final bool isDark;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.32 : 0.22),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize:     fontSize,
          fontWeight:   FontWeight.w700,
          color:        color,
          fontFamily:   'Poppins',
          letterSpacing: 0.7,
          height:        1.0,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  CLOSE BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class _CloseBtn extends StatelessWidget {
  const _CloseBtn({
    required this.diameter,
    required this.isDark,
    required this.onTap,
  });

  final double diameter;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.close_rounded,
          size:  diameter * 0.56,
          color: isDark
              ? Colors.white.withValues(alpha: 0.40)
              : Colors.black.withValues(alpha: 0.30),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PULSING ICON  — sonar ring expansion
// ═══════════════════════════════════════════════════════════════════════════

class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon({
    required this.color,
    required this.icon,
    required this.containerD,
    required this.iconSz,
  });

  final Color     color;
  final IconData  icon;
  final double    containerD;
  final double    iconSz;

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _ring;
  late final Animation<double> _ringAlpha;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _ring = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ringAlpha = Tween<double>(begin: 0.55, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.containerD;

    return SizedBox(
      width:  d,
      height: d,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Expanding sonar ring (overflows its box, clipped by overlay)
          OverflowBox(
            maxWidth:  d * 1.65,
            maxHeight: d * 1.65,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) {
                final ringD = d + _ring.value * d * 0.55;
                return Container(
                  width:  ringD,
                  height: ringD,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withValues(
                        alpha: _ringAlpha.value * 0.45,
                      ),
                      width: 1.5,
                    ),
                  ),
                );
              },
            ),
          ),

          // Icon container — radial gradient fill + glow
          Container(
            width:  d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.color.withValues(alpha: 0.26),
                  widget.color.withValues(alpha: 0.10),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color:      widget.color.withValues(alpha: 0.32),
                  blurRadius: 14,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(widget.icon, color: widget.color, size: widget.iconSz),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  COUNTDOWN TIMER BAR
// ═══════════════════════════════════════════════════════════════════════════

class _TimerBar extends StatefulWidget {
  const _TimerBar({
    required this.duration,
    required this.color,
    required this.height,
  });

  final Duration duration;
  final Color    color;
  final double   height;

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
        value:           1.0 - _ctrl.value,
        minHeight:       widget.height,
        backgroundColor: widget.color.withValues(alpha: 0.08),
        valueColor:      AlwaysStoppedAnimation<Color>(widget.color),
        borderRadius:    const BorderRadius.vertical(bottom: Radius.circular(20)),
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
    required this.thumbSize,
  });

  final List<String> images;
  final Color        color;
  final bool         isDark;
  final double       thumbSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: thumbSize,
      child: Row(
        children: images.asMap().entries.map((e) {
          final isLast = e.key == images.length - 1;
          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                e.value,
                width:  thumbSize,
                height: thumbSize,
                fit:    BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width:  thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.image_rounded,
                    color: color.withValues(alpha: 0.50),
                    size:  thumbSize * 0.35,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}