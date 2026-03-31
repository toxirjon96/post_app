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
//
//  Both portrait and landscape use:
//    • AppDrawerWidget  — slides in ONLY when user taps the menu button
//                         (drawerEnableOpenDragGesture: false ensures it stays
//                          closed until explicitly opened)
//    • CurvedNavigationBar  — bottom bar; compact height in landscape to
//                             preserve vertical content space
//
//  ScaffoldKeyScope always carries the key of the ACTIVE Scaffold so that
//  child pages can call openDrawer() via the correct ScaffoldState regardless
//  of orientation.

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key, required this.child});
  final Widget child;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  // Separate keys prevent ScaffoldState (including open-drawer flag) from
  // bleeding across an orientation change.
  final _portraitKey  = GlobalKey<ScaffoldState>();
  final _landscapeKey = GlobalKey<ScaffoldState>();

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _routes.length; i++) {
      if (path.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx         = _selectedIndex(context);
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final isLandscape = context.isLandscape;
    final isTablet    = context.isTablet;
    final isWide      = isLandscape || isTablet;

    // Always pass the active layout's key so ScaffoldKeyScope consumers
    // (pages that call openDrawer via the inherited key) always target the
    // mounted Scaffold.
    final activeKey = isWide ? _landscapeKey : _portraitKey;

    return ScaffoldKeyScope(
      scaffoldKey: activeKey,
      child: isWide
          ? _buildWideLayout(context, idx, isDark, isTablet)
          : _buildPortraitLayout(context, idx, isDark),
    );
  }

  // ── Portrait phone ─────────────────────────────────────────────────────────
  //  • Drawer: closed by default, opens only via hamburger in the page AppBar
  //  • Bottom: full-height CurvedNavigationBar

  Widget _buildPortraitLayout(BuildContext context, int idx, bool isDark) {
    return Scaffold(
      key: _portraitKey,
      drawer: const AppDrawerWidget(),
      drawerEnableOpenDragGesture: false, // ← button-only open
      body: widget.child,
      bottomNavigationBar: _CurvedBottomNav(
        selectedIndex: idx,
        isDark: isDark,
        compact: false,
        onTap: (i) => context.go(_routes[i]),
      ),
    );
  }

  // ── Landscape phone / tablet ───────────────────────────────────────────────
  //  • Drawer: closed by default, opens only via hamburger in the page AppBar
  //  • Bottom: compact CurvedNavigationBar (shorter height on phones to
  //    preserve vertical space; normal height on tablets which have room)

  Widget _buildWideLayout(
      BuildContext context, int idx, bool isDark, bool isTablet) {
    return Scaffold(
      key: _landscapeKey,
      drawer: const AppDrawerWidget(),
      drawerEnableOpenDragGesture: false, // ← button-only open
      body: widget.child,
      bottomNavigationBar: _CurvedBottomNav(
        selectedIndex: idx,
        isDark: isDark,
        compact: !isTablet, // compact only on landscape phones
        onTap: (i) => context.go(_routes[i]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CURVED BOTTOM NAV  (portrait + landscape)
//
//  Design:
//  • backgroundColor  = scaffold background → bump blends into page
//  • color            = elevated surface (darkCard / white)
//  • buttonBackgroundColor = active tab accent, cross-fades via
//    TweenAnimationBuilder<Color?> on tab switch
//  • Active item  → filled icon, white, inside the accent bump
//  • Inactive item → outlined icon + micro-label, low-opacity
//  • Thin accent gradient rule above the bar
//  • Accent glow shadow below the page edge
//  • compact = true  → 52 dp bar, slightly smaller icons (landscape phones)
//  • compact = false → 62 dp bar, normal icons (portrait + tablets)
// ═══════════════════════════════════════════════════════════════════════════════

class _CurvedBottomNav extends StatelessWidget {
  const _CurvedBottomNav({
    required this.selectedIndex,
    required this.isDark,
    required this.compact,
    required this.onTap,
  });

  final int selectedIndex;
  final bool isDark;
  final bool compact;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final double barH        = compact ? 52.0 : 62.0;
    final double activeSize  = compact ? 21.0 : 24.0;
    final double inactiveSize = compact ? 16.0 : 18.0;

    final bottomInset = MediaQuery.of(context).padding.bottom;
    final accent      = _navItems[selectedIndex].color;

    final scaffoldBg  = isDark ? AppColors.darkBg   : AppColors.lightBg;
    final barSurface  = isDark ? AppColors.darkCard  : AppColors.lightSurface;
    final inactiveCol = isDark
        ? Colors.white.withValues(alpha: 0.38)
        : Colors.grey.shade600;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: accent),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (ctx, animColor, _) {
        final bumpColor = animColor ?? accent;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Thin accent rule above the bar ────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 380),
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    bumpColor.withValues(alpha: isDark ? 0.72 : 0.52),
                    bumpColor.withValues(alpha: isDark ? 0.72 : 0.52),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.15, 0.85, 1.0],
                ),
              ),
            ),

            // ── Glow shadow + curved nav ──────────────────────────────
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: bumpColor.withValues(alpha: isDark ? 0.32 : 0.20),
                    blurRadius: 28,
                    spreadRadius: 0,
                    offset: const Offset(0, -8),
                  ),
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.50 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CurvedNavigationBar(
                backgroundColor: scaffoldBg,
                color: barSurface,
                buttonBackgroundColor: bumpColor,
                animationCurve: Curves.easeInOutCubic,
                animationDuration: const Duration(milliseconds: 400),
                height: barH,
                index: selectedIndex,
                items: List.generate(_navItems.length, (i) {
                  if (i == selectedIndex) {
                    return Icon(
                      _navItems[i].activeIcon,
                      size: activeSize,
                      color: Colors.white,
                    );
                  }
                  return _InactiveNavItem(
                    item: _navItems[i],
                    color: inactiveCol,
                    iconSize: inactiveSize,
                    compact: compact,
                  );
                }),
                onTap: onTap,
              ),
            ),

            // ── System home-indicator fill ────────────────────────────
            if (bottomInset > 0)
              Container(height: bottomInset, color: barSurface),
          ],
        );
      },
    );
  }
}

// ── Inactive nav item: outlined icon + micro-label ────────────────────────────

class _InactiveNavItem extends StatelessWidget {
  const _InactiveNavItem({
    required this.item,
    required this.color,
    required this.iconSize,
    required this.compact,
  });

  final _NavItem item;
  final Color color;
  final double iconSize;
  final bool compact;

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
            fontSize: compact ? 6.5 : 7.0,
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