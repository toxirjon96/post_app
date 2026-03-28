import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constant/theme_config.dart';
import '../util/responsive.dart';
import 'app_drawer.dart';
import 'scaffold_key_scope.dart';

// ─── Nav item model ───────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color color;
}

// ─── Route + item registry ────────────────────────────────────────────────────

const _routes = [
  '/home/posts',
  '/home/search-address',
  '/home/search-car',
  '/home/face-recognition',
  '/home/hotels',
  '/home/organizations',
  '/home/favorites',
  '/home/map',
];

const _navItems = [
  _NavItem(
    label: 'Posts',
    icon: Icons.article_outlined,
    activeIcon: Icons.article_rounded,
    color: AppColors.electricBlue,
  ),
  _NavItem(
    label: 'Address',
    icon: Icons.location_on_outlined,
    activeIcon: Icons.location_on_rounded,
    color: AppColors.teal,
  ),
  _NavItem(
    label: 'Car',
    icon: Icons.directions_car_outlined,
    activeIcon: Icons.directions_car_rounded,
    color: AppColors.amber,
  ),
  _NavItem(
    label: 'Face ID',
    icon: Icons.face_outlined,
    activeIcon: Icons.face_rounded,
    color: AppColors.purple,
  ),
  _NavItem(
    label: 'Hotels',
    icon: Icons.hotel_outlined,
    activeIcon: Icons.hotel_rounded,
    color: AppColors.coral,
  ),
  _NavItem(
    label: 'Orgs',
    icon: Icons.corporate_fare_outlined,
    activeIcon: Icons.corporate_fare_rounded,
    color: AppColors.emerald,
  ),
  _NavItem(
    label: 'Favs',
    icon: Icons.favorite_outline_rounded,
    activeIcon: Icons.favorite_rounded,
    color: AppColors.pink,
  ),
  _NavItem(
    label: 'Map',
    icon: Icons.map_outlined,
    activeIcon: Icons.map_rounded,
    color: Color(0xFF4CAF50),
  ),
];

// ─── Shell scaffold ───────────────────────────────────────────────────────────

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key, required this.child});
  final Widget child;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _routes.length; i++) {
      if (path.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx        = _selectedIndex(context);
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final isTablet   = MediaQuery.sizeOf(context).shortestSide >= 600;

    return ScaffoldKeyScope(
      scaffoldKey: _scaffoldKey,
      child: (isLandscape || isTablet)
          ? _buildRailLayout(context, idx, isDark, isTablet)
          : _buildPortraitLayout(context, idx, isDark),
    );
  }

  // ── Portrait phone ─ floating bottom nav ─────────────────────────────────

  Widget _buildPortraitLayout(
      BuildContext context, int idx, bool isDark) {
    return Scaffold(
      key: _scaffoldKey,
      // extendBody: true lets the page content scroll behind the frosted nav
      // so BackdropFilter blurs real content, not just a flat background.
      extendBody: true,
      drawer: const AppDrawerWidget(),
      body: widget.child,
      bottomNavigationBar: _BottomNav(
        items: _navItems,
        selectedIndex: idx,
        isDark: isDark,
        onTap: (i) => context.go(_routes[i]),
      ),
    );
  }

  // ── Landscape phone / any tablet ─ side rail ──────────────────────────────

  Widget _buildRailLayout(
      BuildContext context, int idx, bool isDark, bool isTablet) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawerWidget(),
      body: Row(
        children: [
          isTablet
              ? _ExtendedRail(
                  items: _navItems,
                  selectedIndex: idx,
                  isDark: isDark,
                  onTap: (i) => context.go(_routes[i]),
                  onMenuTap: () =>
                      _scaffoldKey.currentState?.openDrawer(),
                )
              : _CompactRail(
                  items: _navItems,
                  selectedIndex: idx,
                  isDark: isDark,
                  onTap: (i) => context.go(_routes[i]),
                  onMenuTap: () =>
                      _scaffoldKey.currentState?.openDrawer(),
                ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PORTRAIT BOTTOM NAV
//  Design: frosted-glass floating pill with a "magnetic" indicator that
//  slides between tabs. Two layers animate together:
//    • Pill highlight  — rounded-rect glow behind the active icon
//    • Glow bar        — 3 dp bottom bar with neon glow, same color
//  Both use AnimatedPositioned (x-axis slide) + TweenAnimationBuilder<Color?>
//  so color cross-fades as you switch tabs.
// ═══════════════════════════════════════════════════════════════════════════════

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.items,
    required this.selectedIndex,
    required this.isDark,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  // Layout constants
  static const double _navH      = 68.0;
  static const double _sidePad   = 14.0;
  static const double _bottomPad = 10.0;
  static const double _radius    = 26.0;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final accent      = items[selectedIndex].color;

    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            _sidePad, 0, _sidePad, _bottomPad + bottomInset),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              height: _navH,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBg.withValues(alpha: 0.93)
                    : AppColors.lightSurface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkElevated
                      : AppColors.lightBorder,
                  width: 1,
                ),
                boxShadow: [
                  // Per-tab accent glow — shifts color with each selection
                  BoxShadow(
                    color: accent.withValues(alpha: isDark ? 0.26 : 0.15),
                    blurRadius: 40,
                    spreadRadius: -6,
                    offset: const Offset(0, -8),
                  ),
                  // Depth shadow
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.60 : 0.10),
                    blurRadius: 48,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final totalW = constraints.maxWidth;
                  final itemW  = totalW / items.length;

                  // Sliding pill highlight geometry
                  final pillW = itemW * 0.82;
                  final pillX =
                      selectedIndex * itemW + (itemW - pillW) / 2;

                  // Sliding bottom glow bar geometry
                  const barW = 24.0;
                  const barH = 3.0;
                  final barX =
                      selectedIndex * itemW + (itemW - barW) / 2;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ── Pill highlight ─────────────────────────────
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        top: 8,
                        left: pillX,
                        width: pillW,
                        height: _navH - 16,
                        child: TweenAnimationBuilder<Color?>(
                          tween: ColorTween(end: accent),
                          duration: const Duration(milliseconds: 300),
                          builder: (_, c, _) {
                            final col = c ?? accent;
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                color: col.withValues(
                                    alpha: isDark ? 0.15 : 0.10),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: col.withValues(
                                      alpha: isDark ? 0.28 : 0.16),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: col.withValues(alpha: 0.16),
                                    blurRadius: 14,
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // ── Bottom glow bar ────────────────────────────
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        bottom: 0,
                        left: barX,
                        width: barW,
                        height: barH,
                        child: TweenAnimationBuilder<Color?>(
                          tween: ColorTween(end: accent),
                          duration: const Duration(milliseconds: 300),
                          builder: (_, c, _) {
                            final col = c ?? accent;
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    col,
                                    col.withValues(alpha: 0.35),
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(2)),
                                boxShadow: [
                                  BoxShadow(
                                    color: col.withValues(alpha: 0.90),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // ── Tab tiles ──────────────────────────────────
                      Positioned.fill(
                        child: Row(
                          children: items.asMap().entries.map((e) {
                            return _BottomNavTile(
                              item: e.value,
                              isSelected: e.key == selectedIndex,
                              isDark: isDark,
                              onTap: () => onTap(e.key),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom nav tile ───────────────────────────────────────────────────────────

class _BottomNavTile extends StatelessWidget {
  const _BottomNavTile({
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.18 : 1.0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    key: ValueKey(isSelected),
                    size: 22,
                    color: isSelected
                        ? item.color
                        : isDark
                            ? Colors.white.withValues(alpha: 0.28)
                            : Colors.grey.shade500,
                  ),
                ),
              ),
              // Label collapses with AnimatedSize when not active
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color:
                                isSelected ? item.color : Colors.transparent,
                            letterSpacing: 0.3,
                            fontFamily: 'Poppins',
                          ),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  COMPACT RAIL  ─  landscape phones  (64 dp wide)
//  Design: dark sidebar, icon + micro-label, per-item left-edge accent bar
//  that expands/contracts with AnimatedPositioned + AnimatedOpacity.
// ═══════════════════════════════════════════════════════════════════════════════

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
    final bg = isDark ? AppColors.darkBg : AppColors.lightSurface;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : AppColors.lightBorder;

    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: isDark ? 0.30 : 0.05),
            blurRadius: 14,
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
                physics: const ClampingScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (_, i) => _CompactRailItem(
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
      // Stack: non-positioned child (AnimatedContainer) determines size;
      // Positioned left bar is overlaid at the left edge.
      child: Stack(
        children: [
          // ── Left edge accent bar ────────────────────────────────────
          // Positioned(top:0,bottom:0) fills the item's full height.
          // AnimatedOpacity fades it in/out; color is the item's accent.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 3,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 240),
              opacity: isSelected ? 1.0 : 0.0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      item.color,
                      item.color.withValues(alpha: 0.35),
                    ],
                  ),
                  borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(2)),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withValues(alpha: 0.75),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Item content ────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 230),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? item.color.withValues(alpha: isDark ? 0.13 : 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
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
                            ? Colors.white.withValues(alpha: 0.30)
                            : Colors.grey.shade500,
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
                    letterSpacing: 0.2,
                    fontFamily: 'Poppins',
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
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  EXTENDED RAIL  ─  tablets  (portrait + landscape)
//  Design: 216–240 dp wide sidebar with DUONET logo header, section labels,
//  labeled nav rows, and a per-item left-edge accent bar + gradient highlight.
// ═══════════════════════════════════════════════════════════════════════════════

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

  // First 4 items → "MAIN" section; rest → "MORE"
  static const _primaryEnd = 4;

  @override
  Widget build(BuildContext context) {
    final railW = context.isLargeTablet ? 240.0 : 216.0;
    final bg    = isDark ? AppColors.darkBg : AppColors.lightBg;
    final borderColor =
        isDark ? AppColors.darkElevated : AppColors.lightBorder;

    return Container(
      width: railW,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: isDark ? 0.30 : 0.04),
            blurRadius: 16,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Logo / brand header ──────────────────────────────────
            _RailHeader(isDark: isDark, onMenuTap: onMenuTap),

            // ── Divider ──────────────────────────────────────────────
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.lightBorder,
            ),
            const SizedBox(height: 6),

            // ── Nav list ─────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    vertical: 4, horizontal: 8),
                children: [
                  _SectionLabel(label: 'MAIN', isDark: isDark),
                  ...List.generate(_primaryEnd, (i) {
                    return _ExtendedRailItem(
                      item: items[i],
                      isSelected: i == selectedIndex,
                      isDark: isDark,
                      onTap: () => onTap(i),
                    );
                  }),
                  const SizedBox(height: 4),
                  _SectionLabel(label: 'MORE', isDark: isDark),
                  ...List.generate(items.length - _primaryEnd, (i) {
                    final idx = i + _primaryEnd;
                    return _ExtendedRailItem(
                      item: items[idx],
                      isSelected: idx == selectedIndex,
                      isDark: isDark,
                      onTap: () => onTap(idx),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Extended rail header ──────────────────────────────────────────────────────

class _RailHeader extends StatelessWidget {
  const _RailHeader({required this.isDark, required this.onMenuTap});
  final bool isDark;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 8, 14),
      child: Row(
        children: [
          // Logo circle
          Container(
            width: context.dp(34),
            height: context.dp(34),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.electricBlue, AppColors.teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.route_rounded,
                color: Colors.white, size: context.dp(18)),
          ),
          SizedBox(width: context.dp(10)),
          Expanded(
            child: Text(
              'DUONET',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.darkBg,
                fontSize: context.sp(15),
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          _RailMenuBtn(isDark: isDark, onTap: onMenuTap, small: true),
        ],
      ),
    );
  }
}

// ── Extended rail item ────────────────────────────────────────────────────────

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
    // Outer Padding provides vertical rhythm between items.
    // Stack: non-positioned InkWell/AnimatedContainer determines height;
    // Positioned left bar is overlaid at the left edge.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Stack(
        children: [
          // ── Left edge accent bar (same pattern as compact rail) ────
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 3,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 240),
              opacity: isSelected ? 1.0 : 0.0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      item.color,
                      item.color.withValues(alpha: 0.35),
                    ],
                  ),
                  borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(2)),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withValues(alpha: 0.65),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Tappable row ───────────────────────────────────────────
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(13),
            splashColor: item.color.withValues(alpha: 0.10),
            highlightColor: item.color.withValues(alpha: 0.06),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                  horizontal: context.dp(12),
                  vertical: context.dp(11)),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          item.color.withValues(
                              alpha: isDark ? 0.18 : 0.10),
                          item.color.withValues(
                              alpha: isDark ? 0.05 : 0.03),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(13),
                border: isSelected
                    ? Border.all(
                        color: item.color.withValues(alpha: 0.22),
                        width: 1)
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
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? item.color
                            : isDark
                                ? Colors.white.withValues(alpha: 0.55)
                                : Colors.grey.shade600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  // Active dot indicator
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 240),
                    opacity: isSelected ? 1.0 : 0.0,
                    child: Container(
                      width: context.dp(7),
                      height: context.dp(7),
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.55),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared section label ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: context.sp(9.5),
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white24 : Colors.grey.shade400,
          letterSpacing: 2.0,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

// ─── Shared hamburger / menu button ──────────────────────────────────────────

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