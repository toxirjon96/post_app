import 'package:flutter/material.dart';

import '../../../../common/util/responsive.dart';
import '../model/post_response.dart';
import 'post_card.dart';

class PostListView extends StatelessWidget {
  const PostListView({
    super.key,
    required this.posts,
    this.onRefresh,
  });

  final List<PostResponse> posts;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final isTablet = shortestSide >= 600;
    final isLargeTablet = shortestSide >= 900;
    final useGrid = isLandscape || isTablet;

    Widget listContent = useGrid
        ? _buildGrid(context, isLandscape, isLargeTablet)
        : _buildList(context);

    if (onRefresh != null) {
      listContent = RefreshIndicator(
        onRefresh: onRefresh!,
        child: listContent,
      );
    }

    return Column(
      children: [
        _SummaryBanner(
            count: posts.length,
            isLandscape: isLandscape,
            isTablet: isTablet),
        Expanded(child: listContent),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: posts.length,
      itemBuilder: (context, index) =>
          PostCard(post: posts[index], index: index),
    );
  }

  Widget _buildGrid(BuildContext context, bool isLandscape, bool isLargeTablet) {
    // 3 columns on large tablets, 2 elsewhere
    final crossCount = isLargeTablet ? 3 : 2;
    final aspectRatio = isLargeTablet
        ? 1.1
        : isLandscape
            ? 1.4
            : 1.2;
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
        childAspectRatio: aspectRatio,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) =>
          PostCard(post: posts[index], index: index),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.count,
    required this.isLandscape,
    this.isTablet = false,
  });

  final int count;
  final bool isLandscape;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final compact = isLandscape && !isTablet;
    return Container(
      margin: EdgeInsets.all(compact ? 8 : isTablet ? 20 : 16),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : isTablet ? 24 : 20,
        vertical: compact ? 10 : isTablet ? 16 : 14,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B8EF8), Color(0xFF3B5BDB)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B8EF8).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.article_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Total Posts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}