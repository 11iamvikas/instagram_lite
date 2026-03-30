// lib/features/feed/screens/feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/feed_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/stories_row.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'InstagramLite',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.send_outlined),
            onPressed: () => context.push('/chats'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(feedProvider.notifier).loadInitial(),
        child: feedState.when(
          loading: () => ListView.builder(
            itemCount: 5,
            itemBuilder: (_, __) => const PostCardSkeleton(),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(e.toString()),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(feedProvider.notifier).loadInitial(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (posts) => posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_library_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        'No posts yet',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Follow people or create your first post!',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.go('/create'),
                        child: const Text('Create Post'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: posts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return const StoriesRow();
                    final post = posts[index - 1];
                    return PostCard(
                      post: post,
                      currentUserId: currentUser?.uid ?? '',
                      onLike: () {
                        if (currentUser == null) return;
                        ref
                            .read(feedProvider.notifier)
                            .toggleLikeOptimistic(post.postId, currentUser.uid);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}
