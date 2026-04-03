import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constant/theme_config.dart';
import '../provider/theme_provider.dart';
import '../util/responsive.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────

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
  final Set<String> _expanded = {};

  void _toggle(String id) => setState(() {
        _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id);
      });

  bool _open(String id) => _expanded.contains(id);

  @override
  Widget build(BuildContext context) {
    final themeMode   = ref.watch(themeModeProvider);
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final isLandscape = context.isLandscape;
    final isTablet    = context.isTablet;

    final drawerWidth = isTablet
        ? (isLandscape ? 380.0 : 330.0)
        : (isLandscape ? 310.0 : 288.0);

    final bg           = isDark ? const Color(0xFF070B1C) : const Color(0xFFF4F6FF);
    final textColor    = isDark ? Colors.white             : const Color(0xFF0D1129);
    final subtextColor = isDark ? const Color(0xFF8B9EC0)  : const Color(0xFF6B7FA0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Profile header (compact in landscape) ──────────────────
          _ProfileHeader(isDark: isDark, isLandscape: isLandscape),

          // ── Scrollable menu ────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                top: isLandscape ? 4 : 6,
                bottom: 8,
              ),
              children: [
                // ── MY WORKSPACE ──────────────────────────────────
                _SectionDivider(
                    label: 'MY WORKSPACE',
                    isDark: isDark,
                    isLandscape: isLandscape),
                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'My Profile',
                  subtitle: 'Edit personal info',
                  accentColor: _kBlue,
                  isDark: isDark,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  isLandscape: isLandscape,
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
                  isLandscape: isLandscape,
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
                  isLandscape: isLandscape,
                  onTap: () => Navigator.of(context).pop(),
                ),

                SizedBox(height: isLandscape ? 2 : 4),

                // ── FLEET ─────────────────────────────────────────
                _SectionDivider(
                    label: 'FLEET',
                    isDark: isDark,
                    isLandscape: isLandscape),
                _ExpandableSection(
                  id: 'fleet',
                  icon: Icons.directions_car_outlined,
                  label: 'Fleet Management',
                  color: _kAmber,
                  isDark: isDark,
                  isOpen: _open('fleet'),
                  isLandscape: isLandscape,
                  onToggle: () => _toggle('fleet'),
                  children: [
                    _SubItem(
                        icon: Icons.commute_rounded,
                        label: 'Active Vehicles',
                        count: '24',
                        color: _kAmber,
                        isDark: isDark,
                        isLandscape: isLandscape,
                        onTap: () => Navigator.of(context).pop()),
                    _SubItem(
                        icon: Icons.route_rounded,
                        label: 'Manage Routes',
                        color: _kAmber,
                        isDark: isDark,
                        isLandscape: isLandscape,
                        onTap: () => Navigator.of(context).pop()),
                    _SubItem(
                        icon: Icons.build_outlined,
                        label: 'Maintenance',
                        count: '3',
                        color: _kCoral,
                        isDark: isDark,
                        isLandscape: isLandscape,
                        onTap: () => Navigator.of(context).pop()),
                    _SubItem(
                        icon: Icons.local_gas_station_outlined,
                        label: 'Fuel Logs',
                        color: _kAmber,
                        isDark: isDark,
                        isLandscape: isLandscape,
                        onTap: () => Navigator.of(context).pop()),
                  ],
                ),

                _ExpandableSection(
                  id: 'analytics',
                  icon: Icons.bar_chart_rounded,
                  label: 'Reports & Analytics',
                  color: _kPurple,
                  isDark: isDark,
                  isOpen: _open('analytics'),
                  isLandscape: isLandscape,
                  onToggle: () => _toggle('analytics'),
                  children: [
                    _SubItem(
                        icon: Icons.dashboard_outlined,
                        label: 'Live Dashboard',
                        color: _kPurple,
                        isDark: isDark,
                        isLandscape: isLandscape,
                        onTap: () => Navigator.of(context).pop()),
                    _SubItem(
                        icon: Icons.description_outlined,
                        label: 'Generate Report',
                        color: _kPurple,
                        isDark: isDark,
                        isLandscape: isLandscape,
                        onTap: () => Navigator.of(context).pop()),
                    _SubItem(
                        icon: Icons.file_download_outlined,
                        label: 'Export Data',
                        color: _kPurple,
                        isDark: isDark,
                        isLandscape: isLandscape,
                        onTap: () => Navigator.of(context).pop()),
                  ],
                ),

                SizedBox(height: isLandscape ? 2 : 4),

                // ── SETTINGS & INFO ────────────────────────────────
                _SectionDivider(
                    label: 'SETTINGS & INFO',
                    isDark: isDark,
                    isLandscape: isLandscape),
                _ExpandableSection(
                  id: 'settings',
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  color: _kBlue,
                  isDark: isDark,
                  isOpen: _open('settings'),
                  isLandscape: isLandscape,
                  onToggle: () => _toggle('settings'),
                  children: [
                    _ThemeSubItem(
                      isDark: isDark,
                      isLandscape: isLandscape,
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
                        isLandscape: isLandscape,
                        onTap: () => Navigator.of(context).pop()),
                    _SubItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        color: _kTeal,
                        isDark: isDark,
                        isLandscape: isLandscape,
                        onTap: () => Navigator.of(context).pop()),
                    _SubItem(
                        icon: Icons.lock_outline_rounded,
                        label: 'Security & Privacy',
                        color: _kCoral,
                        isDark: isDark,
                        isLandscape: isLandscape,
                        onTap: () => Navigator.of(context).pop()),
                  ],
                ),
                _ExpandableSection(
                  id: 'about',
                  icon: Icons.info_outline_rounded,
                  label: 'About DUONET',
                  color: _kGreen,
                  isDark: isDark,
                  isOpen: _open('about'),
                  isLandscape: isLandscape,
                  onToggle: () => _toggle('about'),
                  children: [
                    _SubItem(
                        icon: Icons.menu_book_outlined,
                        label: 'Documentation',
                        color: _kGreen,
                        isDark: isDark,
                        isLandscape: isLandscape,
                        onTap: () => Navigator.of(context).pop()),
                    _SubItem(
                        icon: Icons.support_agent_outlined,
                        label: 'Contact Support',
                        color: _kGreen,
                        isDark: isDark,
                        isLandscape: isLandscape,
                        onTap: () => Navigator.of(context).pop()),
                    _SubItem(
                        icon: Icons.new_releases_outlined,
                        label: 'v1.0.0 · Changelog',
                        color: Colors.grey,
                        isDark: isDark,
                        isLandscape: isLandscape,
                        onTap: () => Navigator.of(context).pop()),
                  ],
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Sign-out footer ────────────────────────────────────────
          _SignOutFooter(
            isDark: isDark,
            isLandscape: isLandscape,
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
//  Portrait  — full layout: avatar, name, role, email, status pill, PRO badge
//  Landscape — compact single row: avatar + name + status dot + close button
//              (~60 dp total height vs ~180 dp portrait, freeing the menu)
// ═══════════════════════════════════════════════════════════════════════════════

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.isDark, required this.isLandscape});
  final bool isDark;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return isLandscape
        ? _buildCompact(context, topPad)
        : _buildFull(context, topPad);
  }

  // ── Full portrait header ─────────────────────────────────────────────────

  Widget _buildFull(BuildContext context, double topPad) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _HeaderPainter(isDark: isDark)),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, topPad + 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar row + close button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DrawerAvatar(
                      size: context.dp(56), isDark: isDark, showDot: true),
                  const Spacer(),
                  _HeaderCloseButton(
                      size: context.dp(32), isDark: isDark),
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
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: context.sp(12),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'user1@duonet.io',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.42),
                  fontSize: context.sp(11),
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 14),

              // Status pill + PRO badge
              Row(
                children: [
                  // Available pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: context.dp(6),
                          height: context.dp(6),
                          decoration: const BoxDecoration(
                            color: _kGreen, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
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
                  // PRO badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kAmber, Color(0xFFFF8C00)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _kAmber.withValues(alpha: 0.40),
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

  // ── Compact landscape header ─────────────────────────────────────────────
  //
  // Single row: [avatar 40] [gap] [name + role] [status dot] [PRO] [close]
  // No email, no pills — keeps total height to topPad + 58 dp.

  Widget _buildCompact(BuildContext context, double topPad) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _HeaderPainter(isDark: isDark)),
        ),
        Padding(
          padding:
              EdgeInsets.fromLTRB(14, topPad + 9, 12, 11),
          child: Row(
            children: [
              _DrawerAvatar(size: 40, isDark: isDark, showDot: false),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name + status dot + PRO badge on one line
                    Row(
                      children: [
                        Container(
                          width: 7, height: 7,
                          decoration: const BoxDecoration(
                              color: _kGreen, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'User1',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [_kAmber, Color(0xFFFF8C00)]),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Poppins',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Fleet Manager · DUONET',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.50),
                        fontSize: 11,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              _HeaderCloseButton(size: 28, isDark: isDark),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shared avatar widget ──────────────────────────────────────────────────────

class _DrawerAvatar extends StatelessWidget {
  const _DrawerAvatar({
    required this.size,
    required this.isDark,
    required this.showDot,
  });
  final double size;
  final bool isDark;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final dotSize = size * 0.24;
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [_kBlue, _kTeal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isDark ? null : Colors.white.withValues(alpha: 0.26),
            shape: BoxShape.circle,
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.32), width: 2),
            boxShadow: [
              BoxShadow(
                color: _kBlue.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'U1',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.34,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
        if (showDot)
          Positioned(
            bottom: 1,
            right: 1,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: _kGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF060B20)
                      : const Color(0xFF1348A8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                      color: _kGreen.withValues(alpha: 0.50), blurRadius: 5),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Shared close button ───────────────────────────────────────────────────────

class _HeaderCloseButton extends StatelessWidget {
  const _HeaderCloseButton({required this.size, required this.isDark});
  final double size;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.11),
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Icon(
          Icons.close_rounded,
          color: Colors.white.withValues(alpha: 0.75),
          size: size * 0.52,
        ),
      ),
    );
  }
}

// ─── Header painter — dot-grid + gradient background ──────────────────────────
//
// Replaces the arc pattern with an evenly spaced dot grid for a more modern,
// minimal look. A radial glow blob remains in the top-right corner.

class _HeaderPainter extends CustomPainter {
  _HeaderPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    // Base gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          colors: isDark
              ? [const Color(0xFF060B20), const Color(0xFF0E1A42)]
              : [const Color(0xFF1348A8), const Color(0xFF1E6EDB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Dot-grid decorative overlay
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.055);
    const spacing = 17.0;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.3, dotPaint);
      }
    }

    // Soft radial glow — top-right quarter
    final glowCenter = Offset(size.width * 0.84, size.height * 0.16);
    final glowRadius = size.height * 0.80;
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            (isDark ? _kBlue : Colors.white).withValues(alpha: 0.09),
            Colors.transparent,
          ],
        ).createShader(
            Rect.fromCircle(center: glowCenter, radius: glowRadius)),
    );
  }

  @override
  bool shouldRepaint(_HeaderPainter old) => old.isDark != isDark;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SECTION DIVIDER
//
//  Landscape: tighter vertical padding so more menu rows are visible.
//  Dot prefix replaces the plain text start for a more polished look.
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({
    required this.label,
    required this.isDark,
    required this.isLandscape,
  });
  final String label;
  final bool isDark;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          18, isLandscape ? 8 : 12, 18, isLandscape ? 3 : 5),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.28)
                  : Colors.grey.shade500,
              letterSpacing: 1.6,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 0.5,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  MENU ITEM — non-expandable row
//
//  Icon container: no border, circular-corner box (radius = size/2.5).
//  Subtitle hidden in landscape to save vertical space.
// ═══════════════════════════════════════════════════════════════════════════════

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.isDark,
    required this.textColor,
    required this.subtextColor,
    required this.isLandscape,
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
  final bool isLandscape;
  final VoidCallback onTap;
  final String? subtitle;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final iconBox = isLandscape ? 32.0 : 36.0;
    final vPad    = isLandscape ? 7.0  : 10.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: accentColor.withValues(alpha: 0.10),
        highlightColor: accentColor.withValues(alpha: 0.06),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: vPad),
          child: Row(
            children: [
              // Borderless icon box with rounded corners
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: accentColor
                      .withValues(alpha: isDark ? 0.14 : 0.09),
                  borderRadius:
                      BorderRadius.circular(iconBox / 2.5),
                ),
                child:
                    Icon(icon, size: iconBox * 0.50, color: accentColor),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        height: 1.3,
                      ),
                    ),
                    // Subtitle visible in portrait only
                    if (subtitle != null && !isLandscape)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 11,
                          height: 1.3,
                          fontFamily: 'Poppins',
                        ),
                      ),
                  ],
                ),
              ),

              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? accentColor)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: badgeColor ?? accentColor,
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
                    ? Colors.white.withValues(alpha: 0.18)
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
//  Header: accent icon box (matches _MenuItem style) + label + rotating chevron.
//  Children: AnimatedSize height animation inside a left-accent container.
//  Landscape: reduced vertical padding throughout.
// ═══════════════════════════════════════════════════════════════════════════════

class _ExpandableSection extends StatelessWidget {
  const _ExpandableSection({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.isOpen,
    required this.isLandscape,
    required this.onToggle,
    required this.children,
  });

  final String id;
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool isOpen;
  final bool isLandscape;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final iconBox = isLandscape ? 32.0 : 36.0;
    final vPad    = isLandscape ? 8.0  : 11.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ───────────────────────────────────────────────
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            splashColor: color.withValues(alpha: 0.10),
            highlightColor: color.withValues(alpha: 0.06),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: isOpen
                  ? color.withValues(alpha: isDark ? 0.06 : 0.04)
                  : Colors.transparent,
              padding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: vPad),
              child: Row(
                children: [
                  Container(
                    width: iconBox,
                    height: iconBox,
                    decoration: BoxDecoration(
                      color: color
                          .withValues(alpha: isDark ? 0.14 : 0.09),
                      borderRadius:
                          BorderRadius.circular(iconBox / 2.5),
                    ),
                    child: Icon(icon,
                        size: iconBox * 0.50, color: color),
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
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 230),
                    curve: Curves.easeInOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: isOpen
                          ? color
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.28)
                              : Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Animated children ─────────────────────────────────────────
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: isOpen
                ? Container(
                    margin: const EdgeInsets.only(
                        left: 14, right: 10, bottom: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.022)
                          : color.withValues(alpha: 0.025),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(10),
                      ),
                      border: Border(
                        left: BorderSide(
                            color: color.withValues(alpha: 0.50),
                            width: 2),
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
//  SUB-ITEM — child inside an expandable section
//
//  Landscape: reduced vertical padding.
// ═══════════════════════════════════════════════════════════════════════════════

class _SubItem extends StatelessWidget {
  const _SubItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.isLandscape,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool isLandscape;
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
          padding: EdgeInsets.symmetric(
              horizontal: 14, vertical: isLandscape ? 8 : 11),
          child: Row(
            children: [
              Icon(icon,
                  size: 15, color: color.withValues(alpha: 0.80)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.75)
                        : const Color(0xFF3D4A6A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              if (count != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    count!,
                    style: TextStyle(
                      color: color,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.grey.shade300,
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
    required this.isLandscape,
    required this.themeMode,
    required this.onChanged,
  });

  final bool isDark;
  final bool isLandscape;
  final ThemeMode themeMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isCurrentlyDark = themeMode == ThemeMode.dark;
    final iconColor =
        isCurrentlyDark ? const Color(0xFF1B8EF8) : const Color(0xFFF59E0B);

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 14, vertical: isLandscape ? 6 : 8),
      child: Row(
        children: [
          Icon(
            isCurrentlyDark
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            size: 15,
            color: iconColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isCurrentlyDark ? 'Dark Mode' : 'Light Mode',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.75)
                    : const Color(0xFF3D4A6A),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Transform.scale(
            scale: 0.80,
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
//
//  Landscape: shorter button + less padding so it doesn't consume screen space.
// ═══════════════════════════════════════════════════════════════════════════════

class _SignOutFooter extends StatelessWidget {
  const _SignOutFooter({
    required this.isDark,
    required this.isLandscape,
    required this.onTap,
  });
  final bool isDark;
  final bool isLandscape;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final btnHeight = isLandscape ? 38.0 : context.dp(48);

    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        isLandscape ? 8 : 12,
        14,
        bottomPad + (isLandscape ? 10 : 16),
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: btnHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _kRed.withValues(alpha: isDark ? 0.16 : 0.08),
                _kRed.withValues(alpha: isDark ? 0.08 : 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kRed.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded,
                  color: _kRed,
                  size: isLandscape ? 15.0 : context.dp(18)),
              const SizedBox(width: 7),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: _kRed,
                  fontSize: isLandscape ? 13.0 : context.sp(14),
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