import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/util/responsive.dart';
import '../model/worker_model.dart';

// ─── Design tokens ──────────────────────────────────────────────────────────
const _kOnline = Color(0xFF00D68F);
const _kCall   = Color(0xFF4CAF50);
const _kMsg    = Color(0xFF1B8EF8);
const _kAddr   = Color(0xFF7C6FF7);
const _kBday   = Color(0xFFFF6B6B);

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

// ─── Public widget ───────────────────────────────────────────────────────────

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

class _WorkerCardState extends State<WorkerCard> with TickerProviderStateMixin {
  late final AnimationController _pulse; // online glow ring
  late final AnimationController _press; // tap-down scale

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.worker.isOnline) _pulse.repeat(reverse: true);

    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.025,
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
    final isLandscape = context.isLandscape;
    final isTablet    = context.isTablet;
    final accent      = WorkerCard.workerColor(widget.worker.fullName);
    final cardBg      = isDark ? const Color(0xFF0E1228) : Colors.white;
    final divColor    = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.grey.shade100;

    // compact = landscape phones only (tablets are spacious enough)
    final compact    = isLandscape && !isTablet;
    final panelW     = isTablet
        ? (context.isLargeTablet ? 108.0 : 96.0)
        : (compact ? 82.0 : 92.0);
    final avatarSize = isTablet
        ? (context.isLargeTablet ? 60.0 : 54.0)
        : (compact ? 46.0 : 54.0);

    return AnimatedBuilder(
      animation: _press,
      builder: (_, child) =>
          Transform.scale(scale: 1.0 - _press.value, child: child!),
      child: GestureDetector(
        onTapDown:   (_) => _press.forward(),
        onTapUp:     (_) { _press.reverse(); widget.onTap?.call(); },
        onTapCancel: () => _press.reverse(),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: context.dp(isTablet ? 20 : 16),
            vertical:   context.dp(compact ? 5 : 7),
          ),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.22 : 0.14),
                blurRadius: 30,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.36 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            // ── Stack lets the Positioned panel fill the full card height
            // ── that the Row determines — no IntrinsicHeight needed.
            child: Stack(
              children: [
                // Left gradient panel — stretches to whatever height the Row sets
                Positioned(
                  left:   0,
                  top:    0,
                  bottom: 0,
                  width:  panelW,
                  child:  _PanelBackground(accent: accent),
                ),
                // Card content
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: panelW,
                      child: _LeftPanel(
                        worker:     widget.worker,
                        accent:     accent,
                        pulseCtrl:  _pulse,
                        avatarSize: avatarSize,
                        compact:    compact,
                      ),
                    ),
                    Expanded(
                      child: _RightContent(
                        worker:    widget.worker,
                        accent:    accent,
                        isDark:    isDark,
                        compact:   compact,
                        divColor:  divColor,
                        onCall:    () { HapticFeedback.lightImpact(); widget.onCall?.call();    },
                        onMessage: () { HapticFeedback.lightImpact(); widget.onMessage?.call(); },
                        onProfile: () { HapticFeedback.lightImpact(); widget.onProfile?.call(); },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  PANEL BACKGROUND  —  accent gradient + subtle mesh dot overlay
// ════════════════════════════════════════════════════════════════════════════

class _PanelBackground extends StatelessWidget {
  const _PanelBackground({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, accent.withValues(alpha: 0.55)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const CustomPaint(painter: _MeshPainter()),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  MESH PAINTER  —  subtle dot grid over the gradient panel
// ════════════════════════════════════════════════════════════════════════════

class _MeshPainter extends CustomPainter {
  const _MeshPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    const step = 16.0;
    const r    = 1.3;
    for (var y = step / 2; y < size.height + step; y += step) {
      for (var x = step / 2; x < size.width + step; x += step) {
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MeshPainter _) => false;
}

// ════════════════════════════════════════════════════════════════════════════
//  LEFT PANEL  —  avatar + status pill (on the gradient side)
// ════════════════════════════════════════════════════════════════════════════

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({
    required this.worker,
    required this.accent,
    required this.pulseCtrl,
    required this.avatarSize,
    required this.compact,
  });

  final WorkerModel worker;
  final Color accent;
  final AnimationController pulseCtrl;
  final double avatarSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(8),
        vertical:   context.dp(compact ? 14 : 18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Avatar(
            worker:    worker,
            accent:    accent,
            pulseCtrl: pulseCtrl,
            size:      avatarSize,
          ),
          SizedBox(height: context.dp(compact ? 7 : 9)),
          _StatusPill(isOnline: worker.isOnline, compact: compact),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  AVATAR  —  frosted circle on gradient, initials / image, pulse ring, dot
// ════════════════════════════════════════════════════════════════════════════

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.worker,
    required this.accent,
    required this.pulseCtrl,
    required this.size,
  });

  final WorkerModel worker;
  final Color accent;
  final AnimationController pulseCtrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    const ringPad  = 10.0; // extra space around avatar for pulse ring
    final outerSz  = size + ringPad;
    final dotSz    = (size * 0.21).clamp(9.0, 13.0);
    // The dot sits at the bottom-right of the avatar circle.
    // ringPad / 2 = offset from the outer box edge to the avatar edge.
    final dotOffset = ringPad / 2 - dotSz / 2;

    return SizedBox(
      width:  outerSz,
      height: outerSz,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated pulse ring (online workers only)
          if (worker.isOnline)
            AnimatedBuilder(
              animation: pulseCtrl,
              builder: (_, __) => Container(
                width:  outerSz,
                height: outerSz,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _kOnline.withValues(alpha: 0.50 * pulseCtrl.value),
                    width: 2.0,
                  ),
                ),
              ),
            ),

          // Avatar circle
          Container(
            width:  size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 2.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: worker.imageUrl != null
                  ? Image.network(
                      worker.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _Initials(initials: worker.initials, size: size, color: accent),
                    )
                  : _Initials(initials: worker.initials, size: size, color: accent),
            ),
          ),

          // Online / offline status dot
          Positioned(
            right:  dotOffset.clamp(0.0, outerSz),
            bottom: dotOffset.clamp(0.0, outerSz),
            child: Container(
              width:  dotSz,
              height: dotSz,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: worker.isOnline ? _kOnline : Colors.grey.shade400,
                border: Border.all(
                  color: accent.withValues(alpha: 0.55),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.size, required this.color});
  final String initials;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          initials,
          style: TextStyle(
            color:      color,
            fontSize:   size * 0.34,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
          ),
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════════
//  STATUS PILL  —  translucent white pill on the gradient background
// ════════════════════════════════════════════════════════════════════════════

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOnline, required this.compact});
  final bool isOnline;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dotColor = isOnline ? _kOnline : Colors.grey.shade300;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(compact ? 6 : 7),
        vertical:   context.dp(compact ? 3 : 3.5),
      ),
      decoration: BoxDecoration(
        color:        Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(
          color: Colors.white.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  context.dp(compact ? 5 : 5.5),
            height: context.dp(compact ? 5 : 5.5),
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          SizedBox(width: context.dp(4)),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize:    context.sp(compact ? 9 : 9.5),
              fontWeight:  FontWeight.w700,
              color:       Colors.white,
              letterSpacing: 0.2,
              fontFamily:  'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  RIGHT CONTENT  —  header + info rows + action bar
//
//  Uses mainAxisSize.min throughout — no Spacer, no fixed heights —
//  so the card always sizes to its content with zero overflow risk.
// ════════════════════════════════════════════════════════════════════════════

class _RightContent extends StatelessWidget {
  const _RightContent({
    required this.worker,
    required this.accent,
    required this.isDark,
    required this.compact,
    required this.divColor,
    required this.onCall,
    required this.onMessage,
    required this.onProfile,
  });

  final WorkerModel worker;
  final Color accent;
  final bool isDark;
  final bool compact;
  final Color divColor;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final hPad   = context.dp(compact ? 12 : 14);
    final topPad = context.dp(compact ? 12 : 16);

    final hasInfo = worker.phoneNumber != null ||
        worker.address      != null ||
        worker.checkInTime  != null ||
        worker.checkOutTime != null ||
        worker.birthDate    != null;

    return Column(
      mainAxisSize:       MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, 0),
          child: Column(
            mainAxisSize:       MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                worker.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize:   context.sp(compact ? 13.5 : 15),
                  fontWeight: FontWeight.w800,
                  color:      isDark ? Colors.white : const Color(0xFF0D1B3E),
                  height:     1.2,
                  fontFamily: 'Poppins',
                ),
              ),
              if (worker.position != null) ...[
                SizedBox(height: context.dp(2)),
                Text(
                  worker.position!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize:   context.sp(compact ? 10.5 : 11.5),
                    color:      isDark
                        ? Colors.white54
                        : const Color(0xFF667080),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
              SizedBox(height: context.dp(compact ? 6 : 8)),
              Wrap(
                spacing:    5,
                runSpacing: 4,
                children: [
                  if (worker.department != null)
                    _DeptChip(
                      label:  worker.department!,
                      accent: accent,
                      isDark: isDark,
                    ),
                  _IdChip(id: worker.id, isDark: isDark),
                ],
              ),
            ],
          ),
        ),

        // ── Info rows ────────────────────────────────────────────────────
        if (hasInfo) ...[
          SizedBox(height: context.dp(compact ? 8 : 10)),
          Divider(height: 1, thickness: 1, color: divColor),
          Padding(
            padding: EdgeInsets.fromLTRB(
                hPad, context.dp(compact ? 8 : 10), hPad, 0),
            child: Column(
              mainAxisSize:       MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (worker.phoneNumber != null)
                  _InfoRow(
                    icon:    Icons.phone_outlined,
                    text:    worker.phoneNumber!,
                    color:   _kCall,
                    isDark:  isDark,
                    compact: compact,
                  ),
                if (worker.address != null)
                  _InfoRow(
                    icon:     Icons.location_on_outlined,
                    text:     worker.address!,
                    color:    _kAddr,
                    isDark:   isDark,
                    compact:  compact,
                    maxLines: 2,
                  ),
                if (worker.checkInTime != null || worker.checkOutTime != null)
                  _WorkHoursRow(
                    checkIn:  worker.checkInTime,
                    checkOut: worker.checkOutTime,
                    accent:   accent,
                    isDark:   isDark,
                    compact:  compact,
                  ),
                if (worker.birthDate != null)
                  _InfoRow(
                    icon:    Icons.cake_outlined,
                    text:    worker.birthDate!,
                    color:   _kBday,
                    isDark:  isDark,
                    compact: compact,
                  ),
              ],
            ),
          ),
        ],

        // ── Action bar ───────────────────────────────────────────────────
        SizedBox(height: context.dp(compact ? 8 : 10)),
        Divider(height: 1, thickness: 1, color: divColor),
        _ActionBar(
          worker:    worker,
          isDark:    isDark,
          accent:    accent,
          compact:   compact,
          divColor:  divColor,
          onCall:    onCall,
          onMessage: onMessage,
          onProfile: onProfile,
        ),
      ],
    );
  }
}

// ─── Dept chip ───────────────────────────────────────────────────────────────

class _DeptChip extends StatelessWidget {
  const _DeptChip({
    required this.label,
    required this.accent,
    required this.isDark,
  });
  final String label;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.dp(8), vertical: context.dp(3)),
      decoration: BoxDecoration(
        color:        accent.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(
          color: accent.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize:    context.sp(10),
          fontWeight:  FontWeight.w700,
          color:       accent,
          letterSpacing: 0.2,
          fontFamily:  'Poppins',
        ),
      ),
    );
  }
}

// ─── ID chip ─────────────────────────────────────────────────────────────────

class _IdChip extends StatelessWidget {
  const _IdChip({required this.id, required this.isDark});
  final String id;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.dp(7), vertical: context.dp(3)),
      decoration: BoxDecoration(
        color:        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Text(
        '#$id',
        style: TextStyle(
          fontSize:    context.sp(9.5),
          fontWeight:  FontWeight.w600,
          color:       isDark ? Colors.white38 : Colors.grey.shade500,
          letterSpacing: 0.3,
          fontFamily:  'Poppins',
        ),
      ),
    );
  }
}

// ─── Info row ─────────────────────────────────────────────────────────────────

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
  final String   text;
  final Color    color;
  final bool     isDark;
  final bool     compact;
  final int      maxLines;

  @override
  Widget build(BuildContext context) {
    final iconSz = context.dp(compact ? 18 : 20);
    final gap    = context.dp(compact ? 7 : 8);
    final vPad   = compact ? 3.5 : 4.5;

    return Padding(
      padding: EdgeInsets.only(bottom: vPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width:  iconSz,
            height: iconSz,
            decoration: BoxDecoration(
              color:        color.withValues(alpha: 0.10),
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
                fontSize:  context.sp(compact ? 11.5 : 12),
                color:     isDark ? Colors.white60 : Colors.grey.shade600,
                height:    1.45,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Work hours row ───────────────────────────────────────────────────────────

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
  final Color   accent;
  final bool    isDark;
  final bool    compact;

  @override
  Widget build(BuildContext context) {
    final iconSz  = context.dp(compact ? 18 : 20);
    final gap     = context.dp(compact ? 7 : 8);
    final textSz  = context.sp(compact ? 11.5 : 12);
    final textCol = isDark ? Colors.white60 : Colors.grey.shade600;
    final vPad    = compact ? 3.5 : 4.5;

    return Padding(
      padding: EdgeInsets.only(bottom: vPad),
      child: Row(
        children: [
          Container(
            width:  iconSz,
            height: iconSz,
            decoration: BoxDecoration(
              color:        accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.schedule_rounded, size: iconSz * 0.58, color: accent),
          ),
          SizedBox(width: gap),
          if (checkIn != null) ...[
            Icon(Icons.login_rounded, size: context.sp(10), color: _kOnline),
            const SizedBox(width: 3),
            Text(checkIn!,
                style: TextStyle(
                    fontSize:   textSz,
                    color:      textCol,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins')),
          ],
          if (checkIn != null && checkOut != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Icon(Icons.arrow_forward_rounded,
                  size:  9,
                  color: isDark ? Colors.white24 : Colors.grey.shade400),
            ),
          if (checkOut != null) ...[
            Icon(Icons.logout_rounded, size: context.sp(10), color: _kBday),
            const SizedBox(width: 3),
            Text(checkOut!,
                style: TextStyle(
                    fontSize:   textSz,
                    color:      textCol,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins')),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  ACTION BAR  —  Call · Message · Profile  +  Info popup (bottom-right)
// ════════════════════════════════════════════════════════════════════════════

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.worker,
    required this.isDark,
    required this.accent,
    required this.compact,
    required this.divColor,
    required this.onCall,
    required this.onMessage,
    required this.onProfile,
  });

  final WorkerModel worker;
  final bool isDark;
  final Color accent;
  final bool compact;
  final Color divColor;
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
          Expanded(child: _ActionBtn(
            icon: Icons.call_rounded,
            label: 'Call',
            color: _kCall,
            isDark: isDark,
            compact: compact,
            onTap: onCall,
          )),
          SizedBox(width: context.dp(7)),
          Expanded(child: _ActionBtn(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Message',
            color: _kMsg,
            isDark: isDark,
            compact: compact,
            onTap: onMessage,
          )),
          SizedBox(width: context.dp(7)),
          Expanded(child: _ActionBtn(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            color: accent,
            isDark: isDark,
            compact: compact,
            onTap: onProfile,
          )),
          // ── Separator + Info popup ───────────────────────────────────
          SizedBox(width: context.dp(compact ? 8 : 10)),
          Container(
            width: 1,
            height: context.dp(compact ? 26 : 30),
            color: divColor,
          ),
          SizedBox(width: context.dp(compact ? 5 : 7)),
          _InfoMenuButton(
            worker:  worker,
            isDark:  isDark,
            accent:  accent,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────

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
  final String   label;
  final Color    color;
  final bool     isDark;
  final bool     compact;
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
      builder: (_, child) =>
          Transform.scale(scale: 1.0 - _ctrl.value, child: child!),
      child: GestureDetector(
        onTapDown:   (_) => _ctrl.forward(),
        onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: context.dp(widget.compact ? 7 : 9),
          ),
          decoration: BoxDecoration(
            color:        widget.color.withValues(
                alpha: widget.isDark ? 0.13 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(
              color: widget.color.withValues(
                  alpha: widget.isDark ? 0.28 : 0.20),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  size:  context.dp(widget.compact ? 15 : 17),
                  color: widget.color),
              SizedBox(height: context.dp(3)),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize:    context.sp(widget.compact ? 9.5 : 10),
                  fontWeight:  FontWeight.w700,
                  color:       widget.color,
                  letterSpacing: 0.1,
                  fontFamily:  'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  INFO MENU BUTTON  —  ⋮ button + popup with all worker details
//
//  Placed at the bottom-right of the action bar, separated by a divider.
//  The popup opens upward (PopupMenuPosition.over) so it doesn't go off-screen.
//  Each item shows a colour-coded icon badge on the left and a label/value
//  column on the right, matching the card's design language.
// ════════════════════════════════════════════════════════════════════════════

class _InfoMenuButton extends StatelessWidget {
  const _InfoMenuButton({
    required this.worker,
    required this.isDark,
    required this.accent,
    required this.compact,
  });

  final WorkerModel worker;
  final bool isDark;
  final Color accent;
  final bool compact;

  // ── Colours for each info category ──────────────────────────────────────
  static const _cId       = Color(0xFF1B8EF8); // blue   — identity
  static const _cContact  = Color(0xFF4CAF50); // green  — contact
  static const _cLocation = Color(0xFF7C6FF7); // purple — address
  static const _cWork     = Color(0xFF00E5CC); // teal   — schedule / dept
  static const _cPersonal = Color(0xFFFF6B6B); // coral  — birthday
  static const _cStatus   = Color(0xFF00D68F); // emerald — online

  @override
  Widget build(BuildContext context) {
    final btnSize = context.dp(compact ? 28 : 32);
    final iconSz  = context.dp(compact ? 14 : 16);
    final menuBg  = isDark ? const Color(0xFF121A2E) : Colors.white;
    final shadowC = isDark
        ? Colors.black.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.18);

    return PopupMenuButton<String>(
      position:        PopupMenuPosition.over,
      offset:          const Offset(0, -8),
      color:           menuBg,
      elevation:       0,
      shadowColor:     Colors.transparent,
      shape:           RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      constraints: const BoxConstraints(minWidth: 248, maxWidth: 288),
      // Custom drop shadow via decoration on a wrapper
      child: Container(
        width:  btnSize,
        height: btnSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.grey.shade100,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Icon(
          Icons.more_vert_rounded,
          size:  iconSz,
          color: isDark ? Colors.white54 : Colors.grey.shade500,
        ),
      ),
      itemBuilder: (_) => [
        // ── Identity header ─────────────────────────────────────────────
        _menuHeader(context, menuBg, shadowC),

        // ── Identity ─────────────────────────────────────────────────────
        _menuItem(
          context: context,
          value:   'id',
          icon:    Icons.badge_outlined,
          color:   _cId,
          label:   'Employee ID',
          value_:  '#${worker.id}',
          isDark:  isDark,
        ),
        if (worker.position != null)
          _menuItem(
            context: context,
            value:   'position',
            icon:    Icons.work_outline_rounded,
            color:   accent,
            label:   'Position',
            value_:  worker.position!,
            isDark:  isDark,
          ),
        if (worker.department != null)
          _menuItem(
            context: context,
            value:   'dept',
            icon:    Icons.business_outlined,
            color:   _cWork,
            label:   'Department',
            value_:  worker.department!,
            isDark:  isDark,
          ),

        // ── Contact divider + items ───────────────────────────────────────
        if (worker.phoneNumber != null || worker.address != null)
          _menuDivider(isDark),

        if (worker.phoneNumber != null)
          _menuItem(
            context: context,
            value:   'phone',
            icon:    Icons.phone_outlined,
            color:   _cContact,
            label:   'Phone',
            value_:  worker.phoneNumber!,
            isDark:  isDark,
          ),
        if (worker.address != null)
          _menuItem(
            context: context,
            value:   'address',
            icon:    Icons.location_on_outlined,
            color:   _cLocation,
            label:   'Address',
            value_:  worker.address!,
            isDark:  isDark,
            multiLine: true,
          ),

        // ── Schedule / personal divider + items ───────────────────────────
        if (worker.checkInTime != null ||
            worker.checkOutTime != null ||
            worker.birthDate != null)
          _menuDivider(isDark),

        if (worker.checkInTime != null || worker.checkOutTime != null)
          _menuHoursItem(context, isDark),

        if (worker.birthDate != null)
          _menuItem(
            context: context,
            value:   'bday',
            icon:    Icons.cake_outlined,
            color:   _cPersonal,
            label:   'Birthday',
            value_:  worker.birthDate!,
            isDark:  isDark,
          ),

        // ── Status divider + item ─────────────────────────────────────────
        _menuDivider(isDark),
        _menuStatusItem(context, isDark),
      ],
      onSelected: (_) {},
    );
  }

  // ── Worker identity banner at the top of the menu ──────────────────────
  PopupMenuItem<String> _menuHeader(
      BuildContext context, Color menuBg, Color shadowC) {
    return PopupMenuItem<String>(
      value:   '_header',
      enabled: false,
      padding: EdgeInsets.zero,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.dp(16),
          vertical:   context.dp(14),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: isDark ? 0.30 : 0.14),
              accent.withValues(alpha: 0.04),
            ],
            begin: Alignment.centerLeft,
            end:   Alignment.centerRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Row(
          children: [
            // Mini avatar
            Container(
              width:  40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.60)],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color:      accent.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset:     const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  worker.initials,
                  style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize:       MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.fullName,
                    maxLines:  1,
                    overflow:  TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize:   context.sp(13),
                      fontWeight: FontWeight.w800,
                      color:      isDark ? Colors.white : const Color(0xFF0D1B3E),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (worker.position != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      worker.position!,
                      maxLines:  1,
                      overflow:  TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize:   context.sp(10.5),
                        color:      isDark ? Colors.white54 : const Color(0xFF667080),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Standard info item ───────────────────────────────────────────────────
  PopupMenuItem<String> _menuItem({
    required BuildContext context,
    required String value,
    required IconData icon,
    required Color color,
    required String label,
    required String value_,
    required bool isDark,
    bool multiLine = false,
  }) {
    final labelColor = isDark ? Colors.white38 : Colors.grey.shade500;
    final valueColor = isDark ? Colors.white87 : const Color(0xFF0D1B3E);

    return PopupMenuItem<String>(
      value:   value,
      enabled: false,
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(16),
        vertical:   context.dp(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width:  34,
            height: 34,
            decoration: BoxDecoration(
              color:        color.withValues(alpha: isDark ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize:       MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize:    context.sp(9.5),
                    fontWeight:  FontWeight.w600,
                    color:       labelColor,
                    letterSpacing: 0.4,
                    fontFamily:  'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value_,
                  maxLines:  multiLine ? 2 : 1,
                  overflow:  TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize:   context.sp(12),
                    fontWeight: FontWeight.w600,
                    color:      valueColor,
                    fontFamily: 'Poppins',
                    height:     1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Work hours item (two times with arrow) ────────────────────────────────
  PopupMenuItem<String> _menuHoursItem(BuildContext context, bool isDark) {
    final labelColor = isDark ? Colors.white38 : Colors.grey.shade500;
    final valueColor = isDark ? Colors.white87 : const Color(0xFF0D1B3E);
    final sepColor   = isDark ? Colors.white24 : Colors.grey.shade400;

    return PopupMenuItem<String>(
      value:   'hours',
      enabled: false,
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(16),
        vertical:   context.dp(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width:  34,
            height: 34,
            decoration: BoxDecoration(
              color:        accent.withValues(alpha: isDark ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.schedule_rounded, size: 17, color: accent),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize:       MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WORK HOURS',
                style: TextStyle(
                  fontSize:    context.sp(9.5),
                  fontWeight:  FontWeight.w600,
                  color:       labelColor,
                  letterSpacing: 0.4,
                  fontFamily:  'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (worker.checkInTime != null) ...[
                    Icon(Icons.login_rounded, size: 11, color: _cStatus),
                    const SizedBox(width: 3),
                    Text(
                      worker.checkInTime!,
                      style: TextStyle(
                        fontSize:   context.sp(12),
                        fontWeight: FontWeight.w700,
                        color:      valueColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                  if (worker.checkInTime != null && worker.checkOutTime != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward_rounded, size: 10, color: sepColor),
                    ),
                  if (worker.checkOutTime != null) ...[
                    Icon(Icons.logout_rounded, size: 11, color: _cPersonal),
                    const SizedBox(width: 3),
                    Text(
                      worker.checkOutTime!,
                      style: TextStyle(
                        fontSize:   context.sp(12),
                        fontWeight: FontWeight.w700,
                        color:      valueColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Online status item ───────────────────────────────────────────────────
  PopupMenuItem<String> _menuStatusItem(BuildContext context, bool isDark) {
    final isOnline   = worker.isOnline;
    final dotColor   = isOnline ? _cStatus : Colors.grey.shade400;
    final statusText = isOnline ? 'Online' : 'Offline';
    final labelColor = isDark ? Colors.white38 : Colors.grey.shade500;

    return PopupMenuItem<String>(
      value:   'status',
      enabled: false,
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(16),
        vertical:   context.dp(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width:  34,
            height: 34,
            decoration: BoxDecoration(
              color:        dotColor.withValues(alpha: isDark ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isOnline
                  ? Icons.wifi_rounded
                  : Icons.wifi_off_rounded,
              size:  17,
              color: dotColor,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize:       MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AVAILABILITY',
                style: TextStyle(
                  fontSize:    context.sp(9.5),
                  fontWeight:  FontWeight.w600,
                  color:       labelColor,
                  letterSpacing: 0.4,
                  fontFamily:  'Poppins',
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width:  7,
                    height: 7,
                    decoration: BoxDecoration(
                      color:  dotColor,
                      shape:  BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize:   context.sp(12),
                      fontWeight: FontWeight.w700,
                      color:      dotColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Thin divider between sections ────────────────────────────────────────
  PopupMenuDivider _menuDivider(bool isDark) => PopupMenuDivider(
        height: 1,
      );
}