import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_drawer.dart';
import 'scaffold_key_scope.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key, required this.child});
  final Widget child;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _routes = [
    '/home/posts',
    '/home/search-address',
    '/home/search-car',
    '/home/face-recognition',
    '/home/hotels',
    '/home/organizations',
    '/home/favorites',
    '/home/map',
  ];

  static const _navItems = [
    _NavItem(label: 'Posts', icon: Icons.article_outlined, activeIcon: Icons.article_rounded, color: Color(0xFF1B8EF8)),
    _NavItem(label: 'Address', icon: Icons.location_on_outlined, activeIcon: Icons.location_on_rounded, color: Color(0xFF00E5CC)),
    _NavItem(label: 'Car', icon: Icons.directions_car_outlined, activeIcon: Icons.directions_car_rounded, color: Color(0xFFF59E0B)),
    _NavItem(label: 'Face ID', icon: Icons.face_outlined, activeIcon: Icons.face_rounded, color: Color(0xFF7C6FF7)),
    _NavItem(label: 'Hotels', icon: Icons.hotel_outlined, activeIcon: Icons.hotel_rounded, color: Color(0xFFFF6B6B)),
    _NavItem(label: 'Orgs', icon: Icons.corporate_fare_outlined, activeIcon: Icons.corporate_fare_rounded, color: Color(0xFF00D68F)),
    _NavItem(label: 'Favs', icon: Icons.favorite_outline_rounded, activeIcon: Icons.favorite_rounded, color: Color(0xFFFF4081)),
    _NavItem(label: 'Map', icon: Icons.map_outlined, activeIcon: Icons.map_rounded, color: Color(0xFF4CAF50)),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;

    // Tablets (portrait or landscape) and landscape phones use the rail.
    return ScaffoldKeyScope(
      scaffoldKey: _scaffoldKey,
      child: (isLandscape || isTablet)
          ? _buildRailLayout(context, selectedIndex, isDark, isTablet)
          : _buildPortraitLayout(context, selectedIndex, isDark),
    );
  }

  // ── Portrait: bottom nav ──────────────────────────────────────────────────

  Widget _buildPortraitLayout(
      BuildContext context, int selectedIndex, bool isDark) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawerWidget(),
      body: widget.child,
      bottomNavigationBar: _DuonetBottomNav(
        items: _navItems,
        selectedIndex: selectedIndex,
        isDark: isDark,
        onTap: (i) => context.go(_routes[i]),
      ),
    );
  }

  // ── Rail layout: landscape phones, tablet portrait & landscape ───────────

  Widget _buildRailLayout(
      BuildContext context, int selectedIndex, bool isDark, bool isTablet) {
    final railBg = isDark ? const Color(0xFF0D1028) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF1B8EF8).withValues(alpha: 0.12)
        : Colors.grey.withValues(alpha: 0.12);
    // Wider rail on tablets so labels have breathing room
    final railWidth = isTablet ? 80.0 : 72.0;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawerWidget(),
      body: Row(
        children: [
          // Navigation Rail
          Container(
            width: railWidth,
            decoration: BoxDecoration(
              color: railBg,
              border: Border(
                right: BorderSide(color: borderColor, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Menu button
                  IconButton(
                    icon: Icon(
                      Icons.menu_rounded,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                      size: 22,
                    ),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    tooltip: 'Menu',
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _navItems.length,
                      itemBuilder: (context, i) {
                        final item = _navItems[i];
                        final isSelected = i == selectedIndex;
                        return _RailItem(
                          item: item,
                          isSelected: isSelected,
                          isDark: isDark,
                          onTap: () => context.go(_routes[i]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

// ── Rail item ──────────────────────────────────────────────────────────────

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? item.color.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 220),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                size: 20,
                color: isSelected
                    ? item.color
                    : isDark
                        ? Colors.white.withValues(alpha: 0.35)
                        : Colors.grey.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: isSelected ? 8 : 0,
                fontWeight: FontWeight.w700,
                color: isSelected ? item.color : Colors.transparent,
                height: isSelected ? 1.1 : 0,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.clip,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Nav ──────────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color color;
  const _NavItem({required this.label, required this.icon, required this.activeIcon, required this.color});
}

class _DuonetBottomNav extends StatelessWidget {
  const _DuonetBottomNav({
    required this.items,
    required this.selectedIndex,
    required this.isDark,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0D1028) : Colors.white;
    final border = isDark
        ? const Color(0xFF1B8EF8).withValues(alpha: 0.15)
        : Colors.grey.withValues(alpha: 0.15);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF1B8EF8).withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isSelected = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: isSelected ? 20 : 0,
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? item.color
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: item.color
                                          .withValues(alpha: 0.5),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : [],
                          ),
                        ),
                        AnimatedScale(
                          scale: isSelected ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            size: 22,
                            color: isSelected
                                ? item.color
                                : isDark
                                    ? Colors.white.withValues(alpha: 0.35)
                                    : Colors.grey.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            fontSize: isSelected ? 9 : 0,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? item.color
                                : Colors.transparent,
                            height: isSelected ? 1.2 : 0,
                          ),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}