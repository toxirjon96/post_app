import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

// ─── Public API ────────────────────────────────────────────────────────────────

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

// ─── Design Tokens ─────────────────────────────────────────────────────────────

const _kBg    = Color(0xFF17212B); // Telegram dark
const _kCell  = Color(0xFF0D1520); // camera cell bg
const _kBlue  = Color(0xFF2AABEE); // Telegram accent
const _kCols  = 3;
const _kGap   = 2.0;
const _kMax   = 80;

// ═══════════════════════════════════════════════════════════════════════════════
//  SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _MediaPickerSheet extends StatefulWidget {
  const _MediaPickerSheet();

  @override
  State<_MediaPickerSheet> createState() => _MediaPickerSheetState();
}

class _MediaPickerSheetState extends State<_MediaPickerSheet>
    with WidgetsBindingObserver {
  List<AssetEntity> _assets          = [];
  bool              _permissionDenied = false;
  bool              _loading          = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadGallery();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _permissionDenied) {
      if (mounted) setState(() => _permissionDenied = false);
      _loadGallery();
    }
  }

  Future<void> _loadGallery() async {
    if (mounted) setState(() => _loading = true);
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.hasAccess) {
      if (mounted) setState(() { _permissionDenied = true; _loading = false; });
      return;
    }
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );
    final assets = albums.isEmpty
        ? <AssetEntity>[]
        : await albums.first.getAssetListPaged(page: 0, size: _kMax);
    if (mounted) setState(() { _assets = assets; _loading = false; });
  }

  Future<void> _openCamera() async {
    final XFile? file = await Navigator.of(context, rootNavigator: true).push<XFile?>(
      PageRouteBuilder<XFile?>(
        opaque: true,
        transitionDuration:        const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const _FullScreenCamera(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end:   Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
    if (file != null && mounted) Navigator.pop(context, file);
  }

  Future<void> _pickAsset(AssetEntity asset) async {
    HapticFeedback.lightImpact();
    final file = await asset.loadFile();
    if (file == null || !mounted) return;
    Navigator.pop(context, XFile(file.path));
  }

  @override
  Widget build(BuildContext context) {
    final mq     = MediaQuery.of(context);
    final sheetH = mq.size.height * 0.76;

    return Container(
      height: sheetH + mq.padding.bottom,
      decoration: const BoxDecoration(
        color:        _kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _Handle(),
          _Header(
            count:   _assets.length,
            loading: _loading && !_permissionDenied,
            onClose: () => Navigator.pop(context),
          ),
          Expanded(
            child: _permissionDenied
                ? _PermissionDenied(
                    onRetry: () {
                      setState(() => _permissionDenied = false);
                      _loadGallery();
                    },
                    onSettings: openAppSettings,
                  )
                : _loading
                    ? _SkeletonGrid(onCameraTap: _openCamera)
                    : _buildGrid(),
          ),
          SizedBox(height: mq.padding.bottom),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding:      const EdgeInsets.only(top: _kGap),
      physics:      const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   _kCols,
        crossAxisSpacing: _kGap,
        mainAxisSpacing:  _kGap,
        childAspectRatio: 1,
      ),
      itemCount:   1 + _assets.length,
      itemBuilder: (_, i) {
        if (i == 0) return _CameraCell(onTap: _openCamera);
        final asset = _assets[i - 1];
        return _GalleryCell(asset: asset, onTap: () => _pickAsset(asset));
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  HANDLE
// ═══════════════════════════════════════════════════════════════════════════════

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Container(
        width:  36,
        height: 4,
        decoration: BoxDecoration(
          color:        Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({
    required this.count,
    required this.loading,
    required this.onClose,
  });

  final int          count;
  final bool         loading;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize:       MainAxisSize.min,
                  children: [
                    const Text(
                      'File',
                      style: TextStyle(
                        color:       Colors.white,
                        fontSize:    17,
                        fontWeight:  FontWeight.w700,
                        fontFamily:  'Poppins',
                        letterSpacing: -0.3,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: (!loading && count > 0)
                          ? Text(
                              '$count photos',
                              key: ValueKey(count),
                              style: TextStyle(
                                color:      Colors.white.withValues(alpha: 0.38),
                                fontSize:   11.5,
                                fontFamily: 'Poppins',
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width:  30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.09),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size:  16,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(height: 0.5, color: Colors.white.withValues(alpha: 0.07)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SKELETON GRID  —  shimmer placeholders while gallery loads
// ═══════════════════════════════════════════════════════════════════════════════

class _SkeletonGrid extends StatefulWidget {
  const _SkeletonGrid({required this.onCameraTap});
  final VoidCallback onCameraTap;

  @override
  State<_SkeletonGrid> createState() => _SkeletonGridState();
}

class _SkeletonGridState extends State<_SkeletonGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final alpha = 0.05 + 0.07 * _pulse.value;
        return GridView.builder(
          padding:      const EdgeInsets.only(top: _kGap),
          physics:      const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   _kCols,
            crossAxisSpacing: _kGap,
            mainAxisSpacing:  _kGap,
            childAspectRatio: 1,
          ),
          itemCount:   10,
          itemBuilder: (_, i) => i == 0
              ? _CameraCell(onTap: widget.onCameraTap)
              : Container(color: Colors.white.withValues(alpha: alpha)),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CAMERA CELL  —  static tile, opens full-screen camera on tap
// ═══════════════════════════════════════════════════════════════════════════════

class _CameraCell extends StatefulWidget {
  const _CameraCell({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_CameraCell> createState() => _CameraCellState();
}

class _CameraCellState extends State<_CameraCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync:       this,
      duration:    const Duration(milliseconds: 90),
      lowerBound:  0,
      upperBound:  0.05,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _press,
      builder: (_, child) =>
          Transform.scale(scale: 1.0 - _press.value, child: child!),
      child: GestureDetector(
        onTapDown:   (_) => _press.forward(),
        onTapUp:     (_) { _press.reverse(); HapticFeedback.lightImpact(); widget.onTap(); },
        onTapCancel: () => _press.reverse(),
        child: Container(
          color: _kCell,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width:  54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size:  26,
                  color: Colors.white.withValues(alpha: 0.80),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Camera',
                style: TextStyle(
                  color:         Colors.white.withValues(alpha: 0.50),
                  fontSize:      11,
                  fontWeight:    FontWeight.w600,
                  fontFamily:    'Poppins',
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  GALLERY CELL  —  image thumbnail with press-scale feedback
// ═══════════════════════════════════════════════════════════════════════════════

class _GalleryCell extends StatefulWidget {
  const _GalleryCell({required this.asset, required this.onTap});
  final AssetEntity  asset;
  final VoidCallback onTap;

  @override
  State<_GalleryCell> createState() => _GalleryCellState();
}

class _GalleryCellState extends State<_GalleryCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController   _press;
  late final Future<Uint8List?>    _thumb;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync:      this,
      duration:   const Duration(milliseconds: 90),
      lowerBound: 0,
      upperBound: 0.05,
    );
    _thumb = widget.asset.thumbnailDataWithSize(const ThumbnailSize.square(300));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _press,
      builder: (_, child) =>
          Transform.scale(scale: 1.0 - _press.value, child: child!),
      child: GestureDetector(
        onTapDown:   (_) => _press.forward(),
        onTapUp:     (_) { _press.reverse(); widget.onTap(); },
        onTapCancel: () => _press.reverse(),
        child: FutureBuilder<Uint8List?>(
          future: _thumb,
          builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done || snap.data == null) {
              return Container(color: const Color(0xFF1A2536));
            }
            return Image.memory(
              snap.data!,
              fit:             BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF1A2536),
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white24,
                  size:  24,
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
//  PERMISSION DENIED
// ═══════════════════════════════════════════════════════════════════════════════

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({required this.onRetry, required this.onSettings});
  final VoidCallback onRetry;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  72,
              height: 72,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                color:  _kBlue.withValues(alpha: 0.12),
                border: Border.all(color: _kBlue.withValues(alpha: 0.25), width: 1),
              ),
              child: const Icon(Icons.photo_library_outlined, size: 32, color: _kBlue),
            ),
            const SizedBox(height: 20),
            const Text(
              'Photos Access Required',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w700,
                color:      Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Allow access to your photos so you can\nselect a vehicle image.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize:  13,
                color:     Colors.white.withValues(alpha: 0.45),
                height:    1.55,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onSettings,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color:        _kBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Open Settings',
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    color:      Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onRetry,
              child: Text(
                'Try Again',
                style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  color:      Colors.white.withValues(alpha: 0.35),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  FULL-SCREEN CAMERA
// ═══════════════════════════════════════════════════════════════════════════════

class _FullScreenCamera extends StatefulWidget {
  const _FullScreenCamera();

  @override
  State<_FullScreenCamera> createState() => _FullScreenCameraState();
}

class _FullScreenCameraState extends State<_FullScreenCamera> {
  List<CameraDescription> _cameras   = [];
  CameraController?       _ctrl;
  int                     _camIdx    = 0;
  FlashMode               _flash     = FlashMode.off;
  bool                    _ready     = false;
  bool                    _capturing = false;
  Uint8List?              _lastThumb;

  @override
  void initState() {
    super.initState();
    _initCamera(0);
    _loadLastThumb();
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  Future<void> _initCamera(int idx) async {
    if (mounted) setState(() => _ready = false);
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) Navigator.pop(context);
      return;
    }
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final old = _ctrl;
    _ctrl = null;
    await old?.dispose();

    final ctrl = CameraController(
      _cameras[idx],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await ctrl.initialize();
    if (!mounted) { await ctrl.dispose(); return; }
    await ctrl.setFlashMode(_flash);
    _ctrl   = ctrl;
    _camIdx = idx;
    setState(() => _ready = true);
  }

  Future<void> _loadLastThumb() async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.hasAccess) return;
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (albums.isEmpty) return;
    final assets = await albums.first.getAssetListPaged(page: 0, size: 1);
    if (assets.isEmpty) return;
    final thumb = await assets.first.thumbnailDataWithSize(
      const ThumbnailSize.square(120),
    );
    if (mounted) setState(() => _lastThumb = thumb);
  }

  Future<void> _capture() async {
    if (!_ready || _capturing || _ctrl == null) return;
    setState(() => _capturing = true);
    HapticFeedback.mediumImpact();
    try {
      final file = await _ctrl!.takePicture();
      if (mounted) Navigator.pop(context, file);
    } catch (_) {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || !_ready) return;
    HapticFeedback.selectionClick();
    await _initCamera((_camIdx + 1) % _cameras.length);
  }

  Future<void> _cycleFlash() async {
    if (_ctrl == null || !_ready) return;
    HapticFeedback.selectionClick();
    const modes = [FlashMode.off, FlashMode.auto, FlashMode.always];
    final next = modes[(modes.indexOf(_flash) + 1) % modes.length];
    setState(() => _flash = next);
    await _ctrl!.setFlashMode(next);
  }

  IconData get _flashIcon {
    if (_flash == FlashMode.auto)   return Icons.flash_auto_rounded;
    if (_flash == FlashMode.always) return Icons.flash_on_rounded;
    return Icons.flash_off_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Camera preview ───────────────────────────────────────────────
            if (_ready && _ctrl != null)
              ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width:  _ctrl!.value.previewSize?.height ?? 480.0,
                    height: _ctrl!.value.previewSize?.width  ?? 640.0,
                    child:  CameraPreview(_ctrl!),
                  ),
                ),
              ),

            // ── Loading indicator ────────────────────────────────────────────
            if (!_ready)
              const Center(
                child: SizedBox(
                  width:  28,
                  height: 28,
                  child:  CircularProgressIndicator(
                    color:       Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),

            // ── Top bar: back + flash ────────────────────────────────────────
            Positioned(
              top:   mq.padding.top + 8,
              left:  12,
              right: 12,
              child: Row(
                children: [
                  _CamIconButton(
                    icon:  Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _CamIconButton(
                    icon:   _flashIcon,
                    active: _flash != FlashMode.off,
                    onTap:  _cycleFlash,
                  ),
                ],
              ),
            ),

            // ── Bottom bar: gallery thumb | shutter | flip ───────────────────
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(32, 24, 32, 32 + mq.padding.bottom),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin:  Alignment.bottomCenter,
                    end:    Alignment.topCenter,
                    colors: [Color(0xB3000000), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment:  MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _GalleryThumb(thumb: _lastThumb),
                    _ShutterButton(
                      capturing: _capturing,
                      onCapture: _capture,
                    ),
                    _cameras.length > 1
                        ? _CamIconButton(
                            icon:  Icons.flip_camera_ios_rounded,
                            onTap: _flipCamera,
                          )
                        : const SizedBox(width: 48, height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Camera icon button ────────────────────────────────────────────────────────

class _CamIconButton extends StatelessWidget {
  const _CamIconButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData     icon;
  final VoidCallback onTap;
  final bool         active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? Colors.white.withValues(alpha: 0.92)
              : Colors.black.withValues(alpha: 0.45),
          border: Border.all(
            color: Colors.white.withValues(alpha: active ? 0 : 0.20),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size:  20,
          color: active ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}

// ─── Gallery thumbnail (bottom-left of full-screen camera) ────────────────────

class _GalleryThumb extends StatelessWidget {
  const _GalleryThumb({this.thumb});
  final Uint8List? thumb;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width:  48,
        height: 48,
        child: thumb != null
            ? Image.memory(thumb!, fit: BoxFit.cover, gaplessPlayback: true)
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color:  Colors.white.withValues(alpha: 0.10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.photo_outlined,
                  size:  22,
                  color: Colors.white.withValues(alpha: 0.40),
                ),
              ),
      ),
    );
  }
}

// ─── Shutter button ───────────────────────────────────────────────────────────

class _ShutterButton extends StatefulWidget {
  const _ShutterButton({required this.capturing, required this.onCapture});
  final bool         capturing;
  final VoidCallback onCapture;

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.86).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _anim.forward(),
      onTapUp:     (_) { _anim.reverse(); widget.onCapture(); },
      onTapCancel: () => _anim.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child!),
        child: SizedBox(
          width:  76,
          height: 76,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width:  76,
                height: 76,
                decoration: BoxDecoration(
                  shape:  BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.5),
                ),
              ),
              // Inner circle — shrinks while capturing
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve:    Curves.easeInOut,
                width:    widget.capturing ? 32 : 58,
                height:   widget.capturing ? 32 : 58,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}