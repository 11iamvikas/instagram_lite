// lib/features/feed/widgets/post_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final VoidCallback onLike;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final isLiked = post.isLikedByUser(currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: GestureDetector(
              onTap: () => context.push('/profile/${post.uid}'),
              child: CircleAvatar(
                backgroundImage: post.userPhotoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(post.userPhotoUrl)
                    : null,
                child: post.userPhotoUrl.isEmpty
                    ? Text(post.username[0].toUpperCase())
                    : null,
              ),
            ),
            title: GestureDetector(
              onTap: () => context.push('/profile/${post.uid}'),
              child: Text(
                post.username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            subtitle: Text(timeago.format(post.createdAt)),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                if (post.uid == currentUserId)
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                const PopupMenuItem(value: 'report', child: Text('Report')),
              ],
            ),
          ),

          // Media
          GestureDetector(
            onDoubleTap: onLike,
            onTap: () => context.push('/post/${post.postId}'),
            child: AspectRatio(
              aspectRatio: 1,
              child: CachedNetworkImage(
                imageUrl: post.mediaUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[200]),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : null,
                  ),
                  onPressed: onLike,
                ),
                Text('${post.likes.length}'),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () => context.push('/post/${post.postId}'),
                ),
                Text('${post.commentsCount}'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Caption
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: post.username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '  ${post.caption}'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Shimmer skeleton
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(children: [
        ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.grey),
          title: Container(height: 12, width: 100, color: Colors.grey[300]),
        ),
        Container(height: 300, color: Colors.grey[200]),
        const SizedBox(height: 48),
      ]),
    );
  }
}
