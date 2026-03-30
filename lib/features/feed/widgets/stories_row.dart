// lib/features/feed/widgets/stories_row.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/repositories/user_repository.dart';

final storiesProvider = FutureProvider<List<UserModel>>((ref) async {
  try {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null || currentUser.following.isEmpty) {
      return <UserModel>[];
    }
    final userRepo = ref.read(userRepositoryProvider);
    final futures =
        currentUser.following.take(20).map((uid) => userRepo.getUserById(uid));
    final users = await Future.wait(futures);
    return users.whereType<UserModel>().toList();
  } catch (e) {
    return <UserModel>[];
  }
});

class StoriesRow extends ConsumerWidget {
  const StoriesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final storiesAsync = ref.watch(storiesProvider);

    // Don't show stories row at all if no one to show
    final users = storiesAsync.value ?? <UserModel>[];
    final allUsers = <UserModel>[
      if (currentUser != null) currentUser,
      ...users,
    ];

    if (allUsers.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: allUsers.length,
        itemBuilder: (context, index) {
          final user = allUsers[index];
          final isCurrentUser =
              currentUser != null && user.uid == currentUser.uid && index == 0;
          return _StoryBubble(
            user: user,
            isCurrentUser: isCurrentUser,
          );
        },
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  final UserModel user;
  final bool isCurrentUser;

  const _StoryBubble({
    required this.user,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isCurrentUser
                      ? null
                      : const LinearGradient(
                          colors: [
                            Color(0xFFE040FB),
                            Color(0xFFFF6D00),
                            Color(0xFFFFD600),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: isCurrentUser ? Colors.grey.shade300 : null,
                ),
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: user.photoUrl.isNotEmpty
                        ? NetworkImage(user.photoUrl)
                        : null,
                    child: user.photoUrl.isEmpty
                        ? Text(
                            user.username.isNotEmpty
                                ? user.username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
              ),
              if (isCurrentUser)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 14,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 64,
            child: Text(
              isCurrentUser ? 'Your story' : user.username,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
