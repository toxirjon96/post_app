import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constant/theme_config.dart';
import '../provider/theme_provider.dart';
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

  // Close the floating drawer whenever the layout switches to the
  // always-visible panel mode (landscape or tablet).  Both share the same
  // _scaffoldKey, so ScaffoldState — and its drawer-open flag — persists
  // across orientation changes.  Without this, the portrait drawer remains
  // as an overlay on top of the landscape panel.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final isTablet =
        MediaQuery.sizeOf(context).shortestSide >= 600;
    if (isLandscape || isTablet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            (_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
          _scaffoldKey.currentState?.closeDrawer();
        }
      });
    }
  }

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
    final isLandscape = context.isLandscape;
    final isTablet   = context.isTablet;

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

  // ── Landscape phone / tablet ─ always-visible side panel + curved nav ─────
  //
  //  Layout:
  //
  //    ┌─────────────┬──────────────────────────────┐
  //    │             │                              │
  //    │  Side panel │        Page content          │
  //    │ (drawer     │                              │
  //    │  items)     ├──────────────────────────────┤
  //    │             │    Curved bottom nav bar     │
  //    └─────────────┴──────────────────────────────┘
  //
  //  The curved nav spans only the content column so the panel keeps full
  //  height, maximising the visible item count in landscape.

  Widget _buildLandscapeLayout(
      BuildContext context, int idx, bool isDark, bool isTablet) {
    final panelW = isTablet
        ? (context.isLargeTablet ? 300.0 : 280.0)
        : 200.0;

    return Scaffold(
      key: _scaffoldKey,
      body: Row(
        children: [
          _LandscapePanel(
            isDark: isDark,
            isCompact: !isTablet,
            width: panelW,
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(child: widget.child),
                _CurvedBottomNav(
                  selectedIndex: idx,
                  isDark: isDark,
                  onTap: (i) => context.go(_routes[i]),
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
//  CURVED BOTTOM NAV  ─  used in both portrait phones AND landscape layouts
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
//  LANDSCAPE SIDE PANEL
//
//  Always-visible drawer content in landscape / tablet layouts.
//
//  Compact (200 dp) — landscape phones:
//    Mini gradient profile row, flat scrollable item list, sign-out footer.
//    All drawer sections are flattened (no expand/collapse) so every item is
//    reachable without tapping — critical on a short landscape screen.
//
//  Full (280–300 dp) — tablets:
//    Rich gradient header (DUONET logo + avatar + user info + status pill),
//    expandable sections identical to the floating drawer, sign-out footer.
// ═══════════════════════════════════════════════════════════════════════════════

class _LandscapePanel extends ConsumerStatefulWidget {
  const _LandscapePanel({
    required this.isDark,
    required this.isCompact,
    required this.width,
  });

  final bool isDark;
  final bool isCompact;
  final double width;

  @override
  ConsumerState<_LandscapePanel> createState() => _LandscapePanelState();
}

class _LandscapePanelState extends ConsumerState<_LandscapePanel> {
  // Sections open by default in the full tablet panel
  final Set<String> _expanded = {'fleet', 'settings'};

  void _toggle(String id) => setState(() {
    _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id);
  });

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark
        ? const Color(0xFF07091A)
        : const Color(0xFFF8FAFF);
    final borderColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : AppColors.lightBorder;

    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: widget.isDark ? 0.28 : 0.06),
            blurRadius: 16,
            offset: const Offset(3, 0),
          ),
        ],
      ),
      child: SafeArea(
        right: false,
        child: widget.isCompact
            ? _buildCompact(context)
            : _buildFull(context),
      ),
    );
  }

  // ── Compact panel (landscape phones) ──────────────────────────────────────

  Widget _buildCompact(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final d = widget.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CompactProfileHeader(isDark: d),
        Divider(
          height: 1,
          color: d ? Colors.white12 : Colors.grey.shade200,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 6),
            children: [
              _PSectionLabel('WORKSPACE', isDark: d),
              _CompactItem(icon: Icons.person_outline_rounded,      label: 'My Profile',      color: AppColors.electricBlue, isDark: d, onTap: () {}),
              _CompactItem(icon: Icons.group_outlined,              label: 'Team Members',    color: AppColors.electricBlue, isDark: d, badge: '12', onTap: () {}),
              _CompactItem(icon: Icons.timeline_rounded,            label: 'My Activity',     color: AppColors.electricBlue, isDark: d, onTap: () {}),
              _PSectionLabel('FLEET', isDark: d),
              _CompactItem(icon: Icons.commute_rounded,             label: 'Active Vehicles', color: AppColors.amber,        isDark: d, badge: '24', onTap: () {}),
              _CompactItem(icon: Icons.route_rounded,               label: 'Routes',          color: AppColors.amber,        isDark: d, onTap: () {}),
              _CompactItem(icon: Icons.build_outlined,              label: 'Maintenance',     color: AppColors.coral,        isDark: d, badge: '3',  onTap: () {}),
              _CompactItem(icon: Icons.local_gas_station_outlined,  label: 'Fuel Logs',       color: AppColors.amber,        isDark: d, onTap: () {}),
              _PSectionLabel('REPORTS', isDark: d),
              _CompactItem(icon: Icons.dashboard_outlined,          label: 'Dashboard',       color: AppColors.purple,       isDark: d, onTap: () {}),
              _CompactItem(icon: Icons.description_outlined,        label: 'Reports',         color: AppColors.purple,       isDark: d, onTap: () {}),
              _CompactItem(icon: Icons.file_download_outlined,      label: 'Export',          color: AppColors.purple,       isDark: d, onTap: () {}),
              _PSectionLabel('SETTINGS', isDark: d),
              _CompactThemeToggle(isDark: d, themeMode: themeMode,
                onChanged: (v) => ref.read(themeModeProvider.notifier).state =
                    v ? ThemeMode.dark : ThemeMode.light),
              _CompactItem(icon: Icons.translate_rounded,           label: 'Language',        color: AppColors.electricBlue, isDark: d, onTap: () {}),
              _CompactItem(icon: Icons.notifications_outlined,      label: 'Notifications',   color: AppColors.teal,         isDark: d, onTap: () {}),
              _CompactItem(icon: Icons.lock_outline_rounded,        label: 'Security',        color: AppColors.coral,        isDark: d, onTap: () {}),
              _PSectionLabel('ABOUT', isDark: d),
              _CompactItem(icon: Icons.menu_book_outlined,          label: 'Docs',            color: AppColors.emerald,      isDark: d, onTap: () {}),
              _CompactItem(icon: Icons.support_agent_outlined,      label: 'Support',         color: AppColors.emerald,      isDark: d, onTap: () {}),
              _CompactItem(icon: Icons.new_releases_outlined,       label: 'v1.0.0',          color: Colors.grey,            isDark: d, onTap: () {}),
              const SizedBox(height: 4),
            ],
          ),
        ),
        _PanelSignOut(isDark: d, compact: true),
      ],
    );
  }

  // ── Full panel (tablets) ───────────────────────────────────────────────────

  Widget _buildFull(BuildContext context) {
    final themeMode    = ref.watch(themeModeProvider);
    final d            = widget.isDark;
    final textColor    = d ? Colors.white             : const Color(0xFF0F1629);
    final subtextColor = d ? Colors.white54           : Colors.grey.shade600;

    return Column(
      children: [
        _FullProfileHeader(isDark: d),
        Container(
          height: 1,
          color: d
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.lightBorder,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            children: [
              // ─ Workspace ──────────────────────────────────────────
              _PSectionLabel('MY WORKSPACE', isDark: d, full: true),
              _FullMenuItem(
                icon: Icons.person_outline_rounded,
                label: 'My Profile',
                subtitle: 'Edit personal info',
                isDark: d,
                textColor: textColor,
                subtextColor: subtextColor,
                onTap: () {},
              ),
              _FullMenuItem(
                icon: Icons.group_outlined,
                label: 'Team Members',
                subtitle: '12 active members',
                badge: '12',
                badgeColor: AppColors.electricBlue,
                isDark: d,
                textColor: textColor,
                subtextColor: subtextColor,
                onTap: () {},
              ),
              _FullMenuItem(
                icon: Icons.timeline_rounded,
                label: 'My Activity',
                subtitle: 'Recent actions log',
                isDark: d,
                textColor: textColor,
                subtextColor: subtextColor,
                onTap: () {},
              ),
              const SizedBox(height: 4),

              // ─ Fleet Management ────────────────────────────────────
              _FullExpandable(
                id: 'fleet',
                icon: Icons.directions_car_outlined,
                label: 'Fleet Management',
                color: AppColors.amber,
                isDark: d,
                isOpen: _expanded.contains('fleet'),
                onToggle: () => _toggle('fleet'),
                children: [
                  _FullSubItem(icon: Icons.commute_rounded,            label: 'Active Vehicles',  count: '24', color: AppColors.amber,          isDark: d, onTap: () {}),
                  _FullSubItem(icon: Icons.route_rounded,              label: 'Manage Routes',              color: AppColors.amber,          isDark: d, onTap: () {}),
                  _FullSubItem(icon: Icons.build_outlined,             label: 'Maintenance',      count: '3',  color: AppColors.coral,          isDark: d, onTap: () {}),
                  _FullSubItem(icon: Icons.local_gas_station_outlined, label: 'Fuel Logs',                  color: AppColors.amber,          isDark: d, onTap: () {}),
                ],
              ),

              // ─ Reports & Analytics ─────────────────────────────────
              _FullExpandable(
                id: 'analytics',
                icon: Icons.bar_chart_rounded,
                label: 'Reports & Analytics',
                color: AppColors.purple,
                isDark: d,
                isOpen: _expanded.contains('analytics'),
                onToggle: () => _toggle('analytics'),
                children: [
                  _FullSubItem(icon: Icons.dashboard_outlined,     label: 'Live Dashboard',  color: AppColors.purple, isDark: d, onTap: () {}),
                  _FullSubItem(icon: Icons.description_outlined,   label: 'Generate Report', color: AppColors.purple, isDark: d, onTap: () {}),
                  _FullSubItem(icon: Icons.file_download_outlined, label: 'Export Data',     color: AppColors.purple, isDark: d, onTap: () {}),
                ],
              ),

              // ─ Settings ───────────────────────────────────────────
              _FullExpandable(
                id: 'settings',
                icon: Icons.settings_outlined,
                label: 'Settings',
                color: AppColors.electricBlue,
                isDark: d,
                isOpen: _expanded.contains('settings'),
                onToggle: () => _toggle('settings'),
                children: [
                  _FullThemeSubItem(
                    isDark: d,
                    themeMode: themeMode,
                    onChanged: (v) =>
                        ref.read(themeModeProvider.notifier).state =
                            v ? ThemeMode.dark : ThemeMode.light,
                  ),
                  _FullSubItem(icon: Icons.translate_rounded,      label: 'Language',           color: AppColors.electricBlue, isDark: d, onTap: () {}),
                  _FullSubItem(icon: Icons.notifications_outlined, label: 'Notifications',      color: AppColors.teal,         isDark: d, onTap: () {}),
                  _FullSubItem(icon: Icons.lock_outline_rounded,   label: 'Security & Privacy', color: AppColors.coral,        isDark: d, onTap: () {}),
                ],
              ),

              // ─ About ──────────────────────────────────────────────
              _FullExpandable(
                id: 'about',
                icon: Icons.info_outline_rounded,
                label: 'About DUONET',
                color: AppColors.emerald,
                isDark: d,
                isOpen: _expanded.contains('about'),
                onToggle: () => _toggle('about'),
                children: [
                  _FullSubItem(icon: Icons.menu_book_outlined,     label: 'Documentation',       color: AppColors.emerald, isDark: d, onTap: () {}),
                  _FullSubItem(icon: Icons.support_agent_outlined, label: 'Contact Support',     color: AppColors.emerald, isDark: d, onTap: () {}),
                  _FullSubItem(icon: Icons.new_releases_outlined,  label: 'v1.0.0 · Changelog',  color: Colors.grey,       isDark: d, onTap: () {}),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
        _PanelSignOut(isDark: d, compact: false),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  COMPACT PANEL SUB-WIDGETS  (landscape phones, 200 dp panel)
// ═══════════════════════════════════════════════════════════════════════════════

// ── Compact profile header (avatar row + status pill) ─────────────────────────

class _CompactProfileHeader extends StatelessWidget {
  const _CompactProfileHeader({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0A0E20), const Color(0xFF0F1629)]
              : [const Color(0xFF1565C0), const Color(0xFF1B8EF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Avatar with online dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [AppColors.electricBlue, AppColors.teal])
                      : null,
                  color: isDark ? null : Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35), width: 2),
                ),
                child: const Center(
                  child: Text('U1',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins')),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D68F),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isDark
                            ? const Color(0xFF0A0E20)
                            : const Color(0xFF1565C0),
                        width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('User1',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins'),
                    maxLines: 1),
                Text('Fleet Manager',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 10,
                        fontFamily: 'Poppins'),
                    maxLines: 1),
              ],
            ),
          ),
          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                      color: Color(0xFF00D68F), shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                const Text('On',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Panel section label ────────────────────────────────────────────────────────

class _PSectionLabel extends StatelessWidget {
  const _PSectionLabel(this.label, {required this.isDark, this.full = false});
  final String label;
  final bool isDark;
  final bool full;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(full ? 20 : 11, 8, 11, 3),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white24 : Colors.grey.shade400,
          letterSpacing: 1.8,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

// ── Compact flat item ──────────────────────────────────────────────────────────
// Icon (15 dp) + label + optional badge chip.  Row height ~34 dp.

class _CompactItem extends StatelessWidget {
  const _CompactItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.08),
        highlightColor: color.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 15, color: color.withValues(alpha: 0.85)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(badge!,
                      style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Compact theme toggle ───────────────────────────────────────────────────────

class _CompactThemeToggle extends StatelessWidget {
  const _CompactThemeToggle({
    required this.isDark,
    required this.themeMode,
    required this.onChanged,
  });

  final bool isDark;
  final ThemeMode themeMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final on = themeMode == ThemeMode.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      child: Row(
        children: [
          Icon(
            on ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            size: 15,
            color: on ? AppColors.electricBlue : AppColors.amber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              on ? 'Dark Mode' : 'Light Mode',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Transform.scale(
            scale: 0.68,
            alignment: Alignment.centerRight,
            child: Switch(
              value: on,
              onChanged: onChanged,
              activeThumbColor: AppColors.electricBlue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  FULL PANEL SUB-WIDGETS  (tablets, 280–300 dp panel)
// ═══════════════════════════════════════════════════════════════════════════════

// ── Full profile header ────────────────────────────────────────────────────────
// DUONET logo row + avatar + user details + status pill.
// No close button — the panel is permanently docked, not a modal overlay.

class _FullProfileHeader extends StatelessWidget {
  const _FullProfileHeader({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
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
          // DUONET logo row
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.electricBlue, AppColors.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.route_rounded,
                    color: Colors.white, size: 13),
              ),
              const SizedBox(width: 8),
              const Text(
                'DUONET',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Avatar + user info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? const LinearGradient(
                              colors: [AppColors.electricBlue, AppColors.teal])
                          : null,
                      color: isDark
                          ? null
                          : Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 2),
                    ),
                    child: const Center(
                      child: Text('U1',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Poppins')),
                    ),
                  ),
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 12,
                      height: 12,
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
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('User1',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins')),
                    const SizedBox(height: 1),
                    Text('Fleet Manager · DUONET',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.70),
                            fontSize: 11,
                            fontFamily: 'Poppins')),
                    Text('user1@duonet.io',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.48),
                            fontSize: 10,
                            fontFamily: 'Poppins')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Status pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFF00D68F), shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                const Text('Available',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Full menu item (workspace section) ────────────────────────────────────────

class _FullMenuItem extends StatelessWidget {
  const _FullMenuItem({
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 17,
                    color: isDark ? Colors.white60 : Colors.grey.shade600),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: textColor,
                            fontSize: context.sp(13),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins')),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: TextStyle(
                              color: subtextColor,
                              fontSize: context.sp(11),
                              height: 1.4,
                              fontFamily: 'Poppins')),
                  ],
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? AppColors.electricBlue)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(badge!,
                      style: TextStyle(
                          color: badgeColor ?? AppColors.electricBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins')),
                ),
                const SizedBox(width: 4),
              ],
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

// ── Full expandable section ────────────────────────────────────────────────────
// Tap header to expand / collapse.  Left-edge coloured border on expanded body.

class _FullExpandable extends StatelessWidget {
  const _FullExpandable({
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.15 : 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.22)),
                    ),
                    child: Icon(icon, size: 17, color: color),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F1629),
                        fontSize: context.sp(13),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: isDark ? Colors.white38 : Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 240),
          crossFadeState:
              isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin:
                const EdgeInsets.only(left: 16, right: 10, bottom: 6),
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
                left: BorderSide(
                    color: color.withValues(alpha: 0.35), width: 2),
              ),
            ),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

// ── Full sub-item ──────────────────────────────────────────────────────────────

class _FullSubItem extends StatelessWidget {
  const _FullSubItem({
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            children: [
              Icon(icon, size: 15, color: color.withValues(alpha: 0.80)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color:
                        isDark ? Colors.white70 : Colors.grey.shade700,
                    fontSize: context.sp(12.5),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
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
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins')),
                ),
                const SizedBox(width: 4),
              ],
              Icon(Icons.chevron_right_rounded,
                  size: 14,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Full theme toggle sub-item ─────────────────────────────────────────────────

class _FullThemeSubItem extends StatelessWidget {
  const _FullThemeSubItem({
    required this.isDark,
    required this.themeMode,
    required this.onChanged,
  });

  final bool isDark;
  final ThemeMode themeMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final on = themeMode == ThemeMode.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Icon(
            on ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            size: 15,
            color: on ? AppColors.electricBlue : AppColors.amber,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              on ? 'Dark Mode' : 'Light Mode',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade700,
                fontSize: context.sp(12.5),
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Transform.scale(
            scale: 0.82,
            child: Switch(
              value: on,
              onChanged: onChanged,
              activeThumbColor: AppColors.electricBlue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SHARED PANEL FOOTER  ─  Sign-Out button
// ═══════════════════════════════════════════════════════════════════════════════

class _PanelSignOut extends StatelessWidget {
  const _PanelSignOut({required this.isDark, required this.compact});
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 16,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
      ),
      child: GestureDetector(
        onTap: () => context.go('/login'),
        child: Container(
          height: compact ? 38 : 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFF4D6A)
                .withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFFFF4D6A).withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded,
                  color: const Color(0xFFFF4D6A),
                  size: compact ? 14 : 17),
              const SizedBox(width: 7),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: const Color(0xFFFF4D6A),
                  fontSize: compact ? 12 : 13.5,
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