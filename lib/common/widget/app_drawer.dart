import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constant/theme_config.dart';
import '../provider/theme_provider.dart';
import '../util/responsive.dart';

// ─── Design tokens (drawer-local) ────────────────────────────────────────────

const _kBlue   = AppColors.electricBlue;
const _kTeal   = AppColors.teal;
const _kAmber  = Color(0xFFF59E0B);
const _kPurple = Color(0xFF7C6FF7);
const _kGreen  = Color(0xFF00D68F);
const _kRed    = Color(0xFFFF4D6A);
const _kCoral  = Color(0xFFFF6B6B);

// ─── Entry widget ─────────────────────────────────────────────────────────────

class AppDrawerWidget extends ConsumerStatefulWidget {
  const AppDrawerWidget({super.key});

  @override
  ConsumerState<AppDrawerWidget> createState() => _AppDrawerWidgetState();
}

class _AppDrawerWidgetState extends ConsumerState<AppDrawerWidget> {
  // All sections start collapsed — drawer is always closed when first opened
  // so showing a wall of expanded content would be overwhelming.
  final Set<String> _expanded = {};

  void _toggle(String id) => setState(() {
        if (_expanded.contains(id)) {
          _expanded.remove(id);
        } else {
          _expanded.add(id);
        }
      });

  bool _open(String id) => _expanded.contains(id);

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    // Wider in landscape so items are clearly visible without squishing
    final isLandscape = context.isLandscape;
    final isTablet    = context.isTablet;
    final drawerWidth = isTablet
        ? (isLandscape ? 380.0 : 330.0)
        : (isLandscape ? 310.0 : 288.0);

    final bg = isDark ? const Color(0xFF070B1C) : const Color(0xFFF5F7FF);

    final textColor    = isDark ? Colors.white          : const Color(0xFF0D1129);
    final subtextColor = isDark ? const Color(0xFF8B9EC0) : const Color(0xFF6B7FA0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: bg,
      // Square top-right, rounded bottom-right for a modern panel feel
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Profile header ─────────────────────────────────────────
          _ProfileHeader(isDark: isDark),

          // ── Scrollable menu ────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              children: [
                // ── MY WORKSPACE ──────────────────────────────────
                _SectionDivider(label: 'MY WORKSPACE', isDark: isDark),
                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'My Profile',
                  subtitle: 'Edit personal info',
                  accentColor: _kBlue,
                  isDark: isDark,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () => Navigator.of(context).pop(),
                ),
                _MenuItem(
                  icon: Icons.group_outlined,
                  label: 'Team Members',
                  subtitle: '12 active members',
                  badge: '12',
                  badgeColor: _kBlue,
                  accentColor: _kBlue,
                  isDark: isDark,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () => Navigator.of(context).pop(),
                ),
                _MenuItem(
                  icon: Icons.timeline_rounded,
                  label: 'My Activity',
                  subtitle: 'Recent actions log',
                  accentColor: _kTeal,
                  isDark: isDark,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () => Navigator.of(context).pop(),
                ),

                const SizedBox(height: 4),

                // ── FLEET MANAGEMENT ──────────────────────────────
                _SectionDivider(label: 'FLEET', isDark: isDark),
                _ExpandableSection(
                  id: 'fleet',
                  icon: Icons.directions_car_outlined,
                  label: 'Fleet Management',
                  color: _kAmber,
                  isDark: isDark,
                  isOpen: _open('fleet'),
                  onToggle: () => _toggle('fleet'),
                  children: [
                    _SubItem(
                      icon: Icons.commute_rounded,
                      label: 'Active Vehicles',
                      count: '24',
                      color: _kAmber,
                      isDark: isDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _SubItem(
                      icon: Icons.route_rounded,
                      label: 'Manage Routes',
                      color: _kAmber,
                      isDark: isDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _SubItem(
                      icon: Icons.build_outlined,
                      label: 'Maintenance',
                      count: '3',
                      color: _kCoral,
                      isDark: isDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _SubItem(
                      icon: Icons.local_gas_station_outlined,
                      label: 'Fuel Logs',
                      color: _kAmber,
                      isDark: isDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                // ── ANALYTICS ─────────────────────────────────────
                _ExpandableSection(
                  id: 'analytics',
                  icon: Icons.bar_chart_rounded,
                  label: 'Reports & Analytics',
                  color: _kPurple,
                  isDark: isDark,
                  isOpen: _open('analytics'),
                  onToggle: () => _toggle('analytics'),
                  children: [
                    _SubItem(
                      icon: Icons.dashboard_outlined,
                      label: 'Live Dashboard',
                      color: _kPurple,
                      isDark: isDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _SubItem(
                      icon: Icons.description_outlined,
                      label: 'Generate Report',
                      color: _kPurple,
                      isDark: isDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _SubItem(
                      icon: Icons.file_download_outlined,
                      label: 'Export Data',
                      color: _kPurple,
                      isDark: isDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // ── SETTINGS & INFO ────────────────────────────────
                _SectionDivider(label: 'SETTINGS & INFO', isDark: isDark),
                _ExpandableSection(
                  id: 'settings',
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  color: _kBlue,
                  isDark: isDark,
                  isOpen: _open('settings'),
                  onToggle: () => _toggle('settings'),
                  children: [
                    _ThemeSubItem(
                      isDark: isDark,
                      themeMode: themeMode,
                      onChanged: (val) =>
                          ref.read(themeModeProvider.notifier).state =
                              val ? ThemeMode.dark : ThemeMode.light,
                    ),
                    _SubItem(
                      icon: Icons.translate_rounded,
                      label: 'Language',
                      color: _kBlue,
                      isDark: isDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _SubItem(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      color: _kTeal,
                      isDark: isDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _SubItem(
                      icon: Icons.lock_outline_rounded,
                      label: 'Security & Privacy',
                      color: _kCoral,
                      isDark: isDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                _ExpandableSection(
                  id: 'about',
                  icon: Icons.info_outline_rounded,
                  label: 'About DUONET',
                  color: _kGreen,
                  isDark: isDark,
                  isOpen: _open('about'),
                  onToggle: () => _toggle('about'),
                  children: [
                    _SubItem(
                      icon: Icons.menu_book_outlined,
                      label: 'Documentation',
                      color: _kGreen,
                      isDark: isDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _SubItem(
                      icon: Icons.support_agent_outlined,
                      label: 'Contact Support',
                      color: _kGreen,
                      isDark: isDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _SubItem(
                      icon: Icons.new_releases_outlined,
                      label: 'v1.0.0 · Changelog',
                      color: Colors.grey,
                      isDark: isDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Sign-out footer ────────────────────────────────────────
          _SignOutFooter(
            isDark: isDark,
            onTap: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PROFILE HEADER
//
//  Full-width gradient header with:
//  • Avatar initials circle + online status dot
//  • Name, role, email
//  • Status pill (Available)
//  • Close button (top-right)
//  • Decorative arc pattern for depth
// ═══════════════════════════════════════════════════════════════════════════════

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // ── Background gradient + decorative arcs ──────────────────
        Positioned.fill(
          child: CustomPaint(
            painter: _HeaderArcPainter(isDark: isDark),
          ),
        ),

        // ── Content ────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, topPad + 18, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: avatar + close button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with status dot
                  Stack(
                    children: [
                      Container(
                        width: context.dp(58),
                        height: context.dp(58),
                        decoration: BoxDecoration(
                          gradient: isDark
                              ? const LinearGradient(
                                  colors: [_kBlue, _kTeal],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isDark
                              ? null
                              : Colors.white.withValues(alpha: 0.28),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.40),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _kBlue.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'U1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.sp(20),
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      // Online status dot
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: context.dp(14),
                          height: context.dp(14),
                          decoration: BoxDecoration(
                            color: _kGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF070B1C)
                                  : const Color(0xFF1565C0),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kGreen.withValues(alpha: 0.55),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: context.dp(34),
                      height: context.dp(34),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.80),
                        size: context.dp(18),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Name
              Text(
                'User1',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.sp(18),
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Fleet Manager · DUONET',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: context.sp(12.5),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'user1@duonet.io',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.48),
                  fontSize: context.sp(11),
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 14),

              // Available pill + plan badge
              Row(
                children: [
                  // Online status pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: context.dp(7),
                          height: context.dp(7),
                          decoration: const BoxDecoration(
                            color: _kGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Available',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.sp(11),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Plan badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kAmber, Color(0xFFFF8C00)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _kAmber.withValues(alpha: 0.45),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'PRO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.sp(10),
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Decorative arc painter for the profile header ────────────────────────────

class _HeaderArcPainter extends CustomPainter {
  _HeaderArcPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    // Base gradient
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF0A0F28), const Color(0xFF111A3E)]
            : [const Color(0xFF1565C0), const Color(0xFF2196F3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Decorative arcs
    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 4; i++) {
      final r = size.height * (0.55 + i * 0.38);
      canvas.drawCircle(
        Offset(size.width + size.height * 0.10, -size.height * 0.12),
        r,
        arcPaint,
      );
    }

    // Subtle glow spot top-right
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.07),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.82, size.height * 0.18),
        radius: size.height * 0.55,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.18),
      size.height * 0.55,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_HeaderArcPainter old) => old.isDark != isDark;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SECTION DIVIDER  — labelled separator between groups
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.22)
                  : Colors.grey.shade400,
              letterSpacing: 1.8,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade300,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  MENU ITEM  — single non-expandable row
//
//  Colored left accent bar (3 dp) only on hover/tap via InkWell highlight;
//  resting state keeps a subtle icon container with the accent tint.
// ═══════════════════════════════════════════════════════════════════════════════

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.isDark,
    required this.textColor,
    required this.subtextColor,
    required this.onTap,
    this.subtitle,
    this.badge,
    this.badgeColor,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final bool isDark;
  final Color textColor;
  final Color subtextColor;
  final VoidCallback onTap;
  final String? subtitle;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: accentColor.withValues(alpha: 0.10),
        highlightColor: accentColor.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              // Icon box with accent tint
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor
                      .withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.20),
                  ),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const SizedBox(width: 12),
              // Label + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 11,
                          height: 1.4,
                          fontFamily: 'Poppins',
                        ),
                      ),
                  ],
                ),
              ),
              // Badge
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? _kBlue)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: badgeColor ?? _kBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.20)
                    : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  EXPANDABLE SECTION
//
//  Header row: accent icon box + label + animated chevron
//  Children: AnimatedSize + ClipRect for smooth height animation
//  Left accent border (2 dp, accent color) on the children container
// ═══════════════════════════════════════════════════════════════════════════════

class _ExpandableSection extends StatelessWidget {
  const _ExpandableSection({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.isOpen,
    required this.onToggle,
    required this.children,
  });

  final String id;
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool isOpen;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            splashColor: color.withValues(alpha: 0.10),
            highlightColor: color.withValues(alpha: 0.06),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              decoration: BoxDecoration(
                color: isOpen
                    ? color.withValues(alpha: isDark ? 0.07 : 0.04)
                    : Colors.transparent,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color
                          .withValues(alpha: isDark ? 0.15 : 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: color.withValues(alpha: 0.25)),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF0D1129),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  // Animated chevron
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOutCubic,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isOpen
                            ? color.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: isOpen
                            ? color
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.30)
                                : Colors.grey.shade500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Animated children ────────────────────────────────────────
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: isOpen
                ? Container(
                    margin: const EdgeInsets.only(
                        left: 16, right: 10, bottom: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.025)
                          : color.withValues(alpha: 0.030),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      border: Border(
                        left: BorderSide(
                            color: color.withValues(alpha: 0.45),
                            width: 2.5),
                        bottom: BorderSide(
                            color: color.withValues(alpha: 0.12),
                            width: 1),
                      ),
                    ),
                    child: Column(children: children),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SUB-ITEM  — item inside an expandable section
// ═══════════════════════════════════════════════════════════════════════════════

class _SubItem extends StatelessWidget {
  const _SubItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final String? count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: color.withValues(alpha: 0.10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Icon(icon,
                  size: 16, color: color.withValues(alpha: 0.80)),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.78)
                        : const Color(0xFF3D4A6A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              if (count != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count!,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: 15,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  THEME TOGGLE SUB-ITEM
// ═══════════════════════════════════════════════════════════════════════════════

class _ThemeSubItem extends StatelessWidget {
  const _ThemeSubItem({
    required this.isDark,
    required this.themeMode,
    required this.onChanged,
  });

  final bool isDark;
  final ThemeMode themeMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isCurrentlyDark = themeMode == ThemeMode.dark;
    final iconColor =
        isCurrentlyDark ? const Color(0xFF1B8EF8) : const Color(0xFFF59E0B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            isCurrentlyDark
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              isCurrentlyDark ? 'Dark Mode' : 'Light Mode',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.78)
                    : const Color(0xFF3D4A6A),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Transform.scale(
            scale: 0.82,
            child: Switch(
              value: isCurrentlyDark,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFF1B8EF8),
              activeTrackColor:
                  const Color(0xFF1B8EF8).withValues(alpha: 0.35),
              inactiveThumbColor: const Color(0xFFF59E0B),
              inactiveTrackColor:
                  const Color(0xFFF59E0B).withValues(alpha: 0.30),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SIGN-OUT FOOTER
// ═══════════════════════════════════════════════════════════════════════════════

class _SignOutFooter extends StatelessWidget {
  const _SignOutFooter({required this.isDark, required this.onTap});
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: context.dp(48),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _kRed.withValues(alpha: isDark ? 0.18 : 0.10),
                _kRed.withValues(alpha: isDark ? 0.10 : 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _kRed.withValues(alpha: 0.32)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded,
                  color: _kRed, size: context.dp(18)),
              const SizedBox(width: 8),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: _kRed,
                  fontSize: context.sp(14),
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
