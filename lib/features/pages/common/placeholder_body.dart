import 'package:flutter/material.dart';


class PlaceholderBody extends StatelessWidget {
  const PlaceholderBody({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onRefresh,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  /// If provided, wraps content in [RefreshIndicator].
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;

    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = isLandscape ? 56.0 : (isTablet ? 96.0 : 80.0);
        final containerSize = isLandscape ? 80.0 : (isTablet ? 116.0 : 96.0);
        final titleSize = isLandscape ? 18.0 : (isTablet ? 26.0 : 22.0);
        final subtitleSize = isLandscape ? 13.0 : (isTablet ? 15.0 : 14.0);

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(isLandscape ? 24 : 40),
                child: isLandscape
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _iconWidget(isDark, containerSize, iconSize),
                          const SizedBox(width: 32),
                          Flexible(
                            child: _textContent(
                              isDark,
                              titleSize,
                              subtitleSize,
                              isLandscape,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _iconWidget(isDark, containerSize, iconSize),
                          const SizedBox(height: 24),
                          _textContent(
                            isDark,
                            titleSize,
                            subtitleSize,
                            isLandscape,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        color: color,
        child: content,
      );
    }
    return content;
  }

  Widget _iconWidget(bool isDark, double containerSize, double iconSize) {
    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        shape: BoxShape.circle,
        border:
            Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }

  Widget _textContent(
      bool isDark, double titleSize, double subtitleSize, bool isLandscape) {
    return Column(
      crossAxisAlignment:
          isLandscape ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F1629),
          ),
        ),
        SizedBox(height: isLandscape ? 6 : 10),
        Text(
          subtitle,
          textAlign: isLandscape ? TextAlign.start : TextAlign.center,
          style: TextStyle(
            fontSize: subtitleSize,
            color: isDark ? Colors.white38 : Colors.grey.shade500,
            height: 1.6,
          ),
        ),
        SizedBox(height: isLandscape ? 16 : 32),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 20 : 24,
            vertical: isLandscape ? 10 : 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'Coming Soon',
            style: TextStyle(
              color: Colors.white,
              fontSize: isLandscape ? 13 : 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}