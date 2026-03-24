import 'package:flutter/material.dart';

import '../model/worker_model.dart';

class WorkerCard extends StatelessWidget {
  const WorkerCard({
    super.key,
    required this.worker,
    this.onTap,
  });

  final WorkerModel worker;
  final VoidCallback? onTap;

  // Deterministic color from name
  static Color _avatarColor(String name) {
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
    final index = name.codeUnits.fold(0, (a, b) => a + b) % palette.length;
    return palette[index];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _avatarColor(worker.fullName);
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;

    final cardBg = isDark ? const Color(0xFF141830) : Colors.white;
    final subTextColor = isDark ? Colors.white54 : Colors.grey.shade600;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.shade100;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: isTablet ? 20.0 : 16.0,
            vertical: isTablet ? 8.0 : 6.0),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? color.withValues(alpha: 0.15)
                : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : color.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left: avatar + status ──────────────────────────
            Padding(
              padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
              child: _Avatar(worker: worker, color: color),
            ),

            // ── Divider ───────────────────────────────────────
            Container(
              width: 1,
              height: double.infinity,
              color: dividerColor,
              margin: const EdgeInsets.symmetric(vertical: 12),
            ),

            // ── Right: info ───────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + position badge row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            worker.fullName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F1629),
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (worker.position != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              worker.position!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // ID chip
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      color: color,
                      text: 'ID: ${worker.id}',
                      subTextColor: subTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                    if (worker.department != null)
                      _InfoRow(
                        icon: Icons.business_outlined,
                        color: const Color(0xFF00E5CC),
                        text: worker.department!,
                        subTextColor: subTextColor,
                      ),
                    if (worker.birthDate != null) ...[
                      const SizedBox(height: 4),
                      _InfoRow(
                        icon: Icons.cake_outlined,
                        color: const Color(0xFFFF6B6B),
                        text: worker.birthDate!,
                        subTextColor: subTextColor,
                      ),
                    ],
                    if (worker.phoneNumber != null)
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        color: const Color(0xFF4CAF50),
                        text: worker.phoneNumber!,
                        subTextColor: subTextColor,
                      ),
                    if (worker.checkInTime != null ||
                        worker.checkOutTime != null) ...[
                      const SizedBox(height: 4),
                      _TimeRow(
                        checkIn: worker.checkInTime,
                        checkOut: worker.checkOutTime,
                        color: color,
                        subTextColor: subTextColor,
                      ),
                    ],
                    if (worker.address != null) ...[
                      const SizedBox(height: 4),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        color: const Color(0xFF7C6FF7),
                        text: worker.address!,
                        subTextColor: subTextColor,
                        maxLines: 2,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar ─────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.worker, required this.color});

  final WorkerModel worker;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final avatarSize = isTablet ? 80.0 : 64.0;
    final containerWidth = isTablet ? 88.0 : 72.0;
    final initFontSize = isTablet ? 26.0 : 22.0;

    return SizedBox(
      width: containerWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: worker.imageUrl == null
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color,
                            color.withValues(alpha: 0.6),
                          ],
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: worker.imageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          worker.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _Initials(
                              initials: worker.initials,
                              color: color,
                              fontSize: initFontSize),
                        ),
                      )
                    : Center(
                        child: Text(
                          worker.initials,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: initFontSize,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
              ),
              // Online / Offline indicator
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: worker.isOnline
                        ? const Color(0xFF00D68F)
                        : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF141830)
                          : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: worker.isOnline
                  ? const Color(0xFF00D68F).withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              worker.isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: worker.isOnline
                    ? const Color(0xFF00D68F)
                    : Colors.grey.shade500,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({
    required this.initials,
    required this.color,
    this.fontSize = 22,
  });
  final String initials;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.6)],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ── Info Row ───────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.text,
    required this.subTextColor,
    this.fontWeight = FontWeight.w500,
    this.maxLines = 1,
  });

  final IconData icon;
  final Color color;
  final String text;
  final Color subTextColor;
  final FontWeight fontWeight;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: subTextColor,
                fontWeight: fontWeight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Time Row ───────────────────────────────────────────────────────────────

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.checkIn,
    required this.checkOut,
    required this.color,
    required this.subTextColor,
  });

  final String? checkIn;
  final String? checkOut;
  final Color color;
  final Color subTextColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (checkIn != null) ...[
          Icon(Icons.login_rounded, size: 13, color: const Color(0xFF00D68F)),
          const SizedBox(width: 4),
          Text(
            checkIn!,
            style: TextStyle(
              fontSize: 12,
              color: subTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (checkIn != null && checkOut != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 10,
              color: subTextColor,
            ),
          ),
        ],
        if (checkOut != null) ...[
          Icon(Icons.logout_rounded, size: 13, color: const Color(0xFFFF6B6B)),
          const SizedBox(width: 4),
          Text(
            checkOut!,
            style: TextStyle(
              fontSize: 12,
              color: subTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}