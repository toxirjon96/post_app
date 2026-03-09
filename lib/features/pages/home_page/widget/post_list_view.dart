import 'package:flutter/material.dart';

import '../model/post_response.dart';
import 'post_card.dart';

class PostListView extends StatelessWidget {
  const PostListView({super.key, required this.posts});

  final List<PostResponse> posts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.indigo],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Posts',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              Text(
                posts.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostCard(post: posts[index], index: index);
            },
          ),
        ),
      ],
    );
  }
}
