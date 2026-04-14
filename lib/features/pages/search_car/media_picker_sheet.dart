import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

// ── Public API ────────────────────────────────────────────────────────────────

/// Opens the Telegram-style media picker bottom sheet.
/// Returns the picked [XFile] or `null` if dismissed.
Future<XFile?> showMediaPickerSheet(BuildContext context) {
  return showModalBottomSheet<XFile?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    builder: (_) => const _MediaPickerSheet(),
  );
}

// ── Constants ─────────────────────────────────────────────────────────────────

const _kAccent   = Color(0xFFF59E0B); // amber — matches car page
const _kCamAccent = Color(0xFF00D68F); // teal — camera indicator
const _kCols     = 3;
const _kGap      = 2.0;
const _kMaxLoad  = 72;

// ═══════════════════════════════════════════════════════════════════════════════
//  SHEET WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _MediaPickerSheet extends StatefulWidget {
  const _MediaPickerSheet();
  @override
  State<_MediaPickerSheet> createState() => _MediaPickerSheetState();
}

class _MediaPickerSheetState extends State<_MediaPickerSheet>
    with WidgetsBindingObserver {
  // ── Camera ────────────────────────────────────────────────────────────────
  CameraController? _cam;
  bool _camReady   = false;
  bool _camError   = false;

  // ── Gallery ───────────────────────────────────────────────────────────────
  List<AssetEntity> _assets      = [];
  bool _permissionDenied         = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cam?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cam?.dispose();
      _cam = null;
      if (mounted) setState(() => _camReady = false);
    } else if (state == AppLifecycleState.resumed && !_camReady && !_camError) {
      _initCamera();
    }
  }

  Future<void> _init() async {
    await Future.wait([_initCamera(), _loadGallery()]);
  }

  // ── Camera init ───────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) setState(() => _camError = true);
        return;
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _camError = true);
        return;
      }
      final ctrl = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      _cam = ctrl;
      setState(() => _camReady = true);
    } catch (_) {
      if (mounted) setState(() => _camError = true);
    }
  }

  // ── Gallery load ──────────────────────────────────────────────────────────

  Future<void> _loadGallery() async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.isAuth) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );
    if (albums.isEmpty) return;
    final assets = await albums.first.getAssetListPaged(page: 0, size: _kMaxLoad);
    if (mounted) setState(() => _assets = assets);
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _capturePhoto() async {
    final ctrl = _cam;
    if (ctrl == null || !_camReady) return;
    try {
      HapticFeedback.mediumImpact();
      final file = await ctrl.takePicture();
      if (mounted) Navigator.pop(context, file);
    } catch (_) {}
  }

  Future<void> _pickAsset(AssetEntity asset) async {
    HapticFeedback.lightImpact();
    final file = await asset.loadFile();
    if (file == null || !mounted) return;
    Navigator.pop(context, XFile(file.path));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final mq       = MediaQuery.of(context);
    final sheetH   = mq.size.height * 0.74;

    final bg       = isDark ? const Color(0xFF0B1120) : const Color(0xFFF2F4F8);
    final border   = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.grey.shade200;

    return Container(
      height: sheetH + mq.padding.bottom,
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border:       Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: isDark ? 0.55 : 0.16),
            blurRadius: 40,
            offset:     const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          _Handle(isDark: isDark),
          _Header(
            isDark:  isDark,
            count:   _assets.length,
            onClose: () => Navigator.pop(context),
          ),
          // ── Main content ─────────────────────────────────────────────
          Expanded(
            child: _permissionDenied
                ? _PermissionDenied(isDark: isDark)
                : _buildGrid(isDark),
          ),
          SizedBox(height: mq.padding.bottom),
        ],
      ),
    );
  }

  Widget _buildGrid(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: _kGap),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:     _kCols,
        crossAxisSpacing:   _kGap,
        mainAxisSpacing:    _kGap,
        childAspectRatio:   1,
      ),
      itemCount: 1 + _assets.length, // camera cell + gallery cells
      itemBuilder: (_, i) {
        if (i == 0) {
          return _CameraCell(
            ctrl:     _cam,
            isReady:  _camReady,
            hasError: _camError,
            isDark:   isDark,
            onTap:    _capturePhoto,
          );
        }
        final asset = _assets[i - 1];
        return _GalleryCell(
          asset:   asset,
          isDark:  isDark,
          onTap:   () => _pickAsset(asset),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  DRAG HANDLE
// ═══════════════════════════════════════════════════════════════════════════════

class _Handle extends StatelessWidget {
  const _Handle({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width:  40,
        height: 4,
        decoration: BoxDecoration(
          color:        isDark ? Colors.white24 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  HEADER  —  icon + title + photo count + close button
// ═══════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({
    required this.isDark,
    required this.count,
    required this.onClose,
  });

  final bool isDark;
  final int count;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final titleC    = isDark ? Colors.white : const Color(0xFF0D1B3E);
    final subtitleC = isDark ? Colors.white38 : Colors.grey.shade500;
    final divC      = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.grey.shade200;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 12, 12),
          child: Row(
            children: [
              // Icon badge
              Container(
                width:  38,
                height: 38,
                decoration: BoxDecoration(
                  color:        _kAccent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(11),
                  border:       Border.all(
                    color: _kAccent.withValues(alpha: 0.28),
                    width: 1,
                  ),
                ),
                child: const Icon(
                    Icons.photo_library_outlined, size: 19, color: _kAccent),
              ),
              const SizedBox(width: 12),
              // Titles
              Column(
                mainAxisSize:       MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recents',
                    style: TextStyle(
                      fontSize:   16,
                      fontWeight: FontWeight.w800,
                      color:      titleC,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (count > 0)
                    Text(
                      '$count photos available',
                      style: TextStyle(
                        fontSize:   10.5,
                        color:      subtitleC,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                ],
              ),
              const Spacer(),
              // Close
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width:  32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade100,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size:  16,
                    color: isDark ? Colors.white60 : Colors.grey.shade500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
        Container(height: 1, color: divC),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CAMERA CELL  —  live preview + pulsing border + capture on tap
// ═══════════════════════════════════════════════════════════════════════════════

class _CameraCell extends StatefulWidget {
  const _CameraCell({
    required this.ctrl,
    required this.isReady,
    required this.hasError,
    required this.isDark,
    required this.onTap,
  });

  final CameraController? ctrl;
  final bool isReady;
  final bool hasError;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_CameraCell> createState() => _CameraCellState();
}

class _CameraCellState extends State<_CameraCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final cellBg = isDark ? const Color(0xFF0D1829) : const Color(0xFFE2E8F0);

    return GestureDetector(
      onTap: widget.isReady ? widget.onTap : null,
      child: Stack(
        fit: StackFit.expand,
        children: [

          // ── Background / live preview ──────────────────────────────
          if (widget.isReady && widget.ctrl != null)
            // Center-crop the camera preview into the square cell
            ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width:  widget.ctrl!.value.previewSize?.height ?? 480,
                  height: widget.ctrl!.value.previewSize?.width  ?? 640,
                  child:  CameraPreview(widget.ctrl!),
                ),
              ),
            )
          else
            Container(color: cellBg),

          // ── Loading spinner (before ready, no error) ───────────────
          if (!widget.isReady && !widget.hasError)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) => Center(
                child: Opacity(
                  opacity: 0.35 + 0.65 * _pulse.value,
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size:  34,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),

          // ── Error state ────────────────────────────────────────────
          if (widget.hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.no_photography_outlined,
                      size:  28,
                      color: isDark ? Colors.white24 : Colors.grey.shade400),
                  const SizedBox(height: 6),
                  Text(
                    'Unavailable',
                    style: TextStyle(
                      fontSize:   10,
                      color:      isDark ? Colors.white30 : Colors.grey.shade400,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),

          // ── Bottom gradient label ──────────────────────────────────
          if (widget.isReady || !widget.hasError)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end:   Alignment.topCenter,
                    colors: [Color(0xCC000000), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Camera',
                      style: TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w700,
                        color:      Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Pulsing accent border ──────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) => Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _kCamAccent.withValues(
                      alpha: widget.isReady
                          ? 0.80
                          : 0.25 + 0.40 * _pulse.value,
                    ),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // ── Shutter ripple overlay on ready ────────────────────────
          if (widget.isReady)
            Positioned(
              top: 8, right: 8,
              child: Container(
                width:  26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kCamAccent.withValues(alpha: 0.20),
                  border: Border.all(
                    color: _kCamAccent.withValues(alpha: 0.60),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.circle,
                  size:  12,
                  color: _kCamAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  GALLERY CELL  —  thumbnail with scale-press feedback
// ═══════════════════════════════════════════════════════════════════════════════

class _GalleryCell extends StatefulWidget {
  const _GalleryCell({
    required this.asset,
    required this.isDark,
    required this.onTap,
  });

  final AssetEntity asset;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_GalleryCell> createState() => _GalleryCellState();
}

class _GalleryCellState extends State<_GalleryCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  // Cache the thumbnail future so rebuilds don't re-fetch
  late final Future<dynamic> _thumbFuture;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0,
      upperBound: 0.06,
    );
    _thumbFuture = widget.asset.thumbnailDataWithSize(
      const ThumbnailSize.square(300),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cellBg = widget.isDark
        ? const Color(0xFF141D30)
        : Colors.grey.shade200;

    return AnimatedBuilder(
      animation: _press,
      builder: (_, child) =>
          Transform.scale(scale: 1.0 - _press.value, child: child!),
      child: GestureDetector(
        onTapDown:   (_) => _press.forward(),
        onTapUp:     (_) { _press.reverse(); widget.onTap(); },
        onTapCancel: () => _press.reverse(),
        child: FutureBuilder(
          future: _thumbFuture,
          builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done ||
                snap.data == null) {
              return Container(color: cellBg);
            }
            return Image.memory(
              snap.data!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => Container(
                color: cellBg,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: widget.isDark
                      ? Colors.white24
                      : Colors.grey.shade400,
                  size: 24,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PERMISSION DENIED  —  centred illustration with settings button
// ═══════════════════════════════════════════════════════════════════════════════

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textC = isDark ? Colors.white70 : const Color(0xFF374151);
    final subC  = isDark ? Colors.white38 : Colors.grey.shade500;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration
            Container(
              width:  72,
              height: 72,
              decoration: BoxDecoration(
                color:  _kAccent.withValues(alpha: 0.12),
                shape:  BoxShape.circle,
              ),
              child: const Icon(Icons.photo_library_outlined,
                  size: 34, color: _kAccent),
            ),
            const SizedBox(height: 22),
            Text(
              'Photos Access Required',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w800,
                color:      textC,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Allow access to your photos so you can\nselect a vehicle image.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize:   13,
                color:      subC,
                height:     1.5,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: openAppSettings,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  color:        _kAccent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _kAccent.withValues(alpha: 0.30),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Open Settings',
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    color:      _kAccent,
                    fontFamily: 'Poppins',
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