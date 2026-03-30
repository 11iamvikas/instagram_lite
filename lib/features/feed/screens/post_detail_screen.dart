// lib/features/feed/screens/post_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/models/comment_model.dart';
import '../../../core/models/post_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/repositories/post_repository.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);
    await ref.read(postRepositoryProvider).addComment(
          postId: widget.postId,
          uid: currentUser.uid,
          username: currentUser.username,
          userPhotoUrl: currentUser.photoUrl,
          text: text,
        );
    _commentController.clear();
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .get(),
        builder: (context, postSnap) {
          if (!postSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!postSnap.data!.exists) {
            return const Center(child: Text('Post not found'));
          }

          final post =
              PostModel.fromMap(postSnap.data!.data() as Map<String, dynamic>);

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // Post image
                    SliverToBoxAdapter(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CachedNetworkImage(
                          imageUrl: post.mediaUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Post info
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author row
                            GestureDetector(
                              onTap: () => context.push('/profile/${post.uid}'),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage:
                                        post.userPhotoUrl.isNotEmpty
                                            ? CachedNetworkImageProvider(
                                                post.userPhotoUrl)
                                            : null,
                                    child: post.userPhotoUrl.isEmpty
                                        ? Text(post.username[0].toUpperCase())
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    post.username,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Text(
                                    timeago.format(post.createdAt),
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Caption
                            if (post.caption.isNotEmpty) Text(post.caption),
                            const SizedBox(height: 8),

                            // Likes count
                            Text(
                              '${post.likes.length} likes',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Divider(height: 24),
                            const Text(
                              'Comments',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),

                    // Comments list
                    StreamBuilder<QuerySnapshot>(
                      stream: ref
                          .read(postRepositoryProvider)
                          .commentsStream(widget.postId),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const SliverToBoxAdapter(
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final comments = snap.data!.docs
                            .map((d) => CommentModel.fromMap(
                                d.data() as Map<String, dynamic>))
                            .toList();

                        if (comments.isEmpty) {
                          return const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No comments yet. Be the first!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        }

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final comment = comments[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundImage:
                                      comment.userPhotoUrl.isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              comment.userPhotoUrl)
                                          : null,
                                  child: comment.userPhotoUrl.isEmpty
                                      ? Text(comment.username[0].toUpperCase())
                                      : null,
                                ),
                                title: RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context).style,
                                    children: [
                                      TextSpan(
                                        text: comment.username,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(text: '  ${comment.text}'),
                                    ],
                                  ),
                                ),
                                subtitle: Text(
                                  timeago.format(comment.createdAt),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              );
                            },
                            childCount: comments.length,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Comment input bar
              Container(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: currentUser?.photoUrl.isNotEmpty == true
                          ? CachedNetworkImageProvider(currentUser!.photoUrl)
                          : null,
                      child: currentUser?.photoUrl.isEmpty == true
                          ? Text(currentUser!.username[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: _addComment,
                            child: const Text('Post'),
                          ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
