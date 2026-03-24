import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../provider/theme_provider.dart';

// ── Entry widget ───────────────────────────────────────────────────────────

class AppDrawerWidget extends ConsumerStatefulWidget {
  const AppDrawerWidget({super.key});

  @override
  ConsumerState<AppDrawerWidget> createState() => _AppDrawerWidgetState();
}

class _AppDrawerWidgetState extends ConsumerState<AppDrawerWidget> {
  final Set<String> _expanded = {'fleet', 'settings'};

  void _toggle(String id) => setState(() {
        _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id);
      });

  bool _open(String id) => _expanded.contains(id);

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;

    final bg = isDark ? const Color(0xFF07091A) : const Color(0xFFF8FAFF);
    final textColor = isDark ? Colors.white : const Color(0xFF0F1629);
    final subtextColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return Drawer(
      width: isTablet ? 320 : 288,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Profile header ───────────────────────────────────────────
          _ProfileHeader(isDark: isDark, context: context),

          // ── Scrollable menu ──────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              children: [
                // ─ Workspace ────────────────────────────────────────
                _SectionLabel(label: 'MY WORKSPACE', isDark: isDark),
                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'My Profile',
                  subtitle: 'Edit personal info',
                  isDark: isDark,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.group_outlined,
                  label: 'Team Members',
                  subtitle: '12 active members',
                  badge: '12',
                  badgeColor: const Color(0xFF1B8EF8),
                  isDark: isDark,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.timeline_rounded,
                  label: 'My Activity',
                  subtitle: 'Recent actions log',
                  isDark: isDark,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () {},
                ),
                const SizedBox(height: 4),

                // ─ Fleet Management (expandable) ─────────────────────
                _ExpandableSection(
                  id: 'fleet',
                  icon: Icons.directions_car_outlined,
                  label: 'Fleet Management',
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                  isOpen: _open('fleet'),
                  onToggle: () => _toggle('fleet'),
                  children: [
                    _SubItem(icon: Icons.commute_rounded,             label: 'Active Vehicles',  count: '24', color: const Color(0xFFF59E0B), isDark: isDark, onTap: () {}),
                    _SubItem(icon: Icons.route_rounded,               label: 'Manage Routes',             color: const Color(0xFFF59E0B), isDark: isDark, onTap: () {}),
                    _SubItem(icon: Icons.build_outlined,              label: 'Maintenance',      count: '3',  color: const Color(0xFFFF6B6B), isDark: isDark, onTap: () {}),
                    _SubItem(icon: Icons.local_gas_station_outlined,  label: 'Fuel Logs',                 color: const Color(0xFFF59E0B), isDark: isDark, onTap: () {}),
                  ],
                ),

                // ─ Reports & Analytics (expandable) ──────────────────
                _ExpandableSection(
                  id: 'analytics',
                  icon: Icons.bar_chart_rounded,
                  label: 'Reports & Analytics',
                  color: const Color(0xFF7C6FF7),
                  isDark: isDark,
                  isOpen: _open('analytics'),
                  onToggle: () => _toggle('analytics'),
                  children: [
                    _SubItem(icon: Icons.dashboard_outlined,      label: 'Live Dashboard',  color: const Color(0xFF7C6FF7), isDark: isDark, onTap: () {}),
                    _SubItem(icon: Icons.description_outlined,    label: 'Generate Report', color: const Color(0xFF7C6FF7), isDark: isDark, onTap: () {}),
                    _SubItem(icon: Icons.file_download_outlined,  label: 'Export Data',     color: const Color(0xFF7C6FF7), isDark: isDark, onTap: () {}),
                  ],
                ),

                // ─ Settings (expandable) ──────────────────────────────
                _ExpandableSection(
                  id: 'settings',
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  color: const Color(0xFF1B8EF8),
                  isDark: isDark,
                  isOpen: _open('settings'),
                  onToggle: () => _toggle('settings'),
                  children: [
                    // Appearance with inline theme switch
                    _ThemeSubItem(
                      isDark: isDark,
                      themeMode: themeMode,
                      onChanged: (val) =>
                          ref.read(themeModeProvider.notifier).state =
                              val ? ThemeMode.dark : ThemeMode.light,
                    ),
                    _SubItem(icon: Icons.translate_rounded,          label: 'Language',             color: const Color(0xFF1B8EF8), isDark: isDark, onTap: () {}),
                    _SubItem(icon: Icons.notifications_outlined,     label: 'Notifications',        color: const Color(0xFF00E5CC), isDark: isDark, onTap: () {}),
                    _SubItem(icon: Icons.lock_outline_rounded,       label: 'Security & Privacy',   color: const Color(0xFFFF6B6B), isDark: isDark, onTap: () {}),
                  ],
                ),

                // ─ About (expandable) ─────────────────────────────────
                _ExpandableSection(
                  id: 'about',
                  icon: Icons.info_outline_rounded,
                  label: 'About DUONET',
                  color: const Color(0xFF00D68F),
                  isDark: isDark,
                  isOpen: _open('about'),
                  onToggle: () => _toggle('about'),
                  children: [
                    _SubItem(icon: Icons.menu_book_outlined,       label: 'Documentation',     color: const Color(0xFF00D68F), isDark: isDark, onTap: () {}),
                    _SubItem(icon: Icons.support_agent_outlined,   label: 'Contact Support',   color: const Color(0xFF00D68F), isDark: isDark, onTap: () {}),
                    _SubItem(icon: Icons.new_releases_outlined,    label: 'v1.0.0 · Changelog',color: Colors.grey,             isDark: isDark, onTap: () {}),
                  ],
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Sign out footer ──────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                context.go('/login');
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D6A)
                      .withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFFF4D6A).withValues(alpha: 0.30)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        color: Color(0xFFFF4D6A), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                          color: Color(0xFFFF4D6A),
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
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

// ── Profile Header ─────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.isDark, required this.context});
  final bool isDark;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          22, MediaQuery.of(context).padding.top + 20, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0A0E20), const Color(0xFF0F1629)]
              : [const Color(0xFF1565C0), const Color(0xFF1B8EF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? const LinearGradient(
                              colors: [Color(0xFF1B8EF8), Color(0xFF00E5CC)])
                          : null,
                      color: isDark ? null : Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 2.5),
                    ),
                    child: const Center(
                      child: Text('U1',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D68F),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isDark
                                ? const Color(0xFF0A0E20)
                                : const Color(0xFF1565C0),
                            width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Close
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.7), size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('User1',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('Fleet Manager · DUONET',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5)),
          const SizedBox(height: 1),
          Text('user1@duonet.io',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.50), fontSize: 11)),
          const SizedBox(height: 12),
          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.20), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: Color(0xFF00D68F), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text('Available',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white24 : Colors.grey.shade400,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

// ── Regular menu item ──────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 18,
                    color: isDark ? Colors.white60 : Colors.grey.shade600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: textColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: TextStyle(
                              color: subtextColor, fontSize: 11, height: 1.4)),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? const Color(0xFF1B8EF8))
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(badge!,
                      style: TextStyle(
                          color: badgeColor ?? const Color(0xFF1B8EF8),
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 16,
                  color: isDark ? Colors.white24 : Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Expandable Section ─────────────────────────────────────────────────────

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
      children: [
        // Header row (tap to toggle)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.15 : 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.22)),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F1629),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Animated children
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 240),
          crossFadeState:
              isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(left: 18, right: 10, bottom: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.015),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border(
                left: BorderSide(color: color.withValues(alpha: 0.35), width: 2),
              ),
            ),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

// ── Sub-item ───────────────────────────────────────────────────────────────

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color.withValues(alpha: 0.80)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (count != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(count!,
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 4),
              ],
              Icon(Icons.chevron_right_rounded,
                  size: 15,
                  color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Theme toggle sub-item ──────────────────────────────────────────────────

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Icon(
            isCurrentlyDark
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            size: 16,
            color: isCurrentlyDark
                ? const Color(0xFF1B8EF8)
                : const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isCurrentlyDark ? 'Dark Mode' : 'Light Mode',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.82,
            child: Switch(
              value: isCurrentlyDark,
              onChanged: onChanged,
              activeColor: const Color(0xFF1B8EF8),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}