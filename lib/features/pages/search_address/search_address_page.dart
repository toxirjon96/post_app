import 'package:flutter/material.dart';

import '../../../common/util/responsive.dart';
import '../../../common/widget/scaffold_key_scope.dart';
import '../../workers/model/worker_model.dart';
import '../../workers/widget/worker_card.dart';

// ── Demo data ────────────────────────────────────────────────────────────────

const _kWorkers = [
  WorkerModel(
    id: 'WRK-001',
    fullName: 'Marco Rodriguez',
    position: 'Fleet Manager',
    department: 'Fleet Management',
    isOnline: true,
    phoneNumber: '+1 555-0142',
    address: '123 Harbor View Blvd, Dock 4',
    birthDate: '14.03.1985',
    checkInTime: '08:00',
    checkOutTime: '17:00',
  ),
  WorkerModel(
    id: 'WRK-002',
    fullName: 'Sarah Chen',
    position: 'Route Planner',
    department: 'Operations',
    isOnline: true,
    phoneNumber: '+1 555-0198',
    address: '456 Marina District, Suite 12',
    birthDate: '27.08.1990',
    checkInTime: '09:00',
    checkOutTime: '18:00',
  ),
  WorkerModel(
    id: 'WRK-003',
    fullName: 'James Wilson',
    position: 'Vehicle Inspector',
    department: 'Maintenance',
    isOnline: false,
    phoneNumber: '+1 555-0267',
    address: '789 Industrial Park, Bay 7',
    birthDate: '05.11.1982',
    checkInTime: '07:30',
    checkOutTime: '16:30',
  ),
  WorkerModel(
    id: 'WRK-004',
    fullName: 'Aisha Patel',
    position: 'Data Analyst',
    department: 'Analytics',
    isOnline: true,
    phoneNumber: '+1 555-0314',
    address: '321 Tech Hub Ave, Floor 3',
    birthDate: '19.06.1993',
    checkInTime: '10:00',
    checkOutTime: '19:00',
  ),
  WorkerModel(
    id: 'WRK-005',
    fullName: 'Carlos Mendez',
    position: 'Driver Lead',
    department: 'Transport',
    isOnline: false,
    phoneNumber: '+1 555-0456',
    address: '654 Gateway Blvd, Terminal B',
    birthDate: '30.01.1978',
    checkInTime: '06:00',
    checkOutTime: '15:00',
  ),
  WorkerModel(
    id: 'WRK-006',
    fullName: 'Emily Thompson',
    position: 'HR Specialist',
    department: 'Human Resources',
    isOnline: true,
    phoneNumber: '+1 555-0521',
    address: '987 Office Park Dr, Wing C',
    birthDate: '12.09.1988',
    checkInTime: '08:30',
    checkOutTime: '17:30',
  ),
  WorkerModel(
    id: 'WRK-007',
    fullName: 'Dmitri Volkov',
    position: 'Security Officer',
    department: 'Security',
    isOnline: false,
    phoneNumber: '+1 555-0673',
    address: '147 Guard Station Rd, Post 2',
    birthDate: '22.04.1980',
    checkInTime: '22:00',
    checkOutTime: '06:00',
  ),
  WorkerModel(
    id: 'WRK-008',
    fullName: 'Priya Nair',
    position: 'Software Engineer',
    department: 'IT',
    isOnline: true,
    phoneNumber: '+1 555-0789',
    address: '258 Tech Campus Way, Lab 5',
    birthDate: '03.12.1995',
    checkInTime: '09:00',
    checkOutTime: '18:00',
  ),
  WorkerModel(
    id: 'WRK-009',
    fullName: 'Tom Bradley',
    position: 'Logistics Coordinator',
    department: 'Logistics',
    isOnline: true,
    phoneNumber: '+1 555-0834',
    address: '369 Warehouse District, Unit 9',
    birthDate: '08.07.1986',
    checkInTime: '07:00',
    checkOutTime: '16:00',
  ),
  WorkerModel(
    id: 'WRK-010',
    fullName: 'Lisa Park',
    position: 'Fuel Supervisor',
    department: 'Fleet Management',
    isOnline: false,
    phoneNumber: '+1 555-0912',
    address: '741 Fuel Depot Lane, Station 3',
    birthDate: '16.02.1984',
    checkInTime: '06:30',
    checkOutTime: '15:30',
  ),
];

// ── Filter chip model ────────────────────────────────────────────────────────

enum _FilterType { all, online, offline, department }

class _Filter {
  const _Filter(this.label, this.type, {this.department});
  final String label;
  final _FilterType type;
  final String? department;
}

final _kFilters = [
  const _Filter('All', _FilterType.all),
  const _Filter('Online', _FilterType.online),
  const _Filter('Offline', _FilterType.offline),
  const _Filter('Fleet', _FilterType.department, department: 'Fleet Management'),
  const _Filter('Operations', _FilterType.department, department: 'Operations'),
  const _Filter('Maintenance', _FilterType.department, department: 'Maintenance'),
  const _Filter('Transport', _FilterType.department, department: 'Transport'),
  const _Filter('IT', _FilterType.department, department: 'IT'),
  const _Filter('Logistics', _FilterType.department, department: 'Logistics'),
];

// ── Page ─────────────────────────────────────────────────────────────────────

class SearchAddressPage extends StatefulWidget {
  const SearchAddressPage({super.key});

  @override
  State<SearchAddressPage> createState() => _SearchAddressPageState();
}

class _SearchAddressPageState extends State<SearchAddressPage> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchOpen = false;
  int _filterIndex = 0;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchCtrl.clear();
        _query = '';
        _searchFocus.unfocus();
      } else {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _searchFocus.requestFocus());
      }
    });
  }

  List<WorkerModel> get _filtered {
    final filter = _kFilters[_filterIndex];
    return _kWorkers.where((w) {
      final passFilter = switch (filter.type) {
        _FilterType.all => true,
        _FilterType.online => w.isOnline,
        _FilterType.offline => !w.isOnline,
        _FilterType.department => w.department == filter.department,
      };
      if (!passFilter) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return w.fullName.toLowerCase().contains(q) ||
          (w.position?.toLowerCase().contains(q) ?? false) ||
          (w.department?.toLowerCase().contains(q) ?? false) ||
          (w.address?.toLowerCase().contains(q) ?? false) ||
          (w.phoneNumber?.contains(q) ?? false);
    }).toList();
  }

  int _countFor(_Filter f) => _kWorkers.where((w) => switch (f.type) {
        _FilterType.all => true,
        _FilterType.online => w.isOnline,
        _FilterType.offline => !w.isOnline,
        _FilterType.department => w.department == f.department,
      }).length;

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 700));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final workers = _filtered;

    return Scaffold(
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          _FilterBar(
            filters: _kFilters,
            selectedIndex: _filterIndex,
            countFor: _countFor,
            isDark: isDark,
            onSelect: (i) => setState(() => _filterIndex = i),
          ),
          Expanded(
            child: workers.isEmpty
                ? _EmptyState(query: _query, isDark: isDark)
                : _WorkerList(
                    workers: workers,
                    isTablet: isTablet,
                    isLandscape: isLandscape,
                    onRefresh: _handleRefresh,
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final bgColor = isDark ? const Color(0xFF0A0E1F) : Colors.white;

    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        onPressed: () =>
            ScaffoldKeyScope.of(context).currentState?.openDrawer(),
      ),
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(
                    begin: const Offset(0.08, 0), end: Offset.zero)
                .animate(anim),
            child: child,
          ),
        ),
        child: _searchOpen
            ? TextField(
                key: const ValueKey('search_field'),
                controller: _searchCtrl,
                focusNode: _searchFocus,
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(
                  fontSize: isTablet ? 16 : 15,
                  color: isDark ? Colors.white : const Color(0xFF0F1629),
                ),
                decoration: InputDecoration(
                  hintText: 'Search workers...',
                  hintStyle: TextStyle(
                    color:
                        isDark ? Colors.white38 : Colors.grey.shade400,
                    fontSize: isTablet ? 16 : 15,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                cursorColor: const Color(0xFF00E5CC),
              )
            : Text(
                key: const ValueKey('title'),
                'Team Directory',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isTablet ? 19 : 17,
                  color:
                      isDark ? Colors.white : const Color(0xFF0F1629),
                ),
              ),
      ),
      centerTitle: !_searchOpen,
      actions: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _searchOpen
              ? IconButton(
                  key: const ValueKey('close'),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _toggleSearch,
                )
              : IconButton(
                  key: const ValueKey('search'),
                  icon: const Icon(Icons.search_rounded),
                  onPressed: _toggleSearch,
                ),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade100,
        ),
      ),
    );
  }
}

// ── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filters,
    required this.selectedIndex,
    required this.countFor,
    required this.isDark,
    required this.onSelect,
  });

  final List<_Filter> filters;
  final int selectedIndex;
  final int Function(_Filter) countFor;
  final bool isDark;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    return Container(
      height: context.dp(isTablet ? 56 : 52),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0E1F) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.shade100,
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 14, vertical: 9),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 7),
        itemBuilder: (context, i) {
          final f = filters[i];
          final selected = i == selectedIndex;
          final color = WorkerCard.workerColor(f.label);
          final count = countFor(f);

          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: isDark ? 0.22 : 0.12)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? color.withValues(alpha: 0.50)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.shade200),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    f.label,
                    style: TextStyle(
                      fontSize: context.sp(isTablet ? 13 : 12.5),
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected
                          ? color
                          : (isDark
                              ? Colors.white54
                              : Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: 0.20)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: context.sp(isTablet ? 11 : 10),
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? color
                            : (isDark
                                ? Colors.white38
                                : Colors.grey.shade500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Worker list / grid ───────────────────────────────────────────────────────

class _WorkerList extends StatefulWidget {
  const _WorkerList({
    required this.workers,
    required this.isTablet,
    required this.isLandscape,
    required this.onRefresh,
  });

  final List<WorkerModel> workers;
  final bool isTablet;
  final bool isLandscape;
  final Future<void> Function() onRefresh;

  @override
  State<_WorkerList> createState() => _WorkerListState();
}

class _WorkerListState extends State<_WorkerList> {
  // Key to force rebuild + re-trigger animations when list changes
  Key _listKey = UniqueKey();

  @override
  void didUpdateWidget(covariant _WorkerList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workers != widget.workers) {
      setState(() => _listKey = UniqueKey());
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: const Color(0xFF00E5CC),
      child: ListView.builder(
        key: _listKey,
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: widget.workers.length,
        itemBuilder: (_, i) => _SlideFadeIn(
          index: i,
          child: WorkerCard(
            worker: widget.workers[i],
            onCall: () {},
            onMessage: () {},
            onProfile: () {},
          ),
        ),
      ),
    );
  }
}

// ── Staggered slide-fade-in wrapper ─────────────────────────────────────────

class _SlideFadeIn extends StatefulWidget {
  const _SlideFadeIn({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_SlideFadeIn> createState() => _SlideFadeInState();
}

class _SlideFadeInState extends State<_SlideFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // Stagger by 60ms per card, max 400ms delay
    final delay = (widget.index * 60).clamp(0, 400);
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query, required this.isDark});
  final String query;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isTablet ? 100 : 90,
              height: isTablet ? 100 : 90,
              decoration: BoxDecoration(
                color: const Color(0xFF00E5CC)
                    .withValues(alpha: isDark ? 0.12 : 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      const Color(0xFF00E5CC).withValues(alpha: 0.28),
                  width: 1.5,
                ),
              ),
              child: Icon(Icons.person_search_rounded,
                  size: isTablet ? 48 : 42,
                  color: const Color(0xFF00E5CC)),
            ),
            const SizedBox(height: 20),
            Text(
              query.isEmpty ? 'No workers found' : 'No results for "$query"',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F1629),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isEmpty
                  ? 'Try selecting a different filter.'
                  : 'Check spelling or try different keywords.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 14.5 : 13.5,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}