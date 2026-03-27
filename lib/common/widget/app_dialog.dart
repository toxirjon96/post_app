import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constant/theme_config.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  PUBLIC TYPES
// ═══════════════════════════════════════════════════════════════════════════

enum AppDialogType { success, error, warning }

class AppDialogAction {
  const AppDialogAction({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
}

// ═══════════════════════════════════════════════════════════════════════════
//  ENTRY POINT
// ═══════════════════════════════════════════════════════════════════════════

class AppDialog {
  const AppDialog._();

  /// Show a fully-animated modal dialog.
  ///
  /// * [images]          – up to 4 image URLs displayed in an adaptive grid.
  /// * [primaryAction]   – right / main CTA button.
  /// * [secondaryAction] – left / ghost button.
  static Future<T?> show<T>({
    required BuildContext context,
    required AppDialogType type,
    required String title,
    required String message,
    List<String>? images,
    AppDialogAction? primaryAction,
    AppDialogAction? secondaryAction,
    bool barrierDismissible = true,
  }) {
    HapticFeedback.mediumImpact();
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: false, // animated dismissal is handled internally
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, _, _) => _AppDialogWidget(
        type: type,
        title: title,
        message: message,
        images: images,
        primaryAction: primaryAction,
        secondaryAction: secondaryAction,
        barrierDismissible: barrierDismissible,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  DIALOG WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class _AppDialogWidget extends StatefulWidget {
  const _AppDialogWidget({
    required this.type,
    required this.title,
    required this.message,
    this.images,
    this.primaryAction,
    this.secondaryAction,
    required this.barrierDismissible,
  });

  final AppDialogType type;
  final String title;
  final String message;
  final List<String>? images;
  final AppDialogAction? primaryAction;
  final AppDialogAction? secondaryAction;
  final bool barrierDismissible;

  @override
  State<_AppDialogWidget> createState() => _AppDialogWidgetState();
}

class _AppDialogWidgetState extends State<_AppDialogWidget>
    with TickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────────────────
  late final AnimationController _entryCtrl; // card enter / exit
  late final AnimationController _iconCtrl;  // ring → symbol → particles
  late final AnimationController _pulseCtrl; // continuous glow ring

  // ── Entry animations ───────────────────────────────────────────────────
  late final Animation<double> _backdropAlpha;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  // ── Icon sequence animations ───────────────────────────────────────────
  late final Animation<double> _ringAnim;      // arc drawing
  late final Animation<double> _symbolAnim;    // icon opacity + scale-in
  late final Animation<double> _particleAnim;  // particle burst
  late final Animation<double> _iconBounce;    // icon container pop

  // ── Continuous ─────────────────────────────────────────────────────────
  late final Animation<double> _pulseAnim;

  late final List<_ParticleData> _particles;
  bool _dismissing = false;

  // ── Per-type helpers ────────────────────────────────────────────────────
  static Color _color(AppDialogType t) => switch (t) {
        AppDialogType.success => AppColors.emerald,
        AppDialogType.error   => AppColors.coral,
        AppDialogType.warning => AppColors.amber,
      };

  static Color _glow(AppDialogType t) => switch (t) {
        AppDialogType.success => const Color(0xFF00FF9F),
        AppDialogType.error   => const Color(0xFFFF9090),
        AppDialogType.warning => const Color(0xFFFFD166),
      };

  static IconData _icon(AppDialogType t) => switch (t) {
        AppDialogType.success => Icons.check_rounded,
        AppDialogType.error   => Icons.close_rounded,
        AppDialogType.warning => Icons.priority_high_rounded,
      };

  static String _badge(AppDialogType t) => switch (t) {
        AppDialogType.success => 'SUCCESS',
        AppDialogType.error   => 'ERROR',
        AppDialogType.warning => 'WARNING',
      };

  // ── Lifecycle ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Entry controller — 560 ms, one-shot
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _backdropAlpha = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
    _cardScale = Tween<double>(begin: 0.68, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack),
    );
    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _entryCtrl,
          curve: const Interval(0, 0.55, curve: Curves.easeOut)),
    );
    _cardSlide =
        Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic),
    );

    // Icon controller — 1 500 ms, one-shot
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _ringAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _iconCtrl,
          curve: const Interval(0.0, 0.45, curve: Curves.easeInOut)),
    );
    _symbolAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _iconCtrl,
          curve: const Interval(0.35, 0.70, curve: Curves.easeOut)),
    );
    _particleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _iconCtrl,
          curve: const Interval(0.55, 1.0, curve: Curves.easeOut)),
    );
    _iconBounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.20), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.20, end: 0.92), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.00), weight: 50),
    ]).animate(
      CurvedAnimation(
          parent: _iconCtrl, curve: const Interval(0, 0.55)),
    );

    // Pulse controller — 2 000 ms, looping
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Deterministic particles
    final rng = math.Random(7);
    _particles = List.generate(9, (i) {
      final baseAngle = (i / 9) * 2 * math.pi;
      return _ParticleData(
        angle: baseAngle + (rng.nextDouble() - 0.5) * 0.5,
        size: 3.2 + rng.nextDouble() * 2.4,
        speed: 0.65 + rng.nextDouble() * 0.7,
      );
    });

    // Kick off animations
    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 150),
        () { if (mounted) _iconCtrl.forward(); });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _iconCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    setState(() => _dismissing = true);
    HapticFeedback.lightImpact();
    _pulseCtrl.stop();
    await _entryCtrl.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _color(widget.type);
    final glow  = _glow(widget.type);

    return AnimatedBuilder(
      animation: Listenable.merge([_entryCtrl, _iconCtrl, _pulseCtrl]),
      builder: (context, _) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // ── Blurred backdrop ──────────────────────────────────────
              Positioned.fill(
                child: GestureDetector(
                  onTap: widget.barrierDismissible ? _dismiss : null,
                  child: Opacity(
                    opacity: _backdropAlpha.value,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 14 * _backdropAlpha.value,
                        sigmaY: 14 * _backdropAlpha.value,
                      ),
                      child: Container(
                        color: Colors.black
                            .withValues(alpha: 0.62 * _backdropAlpha.value),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Dialog card ───────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () {}, // stop backdrop tap propagation
                  child: SlideTransition(
                    position: _cardSlide,
                    child: ScaleTransition(
                      scale: _cardScale,
                      child: FadeTransition(
                        opacity: _cardFade,
                        child: _buildCard(context, isDark, color, glow),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Card (orientation-aware) ───────────────────────────────────────────
  Widget _buildCard(
      BuildContext context, bool isDark, Color color, Color glow) {
    final mq = MediaQuery.of(context);
    final isLandscape = mq.orientation == Orientation.landscape;
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : color.withValues(alpha: 0.18);
    final decoration = BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: border, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: glow.withValues(alpha: 0.22),
          blurRadius: 56,
          spreadRadius: -6,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.58 : 0.12),
          blurRadius: 40,
          offset: const Offset(0, 18),
        ),
      ],
    );

    if (isLandscape) {
      // ── Landscape: two-column layout (iOS iPad / Slack / Material wide) ──
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: math.max(22.0, mq.padding.left + 12),
          vertical: 14,
        ),
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: mq.size.height * 0.90,
        ),
        decoration: decoration,
        child: _buildLandscapeLayout(context, isDark, color, glow),
      );
    }

    // ── Portrait: single-column layout (unchanged) ──────────────────────
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: decoration,
      child: _buildPortraitLayout(context, isDark, color, glow),
    );
  }

  // ── Portrait layout (original single-column) ───────────────────────────
  Widget _buildPortraitLayout(
      BuildContext context, bool isDark, Color color, Color glow) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(isDark, color),
        _buildIconSection(color, glow, isDark, compact: false),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Column(
            children: [
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.58)
                          : const Color(0xFF4A5270),
                      height: 1.65,
                    ),
              ),
            ],
          ),
        ),
        if (widget.images?.isNotEmpty == true) ...[
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _ImageGrid(
              images: widget.images!.take(4).toList(),
              color: color,
              isDark: isDark,
            ),
          ),
        ],
        const SizedBox(height: 24),
        _buildActions(color, glow, isDark),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Landscape layout (two-column: icon-left, content-right) ───────────
  //   Inspired by: iOS iPad alerts · Slack modal · Airbnb wide dialogs
  Widget _buildLandscapeLayout(
      BuildContext context, bool isDark, Color color, Color glow) {
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.58)
        : const Color(0xFF4A5270);

    return SingleChildScrollView(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left accent panel: type badge + compact icon ──────────
            Container(
              width: 148,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.06 : 0.04),
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(27)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 18),
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          color.withValues(alpha: isDark ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: color.withValues(alpha: 0.30), width: 1),
                    ),
                    child: Text(
                      _badge(widget.type),
                      style: TextStyle(
                        fontSize: 9.0,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 1.6,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  // Compact animated icon
                  _buildIconSection(color, glow, isDark, compact: true),
                  const SizedBox(height: 18),
                ],
              ),
            ),

            // ── Right content panel ───────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 14, 14, 0),
                      child: GestureDetector(
                        onTap: _dismiss,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.07)
                                : Colors.grey.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Title + message (left-aligned in landscape)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.message,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: subColor, height: 1.65),
                        ),
                      ],
                    ),
                  ),

                  // Images (compact row in landscape)
                  if (widget.images?.isNotEmpty == true) ...[
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _ImageGrid(
                        images: widget.images!.take(4).toList(),
                        color: color,
                        isDark: isDark,
                      ),
                    ),
                  ],

                  // Action buttons
                  const SizedBox(height: 18),
                  _buildActions(color, glow, isDark),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header row (portrait) ──────────────────────────────────────────────
  Widget _buildHeader(bool isDark, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 0),
      child: Row(
        children: [
          _buildTypeBadge(color, isDark),
          const Spacer(),
          _buildCloseButton(isDark),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 1),
      ),
      child: Text(
        _badge(widget.type),
        style: TextStyle(
          fontSize: 9.0,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 1.6,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildCloseButton(bool isDark) {
    return GestureDetector(
      onTap: _dismiss,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.grey.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.close_rounded,
          size: 16,
          color: isDark ? Colors.white54 : Colors.grey.shade500,
        ),
      ),
    );
  }

  // ── Animated icon section ──────────────────────────────────────────────
  //   compact=true → smaller icon for landscape left-panel
  Widget _buildIconSection(Color color, Color glow, bool isDark,
      {bool compact = false}) {
    final iconDiameter = compact ? 64.0 : 86.0;
    final canvasSize = compact ? 90.0 : 130.0;
    final outerGlow = compact ? 10.0 : 18.0;
    final outerCanvas = compact ? 30.0 : 50.0;
    final iconSize = compact ? 26.0 : 36.0;
    final vPad = compact ? 10.0 : 18.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: vPad),
      child: SizedBox(
        width: canvasSize + outerCanvas,
        height: canvasSize + outerCanvas,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Pulsing outer glow ring ─────────────────────────────
            Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                width: canvasSize + outerGlow,
                height: canvasSize + outerGlow,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glow.withValues(alpha: 0.18),
                      glow.withValues(alpha: 0.0),
                    ],
                    radius: 0.75,
                  ),
                ),
              ),
            ),

            // ── Particle burst ─────────────────────────────────────
            SizedBox(
              width: canvasSize + outerCanvas,
              height: canvasSize + outerCanvas,
              child: CustomPaint(
                painter: _ParticlePainter(
                  progress: _particleAnim.value,
                  color: color,
                  particles: _particles,
                  baseRadius: (iconDiameter / 2) + 4,
                ),
              ),
            ),

            // ── Icon container with ring + symbol ──────────────────
            Transform.scale(
              scale: _iconBounce.value.clamp(0.0, 1.25),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background fill
                  Container(
                    width: iconDiameter,
                    height: iconDiameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withValues(alpha: isDark ? 0.32 : 0.16),
                          color.withValues(alpha: isDark ? 0.10 : 0.04),
                        ],
                      ),
                    ),
                  ),

                  // Arc drawing animation
                  SizedBox(
                    width: iconDiameter,
                    height: iconDiameter,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: _ringAnim.value,
                        color: color,
                      ),
                    ),
                  ),

                  // Icon symbol
                  Opacity(
                    opacity: _symbolAnim.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.55 + _symbolAnim.value * 0.45,
                      child: Icon(
                        _icon(widget.type),
                        color: color,
                        size: iconSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Action buttons ─────────────────────────────────────────────────────
  Widget _buildActions(Color color, Color glow, bool isDark) {
    final primary   = widget.primaryAction;
    final secondary = widget.secondaryAction;

    Widget primaryBtn(String label, VoidCallback onTap) => _GradientButton(
          label: label,
          color: color,
          glow: glow,
          onTap: onTap,
        );

    Widget secondaryBtn(String label, VoidCallback onTap) => _GhostButton(
          label: label,
          color: color,
          isDark: isDark,
          onTap: onTap,
        );

    if (primary == null && secondary == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: primaryBtn('Got it', _dismiss),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (secondary != null) ...[
            Expanded(
              child: secondaryBtn(secondary.label, () {
                secondary.onTap();
                _dismiss();
              }),
            ),
            if (primary != null) const SizedBox(width: 12),
          ],
          if (primary != null)
            Expanded(
              child: primaryBtn(primary.label, () {
                primary.onTap();
                _dismiss();
              }),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  BUTTONS
// ═══════════════════════════════════════════════════════════════════════════

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.color,
    required this.glow,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color glow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.72)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.42),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.11)
                : Colors.grey.withValues(alpha: 0.22),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF4A5270),
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  IMAGE GRID  (1-4 images, adaptive layout)
// ═══════════════════════════════════════════════════════════════════════════

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({
    required this.images,
    required this.color,
    required this.isDark,
  });

  final List<String> images;
  final Color color;
  final bool isDark;

  Widget _img(String url,
      {double? height, double? width, BorderRadius? radius}) {
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.circular(12),
      child: Image.network(
        url,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.18 : 0.10),
            borderRadius: radius ?? BorderRadius.circular(12),
          ),
          child: Icon(Icons.image_rounded,
              color: color.withValues(alpha: 0.50), size: 28),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (images.length) {
      1 => ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: _img(images[0],
                height: 180, radius: BorderRadius.circular(14)),
          ),
        ),
      2 => SizedBox(
          height: 140,
          child: Row(children: [
            Expanded(child: _img(images[0], height: 140)),
            const SizedBox(width: 6),
            Expanded(child: _img(images[1], height: 140)),
          ]),
        ),
      3 => SizedBox(
          height: 160,
          child: Row(children: [
            Expanded(flex: 3, child: _img(images[0], height: 160)),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: Column(children: [
                Expanded(child: _img(images[1])),
                const SizedBox(height: 6),
                Expanded(child: _img(images[2])),
              ]),
            ),
          ]),
        ),
      _ => SizedBox(
          height: 160,
          child: Column(children: [
            Expanded(
              child: Row(children: [
                Expanded(child: _img(images[0])),
                const SizedBox(width: 6),
                Expanded(child: _img(images[1])),
              ]),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Row(children: [
                Expanded(child: _img(images[2])),
                const SizedBox(width: 6),
                Expanded(child: _img(images[3])),
              ]),
            ),
          ]),
        ),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════

class _ParticleData {
  const _ParticleData(
      {required this.angle, required this.size, required this.speed});
  final double angle;
  final double size;
  final double speed;
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({
    required this.progress,
    required this.color,
    required this.particles,
    required this.baseRadius,
  });

  final double progress;
  final Color color;
  final List<_ParticleData> particles;
  final double baseRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);

    for (final p in particles) {
      final dist = baseRadius + 6 + progress * 36 * p.speed;
      final fade = math.pow(1.0 - progress, 0.6).toDouble();
      final r    = p.size * (1 - progress * 0.45);
      if (fade <= 0 || r <= 0) continue;

      final pos = center +
          Offset(math.cos(p.angle) * dist, math.sin(p.angle) * dist);
      canvas.drawCircle(
        pos,
        r,
        Paint()..color = color.withValues(alpha: (fade * 0.88).clamp(0, 1)),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 3;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}