import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/worker_model.dart';

// ── Public widget ──────────────────────────────────────────────────────────

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

  static Color workerColor(String name) {
    const palette = [
      Color(0xFF1B8EF8),
      Color(0xFF7C6FF7),
      Color(0xFF00D68F),
      Color(0xFFF59E0B),
      Color(0xFFFF6B6B),
      Color(0xFF00E5CC),
      Color(0xFFFF4081),
      Color(0xFF4CAF50),
    ];
    final idx =
        name.codeUnits.fold(0, (a, b) => a + b) % palette.length;
    return palette[idx];
  }

  @override
  State<WorkerCard> createState() => _WorkerCardState();
}

class _WorkerCardState extends State<WorkerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.worker.isOnline) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final color = WorkerCard.workerColor(widget.worker.fullName);

    final cardBg = isDark ? const Color(0xFF0E1228) : Colors.white;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.shade100;
    final hPad = isTablet ? 20.0 : 16.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: isTablet ? 20.0 : 16.0, vertical: isTablet ? 9.0 : 7.0),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          // Colored left accent bar
          border: Border(
            left: BorderSide(color: color, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.14 : 0.16),
              blurRadius: 22,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: isDark ? 0.40 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TOP: avatar + name + status ─────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with optional pulse ring
                  _WorkerAvatar(
                    worker: widget.worker,
                    color: color,
                    pulseController: _pulse,
                    isDark: isDark,
                    size: isTablet ? 72.0 : 60.0,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + online badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.worker.fullName,
                                style: TextStyle(
                                  fontSize: isTablet ? 16.5 : 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F1629),
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _StatusBadge(
                                isOnline: widget.worker.isOnline),
                          ],
                        ),
                        if (widget.worker.position != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.worker.position!,
                            style: TextStyle(
                              fontSize: isTablet ? 13 : 12,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                        if (widget.worker.department != null) ...[
                          const SizedBox(height: 6),
                          _DeptChip(
                              label: widget.worker.department!,
                              color: color,
                              isDark: isDark),
                        ],
                        const SizedBox(height: 4),
                        // Worker ID
                        Text(
                          'ID: ${widget.worker.id}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark
                                ? Colors.white30
                                : Colors.grey.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── DIVIDER ──────────────────────────────────────────────
            Divider(
                height: 1,
                thickness: 1,
                indent: hPad,
                endIndent: hPad,
                color: dividerColor),

            // ── INFO ROWS ────────────────────────────────────────────
            Padding(
              padding:
                  EdgeInsets.fromLTRB(hPad, 10, hPad, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.worker.phoneNumber != null)
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      color: const Color(0xFF4CAF50),
                      text: widget.worker.phoneNumber!,
                      isDark: isDark,
                    ),
                  if (widget.worker.address != null)
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      color: const Color(0xFF7C6FF7),
                      text: widget.worker.address!,
                      isDark: isDark,
                      maxLines: 2,
                    ),
                  if (widget.worker.birthDate != null)
                    _InfoRow(
                      icon: Icons.cake_outlined,
                      color: const Color(0xFFFF6B6B),
                      text: widget.worker.birthDate!,
                      isDark: isDark,
                    ),
                  if (widget.worker.checkInTime != null ||
                      widget.worker.checkOutTime != null)
                    _WorkHoursRow(
                      checkIn: widget.worker.checkInTime,
                      checkOut: widget.worker.checkOutTime,
                      color: color,
                      isDark: isDark,
                    ),
                  const SizedBox(height: 4),
                ],
              ),
            ),

            // ── DIVIDER ──────────────────────────────────────────────
            Divider(
                height: 1,
                thickness: 1,
                indent: hPad,
                endIndent: hPad,
                color: dividerColor),

            // ── ACTIONS ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad - 4, 8, hPad - 4, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.call_rounded,
                      label: 'Call',
                      color: const Color(0xFF4CAF50),
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onCall?.call();
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Message',
                      color: const Color(0xFF1B8EF8),
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onMessage?.call();
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      color: color,
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onProfile?.call();
                      },
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
}

// ── Avatar with pulse ring ──────────────────────────────────────────────────

class _WorkerAvatar extends StatelessWidget {
  const _WorkerAvatar({
    required this.worker,
    required this.color,
    required this.pulseController,
    required this.isDark,
    required this.size,
  });

  final WorkerModel worker;
  final Color color;
  final AnimationController pulseController;
  final bool isDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse glow ring (online only)
          if (worker.isOnline)
            AnimatedBuilder(
              animation: pulseController,
              builder: (context, _) {
                return Container(
                  width: size + 8,
                  height: size + 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00D68F).withValues(
                          alpha: 0.4 * pulseController.value),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          // Avatar circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: worker.imageUrl == null
                  ? LinearGradient(
                      colors: [color, color.withValues(alpha: 0.60)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.30),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white,
                width: 2,
              ),
            ),
            child: worker.imageUrl != null
                ? ClipOval(
                    child: Image.network(
                      worker.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _InitialsAvatar(initials: worker.initials),
                    ),
                  )
                : Center(
                    child: Text(
                      worker.initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
          ),
          // Online/offline indicator dot
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: worker.isOnline
                    ? const Color(0xFF00D68F)
                    : Colors.grey.shade400,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF0E1228) : Colors.white,
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

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) => Center(
        child: Text(initials,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
      );
}

// ── Status badge ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isOnline});
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: (isOnline ? const Color(0xFF00D68F) : Colors.grey)
            .withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isOnline ? const Color(0xFF00D68F) : Colors.grey)
              .withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF00D68F) : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: isOnline ? const Color(0xFF00D68F) : Colors.grey,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Department chip ─────────────────────────────────────────────────────────

class _DeptChip extends StatelessWidget {
  const _DeptChip(
      {required this.label, required this.color, required this.isDark});
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Info row ────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.text,
    required this.isDark,
    this.maxLines = 1,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool isDark;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Work hours row ──────────────────────────────────────────────────────────

class _WorkHoursRow extends StatelessWidget {
  const _WorkHoursRow({
    required this.checkIn,
    required this.checkOut,
    required this.color,
    required this.isDark,
  });

  final String? checkIn;
  final String? checkOut;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.schedule_rounded, size: 12, color: color),
          ),
          const SizedBox(width: 8),
          if (checkIn != null) ...[
            Icon(Icons.login_rounded,
                size: 11, color: const Color(0xFF00D68F)),
            const SizedBox(width: 3),
            Text(checkIn!,
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    fontWeight: FontWeight.w600)),
          ],
          if (checkIn != null && checkOut != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward_rounded,
                  size: 9,
                  color: isDark ? Colors.white30 : Colors.grey.shade400),
            ),
          ],
          if (checkOut != null) ...[
            Icon(Icons.logout_rounded,
                size: 11, color: const Color(0xFFFF6B6B)),
            const SizedBox(width: 3),
            Text(checkOut!,
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

// ── Action button ───────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: color.withValues(alpha: isDark ? 0.28 : 0.18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}