// lib/features/profile/screens/profile_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/post_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/user_repository.dart';

class ProfileScreen extends ConsumerWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (currentUser) {
        if (currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final resolvedUid =
            (uid == 'me' || uid.isEmpty) ? currentUser.uid : uid;
        final isMe = resolvedUid == currentUser.uid;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isMe ? currentUser.username : resolvedUid,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              if (isMe)
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                  },
                ),
            ],
          ),
          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(resolvedUid)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }

              if (!snap.hasData || snap.data == null || !snap.data!.exists) {
                return const Center(
                  child: Text('Profile not found'),
                );
              }

              final data = snap.data!.data() as Map<String, dynamic>?;
              if (data == null) {
                return const Center(child: Text('No profile data'));
              }

              final user = UserModel.fromMap(data);
              final isFollowing = currentUser.following.contains(resolvedUid);

              return RefreshIndicator(
                onRefresh: () async {},
                child: CustomScrollView(
                  slivers: [
                    // Profile header
                    SliverToBoxAdapter(
                      child: _ProfileHeader(
                        user: user,
                        isMe: isMe,
                        isFollowing: isFollowing,
                        currentUser: currentUser,
                      ),
                    ),

                    // Divider
                    const SliverToBoxAdapter(
                      child: Divider(height: 1),
                    ),

                    // Posts grid header
                    SliverToBoxAdapter(
                      child: _PostsGrid(uid: resolvedUid),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  final UserModel user;
  final bool isMe;
  final bool isFollowing;
  final UserModel currentUser;

  const _ProfileHeader({
    required this.user,
    required this.isMe,
    required this.isFollowing,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile picture
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: user.photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: user.photoUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.person,
                                size: 40, color: Colors.grey),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Text(
                                user.username.isNotEmpty
                                    ? user.username[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Text(
                              user.username.isNotEmpty
                                  ? user.username[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 24),

              // Stats — posts, followers, following
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatColumn(
                      label: 'Posts',
                      count: user.postsCount,
                    ),
                    _StatColumn(
                      label: 'Followers',
                      count: user.followers.length,
                    ),
                    _StatColumn(
                      label: 'Following',
                      count: user.following.length,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Display name
          if (user.displayName.isNotEmpty)
            Text(
              user.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 2),

          // Email
          if (user.email.isNotEmpty)
            Text(
              user.email,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),

          // Bio
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(user.bio, style: const TextStyle(fontSize: 14)),
          ],
          const SizedBox(height: 12),

          // Action buttons
          if (isMe) ...[
            SizedBox(
              width: double.infinity,
              height: 34,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () {
                        final userRepo = ref.read(userRepositoryProvider);
                        if (isFollowing) {
                          userRepo.unfollowUser(currentUser.uid, user.uid);
                        } else {
                          userRepo.followUser(currentUser.uid, user.uid);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing
                            ? Colors.grey.shade200
                            : const Color(0xFF405DE6),
                        foregroundColor:
                            isFollowing ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isFollowing ? 'Following' : 'Follow',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      onPressed: () => context.push('/chat/${user.uid}'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Message',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final int count;

  const _StatColumn({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatCount(count),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // Format large numbers like Instagram: 1.2K, 3.4M
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _PostsGrid extends StatelessWidget {
  final String uid;
  const _PostsGrid({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const SizedBox.shrink();
        }

        if (!snap.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final posts = snap.data!.docs
            .map((d) => PostModel.fromMap(d.data() as Map<String, dynamic>))
            .toList();

        if (posts.isEmpty) {
          return const SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No Posts Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Start sharing your moments',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // Posts grid
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return GestureDetector(
              onTap: () => context.push('/post/${post.postId}'),
              child: CachedNetworkImage(
                imageUrl: post.mediaUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey.shade200),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
