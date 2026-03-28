import 'package:curved_navigation_bar/curved_navigation_bar.dart';
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
    final idx       = _selectedIndex(context);
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final isTablet  = MediaQuery.sizeOf(context).shortestSide >= 600;

    return ScaffoldKeyScope(
      scaffoldKey: _scaffoldKey,
      child: (isLandscape || isTablet)
          ? _buildRailLayout(context, idx, isDark, isTablet)
          : _buildPortraitLayout(context, idx, isDark),
    );
  }

  // ── Portrait phone ─ curved bottom nav ───────────────────────────────────

  Widget _buildPortraitLayout(
      BuildContext context, int idx, bool isDark) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawerWidget(),
      body: widget.child,
      bottomNavigationBar: _CurvedBottomNav(
        selectedIndex: idx,
        isDark: isDark,
        onTap: (i) => context.go(_routes[i]),
      ),
    );
  }

  // ── Landscape phone / tablet ─ side rail ──────────────────────────────────

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
//  CURVED BOTTOM NAV  ─  portrait phones
//
//  Design strategy with curved_navigation_bar 1.0.6:
//
//  • backgroundColor  = scaffold background  →  the bump's surround blends
//    seamlessly into the page; no visible "gap" between body and bar.
//  • color            = slightly elevated surface (darkCard / lightSurface)
//    →  the bar visually "lifts" from the background.
//  • buttonBackgroundColor  = current tab's accent colour, driven by a
//    TweenAnimationBuilder<Color?> so the bump cross-fades when you switch
//    tabs (e.g. electricBlue → amber in ~380 ms).
//  • Items array is rebuilt on every selectedIndex change:
//      – active   → filled icon, size 24, white  (shown in the accent bump)
//      – inactive → outlined icon, size 19, low-opacity  (shown in the bar)
//    The per-tab Column(Icon + micro-label) gives each item a name even on
//    a compact 360 dp phone (8 items × ~45 dp each).
//  • A Container with an upward box-shadow wraps the CurvedNavigationBar to
//    produce an accent-colored glow above the bar that shifts hue per tab.
//  • A SafeArea fill at the very bottom extends the bar color to the device
//    home-indicator region so the bar never looks "cut off".
// ═══════════════════════════════════════════════════════════════════════════════

class _CurvedBottomNav extends StatelessWidget {
  const _CurvedBottomNav({
    required this.selectedIndex,
    required this.isDark,
    required this.onTap,
  });

  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  // Bar dimensions – chosen so 8 items × ~45 dp each comfortably fits
  // icon (18 dp) + 2 dp gap + label (7 dp) inside a 62 dp tall bar.
  static const double _barHeight    = 62.0;
  static const double _iconPad      = 10.0; // bump circle inner padding
  static const double _activeSize   = 24.0;
  static const double _inactiveSize = 18.0;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final accent      = _navItems[selectedIndex].color;

    // Scaffold background — must match CurvedNavigationBar.backgroundColor
    // so the bump area blends into the page perfectly.
    final scaffoldBg  = isDark ? AppColors.darkBg    : AppColors.lightBg;
    final barSurface  = isDark ? AppColors.darkCard   : AppColors.lightSurface;
    final inactiveCol = isDark
        ? Colors.white.withValues(alpha: 0.38)
        : Colors.grey.shade600;

    return TweenAnimationBuilder<Color?>(
      // Animate the bump background color as tabs change.
      tween: ColorTween(end: accent),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (ctx, animColor, child) {
        final bumpColor = animColor ?? accent;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Thin accent rule above the bar ──────────────────────
            // A full-width gradient line; fades at the edges so it
            // looks like a center glow rather than a hard line.
            AnimatedContainer(
              duration: const Duration(milliseconds: 380),
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    bumpColor.withValues(alpha: isDark ? 0.70 : 0.50),
                    bumpColor.withValues(alpha: isDark ? 0.70 : 0.50),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.15, 0.85, 1.0],
                ),
              ),
            ),

            // ── Accent glow + curved nav ─────────────────────────────
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  // Accent colour glow radiates upward from the bar.
                  BoxShadow(
                    color: bumpColor
                        .withValues(alpha: isDark ? 0.30 : 0.18),
                    blurRadius: 26,
                    spreadRadius: 0,
                    offset: const Offset(0, -6),
                  ),
                  // Depth shadow beneath the bar.
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.50 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CurvedNavigationBar(
                // Matches scaffold background → bump area is invisible.
                backgroundColor: scaffoldBg,
                // The bar itself is slightly elevated from the background.
                color: barSurface,
                // Animated accent hue per selected tab.
                buttonBackgroundColor: bumpColor,
                animationCurve: Curves.easeInOutCubic,
                animationDuration: const Duration(milliseconds: 400),
                height: _barHeight,
                index: selectedIndex,
                // Rebuild items on each selectedIndex change so:
                //   active   → filled icon, white (inside the accent bump)
                //   inactive → outlined icon + tiny label, low-opacity
                items: List.generate(_navItems.length, (i) {
                  final active = i == selectedIndex;
                  if (active) {
                    return Icon(
                      _navItems[i].activeIcon,
                      size: _activeSize,
                      color: Colors.white,
                    );
                  }
                  return _InactiveNavItem(
                    item: _navItems[i],
                    color: inactiveCol,
                    iconSize: _inactiveSize,
                  );
                }),
                onTap: onTap,
              ),
            ),

            // ── Safe-area fill ───────────────────────────────────────
            // Extends bar color to the home-indicator region so the
            // bar never appears "cut off" on notched / gesture phones.
            if (bottomInset > 0)
              Container(
                height: bottomInset,
                color: barSurface,
              ),
          ],
        );
      },
    );
  }
}

// ── Inactive nav item: outlined icon + micro-label ────────────────────────────
// Using a Column so each of the 8 items is identifiable even on a narrow phone.
// Font size 7 dp is readable but doesn't compete with the active bump.

class _InactiveNavItem extends StatelessWidget {
  const _InactiveNavItem({
    required this.item,
    required this.color,
    required this.iconSize,
  });

  final _NavItem item;
  final Color color;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(item.icon, size: iconSize, color: color),
        const SizedBox(height: 2),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.clip,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.2,
            fontFamily: 'Poppins',
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  COMPACT RAIL  ─  landscape phones  (64 dp wide)
//  Per-item left-edge accent bar (Positioned, fades with AnimatedOpacity).
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
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
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
      // Stack: the non-positioned AnimatedContainer determines height;
      // the Positioned bar is overlaid at the left edge at full height.
      child: Stack(
        children: [
          // ── Left-edge accent bar ────────────────────────────────────
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
//  EXTENDED RAIL  ─  tablets  (portrait + landscape)  216–240 dp wide
//  DUONET logo header, MAIN / MORE section groups, per-item left-edge bar.
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

  static const _primaryEnd = 4;

  @override
  Widget build(BuildContext context) {
    final railW       = context.isLargeTablet ? 240.0 : 216.0;
    final bg          = isDark ? AppColors.darkBg    : AppColors.lightBg;
    final borderColor = isDark ? AppColors.darkElevated : AppColors.lightBorder;

    return Container(
      width: railW,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
            blurRadius: 16,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── DUONET brand header ───────────────────────────────────
            _RailHeader(isDark: isDark, onMenuTap: onMenuTap),
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
                  ...List.generate(_primaryEnd, (i) => _ExtendedRailItem(
                    item: items[i],
                    isSelected: i == selectedIndex,
                    isDark: isDark,
                    onTap: () => onTap(i),
                  )),
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

// ── Extended rail header (logo + hamburger) ───────────────────────────────────

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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Stack(
        children: [
          // ── Left-edge accent bar ────────────────────────────────────
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
                  // Glowing active dot
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

// ─── Shared hamburger button ──────────────────────────────────────────────────

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