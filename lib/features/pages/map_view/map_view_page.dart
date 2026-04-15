import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../common/constant/theme_config.dart';
import '../../../common/util/responsive.dart';
import '../../../common/widget/scaffold_key_scope.dart';

// ── OSM style ─────────────────────────────────────────────────────────────────
const _kOsmStyle = '''
{
  "version": 8,
  "sources": {
    "osm": {
      "type": "raster",
      "tiles": ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
      "tileSize": 256,
      "attribution": "© OpenStreetMap"
    }
  },
  "layers": [{"id":"osm","type":"raster","source":"osm","minzoom":0,"maxzoom":19}]
}
''';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _bg      = AppColors.darkBg;
const _surface = AppColors.darkSurface;
const _card    = AppColors.darkCard;
const _elev    = AppColors.darkElevated;
const _blue    = AppColors.electricBlue;
const _teal    = AppColors.teal;
const _text    = Color(0xFFECF0FA);
const _textSec = Color(0xFF6B7FA0);
const _hint    = Color(0xFF415070);
const _field   = Color(0xFF111E36);
const _error   = AppColors.coral;

// ── Glass helper ──────────────────────────────────────────────────────────────
Widget _glass({
  required Widget child,
  double radius = 20,
  double opacity = 0.80,
  EdgeInsetsGeometry? padding,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: _bg.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 0.8),
        ),
        child: child,
      ),
    ),
  );
}

// ── Mock data ─────────────────────────────────────────────────────────────────
class _Item {
  final int id;
  final String name;
  final DateTime createdAt;
  final String img1, img2;
  final LatLng coords;
  const _Item({
    required this.id, required this.name, required this.createdAt,
    required this.img1, required this.img2, required this.coords,
  });
}

const _rawData = [
  ('Toshkent Metro Station',   LatLng(41.2995, 69.2401)),
  ('Samarkand Grand Bazaar',   LatLng(39.6270, 66.9749)),
  ('Bukhara Old City',         LatLng(39.7747, 64.4286)),
  ('Namangan Central Park',    LatLng(41.0011, 71.6725)),
  ('Fergana Valley Route',     LatLng(40.3834, 71.7812)),
  ('Andijan Main Square',      LatLng(40.7828, 72.3437)),
  ('Nukus Art Museum',         LatLng(42.4647, 59.6038)),
  ('Termez Border Post',       LatLng(37.2241, 67.2783)),
  ('Guliston City Center',     LatLng(40.4897, 68.7751)),
  ('Jizzakh District Hub',     LatLng(40.1158, 67.8422)),
  ('Sirdaryo Bridge',          LatLng(40.8439, 68.6660)),
  ('Qarshi Airport',           LatLng(38.8629, 65.7990)),
  ('Navoi Mining Zone',        LatLng(40.0842, 65.3791)),
  ('Urgench Bazaar',           LatLng(41.5547, 60.6317)),
  ('Khiva Ancient Wall',       LatLng(41.3783, 60.3634)),
  ('Shakhrisabz Palace',       LatLng(39.0489, 66.8299)),
  ('Margilan Silk Factory',    LatLng(40.4737, 71.7224)),
  ('Kokand Fortress',          LatLng(40.5289, 70.9428)),
  ('Denov Village',            LatLng(37.7683, 67.9047)),
  ('Muynaq Ship Graveyard',    LatLng(43.8006, 59.0158)),
  ('Chimgan Mountain Resort',  LatLng(41.5476, 70.0581)),
  ('Charvak Lake',             LatLng(41.6182, 70.1213)),
  ('Chorsu Bazaar',            LatLng(41.3096, 69.2348)),
  ('Amudarya River Camp',      LatLng(40.1233, 62.8580)),
  ('Zarafshan Valley Post',    LatLng(39.9234, 64.5769)),
  ('Kyzylkum Desert Track',    LatLng(41.1000, 64.5000)),
  ('Angren Coal Station',      LatLng(41.0144, 70.1395)),
  ('Olmaliq Mine',             LatLng(40.8884, 69.3374)),
  ('Yangiyer Rail Station',    LatLng(40.7730, 69.0453)),
  ('Bekabad Steel Plant',      LatLng(40.2247, 69.2177)),
  ('Ohangaron River Bridge',   LatLng(41.2670, 69.6340)),
  ('Eski Shahar Quarter',      LatLng(41.2960, 69.2330)),
  ('Hazrati Imam Complex',     LatLng(41.3011, 69.2277)),
  ('Tillya Kari Madrasa',      LatLng(39.6520, 66.9597)),
  ('Registan Square',          LatLng(39.6548, 66.9757)),
  ('Shah-i-Zinda Necropolis',  LatLng(39.6573, 66.9750)),
  ('Gur-e-Amir Mausoleum',     LatLng(39.6475, 66.9730)),
  ('Ark Fortress Bukhara',     LatLng(39.7763, 64.4167)),
  ('Sitorai Mohi Palace',      LatLng(39.7820, 64.4286)),
  ('Poi Kalon Minaret',        LatLng(39.7755, 64.4166)),
  ('Toshkent TV Tower',        LatLng(41.2994, 69.2401)),
  ('Shodlik Palace Hotel',     LatLng(41.2850, 69.2100)),
  ('Alay Mountain Pass',       LatLng(40.5167, 70.6500)),
  ('Independence Square TAS',  LatLng(41.3000, 69.2700)),
  ('Minor Mosque Toshkent',    LatLng(41.3043, 69.2370)),
  ('Barak Khan Madrassa',      LatLng(41.3000, 69.2400)),
  ('Kukeldash Madrassa',       LatLng(41.2981, 69.2367)),
];

final _mockData = List<_Item>.generate(_rawData.length, (i) {
  final id = 1001 + i;
  return _Item(
    id: id,
    name: _rawData[i].$1,
    createdAt: DateTime(2024, 1, 1).add(Duration(days: i * 7 + i)),
    img1: 'https://picsum.photos/seed/${id}a/600/400',
    img2: 'https://picsum.photos/seed/${id}b/600/400',
    coords: _rawData[i].$2,
  );
});

// ── Formatters ────────────────────────────────────────────────────────────────
const _mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
String _fmtDt(DateTime d) =>
    '${d.day.toString().padLeft(2,'0')} ${_mo[d.month-1]} ${d.year}'
    '  ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2,'0')} ${_mo[d.month-1]} ${d.year}';

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
  final _searchCtrl    = TextEditingController();
  DateTime? _dateBegin, _dateEnd;
  bool      _filterExpanded = true;

  // Results
  List<_Item> _results  = [];
  bool        _searched = false;
  int         _page     = 0;
  static const _pageSize = 10;
  _Item?      _selectedItem;

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
  List<_Item> get _pageItems {
    final s = _page * _pageSize;
    return _results.sublist(s, (s + _pageSize).clamp(0, _results.length));
  }
  int get _totalPages => (_results.length / _pageSize).ceil().clamp(1, 9999);

  // ── Snap sizes (adaptive to orientation + device) ─────────────────────────
  List<double> _snapSizes(BuildContext ctx) {
    final isLand = ctx.isLandscape;
    final isTab  = ctx.isTablet;
    if (isLand && !isTab) return const [0.22, 0.50];          // phone landscape: taller snaps
    if (isLand &&  isTab) return const [0.10, 0.30, 0.55];   // tablet landscape
    if (!isLand && isTab) return const [0.10, 0.32, 0.60];   // tablet portrait
    return                       const [0.13, 0.36, 0.65];   // phone portrait
  }

  double _initSize(BuildContext ctx) => _snapSizes(ctx).first;
  double _maxSize(BuildContext ctx)  => _snapSizes(ctx).last;

  // ── Actions ───────────────────────────────────────────────────────────────
  void _search() {
    FocusScope.of(context).unfocus();
    final q = _searchCtrl.text.trim().toLowerCase();
    final out = _mockData.where((e) =>
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

  // ── DateTime picker (fixed: input mode in landscape, text-scale clamped) ──
  Future<void> _pickDateTime(bool isBegin) async {
    final isLand = context.isLandscape;
    final init   = isBegin ? (_dateBegin ?? DateTime(2024)) : (_dateEnd ?? DateTime.now());

    final date = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2020),
      lastDate:  DateTime(2027),
      // Use input (text field) mode in landscape to avoid calendar overflow
      initialEntryMode: isLand ? DatePickerEntryMode.input : DatePickerEntryMode.calendar,
      builder: (ctx, child) => _pickerTheme(ctx, child),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(init),
      // Use input mode in landscape to avoid dial overflow
      initialEntryMode: isLand ? TimePickerEntryMode.input : TimePickerEntryMode.dial,
      builder: (ctx, child) => _pickerTheme(ctx, child),
    );
    if (!mounted) return;

    final dt = DateTime(date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0);
    setState(() => isBegin ? _dateBegin = dt : _dateEnd = dt);
  }

  // Clamp text scale + apply dark theme — prevents picker overflow on small screens
  Widget _pickerTheme(BuildContext ctx, Widget? child) => MediaQuery(
    data: MediaQuery.of(ctx).copyWith(
      textScaler: TextScaler.noScaling,
    ),
    child: Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: _blue, onPrimary: Colors.white,
          surface: _card, onSurface: _text,
        ),
        dialogTheme: const DialogThemeData(backgroundColor: _surface),
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

  void _flyToItem(_Item item) {
    if (_mapCtrl == null || !_mapReady) return;
    _mapCtrl!.animateCamera(CameraUpdate.newLatLngZoom(item.coords, 11.5));
  }

  void _selectItem(_Item item) {
    setState(() => _selectedItem = item);
    _syncMarkers();
    _flyToItem(item);
  }

  // ── Fullscreen ────────────────────────────────────────────────────────────
  void _openFullscreenMap() => Navigator.push(context, MaterialPageRoute(
    fullscreenDialog: true,
    builder: (ctx) => const _FullscreenMapPage(),
  ));

  void _openFullscreenImages(int idx) {
    if (_selectedItem == null) return;
    Navigator.push(context, MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => _FullscreenImagesPage(item: _selectedItem!, initialIndex: idx),
    ));
  }

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

    // Height occupied by the sheet in minimum (peek) state
    // — used to keep images panel and map interaction clear of the sheet
    final peekH    = mq.size.height * initSnap + mq.padding.bottom;

    // Width of the images side-panel
    final imgW = _selectedItem != null
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
                styleString: _kOsmStyle,
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
            //    Positioned between filter bottom and sheet peek top.
            //    IgnorePointer when hidden so map remains interactive.
            Positioned(
              right: 10,
              // anchor just below the status bar / safe-area top
              top: mq.padding.top + 10,
              // stop above the sheet peek + system nav
              bottom: peekH + 10,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: imgW,
                child: imgW > 0
                    ? _buildImagesPanel(context)
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
    final search  = _SearchField(controller: _searchCtrl);
    final fromDt  = _DateTile(label: 'From',  icon: Icons.event_rounded,          value: _dateBegin, accent: _teal, onTap: () => _pickDateTime(true));
    final untilDt = _DateTile(label: 'Until', icon: Icons.event_available_rounded, value: _dateEnd,   accent: _blue, onTap: () => _pickDateTime(false));
    final srchBtn = _Btn(icon: Icons.search_rounded, label: 'Search', filled: true,  color: _blue,    onTap: _search);
    final clrBtn  = _Btn(icon: Icons.clear_rounded,  label: 'Clear',  filled: false, color: _textSec, onTap: _clear);

    return _glass(
      radius: 18,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row (always visible, collapses controls)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _filterExpanded = !_filterExpanded),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                child: Row(
                  children: [
                    _TapIcon(
                      icon: Icons.menu_rounded,
                      onTap: () => ScaffoldKeyScope.of(context).currentState?.openDrawer(),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_blue, _teal]),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(Icons.map_rounded, size: 13, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Map View',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _text, fontFamily: 'Poppins'),
                    ),
                    if (_results.isNotEmpty) ...[
                      const SizedBox(width: 7),
                      _Chip(label: '${_results.length}', color: _blue),
                    ],
                    const Spacer(),
                    AnimatedRotation(
                      turns: _filterExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(Icons.keyboard_arrow_down_rounded, color: _textSec, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Collapsible controls
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: _filterExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: isLand
                        // Landscape: 2-column to keep height minimal
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  search,
                                  const SizedBox(height: 7),
                                  fromDt,
                                ]),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  untilDt,
                                  const SizedBox(height: 7),
                                  Row(children: [
                                    Expanded(child: srchBtn),
                                    const SizedBox(width: 6),
                                    Expanded(child: clrBtn),
                                  ]),
                                ]),
                              ),
                            ],
                          )
                        // Portrait: stacked
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
  Widget _buildImagesPanel(BuildContext context) {
    final item = _selectedItem!;
    return _glass(
      radius: 16,
      child: Column(
        children: [
          // Header
          SizedBox(
            height: 30,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const Icon(Icons.photo_library_rounded, size: 11, color: _blue),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '#${item.id}',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _blue),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Expanded(child: _ImageTile(url: item.img1, index: 0, onFullscreen: _openFullscreenImages)),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Expanded(child: _ImageTile(url: item.img2, index: 1, onFullscreen: _openFullscreenImages)),
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
            color: _bg.withValues(alpha: 0.90),
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
                  color: _blue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _blue.withValues(alpha: 0.25), width: 0.8),
                ),
                child: const Icon(Icons.table_rows_rounded, size: 14, color: _blue),
              ),
              const SizedBox(width: 10),
              const Text('Results', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
              if (_searched) ...[
                const SizedBox(width: 8),
                _Chip(
                  label: _results.isEmpty ? 'No results' : '${_results.length}',
                  color: _results.isEmpty ? _error : _blue,
                ),
              ],
              const Spacer(),
              if (_selectedItem != null) ...[
                _Chip(label: 'Tap row → map', color: _teal),
                const SizedBox(width: 6),
              ],
              _TapIcon(icon: Icons.fullscreen_rounded, onTap: _openFullscreenMap),
            ],
          ),
        ),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
      ],
    );
  }

  Widget _buildSheetBody(ScrollController sc, bool isLand) {
    if (!_searched) {
      return _EmptyState(
        icon: Icons.manage_search_rounded,
        title: 'Ready to search',
        subtitle: 'Use the filters above and tap Search.',
      );
    }
    if (_results.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No results found',
        subtitle: 'Try adjusting your search criteria.',
        isError: true,
      );
    }

    return LayoutBuilder(builder: (ctx, c) {
      // Wide table on landscape / tablets; card list on portrait phones
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
                    ? _WideRow(rowIndex: idx, item: item, isSelected: sel, onTap: () => _selectItem(item))
                    : _CardRow(rowIndex: idx, item: item, isSelected: sel, onTap: () => _selectItem(item));
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
        color: _elev.withValues(alpha: 0.55),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: const Row(children: [
        _HCell(label: '#',    flex: 1),
        _HCell(label: 'ID',   flex: 2),
        _HCell(label: 'Name', flex: 5),
        _HCell(label: 'Date', flex: 3),
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
          child: Text('…', style: TextStyle(color: _hint, fontSize: 12)),
        ));
      }
      nums.add(_PageNum(page: p, current: _page, onTap: _goToPage));
      prev = p;
    }

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.55),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: Row(
        children: [
          Text(
            wide ? '$start – $end  of  $total' : '$start–$end / $total',
            style: const TextStyle(fontSize: 11.5, color: _textSec),
          ),
          const Spacer(),
          ...nums,
          const SizedBox(width: 6),
          _PagBtn(icon: Icons.chevron_left_rounded,  enabled: _page > 0,              onTap: () => _goToPage(_page - 1)),
          const SizedBox(width: 4),
          _PagBtn(icon: Icons.chevron_right_rounded, enabled: _page < _totalPages - 1, onTap: () => _goToPage(_page + 1)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Image tile (in the side panel)
// ═════════════════════════════════════════════════════════════════════════════
class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.url, required this.index, required this.onFullscreen});
  final String url; final int index; final void Function(int) onFullscreen;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: url, fit: BoxFit.cover,
          placeholder: (ctx, url) => Container(
            color: _field,
            child: const Center(child: SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.6, valueColor: AlwaysStoppedAnimation<Color>(_blue)),
            )),
          ),
          errorWidget: (ctx, url, err) => Container(
            color: _field,
            child: const Icon(Icons.broken_image_outlined, size: 18, color: _hint),
          ),
        ),
        Positioned(
          top: 5, right: 5,
          child: GestureDetector(
            onTap: () => onFullscreen(index),
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: const Icon(Icons.open_in_full_rounded, size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Fullscreen map page
// ═════════════════════════════════════════════════════════════════════════════
class _FullscreenMapPage extends StatefulWidget {
  const _FullscreenMapPage();
  @override
  State<_FullscreenMapPage> createState() => _FullscreenMapPageState();
}
class _FullscreenMapPageState extends State<_FullscreenMapPage> {
  @override
  void initState() { super.initState(); SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); }
  @override
  void dispose()   { SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(children: [
      MapLibreMap(
        styleString: _kOsmStyle,
        initialCameraPosition: const CameraPosition(target: LatLng(41.3775, 64.5853), zoom: 5.2),
        compassEnabled: true, myLocationEnabled: false, trackCameraPosition: false,
      ),
      SafeArea(child: Padding(
        padding: const EdgeInsets.all(12),
        child: _TapIcon(icon: Icons.fullscreen_exit_rounded, size: 40, iconSize: 20, onTap: () => Navigator.pop(context)),
      )),
    ]),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
//  Fullscreen images page  — double-tap to zoom in/out + pinch zoom
// ═════════════════════════════════════════════════════════════════════════════
class _FullscreenImagesPage extends StatefulWidget {
  const _FullscreenImagesPage({required this.item, required this.initialIndex});
  final _Item item; final int initialIndex;
  @override
  State<_FullscreenImagesPage> createState() => _FullscreenImagesPageState();
}

class _FullscreenImagesPageState extends State<_FullscreenImagesPage> with TickerProviderStateMixin {
  late final PageController _pageCtrl;
  late int _idx;

  // One TransformationController per image
  late final List<TransformationController> _transforms;
  // Zoom animation
  late final AnimationController _zoomAniCtrl;
  Animation<Matrix4>? _zoomAni;
  // Capture double-tap position
  TapDownDetails? _tapDown;

  @override
  void initState() {
    super.initState();
    _idx        = widget.initialIndex;
    _pageCtrl   = PageController(initialPage: widget.initialIndex);
    _transforms = [TransformationController(), TransformationController()];
    _zoomAniCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final t in _transforms) { t.dispose(); }
    _zoomAniCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── Double-tap zoom ───────────────────────────────────────────────────────
  void _onDoubleTap(int imgIdx) {
    final ctrl      = _transforms[imgIdx];
    final isZoomed  = ctrl.value.getMaxScaleOnAxis() > 1.05;
    final targetM   = isZoomed
        ? Matrix4.identity()
        : _zoomMatrix(_tapDown?.localPosition ?? Offset.zero, 2.5);

    _zoomAni = Matrix4Tween(begin: ctrl.value.clone(), end: targetM)
        .animate(CurvedAnimation(parent: _zoomAniCtrl, curve: Curves.easeInOutCubic));

    _zoomAni!.addListener(() {
      ctrl.value = _zoomAni!.value;
    });
    _zoomAniCtrl.forward(from: 0);
  }

  // Build a zoom matrix that keeps focalPoint stationary
  static Matrix4 _zoomMatrix(Offset focalPoint, double scale) {
    return Matrix4.identity()
      ..translateByDouble(focalPoint.dx, focalPoint.dy, 0, 0)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-focalPoint.dx, -focalPoint.dy, 0, 0);
  }

  @override
  Widget build(BuildContext context) {
    final urls = [widget.item.img1, widget.item.img2];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Image PageView ───────────────────────────────────────────────
          PageView.builder(
            controller: _pageCtrl,
            itemCount: 2,
            onPageChanged: (i) {
              setState(() => _idx = i);
              // Reset zoom when swiping to new image
              _transforms[1 - i].value = Matrix4.identity();
            },
            itemBuilder: (ctx, i) => GestureDetector(
              // Capture tap position BEFORE the double-tap fires
              onDoubleTapDown: (d) => _tapDown = d,
              onDoubleTap:     () => _onDoubleTap(i),
              child: InteractiveViewer(
                transformationController: _transforms[i],
                minScale: 0.7,
                maxScale: 5.0,
                child: CachedNetworkImage(
                  imageUrl: urls[i],
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (ctx, url) => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_blue),
                    ),
                  ),
                  errorWidget: (ctx, url, err) => const Center(
                    child: Icon(Icons.broken_image_outlined, color: _hint, size: 48),
                  ),
                ),
              ),
            ),
          ),

          // ── Top bar ─────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  _TapIcon(
                    icon: Icons.fullscreen_exit_rounded,
                    size: 40, iconSize: 20,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _glass(
                      radius: 10,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        '#${widget.item.id}  ·  ${widget.item.name}',
                        style: const TextStyle(fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Hint + dot indicator ─────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(2, (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _idx ? 22 : 8, height: 8,
                        decoration: BoxDecoration(
                          color: i == _idx ? _blue : Colors.white.withValues(alpha: 0.32),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Image ${_idx + 1} of 2  ·  Pinch or double-tap to zoom',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.50)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Prev / Next arrows ───────────────────────────────────────────
          if (_idx > 0)
            Positioned(
              left: 8, top: 0, bottom: 0,
              child: Center(child: _TapIcon(
                icon: Icons.chevron_left_rounded, size: 40, iconSize: 22,
                onTap: () => _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
              )),
            ),
          if (_idx < 1)
            Positioned(
              right: 8, top: 0, bottom: 0,
              child: Center(child: _TapIcon(
                icon: Icons.chevron_right_rounded, size: 40, iconSize: 22,
                onTap: () => _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
              )),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Filter widgets
// ═════════════════════════════════════════════════════════════════════════════
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: _text, fontSize: 13.5),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _hint),
          hintText: 'Search by name…',
          hintStyle: const TextStyle(color: _hint, fontSize: 13.5),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (ctx, val, child) => val.text.isNotEmpty
                ? GestureDetector(onTap: controller.clear, child: const Icon(Icons.close_rounded, size: 16, color: _hint))
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.icon, required this.value, required this.accent, required this.onTap});
  final String label; final IconData icon; final DateTime? value; final Color accent; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final has = value != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: has ? accent.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: has ? accent.withValues(alpha: 0.50) : Colors.white.withValues(alpha: 0.10),
            width: has ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: has ? accent : _hint),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: has ? accent : _hint, letterSpacing: 0.5),
                  ),
                  Text(
                    has ? _fmtDt(value!) : 'Select…',
                    style: TextStyle(fontSize: 10.5, color: has ? _text : _hint, fontWeight: has ? FontWeight.w600 : FontWeight.normal),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.expand_more_rounded, size: 14, color: has ? accent : _hint),
          ],
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.label, required this.filled, required this.color, required this.onTap});
  final IconData icon; final String label; final bool filled; final Color color; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: filled ? LinearGradient(colors: [color, color.withValues(alpha: 0.70)]) : null,
          color: filled ? null : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: filled ? null : Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: filled ? [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 3))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: filled ? Colors.white : _textSec),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: filled ? Colors.white : _textSec)),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Table rows
// ═════════════════════════════════════════════════════════════════════════════
class _HCell extends StatelessWidget {
  const _HCell({required this.label, required this.flex});
  final String label; final int flex;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: _textSec, letterSpacing: 0.9),
      ),
    ),
  );
}

class _WideRow extends StatelessWidget {
  const _WideRow({required this.rowIndex, required this.item, required this.isSelected, required this.onTap});
  final int rowIndex; final _Item item; final bool isSelected; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final even = rowIndex % 2 == 0;
    return InkWell(
      onTap: onTap,
      splashColor: _blue.withValues(alpha: 0.08),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 44),
        decoration: BoxDecoration(
          color: isSelected
              ? _blue.withValues(alpha: 0.13)
              : even ? Colors.transparent : Colors.white.withValues(alpha: 0.03),
          border: Border(
            left: isSelected ? const BorderSide(color: _blue, width: 3) : BorderSide.none,
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 1, child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Text(
                  '${rowIndex + 1}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? _blue : _textSec),
                ),
              )),
              Expanded(flex: 2, child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: Align(alignment: Alignment.centerLeft, child: _Chip(label: '#${item.id}', color: _blue)),
              )),
              Expanded(flex: 5, child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? _text : _text.withValues(alpha: 0.82),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    height: 1.4,
                  ),
                  softWrap: true,
                ),
              )),
              Expanded(flex: 3, child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 10, color: _hint),
                    const SizedBox(width: 4),
                    Flexible(child: Text(
                      _fmtDate(item.createdAt),
                      style: const TextStyle(fontSize: 11.5, color: _textSec, height: 1.35),
                      softWrap: true,
                    )),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.rowIndex, required this.item, required this.isSelected, required this.onTap});
  final int rowIndex; final _Item item; final bool isSelected; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: _blue.withValues(alpha: 0.08),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
        decoration: BoxDecoration(
          color: isSelected ? _blue.withValues(alpha: 0.13) : Colors.transparent,
          border: Border(
            left: isSelected ? const BorderSide(color: _blue, width: 3) : BorderSide.none,
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Container(
                width: 22, height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? _blue.withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '${rowIndex + 1}',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: isSelected ? _blue : _textSec),
                ),
              ),
              const SizedBox(width: 7),
              _Chip(label: '#${item.id}', color: _blue),
              const Spacer(),
              const Icon(Icons.calendar_today_rounded, size: 10, color: _hint),
              const SizedBox(width: 4),
              Text(_fmtDate(item.createdAt), style: const TextStyle(fontSize: 11, color: _textSec)),
            ]),
            const SizedBox(height: 5),
            Text(
              item.name,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _text : _text.withValues(alpha: 0.88),
                height: 1.35,
              ),
              softWrap: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Shared small widgets
// ═════════════════════════════════════════════════════════════════════════════

/// Semi-transparent icon button used as overlay on map / images
class _TapIcon extends StatelessWidget {
  const _TapIcon({required this.icon, required this.onTap, this.size = 32, this.iconSize = 18});
  final IconData icon; final VoidCallback onTap; final double size, iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Icon(icon, size: iconSize, color: Colors.white),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label; final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.22), width: 0.8),
    ),
    child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
  );
}

class _PageNum extends StatelessWidget {
  const _PageNum({required this.page, required this.current, required this.onTap});
  final int page, current; final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final active = page == current;
    return GestureDetector(
      onTap: () => onTap(page),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 26, height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: active ? _blue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: active ? null : Border.all(color: Colors.white.withValues(alpha: 0.14)),
          boxShadow: active
              ? [BoxShadow(color: _blue.withValues(alpha: 0.32), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${page + 1}',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: active ? Colors.white : _textSec),
        ),
      ),
    );
  }
}

class _PagBtn extends StatelessWidget {
  const _PagBtn({required this.icon, required this.enabled, required this.onTap});
  final IconData icon; final bool enabled; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 28, height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: enabled ? Colors.white.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: enabled ? _text : _hint.withValues(alpha: 0.4)),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.subtitle, this.isError = false});
  final IconData icon; final String title, subtitle; final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? _error : _blue;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.22), width: 1.5),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(color: _text, fontSize: 14.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: _textSec, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}