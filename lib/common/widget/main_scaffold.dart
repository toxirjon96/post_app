import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../util/responsive.dart';
import 'app_drawer.dart';
import 'scaffold_key_scope.dart';

// ── Model ──────────────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color color;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.color,
  });
}

// ── Shell ──────────────────────────────────────────────────────────────────

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
    _NavItem(label: 'Posts',   icon: Icons.article_outlined,       activeIcon: Icons.article_rounded,       color: Color(0xFF1B8EF8)),
    _NavItem(label: 'Address', icon: Icons.location_on_outlined,   activeIcon: Icons.location_on_rounded,   color: Color(0xFF00E5CC)),
    _NavItem(label: 'Car',     icon: Icons.directions_car_outlined, activeIcon: Icons.directions_car_rounded, color: Color(0xFFF59E0B)),
    _NavItem(label: 'Face ID', icon: Icons.face_outlined,          activeIcon: Icons.face_rounded,          color: Color(0xFF7C6FF7)),
    _NavItem(label: 'Hotels',  icon: Icons.hotel_outlined,         activeIcon: Icons.hotel_rounded,         color: Color(0xFFFF6B6B)),
    _NavItem(label: 'Orgs',    icon: Icons.corporate_fare_outlined, activeIcon: Icons.corporate_fare_rounded, color: Color(0xFF00D68F)),
    _NavItem(label: 'Favs',    icon: Icons.favorite_outline_rounded, activeIcon: Icons.favorite_rounded,    color: Color(0xFFFF4081)),
    _NavItem(label: 'Map',     icon: Icons.map_outlined,           activeIcon: Icons.map_rounded,           color: Color(0xFF4CAF50)),
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

    return ScaffoldKeyScope(
      scaffoldKey: _scaffoldKey,
      child: (isLandscape || isTablet)
          ? _buildRailLayout(context, selectedIndex, isDark, isTablet)
          : _buildPortraitLayout(context, selectedIndex, isDark),
    );
  }

  // ── Portrait: floating pill bottom nav ────────────────────────────────────

  Widget _buildPortraitLayout(
      BuildContext context, int selectedIndex, bool isDark) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawerWidget(),
      body: widget.child,
      bottomNavigationBar: _FloatingBottomNav(
        items: _navItems,
        selectedIndex: selectedIndex,
        isDark: isDark,
        onTap: (i) => context.go(_routes[i]),
      ),
    );
  }

  // ── Landscape / Tablet: side rail ─────────────────────────────────────────

  Widget _buildRailLayout(
      BuildContext context, int selectedIndex, bool isDark, bool isTablet) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawerWidget(),
      body: Row(
        children: [
          isTablet
              ? _ExtendedRail(
                  items: _navItems,
                  selectedIndex: selectedIndex,
                  isDark: isDark,
                  onTap: (i) => context.go(_routes[i]),
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                )
              : _CompactRail(
                  items: _navItems,
                  selectedIndex: selectedIndex,
                  isDark: isDark,
                  onTap: (i) => context.go(_routes[i]),
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

// ── Floating Bottom Nav ────────────────────────────────────────────────────

class _FloatingBottomNav extends StatelessWidget {
  const _FloatingBottomNav({
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
    final accentColor = items[selectedIndex].color;
    final bgColor = isDark
        ? const Color(0xFF0D1028).withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.96);

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                height: 66,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    // colored glow from selected tab
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.20),
                      blurRadius: 28,
                      spreadRadius: -4,
                      offset: const Offset(0, -6),
                    ),
                    // depth shadow
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.50 : 0.12),
                      blurRadius: 36,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  children: items.asMap().entries.map((e) => _NavButton(
                        item: e.value,
                        isSelected: e.key == selectedIndex,
                        isDark: isDark,
                        onTap: () => onTap(e.key),
                      )).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav Button ──────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  const _NavButton({
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 11 : 5,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? item.color.withValues(alpha: isDark ? 0.22 : 0.13)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: isSelected
                  ? Border.all(
                      color:
                          item.color.withValues(alpha: isDark ? 0.38 : 0.22),
                      width: 1.5,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: item.color.withValues(alpha: 0.24),
                        blurRadius: 14,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.12 : 1.0,
                  duration: const Duration(milliseconds: 280),
                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    size: 22,
                    color: isSelected
                        ? item.color
                        : isDark
                            ? Colors.white.withValues(alpha: 0.30)
                            : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: isSelected ? 8.5 : 0,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? item.color : Colors.transparent,
                    height: isSelected ? 1.2 : 0.01,
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
        ),
      ),
    );
  }
}

// ── Compact Rail ─ landscape phones ────────────────────────────────────────

class _CompactRail extends StatelessWidget {
  const _CompactRail({
    required this.items,
    required this.selectedIndex,
    required this.isDark,
    required this.onTap,
    required this.onMenuTap,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onTap;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0A0D1E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.withValues(alpha: 0.12);

    return Container(
      width: 66,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: isDark ? 0.30 : 0.04),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _RailMenuBtn(isDark: isDark, onTap: onMenuTap),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) => _CompactRailItem(
                  item: items[i],
                  isSelected: i == selectedIndex,
                  isDark: isDark,
                  onTap: () => onTap(i),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactRailItem extends StatelessWidget {
  const _CompactRailItem({
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
        duration: const Duration(milliseconds: 230),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? item.color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: item.color.withValues(alpha: 0.30), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.14 : 1.0,
              duration: const Duration(milliseconds: 230),
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
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 7.5 : 0,
                fontWeight: FontWeight.w700,
                color: isSelected ? item.color : Colors.transparent,
                height: isSelected ? 1.1 : 0.01,
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

// ── Extended Rail ─ tablets ─────────────────────────────────────────────────

class _ExtendedRail extends StatelessWidget {
  const _ExtendedRail({
    required this.items,
    required this.selectedIndex,
    required this.isDark,
    required this.onTap,
    required this.onMenuTap,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onTap;
  final VoidCallback onMenuTap;

  static const _primaryEnd = 4;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0A0D1E) : const Color(0xFFF5F7FF);
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200;

    return Container(
      width: context.isLargeTablet ? 240 : 216,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: isDark ? 0.28 : 0.04),
            blurRadius: 14,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Logo header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 8, 14),
              child: Row(
                children: [
                  Container(
                    width: context.dp(34),
                    height: context.dp(34),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1B8EF8), Color(0xFF00E5CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.route_rounded,
                        color: Colors.white, size: context.dp(18)),
                  ),
                  SizedBox(width: context.dp(10)),
                  Text(
                    'DUONET',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F1629),
                      fontSize: context.sp(15),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const Spacer(),
                  _RailMenuBtn(isDark: isDark, onTap: onMenuTap, small: true),
                ],
              ),
            ),
            // ── Navigation list ──────────────────────────────────────
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                children: [
                  _railSectionLabel(context, 'MAIN', isDark),
                  ...List.generate(
                    _primaryEnd,
                    (i) => _ExtendedRailItem(
                      item: items[i],
                      isSelected: i == selectedIndex,
                      isDark: isDark,
                      onTap: () => onTap(i),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _railSectionLabel(context, 'MORE', isDark),
                  ...List.generate(
                    items.length - _primaryEnd,
                    (i) {
                      final idx = i + _primaryEnd;
                      return _ExtendedRailItem(
                        item: items[idx],
                        isSelected: idx == selectedIndex,
                        isDark: isDark,
                        onTap: () => onTap(idx),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _railSectionLabel(BuildContext context, String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: context.sp(9.5),
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white24 : Colors.grey.shade400,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

class _ExtendedRailItem extends StatelessWidget {
  const _ExtendedRailItem({
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        splashColor: item.color.withValues(alpha: 0.10),
        highlightColor: item.color.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
              horizontal: context.dp(12), vertical: context.dp(11)),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      item.color
                          .withValues(alpha: isDark ? 0.22 : 0.11),
                      item.color
                          .withValues(alpha: isDark ? 0.08 : 0.04),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(13),
            border: isSelected
                ? Border.all(
                    color: item.color.withValues(alpha: 0.24), width: 1)
                : null,
          ),
          child: Row(
            children: [
              AnimatedScale(
                scale: isSelected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 240),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: context.dp(20),
                  color: isSelected
                      ? item.color
                      : isDark
                          ? Colors.white.withValues(alpha: 0.38)
                          : Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: context.sp(13.5),
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? item.color
                        : isDark
                            ? Colors.white.withValues(alpha: 0.55)
                            : Colors.grey.shade600,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: context.dp(7),
                  height: context.dp(7),
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: item.color.withValues(alpha: 0.5),
                          blurRadius: 6),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared menu button ──────────────────────────────────────────────────────

class _RailMenuBtn extends StatelessWidget {
  const _RailMenuBtn({
    required this.isDark,
    required this.onTap,
    this.small = false,
  });

  final bool isDark;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.menu_rounded,
        color: isDark ? Colors.white54 : Colors.grey.shade600,
        size: context.dp(small ? 20 : 22),
      ),
      onPressed: onTap,
      tooltip: 'Menu',
      visualDensity: small ? VisualDensity.compact : null,
    );
  }
}