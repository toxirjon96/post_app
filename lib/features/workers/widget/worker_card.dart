import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/util/responsive.dart';
import '../model/worker_model.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────────
const _kOnline  = Color(0xFF00D68F);
const _kCall    = Color(0xFF4CAF50);
const _kMsg     = Color(0xFF1B8EF8);
const _kAddr    = Color(0xFF7C6FF7);
const _kBday    = Color(0xFFFF6B6B);

// ─── Per-worker accent palette (deterministic from name) ───────────────────────
const _kPalette = <Color>[
  Color(0xFF1B8EF8), // electric blue
  Color(0xFF7C6FF7), // purple
  Color(0xFF00D68F), // emerald
  Color(0xFFF59E0B), // amber
  Color(0xFFFF6B6B), // coral
  Color(0xFF00E5CC), // teal
  Color(0xFFFF4081), // pink
  Color(0xFF4CAF50), // green
];

// ─── Public widget ──────────────────────────────────────────────────────────────

class WorkerCard extends StatefulWidget {
  const WorkerCard({
    super.key,
    required this.worker,
    this.onTap,
    this.onCall,
    this.onMessage,
    this.onProfile,
  });

  final WorkerModel worker;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final VoidCallback? onProfile;

  /// Deterministic per-worker accent colour from the DUONET palette.
  static Color workerColor(String name) {
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % _kPalette.length;
    return _kPalette[idx];
  }

  @override
  State<WorkerCard> createState() => _WorkerCardState();
}

class _WorkerCardState extends State<WorkerCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulse; // online glow ring — repeats
  late final AnimationController _press; // tap-down scale feedback

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.worker.isOnline) _pulse.repeat(reverse: true);

    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.0,
      upperBound: 0.028,
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final isTablet    = context.isTablet;
    final isLandscape = context.isLandscape;
    final accent      = WorkerCard.workerColor(widget.worker.fullName);
    final cardBg      = isDark ? const Color(0xFF0E1228) : Colors.white;

    return AnimatedBuilder(
      animation: _press,
      builder: (ctx, child) =>
          Transform.scale(scale: 1.0 - _press.value, child: child!),
      child: GestureDetector(
        onTapDown:  (_) => _press.forward(),
        onTapUp:    (_) { _press.reverse(); widget.onTap?.call(); },
        onTapCancel: () => _press.reverse(),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: context.dp(isTablet ? 20 : 16),
            vertical:   context.dp(isTablet ? 10 : 7),
          ),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              // Per-worker colour glow
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.22 : 0.16),
                blurRadius: 34,
                spreadRadius: -6,
                offset: const Offset(0, 12),
              ),
              // Ambient depth shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.07),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: (isLandscape || isTablet)
                ? _buildHorizontal(context, isDark, isTablet, accent, cardBg)
                : _buildVertical(context, isDark, accent),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  VERTICAL LAYOUT  ─  portrait phones
  //
  //  ┌────────────────────────────────────┐
  //  │  Gradient banner                   │
  //  │  [Avatar]  Name        [● Online]  │
  //  │            Position                │
  //  │            [Dept]  [ID]            │
  //  ├────────────────────────────────────┤
  //  │  ☎  Phone                          │
  //  │  📍 Address                        │
  //  │  ⏰ 09:00 → 18:00                  │
  //  │  🎂 12.05.1990                     │
  //  ├────────────────────────────────────┤
  //  │  [Call]   [Message]   [Profile]    │
  //  └────────────────────────────────────┘
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildVertical(BuildContext context, bool isDark, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroBanner(
          worker: widget.worker,
          accent: accent,
          isDark: isDark,
          pulseCtrl: _pulse,
          height: 104,
          avatarSize: 62,
        ),
        _InfoSection(
          worker: widget.worker,
          isDark: isDark,
          accent: accent,
          twoColumns: false,
          compact: false,
        ),
        _ActionBar(
          isDark: isDark,
          accent: accent,
          compact: false,
          onCall:    () { HapticFeedback.lightImpact(); widget.onCall?.call();    },
          onMessage: () { HapticFeedback.lightImpact(); widget.onMessage?.call(); },
          onProfile: () { HapticFeedback.lightImpact(); widget.onProfile?.call(); },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HORIZONTAL LAYOUT  ─  landscape phones  +  all tablets
  //
  //  Phones (landscape):   128 dp left panel
  //  Small tablets:        158 dp left panel   (shortestSide 600–900)
  //  Large tablets:        188 dp left panel   (shortestSide ≥ 900)
  //
  //  ┌──────────────┬──────────────────────────────────────┐
  //  │  Gradient    │  [Dept]  [ID]                        │
  //  │  hero panel  │  ─ info rows / 2-col grid ─          │
  //  │              │                                      │
  //  │  [Avatar]    ├──────────────────────────────────────┤
  //  │  Name        │  [Call]   [Message]   [Profile]      │
  //  │  [● Status]  │                                      │
  //  └──────────────┴──────────────────────────────────────┘
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHorizontal(BuildContext context, bool isDark, bool isTablet,
      Color accent, Color cardBg) {
    final panelW     = isTablet
        ? (context.isLargeTablet ? 188.0 : 158.0)
        : 128.0;
    final avatarSize = isTablet
        ? (context.isLargeTablet ? 82.0 : 70.0)
        : 58.0;
    final divColor   = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.shade100;
    final hPad = context.dp(isTablet ? 16 : 13);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left gradient hero panel ──────────────────────────────
          _HeroPanel(
            worker: widget.worker,
            accent: accent,
            isDark: isDark,
            pulseCtrl: _pulse,
            width: panelW,
            avatarSize: avatarSize,
          ),

          // ── Right content column ──────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      hPad, context.dp(14), hPad, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chips row
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        children: [
                          if (widget.worker.department != null)
                            _DeptChip(
                              label: widget.worker.department!,
                              accent: accent,
                              isDark: isDark,
                            ),
                          _IdChip(
                            id: widget.worker.id,
                            isDark: isDark,
                          ),
                        ],
                      ),
                      SizedBox(height: context.dp(10)),
                      // Info grid (2-col on tablets, 1-col on phones)
                      _InfoSection(
                        worker: widget.worker,
                        isDark: isDark,
                        accent: accent,
                        twoColumns: isTablet,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Divider(height: 1, thickness: 1, color: divColor),
                _ActionBar(
                  isDark: isDark,
                  accent: accent,
                  compact: true,
                  onCall:    () { HapticFeedback.lightImpact(); widget.onCall?.call();    },
                  onMessage: () { HapticFeedback.lightImpact(); widget.onMessage?.call(); },
                  onProfile: () { HapticFeedback.lightImpact(); widget.onProfile?.call(); },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  HERO BANNER  ─  portrait phone top header
//
//  Full-width gradient panel.  Mesh dot pattern overlaid for texture.
//  Avatar on the left, name + position + chips on the right.
//  White avatar (semi-opaque) contrasts against the colored gradient.
// ═══════════════════════════════════════════════════════════════════════════════

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.worker,
    required this.accent,
    required this.isDark,
    required this.pulseCtrl,
    required this.height,
    required this.avatarSize,
  });

  final WorkerModel worker;
  final Color accent;
  final bool isDark;
  final AnimationController pulseCtrl;
  final double height;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.60)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Mesh dot texture
          const Positioned.fill(child: CustomPaint(painter: _MeshPainter())),
          // Content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.dp(16),
              vertical:   context.dp(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _WorkerAvatar(
                  worker: worker,
                  accent: accent,
                  pulseCtrl: pulseCtrl,
                  size: avatarSize,
                  onBanner: true,
                  isDark: isDark,
                ),
                SizedBox(width: context.dp(13)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              worker.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: context.sp(15.5),
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _StatusBadge(
                              isOnline: worker.isOnline, onBanner: true),
                        ],
                      ),
                      if (worker.position != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          worker.position!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.sp(12),
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.82),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (worker.department != null)
                            _DeptChip(
                              label: worker.department!,
                              accent: accent,
                              isDark: isDark,
                              onBanner: true,
                            ),
                          _IdChip(
                            id: worker.id,
                            isDark: isDark,
                            onBanner: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  HERO PANEL  ─  landscape / tablet left sidebar
//
//  Full-height gradient column.  Avatar centred with name + status below.
//  Top-to-bottom gradient gives the panel more depth than the horizontal banner.
// ═══════════════════════════════════════════════════════════════════════════════

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.worker,
    required this.accent,
    required this.isDark,
    required this.pulseCtrl,
    required this.width,
    required this.avatarSize,
  });

  final WorkerModel worker;
  final Color accent;
  final bool isDark;
  final AnimationController pulseCtrl;
  final double width;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.52)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _MeshPainter())),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.dp(12),
              vertical:   context.dp(22),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WorkerAvatar(
                  worker: worker,
                  accent: accent,
                  pulseCtrl: pulseCtrl,
                  size: avatarSize,
                  onBanner: true,
                  isDark: isDark,
                ),
                SizedBox(height: context.dp(10)),
                Text(
                  worker.fullName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.sp(13),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.3,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (worker.position != null) ...[
                  SizedBox(height: context.dp(3)),
                  Text(
                    worker.position!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.sp(11),
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.78),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
                SizedBox(height: context.dp(10)),
                _StatusBadge(isOnline: worker.isOnline, onBanner: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  MESH PAINTER  ─  subtle dot grid overlay on gradient surfaces
//  18 dp grid, 1.4 dp radius, 7 % white opacity.
// ═══════════════════════════════════════════════════════════════════════════════

class _MeshPainter extends CustomPainter {
  const _MeshPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    const step = 18.0;
    const r    = 1.4;
    for (var y = step / 2; y < size.height + step; y += step) {
      for (var x = step / 2; x < size.width + step; x += step) {
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MeshPainter _) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WORKER AVATAR
//
//  onBanner = true  → white semi-opaque circle, accent-coloured initials.
//                     Stands out against the gradient background.
//  onBanner = false → gradient circle (accent → faded), white initials.
//                     Classic avatar look on white/dark card body.
//
//  Online workers get an animated green glow ring that pulses slowly.
// ═══════════════════════════════════════════════════════════════════════════════

class _WorkerAvatar extends StatelessWidget {
  const _WorkerAvatar({
    required this.worker,
    required this.accent,
    required this.pulseCtrl,
    required this.size,
    required this.onBanner,
    required this.isDark,
  });

  final WorkerModel worker;
  final Color accent;
  final AnimationController pulseCtrl;
  final double size;
  final bool onBanner;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ringSize = size + 10;
    final dotBorder = onBanner
        ? accent.withValues(alpha: 0.75)
        : (isDark ? const Color(0xFF0E1228) : Colors.white);

    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated pulse ring — online only
          if (worker.isOnline)
            AnimatedBuilder(
              animation: pulseCtrl,
              builder: (context, child) => Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _kOnline.withValues(
                        alpha: 0.50 * pulseCtrl.value),
                    width: 2.5,
                  ),
                ),
              ),
            ),

          // Avatar circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Banner variant: white frosted look; card variant: accent gradient
              color: onBanner
                  ? Colors.white.withValues(alpha: 0.22)
                  : null,
              gradient: onBanner
                  ? null
                  : (worker.imageUrl == null
                      ? LinearGradient(
                          colors: [accent, accent.withValues(alpha: 0.55)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null),
              boxShadow: [
                BoxShadow(
                  color: onBanner
                      ? Colors.black.withValues(alpha: 0.20)
                      : accent.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: onBanner
                    ? Colors.white.withValues(alpha: 0.50)
                    : Colors.white.withValues(
                        alpha: isDark ? 0.12 : 1.0),
                width: 2.5,
              ),
            ),
            child: worker.imageUrl != null
                ? ClipOval(
                    child: Image.network(
                      worker.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _InitialsText(
                          initials: worker.initials,
                          size: size,
                          color: onBanner ? accent : Colors.white),
                    ),
                  )
                : Center(
                    child: Text(
                      worker.initials,
                      style: TextStyle(
                        color: onBanner ? accent : Colors.white,
                        fontSize: size * 0.34,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
          ),

          // Online / offline status dot
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: worker.isOnline ? _kOnline : Colors.grey.shade500,
                shape: BoxShape.circle,
                border: Border.all(color: dotBorder, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsText extends StatelessWidget {
  const _InitialsText({
    required this.initials,
    required this.size,
    required this.color,
  });
  final String initials;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
        child: Text(initials,
            style: TextStyle(
                color: color,
                fontSize: size * 0.34,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins')),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  STATUS BADGE
//  onBanner variant: translucent white pill → readable on any accent colour.
//  Card body variant: tinted coloured pill (online=green, offline=grey).
// ═══════════════════════════════════════════════════════════════════════════════

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isOnline, this.onBanner = false});
  final bool isOnline;
  final bool onBanner;

  @override
  Widget build(BuildContext context) {
    final dotColor  = isOnline ? _kOnline : Colors.grey.shade400;
    final textColor = onBanner
        ? Colors.white
        : (isOnline ? _kOnline : Colors.grey.shade600);
    final bgColor   = onBanner
        ? Colors.white.withValues(alpha: 0.18)
        : dotColor.withValues(alpha: 0.13);
    final borderColor = onBanner
        ? Colors.white.withValues(alpha: 0.30)
        : dotColor.withValues(alpha: 0.35);

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.dp(7), vertical: context.dp(3.5)),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: context.dp(5.5),
            height: context.dp(5.5),
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          SizedBox(width: context.dp(4)),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: context.sp(9.5),
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.2,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dept chip ──────────────────────────────────────────────────────────────────

class _DeptChip extends StatelessWidget {
  const _DeptChip({
    required this.label,
    required this.accent,
    required this.isDark,
    this.onBanner = false,
  });
  final String label;
  final Color accent;
  final bool isDark;
  final bool onBanner;

  @override
  Widget build(BuildContext context) {
    final bg     = onBanner
        ? Colors.white.withValues(alpha: 0.18)
        : accent.withValues(alpha: isDark ? 0.16 : 0.10);
    final border = onBanner
        ? Colors.white.withValues(alpha: 0.30)
        : accent.withValues(alpha: 0.28);
    final text   = onBanner ? Colors.white : accent;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.dp(8), vertical: context.dp(3)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: context.sp(10),
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: 0.2,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

// ─── ID chip ────────────────────────────────────────────────────────────────────

class _IdChip extends StatelessWidget {
  const _IdChip({required this.id, required this.isDark, this.onBanner = false});
  final String id;
  final bool isDark;
  final bool onBanner;

  @override
  Widget build(BuildContext context) {
    final bg     = onBanner
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100);
    final border = onBanner
        ? Colors.white.withValues(alpha: 0.22)
        : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade300);
    final text   = onBanner
        ? Colors.white.withValues(alpha: 0.90)
        : (isDark ? Colors.white38 : Colors.grey.shade500);

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.dp(7), vertical: context.dp(3)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        '#$id',
        style: TextStyle(
          fontSize: context.sp(9.5),
          fontWeight: FontWeight.w600,
          color: text,
          letterSpacing: 0.3,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  INFO SECTION
//  single column (portrait phones) or 2-column grid (tablets, landscape).
// ═══════════════════════════════════════════════════════════════════════════════

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.worker,
    required this.isDark,
    required this.accent,
    required this.twoColumns,
    required this.compact,
  });

  final WorkerModel worker;
  final bool isDark;
  final Color accent;
  final bool twoColumns;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final divColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.shade100;
    final vPad = compact ? 10.0 : 12.0;
    final hPad = compact ? context.dp(13) : context.dp(16);

    final phone = worker.phoneNumber != null
        ? _InfoRow(icon: Icons.phone_outlined,        text: worker.phoneNumber!, color: _kCall,  isDark: isDark, compact: compact)
        : null;
    final addr = worker.address != null
        ? _InfoRow(icon: Icons.location_on_outlined,  text: worker.address!,    color: _kAddr,  isDark: isDark, compact: compact, maxLines: 2)
        : null;
    final schedule = (worker.checkInTime != null || worker.checkOutTime != null)
        ? _WorkHoursRow(checkIn: worker.checkInTime, checkOut: worker.checkOutTime, accent: accent, isDark: isDark, compact: compact)
        : null;
    final bday = worker.birthDate != null
        ? _InfoRow(icon: Icons.cake_outlined,         text: worker.birthDate!,  color: _kBday,  isDark: isDark, compact: compact)
        : null;

    // Check if there are any info items at all
    final hasAny = phone != null || addr != null || schedule != null || bday != null;
    if (!hasAny) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, thickness: 1, color: divColor),
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad - 2),
          child: twoColumns
              ? _TwoColumnGrid(
                  left:  [?phone, ?schedule],
                  right: [?addr,  ?bday],
                )
              : Column(
                  children: [?phone, ?addr, ?schedule, ?bday],
                ),
        ),
      ],
    );
  }
}

class _TwoColumnGrid extends StatelessWidget {
  const _TwoColumnGrid({required this.left, required this.right});
  final List<Widget> left;
  final List<Widget> right;

  @override
  Widget build(BuildContext context) {
    if (left.isEmpty && right.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (left.isNotEmpty)
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: left)),
        if (left.isNotEmpty && right.isNotEmpty)
          SizedBox(width: context.dp(12)),
        if (right.isNotEmpty)
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: right)),
      ],
    );
  }
}

// ─── Info row ───────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.color,
    required this.isDark,
    required this.compact,
    this.maxLines = 1,
  });

  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;
  final bool compact;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final iconSz = context.dp(compact ? 20 : 22);
    final gap    = context.dp(compact ? 7  : 8);
    final vPad   = compact ? 4.0 : 5.0;

    return Padding(
      padding: EdgeInsets.only(bottom: vPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconSz,
            height: iconSz,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: iconSz * 0.58, color: color),
          ),
          SizedBox(width: gap),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.sp(compact ? 12 : 12.5),
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.45,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Work hours row ──────────────────────────────────────────────────────────────

class _WorkHoursRow extends StatelessWidget {
  const _WorkHoursRow({
    required this.checkIn,
    required this.checkOut,
    required this.accent,
    required this.isDark,
    required this.compact,
  });

  final String? checkIn;
  final String? checkOut;
  final Color accent;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSz  = context.dp(compact ? 20 : 22);
    final gap     = context.dp(compact ? 7  : 8);
    final textSz  = context.sp(compact ? 12 : 12.5);
    final textCol = isDark ? Colors.white60 : Colors.grey.shade600;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 4.0 : 5.0),
      child: Row(
        children: [
          Container(
            width: iconSz,
            height: iconSz,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.schedule_rounded,
                size: iconSz * 0.58, color: accent),
          ),
          SizedBox(width: gap),
          if (checkIn != null) ...[
            Icon(Icons.login_rounded,
                size: context.sp(10.5), color: _kOnline),
            const SizedBox(width: 3),
            Text(checkIn!,
                style: TextStyle(
                    fontSize: textSz,
                    color: textCol,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins')),
          ],
          if (checkIn != null && checkOut != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Icon(Icons.arrow_forward_rounded,
                  size: 9,
                  color: isDark ? Colors.white24 : Colors.grey.shade400),
            ),
          if (checkOut != null) ...[
            Icon(Icons.logout_rounded,
                size: context.sp(10.5), color: _kBday),
            const SizedBox(width: 3),
            Text(checkOut!,
                style: TextStyle(
                    fontSize: textSz,
                    color: textCol,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins')),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ACTION BAR  ─  three equal-weight action buttons
//
//  Call    → green   (primary contact action)
//  Message → blue    (async contact)
//  Profile → accent  (worker-specific colour)
//
//  compact = true  reduces vertical padding for landscape layouts.
// ═══════════════════════════════════════════════════════════════════════════════

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isDark,
    required this.accent,
    required this.compact,
    required this.onCall,
    required this.onMessage,
    required this.onProfile,
  });

  final bool isDark;
  final Color accent;
  final bool compact;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final vPad = context.dp(compact ? 8 : 10);
    final hPad = context.dp(compact ? 10 : 12);

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
      child: Row(
        children: [
          Expanded(
            child: _ActionBtn(
              icon: Icons.call_rounded,
              label: 'Call',
              color: _kCall,
              isDark: isDark,
              compact: compact,
              onTap: onCall,
            ),
          ),
          SizedBox(width: context.dp(7)),
          Expanded(
            child: _ActionBtn(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Message',
              color: _kMsg,
              isDark: isDark,
              compact: compact,
              onTap: onMessage,
            ),
          ),
          SizedBox(width: context.dp(7)),
          Expanded(
            child: _ActionBtn(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              color: accent,
              isDark: isDark,
              compact: compact,
              onTap: onProfile,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action button ───────────────────────────────────────────────────────────────

class _ActionBtn extends StatefulWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.05,
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
      animation: _ctrl,
      builder: (ctx, child) =>
          Transform.scale(scale: 1.0 - _ctrl.value, child: child!),
      child: GestureDetector(
        onTapDown:  (_) => _ctrl.forward(),
        onTapUp:    (_) { _ctrl.reverse(); widget.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: context.dp(widget.compact ? 8 : 10),
          ),
          decoration: BoxDecoration(
            color: widget.color.withValues(
                alpha: widget.isDark ? 0.13 : 0.08),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: widget.color.withValues(
                  alpha: widget.isDark ? 0.28 : 0.20),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  size: context.dp(widget.compact ? 16 : 18),
                  color: widget.color),
              SizedBox(height: context.dp(3)),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: context.sp(widget.compact ? 9.5 : 10),
                  color: widget.color,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}