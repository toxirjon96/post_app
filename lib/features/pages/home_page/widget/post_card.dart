import 'package:flutter/material.dart';

import '../model/post_response.dart';

class PostCard extends StatefulWidget {
  final PostResponse post;
  final int index;

  const PostCard({
    super.key,
    required this.post,
    required this.index,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    fadeAnimation = Tween<double>(begin: 0, end: 1).animate(controller);
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) controller.forward();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: isLandscape ? 8 : 16,
            vertical: isLandscape ? 6 : 8,
          ),
          padding: EdgeInsets.all(isLandscape ? 12 : 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141830) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade100,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B8EF8).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_rounded,
                            size: 14, color: Color(0xFF1B8EF8)),
                        const SizedBox(width: 4),
                        Text(
                          'User ${widget.post.userId}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B8EF8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${widget.post.id}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.white30
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isLandscape ? 8 : 10),
              Text(
                widget.post.title,
                style: TextStyle(
                  fontSize: isLandscape ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F1629),
                  height: 1.3,
                ),
                maxLines: isLandscape ? 2 : 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isLandscape ? 6 : 10),
              Text(
                widget.post.body,
                style: TextStyle(
                  fontSize: isLandscape ? 12 : 14,
                  color: isDark
                      ? Colors.white54
                      : Colors.grey.shade600,
                  height: 1.5,
                ),
                maxLines: isLandscape ? 2 : 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}