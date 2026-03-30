// lib/core/providers/feed_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../repositories/post_repository.dart';
import 'auth_provider.dart';

class FeedNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  FeedNotifier(this._repo, this._ref) : super(const AsyncValue.loading()) {
    loadInitial();
  }

  final PostRepository _repo;
  final Ref _ref;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  Future<void> loadInitial() async {
    state = const AsyncValue.loading();
    _lastDoc = null;
    _hasMore = true;

    try {
      final user = _ref.read(currentUserProvider).value;
      final List<String> followingIds =
          List<String>.from(user?.following ?? <String>[]);

      final List<PostModel> posts = await _repo.getFeedPage(
        followingIds: followingIds,
      );
      state = AsyncValue.data(posts);
    } catch (e, st) {
      // On any error just show empty feed instead of crashing
      state = const AsyncValue.data(<PostModel>[]);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;

    final List<PostModel> current =
        List<PostModel>.from(state.value ?? <PostModel>[]);

    try {
      final user = _ref.read(currentUserProvider).value;
      final List<String> followingIds =
          List<String>.from(user?.following ?? <String>[]);

      final List<PostModel> more = await _repo.getFeedPage(
        lastDoc: _lastDoc,
        followingIds: followingIds,
      );

      _hasMore = more.length == 10;
      final List<PostModel> combined = <PostModel>[...current, ...more];
      state = AsyncValue.data(combined);
    } catch (e) {
      state = AsyncValue.data(current);
    } finally {
      _isLoadingMore = false;
    }
  }

  void toggleLikeOptimistic(String postId, String userId) {
    final List<PostModel> posts =
        List<PostModel>.from(state.value ?? <PostModel>[]);

    final idx = posts.indexWhere((p) => p.postId == postId);
    if (idx == -1) return;

    final post = posts[idx];
    final isLiked = post.isLikedByUser(userId);

    final List<String> updatedLikes = isLiked
        ? List<String>.from(post.likes).where((id) => id != userId).toList()
        : <String>[...List<String>.from(post.likes), userId];

    posts[idx] = PostModel(
      postId: post.postId,
      uid: post.uid,
      username: post.username,
      userPhotoUrl: post.userPhotoUrl,
      mediaUrl: post.mediaUrl,
      postType: post.postType,
      caption: post.caption,
      likes: updatedLikes,
      commentsCount: post.commentsCount,
      createdAt: post.createdAt,
    );

    state = AsyncValue.data(List<PostModel>.from(posts));
    _repo.toggleLike(postId: postId, userId: userId, isLiked: isLiked);
  }
}

final feedProvider =
    StateNotifierProvider<FeedNotifier, AsyncValue<List<PostModel>>>(
  (ref) => FeedNotifier(ref.read(postRepositoryProvider), ref),
);
