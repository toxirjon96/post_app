import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../common/util/responsive.dart';
import '../../../common/widget/scaffold_key_scope.dart';
import 'model/map_item.dart';
import 'widget/fullscreen_map_page.dart';
import 'widget/map_card_row.dart';
import 'widget/map_chip.dart';
import 'widget/map_date_tile.dart';
import 'widget/map_empty_state.dart';
import 'widget/map_filter_button.dart';
import 'widget/map_h_cell.dart';
import 'widget/map_image_tile.dart';
import 'widget/map_pag_btn.dart';
import 'widget/map_page_num.dart';
import 'widget/map_search_field.dart';
import 'widget/map_tap_icon.dart';
import 'widget/map_theme.dart';
import 'widget/map_wide_row.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  MapViewPage
// ═════════════════════════════════════════════════════════════════════════════
class MapViewPage extends StatefulWidget {
  const MapViewPage({super.key});
  @override
  State<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  // Filter
  final _searchCtrl = TextEditingController();
  DateTime? _dateBegin, _dateEnd;
  bool _filterExpanded = true;

  // Results
  List<MapItem> _results = [];
  bool _searched = false;
  int _page = 0;
  static const _pageSize = 10;
  MapItem? _selectedItem;

  // Map
  MapLibreMapController? _mapCtrl;
  bool _mapReady = false;

  // Sheet
  final _sheetCtrl = DraggableScrollableController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _sheetCtrl.dispose();
    super.dispose();
  }

  // ── Computed ──────────────────────────────────────────────────────────────
  List<MapItem> get _pageItems {
    final s = _page * _pageSize;
    return _results.sublist(s, (s + _pageSize).clamp(0, _results.length));
  }

  int get _totalPages => (_results.length / _pageSize).ceil().clamp(1, 9999);

  // ── Snap sizes ────────────────────────────────────────────────────────────
  List<double> _snapSizes(BuildContext ctx) {
    final isLand = ctx.isLandscape;
    final isTab  = ctx.isTablet;
    if (isLand && !isTab) return const [0.22, 0.50];
    if (isLand &&  isTab) return const [0.10, 0.30, 0.55];
    if (!isLand && isTab) return const [0.10, 0.32, 0.60];
    return                       const [0.13, 0.36, 0.65];
  }

  double _initSize(BuildContext ctx) => _snapSizes(ctx).first;
  double _maxSize(BuildContext ctx)  => _snapSizes(ctx).last;

  // ── Actions ───────────────────────────────────────────────────────────────
  void _search() {
    FocusScope.of(context).unfocus();
    final q   = _searchCtrl.text.trim().toLowerCase();
    final out = mockMapData.where((e) =>
        (q.isEmpty || e.name.toLowerCase().contains(q)) &&
        (_dateBegin == null || !e.createdAt.isBefore(_dateBegin!)) &&
        (_dateEnd   == null || !e.createdAt.isAfter(_dateEnd!))).toList();
    setState(() {
      _results      = out;
      _searched     = true;
      _page         = 0;
      _selectedItem = out.isNotEmpty ? out.first : null;
    });
    HapticFeedback.mediumImpact();
    _syncMarkers();
    if (_selectedItem != null) _flyToItem(_selectedItem!);
    _snapSheetTo(_snapSizes(context).length >= 2 ? _snapSizes(context)[1] : _snapSizes(context).first);
  }

  void _clear() {
    FocusScope.of(context).unfocus();
    _searchCtrl.clear();
    setState(() {
      _dateBegin = _dateEnd = null;
      _results   = [];
      _searched  = false;
      _page      = 0;
      _selectedItem = null;
    });
    HapticFeedback.selectionClick();
    _mapCtrl?.clearCircles();
    _snapSheetTo(_initSize(context));
  }

  void _snapSheetTo(double size) {
    if (!_sheetCtrl.isAttached) return;
    _sheetCtrl.animateTo(
      size,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pickDateTime(bool isBegin) async {
    final isLand = context.isLandscape;
    final init   = isBegin ? (_dateBegin ?? DateTime(2024)) : (_dateEnd ?? DateTime.now());

    final date = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2020),
      lastDate: DateTime(2027),
      initialEntryMode: isLand ? DatePickerEntryMode.input : DatePickerEntryMode.calendar,
      builder: (ctx, child) => _pickerTheme(ctx, child),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(init),
      initialEntryMode: isLand ? TimePickerEntryMode.input : TimePickerEntryMode.dial,
      builder: (ctx, child) => _pickerTheme(ctx, child),
    );
    if (!mounted) return;

    final dt = DateTime(date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0);
    setState(() => isBegin ? _dateBegin = dt : _dateEnd = dt);
  }

  Widget _pickerTheme(BuildContext ctx, Widget? child) => MediaQuery(
    data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.noScaling),
    child: Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: kMapBlue, onPrimary: Colors.white,
          surface: kMapCard, onSurface: kMapText,
        ),
        dialogTheme: const DialogThemeData(backgroundColor: kMapSurface),
      ),
      child: child!,
    ),
  );

  void _goToPage(int p) => setState(() {
    _page = p;
    _selectedItem = _pageItems.isNotEmpty ? _pageItems.first : _selectedItem;
  });

  // ── Map markers ───────────────────────────────────────────────────────────
  Future<void> _syncMarkers() async {
    final ctrl = _mapCtrl;
    if (ctrl == null || !_mapReady) return;
    await ctrl.clearCircles();
    for (final item in _results) {
      final sel = item == _selectedItem;
      await ctrl.addCircle(CircleOptions(
        geometry:          item.coords,
        circleRadius:      sel ? 12.0 : 7.0,
        circleColor:       sel ? '#00E5CC' : '#1B8EF8',
        circleOpacity:     sel ? 1.0 : 0.82,
        circleStrokeWidth: sel ? 3.0 : 1.5,
        circleStrokeColor: '#FFFFFF',
      ));
    }
  }

  void _flyToItem(MapItem item) {
    if (_mapCtrl == null || !_mapReady) return;
    _mapCtrl!.animateCamera(CameraUpdate.newLatLngZoom(item.coords, 11.5));
  }

  void _selectItem(MapItem item) {
    setState(() => _selectedItem = item);
    _syncMarkers();
    _flyToItem(item);
  }

  void _openFullscreenMap() => Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const FullscreenMapPage(),
    ),
  );

  // ═════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final mq       = MediaQuery.of(context);
    final isLand   = context.isLandscape;
    final snaps    = _snapSizes(context);
    final initSnap = _initSize(context);
    final maxSnap  = _maxSize(context);
    final peekH    = mq.size.height * initSnap + mq.padding.bottom;
    final imgW     = _selectedItem != null
        ? context.dp(context.isTablet ? 172.0 : 148.0)
        : 0.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── 0: Full-screen map ─────────────────────────────────────────
            Positioned.fill(
              child: MapLibreMap(
                styleString: kOsmStyle,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(41.3775, 64.5853), zoom: 5.0,
                ),
                onMapCreated: (c) => _mapCtrl = c,
                onStyleLoadedCallback: () {
                  setState(() => _mapReady = true);
                  _syncMarkers();
                },
                compassEnabled: true,
                myLocationEnabled: false,
                trackCameraPosition: false,
              ),
            ),

            // ── 1: Filter panel (top) ──────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: _buildFilterPanel(context, isLand),
                ),
              ),
            ),

            // ── 2: Images side-panel (right) ──────────────────────────────
            Positioned(
              right: 10,
              top: mq.padding.top + 10,
              bottom: peekH + 10,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: imgW,
                child: imgW > 0
                    ? _buildImagesPanel()
                    : const IgnorePointer(child: SizedBox.shrink()),
              ),
            ),

            // ── 3: OSM attribution ─────────────────────────────────────────
            Positioned(
              bottom: peekH + 4,
              left: 10,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(fontSize: 8.5, color: Colors.white60),
                  ),
                ),
              ),
            ),

            // ── 4: Bottom table sheet ──────────────────────────────────────
            DraggableScrollableSheet(
              controller:       _sheetCtrl,
              initialChildSize: initSnap,
              minChildSize:     initSnap,
              maxChildSize:     maxSnap,
              snap:             true,
              snapSizes:        snaps,
              builder:          (ctx, sc) => _buildSheet(ctx, sc, isLand),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Filter panel
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFilterPanel(BuildContext context, bool isLand) {
    final search  = MapSearchField(controller: _searchCtrl);
    final fromDt  = MapDateTile(label: 'From',  icon: Icons.event_rounded,           value: _dateBegin, accent: kMapTeal, onTap: () => _pickDateTime(true));
    final untilDt = MapDateTile(label: 'Until', icon: Icons.event_available_rounded,  value: _dateEnd,   accent: kMapBlue, onTap: () => _pickDateTime(false));
    final srchBtn = MapFilterButton(icon: Icons.search_rounded, label: 'Search', filled: true,  color: kMapBlue,    onTap: _search);
    final clrBtn  = MapFilterButton(icon: Icons.clear_rounded,  label: 'Clear',  filled: false, color: kMapTextSec, onTap: _clear);

    return mapGlass(
      radius: 18,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _filterExpanded = !_filterExpanded),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                child: Row(
                  children: [
                    MapTapIcon(
                      icon: Icons.menu_rounded,
                      onTap: () => ScaffoldKeyScope.of(context).currentState?.openDrawer(),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [kMapBlue, kMapTeal]),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(Icons.map_rounded, size: 13, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Map View',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kMapText, fontFamily: 'Poppins'),
                    ),
                    if (_results.isNotEmpty) ...[
                      const SizedBox(width: 7),
                      MapChip(label: '${_results.length}', color: kMapBlue),
                    ],
                    const Spacer(),
                    AnimatedRotation(
                      turns: _filterExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(Icons.keyboard_arrow_down_rounded, color: kMapTextSec, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: _filterExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: isLand
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
                                search,
                                const SizedBox(height: 7),
                                fromDt,
                              ])),
                              const SizedBox(width: 8),
                              Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
                                untilDt,
                                const SizedBox(height: 7),
                                Row(children: [
                                  Expanded(child: srchBtn),
                                  const SizedBox(width: 6),
                                  Expanded(child: clrBtn),
                                ]),
                              ])),
                            ],
                          )
                        : Column(mainAxisSize: MainAxisSize.min, children: [
                            search,
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(child: fromDt),
                              const SizedBox(width: 7),
                              Expanded(child: untilDt),
                              const SizedBox(width: 7),
                              srchBtn,
                              const SizedBox(width: 5),
                              clrBtn,
                            ]),
                          ]),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Images side-panel
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildImagesPanel() {
    final item    = _selectedItem!;
    final allUrls = [item.img1, item.img2];
    final title   = '#${item.id}  ·  ${item.name}';

    return mapGlass(
      radius: 16,
      child: Column(
        children: [
          SizedBox(
            height: 30,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const Icon(Icons.photo_library_rounded, size: 11, color: kMapBlue),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '#${item.id}',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kMapBlue),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Expanded(child: MapImageTile(url: item.img1, index: 0, allUrls: allUrls, title: title)),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Expanded(child: MapImageTile(url: item.img2, index: 1, allUrls: allUrls, title: title)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Bottom sheet
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSheet(BuildContext ctx, ScrollController sc, bool isLand) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: kMapBg.withValues(alpha: 0.90),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.10))),
          ),
          child: Column(
            children: [
              _buildSheetHeader(),
              Expanded(child: _buildSheetBody(sc, isLand)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 38, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 12, 10),
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: kMapBlue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kMapBlue.withValues(alpha: 0.25), width: 0.8),
                ),
                child: const Icon(Icons.table_rows_rounded, size: 14, color: kMapBlue),
              ),
              const SizedBox(width: 10),
              const Text('Results', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kMapText)),
              if (_searched) ...[
                const SizedBox(width: 8),
                MapChip(
                  label: _results.isEmpty ? 'No results' : '${_results.length}',
                  color: _results.isEmpty ? kMapError : kMapBlue,
                ),
              ],
              const Spacer(),
              if (_selectedItem != null) ...[
                const MapChip(label: 'Tap row → map', color: kMapTeal),
                const SizedBox(width: 6),
              ],
              MapTapIcon(icon: Icons.fullscreen_rounded, onTap: _openFullscreenMap),
            ],
          ),
        ),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
      ],
    );
  }

  Widget _buildSheetBody(ScrollController sc, bool isLand) {
    if (!_searched) {
      return const MapEmptyState(
        icon: Icons.manage_search_rounded,
        title: 'Ready to search',
        subtitle: 'Use the filters above and tap Search.',
      );
    }
    if (_results.isEmpty) {
      return const MapEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No results found',
        subtitle: 'Try adjusting your search criteria.',
        isError: true,
      );
    }

    return LayoutBuilder(builder: (ctx, c) {
      final wide = c.maxWidth >= 440 || isLand;
      return Column(
        children: [
          if (wide) _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              controller: sc,
              padding: EdgeInsets.zero,
              itemCount: _pageItems.length,
              itemBuilder: (ctx, i) {
                final item = _pageItems[i];
                final idx  = _page * _pageSize + i;
                final sel  = item == _selectedItem;
                return wide
                    ? MapWideRow(rowIndex: idx, item: item, isSelected: sel, onTap: () => _selectItem(item))
                    : MapCardRow(rowIndex: idx, item: item, isSelected: sel, onTap: () => _selectItem(item));
              },
            ),
          ),
          _buildPagination(wide: wide),
        ],
      );
    });
  }

  Widget _buildTableHeader() {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: kMapElev.withValues(alpha: 0.55),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: const Row(children: [
        MapHCell(label: '#',    flex: 1),
        MapHCell(label: 'ID',   flex: 2),
        MapHCell(label: 'Name', flex: 5),
        MapHCell(label: 'Date', flex: 3),
      ]),
    );
  }

  Widget _buildPagination({required bool wide}) {
    final total = _results.length;
    final start = _page * _pageSize + 1;
    final end   = ((_page + 1) * _pageSize).clamp(0, total);

    final pages = <int>{0, _totalPages - 1, _page};
    if (_page > 0) pages.add(_page - 1);
    if (_page < _totalPages - 1) pages.add(_page + 1);
    final sorted = pages.toList()..sort();

    final nums = <Widget>[];
    int? prev;
    for (final p in sorted) {
      if (prev != null && p - prev > 1) {
        nums.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 3),
          child: Text('…', style: TextStyle(color: kMapHint, fontSize: 12)),
        ));
      }
      nums.add(MapPageNum(page: p, current: _page, onTap: _goToPage));
      prev = p;
    }

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: kMapSurface.withValues(alpha: 0.55),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: Row(
        children: [
          Text(
            wide ? '$start – $end  of  $total' : '$start–$end / $total',
            style: const TextStyle(fontSize: 11.5, color: kMapTextSec),
          ),
          const Spacer(),
          ...nums,
          const SizedBox(width: 6),
          MapPagBtn(icon: Icons.chevron_left_rounded,  enabled: _page > 0,               onTap: () => _goToPage(_page - 1)),
          const SizedBox(width: 4),
          MapPagBtn(icon: Icons.chevron_right_rounded, enabled: _page < _totalPages - 1, onTap: () => _goToPage(_page + 1)),
        ],
      ),
    );
  }
}