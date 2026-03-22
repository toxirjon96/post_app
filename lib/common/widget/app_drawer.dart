import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../provider/theme_provider.dart';

class AppDrawerWidget extends ConsumerWidget {
  const AppDrawerWidget({super.key});

  static const _navItems = [
    _DrawerNavItem(path: '/home/posts', label: 'Posts', icon: Icons.article_outlined),
    _DrawerNavItem(path: '/home/search-address', label: 'Search Address', icon: Icons.location_on_outlined),
    _DrawerNavItem(path: '/home/search-car', label: 'Search Car', icon: Icons.directions_car_outlined),
    _DrawerNavItem(path: '/home/face-recognition', label: 'Face Recognition', icon: Icons.face_outlined),
    _DrawerNavItem(path: '/home/hotels', label: 'Hotels', icon: Icons.hotel_outlined),
    _DrawerNavItem(path: '/home/organizations', label: 'Organizations', icon: Icons.corporate_fare_outlined),
    _DrawerNavItem(path: '/home/favorites', label: 'Favorites', icon: Icons.favorite_outline_rounded),
    _DrawerNavItem(path: '/home/map', label: 'Map', icon: Icons.map_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPath = GoRouterState.of(context).uri.path;

    final bg = isDark ? const Color(0xFF07091A) : const Color(0xFFF8FAFF);
    final surfaceColor = isDark ? const Color(0xFF0F1629) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F1629);

    return Drawer(
      width: 285,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0A0E20), const Color(0xFF0F1629)]
                    : [const Color(0xFF1B8EF8), const Color(0xFF00E5CC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? const LinearGradient(colors: [Color(0xFF1B8EF8), Color(0xFF00E5CC)])
                            : null,
                        color: isDark ? null : Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.route_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'DUONET',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // User avatar
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B8EF8), Color(0xFF00E5CC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          'U1',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'User1',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Fleet Manager',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'user1@duonet.io',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Nav Items ────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              children: [
                ..._navItems.map((item) {
                  final isActive = currentPath.startsWith(item.path);
                  return _DrawerNavTile(
                    item: item,
                    isActive: isActive,
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(item.path);
                    },
                  );
                }),
                const SizedBox(height: 8),
                Divider(color: isDark ? Colors.white12 : Colors.grey.shade200, height: 1),
                const SizedBox(height: 8),
                _DrawerActionTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  isDark: isDark,
                  textColor: textColor,
                  onTap: () => Navigator.of(context).pop(),
                ),
                _DrawerActionTile(
                  icon: Icons.info_outline_rounded,
                  label: 'About DUONET',
                  isDark: isDark,
                  textColor: textColor,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // ── Footer ───────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Dark / Light toggle
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        themeMode == ThemeMode.dark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF1B8EF8) : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          themeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value: themeMode == ThemeMode.dark,
                          onChanged: (val) => ref.read(themeModeProvider.notifier).state =
                              val ? ThemeMode.dark : ThemeMode.light,
                          activeColor: const Color(0xFF1B8EF8),
                          inactiveThumbColor: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Logout
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/login');
                  },
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D6A).withOpacity(isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF4D6A).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: Color(0xFFFF4D6A), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            color: Color(0xFFFF4D6A),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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

class _DrawerNavItem {
  final String path;
  final String label;
  final IconData icon;
  const _DrawerNavItem({required this.path, required this.label, required this.icon});
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.item,
    required this.isActive,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.onTap,
  });

  final _DrawerNavItem item;
  final bool isActive;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF1B8EF8).withOpacity(isDark ? 0.15 : 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(
                      color: const Color(0xFF1B8EF8).withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isActive
                      ? const Color(0xFF1B8EF8)
                      : isDark
                          ? Colors.white54
                          : Colors.grey.shade600,
                ),
                const SizedBox(width: 14),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isActive ? const Color(0xFF1B8EF8) : textColor,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1B8EF8),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  const _DrawerActionTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(icon, size: 20, color: isDark ? Colors.white54 : Colors.grey.shade600),
                const SizedBox(width: 14),
                Text(label,
                    style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}