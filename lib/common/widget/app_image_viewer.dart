import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constant/theme_config.dart';

// ── Design tokens (local to this file) ───────────────────────────────────────
const _blue = AppColors.electricBlue;
const _hint = Color(0xFF415070);

// ═════════════════════════════════════════════════════════════════════════════
//  AppImageViewer — global modal image viewer with pinch & double-tap zoom
// ═════════════════════════════════════════════════════════════════════════════
class AppImageViewer {
  const AppImageViewer._();

  static Future<void> show(
    BuildContext context, {
    required List<String> urls,
    int initialIndex = 0,
    String? title,
  }) {
    assert(urls.isNotEmpty, 'urls must not be empty');
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close image viewer',
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, _) => _ImageViewerModal(
        urls: urls,
        initialIndex: initialIndex,
        title: title,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Modal widget
// ─────────────────────────────────────────────────────────────────────────────
class _ImageViewerModal extends StatefulWidget {
  const _ImageViewerModal({
    required this.urls,
    required this.initialIndex,
    this.title,
  });

  final List<String> urls;
  final int initialIndex;
  final String? title;

  @override
  State<_ImageViewerModal> createState() => _ImageViewerModalState();
}

class _ImageViewerModalState extends State<_ImageViewerModal>
    with TickerProviderStateMixin {
  late final PageController _pageCtrl;
  late int _idx;

  late final List<TransformationController> _transforms;
  late final AnimationController _zoomAniCtrl;
  Animation<Matrix4>? _zoomAni;
  TapDownDetails? _tapDown;

  @override
  void initState() {
    super.initState();
    _idx      = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
    _transforms = List.generate(
      widget.urls.length,
      (_) => TransformationController(),
    );
    _zoomAniCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final t in _transforms) {
      t.dispose();
    }
    _zoomAniCtrl.dispose();
    super.dispose();
  }

  // ── Double-tap zoom ───────────────────────────────────────────────────────
  void _onDoubleTap(int imgIdx) {
    final ctrl     = _transforms[imgIdx];
    final isZoomed = ctrl.value.getMaxScaleOnAxis() > 1.05;
    final target   = isZoomed
        ? Matrix4.identity()
        : _zoomMatrix(_tapDown?.localPosition ?? Offset.zero, 2.5);

    _zoomAni = Matrix4Tween(begin: ctrl.value.clone(), end: target)
        .animate(CurvedAnimation(parent: _zoomAniCtrl, curve: Curves.easeInOutCubic));
    _zoomAni!.addListener(() => ctrl.value = _zoomAni!.value);
    _zoomAniCtrl.forward(from: 0);
  }

  // ── Button zoom in/out ────────────────────────────────────────────────────
  void _zoomIn() {
    final ctrl     = _transforms[_idx];
    final current  = ctrl.value.getMaxScaleOnAxis();
    final newScale = (current * 1.5).clamp(0.7, 5.0);
    _animateToScale(newScale);
  }

  void _zoomOut() {
    final ctrl     = _transforms[_idx];
    final current  = ctrl.value.getMaxScaleOnAxis();
    final newScale = (current / 1.5).clamp(0.7, 5.0);
    _animateToScale(newScale);
  }

  void _animateToScale(double scale) {
    final ctrl   = _transforms[_idx];
    final target = Matrix4.identity()..scaleByDouble(scale, scale, 1.0, 1.0);
    _zoomAni = Matrix4Tween(begin: ctrl.value.clone(), end: target)
        .animate(CurvedAnimation(parent: _zoomAniCtrl, curve: Curves.easeInOutCubic));
    _zoomAni!.addListener(() => ctrl.value = _zoomAni!.value);
    _zoomAniCtrl.forward(from: 0);
  }

  static Matrix4 _zoomMatrix(Offset focalPoint, double scale) {
    return Matrix4.identity()
      ..translateByDouble(focalPoint.dx, focalPoint.dy, 0, 0)
      ..scaleByDouble(scale, scale, 1.0, 1.0)
      ..translateByDouble(-focalPoint.dx, -focalPoint.dy, 0, 0);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final count = widget.urls.length;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── PageView ───────────────────────────────────────────────────
          PageView.builder(
            controller: _pageCtrl,
            itemCount: count,
            onPageChanged: (i) {
              setState(() => _idx = i);
              _transforms[1 - i.clamp(0, count - 1)].value = Matrix4.identity();
            },
            itemBuilder: (ctx, i) => GestureDetector(
              onDoubleTapDown: (d) => _tapDown = d,
              onDoubleTap: () => _onDoubleTap(i),
              child: InteractiveViewer(
                transformationController: _transforms[i],
                minScale: 0.7,
                maxScale: 5.0,
                child: CachedNetworkImage(
                  imageUrl: widget.urls[i],
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (ctx, _) => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_blue),
                    ),
                  ),
                  errorWidget: (ctx, _, _) => const Center(
                    child: Icon(Icons.broken_image_outlined, color: _hint, size: 48),
                  ),
                ),
              ),
            ),
          ),

          // ── Top bar ────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  _IconBtn(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  if (widget.title != null)
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                            ),
                            child: Text(
                              widget.title!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Bottom bar: dots + zoom buttons ───────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Zoom in / out buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _IconBtn(icon: Icons.zoom_out_rounded, onTap: _zoomOut),
                        const SizedBox(width: 14),
                        _IconBtn(icon: Icons.zoom_in_rounded,  onTap: _zoomIn),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Page dots
                    if (count > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(count, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _idx ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _idx ? _blue : Colors.white.withValues(alpha: 0.32),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )),
                      ),
                    if (count > 1) const SizedBox(height: 7),
                    Text(
                      count > 1
                          ? 'Image ${_idx + 1} of $count  ·  Pinch or double-tap to zoom'
                          : 'Pinch or double-tap to zoom',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.50),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Prev / next arrows ─────────────────────────────────────────
          if (_idx > 0)
            Positioned(
              left: 8, top: 0, bottom: 0,
              child: Center(
                child: _IconBtn(
                  icon: Icons.chevron_left_rounded,
                  size: 40, iconSize: 22,
                  onTap: () => _pageCtrl.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  ),
                ),
              ),
            ),
          if (_idx < count - 1)
            Positioned(
              right: 8, top: 0, bottom: 0,
              child: Center(
                child: _IconBtn(
                  icon: Icons.chevron_right_rounded,
                  size: 40, iconSize: 22,
                  onTap: () => _pageCtrl.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Icon button used inside the modal ─────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.size = 36,
    this.iconSize = 18,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, size: iconSize, color: Colors.white),
    ),
  );
}