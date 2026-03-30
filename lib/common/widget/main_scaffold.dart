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
  // Portrait gets the keyed Scaffold that carries the AppDrawer.
  // Landscape uses a separate key so portrait ScaffoldState (including any
  // open drawer) is fully disposed when the layout switches — no bleeds.
  final _scaffoldKey  = GlobalKey<ScaffoldState>(); // portrait
  final _landscapeKey = GlobalKey<ScaffoldState>(); // landscape / tablet

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

    return ScaffoldKeyScope(
      scaffoldKey: _scaffoldKey,
      child: (isLandscape || isTablet)
          ? _buildLandscapeLayout(context, idx, isDark, isTablet)
          : _buildPortraitLayout(context, idx, isDark),
    );
  }

  // ── Portrait phone ─ curved bottom nav + floating drawer ──────────────────

  Widget _buildPortraitLayout(BuildContext context, int idx, bool isDark) {
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

  // ── Landscape phone / tablet ─ nav rail + full-height content ─────────────
  //
  //  Layout:
  //
  //    ┌──────────┬──────────────────────────────────────┐
  //    │  Nav     │                                      │
  //    │  Rail    │           Page content               │
  //    │ (icons + │           (full height)              │
  //    │  labels) │                                      │
  //    └──────────┴──────────────────────────────────────┘
  //
  //  The nav rail is ONLY navigation items — completely separate from the
  //  drawer.  The AppDrawer slides in from the left when the menu button at
  //  the top of the rail is tapped, and starts closed on every fresh
  //  landscape session (separate _landscapeKey → clean ScaffoldState).

  Widget _buildLandscapeLayout(
      BuildContext context, int idx, bool isDark, bool isTablet) {
    final railW = isTablet ? 80.0 : 72.0;

    return Scaffold(
      key: _landscapeKey,              // separate key → portrait drawer never bleeds
      drawer: const AppDrawerWidget(), // starts closed; opened via rail menu button
      body: Row(
        children: [
          _LandscapeNavRail(
            isDark: isDark,
            width: railW,
            selectedIndex: idx,
            onNavTap: (i) => context.go(_routes[i]),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CURVED BOTTOM NAV  ─  portrait phones only
//
//  Design strategy:
//  • backgroundColor  = scaffold background → bump blends into the page.
//  • color            = elevated surface (darkCard / lightSurface).
//  • buttonBackgroundColor  = current tab's accent, animated via
//    TweenAnimationBuilder<Color?> so the bump cross-fades on tab switch.
//  • active item  → filled icon, white, inside the accent bump.
//  • inactive item → outlined icon + 7 dp micro-label, low-opacity.
//  • Accent gradient rule above the bar + glow shadow below.
//  • SafeArea fill extends the bar color to the home-indicator region.
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

  static const double _barHeight    = 62.0;
  static const double _activeSize   = 24.0;
  static const double _inactiveSize = 18.0;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final accent      = _navItems[selectedIndex].color;

    final scaffoldBg  = isDark ? AppColors.darkBg    : AppColors.lightBg;
    final barSurface  = isDark ? AppColors.darkCard   : AppColors.lightSurface;
    final inactiveCol = isDark
        ? Colors.white.withValues(alpha: 0.38)
        : Colors.grey.shade600;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: accent),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (ctx, animColor, child) {
        final bumpColor = animColor ?? accent;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Thin accent rule above the bar ──────────────────────
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
                  BoxShadow(
                    color: bumpColor.withValues(alpha: isDark ? 0.30 : 0.18),
                    blurRadius: 26,
                    spreadRadius: 0,
                    offset: const Offset(0, -6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.08),
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
                height: _barHeight,
                index: selectedIndex,
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
//  LANDSCAPE NAV RAIL
//
//  Narrow always-visible vertical strip in landscape / tablet layouts.
//  Contains ONLY the 8 navigation destinations — completely separate from
//  the AppDrawer.
//
//  Structure:
//    ┌──────────────────┐
//    │  Gradient header │  ← DUONET logo icon + hamburger to open AppDrawer
//    ├──────────────────┤
//    │  Posts      ◄    │  ← active: 3 dp left accent bar + tinted bg
//    │  Address         │  ← inactive: muted icon + muted label
//    │  Car             │
//    │  Face ID         │
//    │  Hotels          │
//    │  Orgs            │
//    │  Favs            │
//    │  Map             │
//    └──────────────────┘
//
//  Width: 72 dp (phones) / 80 dp (tablets)
// ═══════════════════════════════════════════════════════════════════════════════

class _LandscapeNavRail extends StatelessWidget {
  const _LandscapeNavRail({
    required this.isDark,
    required this.width,
    required this.selectedIndex,
    required this.onNavTap,
  });

  final bool isDark;
  final double width;
  final int selectedIndex;
  final ValueChanged<int> onNavTap;

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? const Color(0xFF07091A)
        : const Color(0xFFF8FAFF);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : AppColors.lightBorder;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 16,
            offset: const Offset(3, 0),
          ),
        ],
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            _NavRailHeader(isDark: isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: List.generate(
                    _navItems.length,
                    (i) => _NavRailItem(
                      item: _navItems[i],
                      isActive: i == selectedIndex,
                      isDark: isDark,
                      onTap: () => onNavTap(i),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nav rail header ── gradient + DUONET icon + menu button ───────────────────

class _NavRailHeader extends StatelessWidget {
  const _NavRailHeader({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0A0E20), const Color(0xFF0F1629)]
              : [const Color(0xFF1565C0), const Color(0xFF1B8EF8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // DUONET logo circle
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.electricBlue, AppColors.teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.route_rounded, color: Colors.white, size: 14),
          ),
          const SizedBox(height: 8),
          // Hamburger — opens the AppDrawer overlay
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Scaffold.of(context).openDrawer(),
              borderRadius: BorderRadius.circular(8),
              splashColor: Colors.white12,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.menu_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nav rail item ── icon (top) + micro-label (bottom) ────────────────────────
//
//  Active:   3 dp left accent border + tinted bg + filled icon + bold label
//  Inactive: transparent bg, muted icon + muted label

class _NavRailItem extends StatelessWidget {
  const _NavRailItem({
    required this.item,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent      = item.color;
    final activeBg    = accent.withValues(alpha: isDark ? 0.14 : 0.10);
    final activeText  = isDark ? Colors.white   : const Color(0xFF0F1629);
    final inactiveCol = isDark ? Colors.white38 : Colors.grey.shade500;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withValues(alpha: 0.10),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? activeBg : null,
            // Reserve 3 dp on the left always so icons stay pixel-aligned
            // when switching between active and inactive states.
            border: Border(
              left: BorderSide(
                color: isActive ? accent : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                size: 20,
                color: isActive ? accent : inactiveCol,
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive ? activeText : inactiveCol,
                  fontSize: 8.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontFamily: 'Poppins',
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}