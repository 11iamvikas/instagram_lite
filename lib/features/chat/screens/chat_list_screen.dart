// lib/features/chat/screens/chat_list_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/providers/auth_provider.dart';
import '../../../core/repositories/chat_repository.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/models/user_model.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            ref.read(chatRepositoryProvider).chatListStream(currentUser.uid),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snap.data!.docs;
          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No messages yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Start a conversation by visiting a profile',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final data = chats[index].data() as Map<String, dynamic>;
              final participants =
                  List<String>.from(data['participants'] ?? []);
              final otherUid = participants
                  .firstWhere((id) => id != currentUser.uid, orElse: () => '');
              final lastMessage = data['lastMessage'] ?? '';
              final lastTime = data['lastMessageTime'] != null
                  ? (data['lastMessageTime'] as Timestamp).toDate()
                  : DateTime.now();
              final unread = data['unreadCount_${currentUser.uid}'] ?? 0;

              return FutureBuilder<UserModel?>(
                future: ref.read(userRepositoryProvider).getUserById(otherUid),
                builder: (context, userSnap) {
                  final user = userSnap.data;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundImage: user?.photoUrl.isNotEmpty == true
                          ? CachedNetworkImageProvider(user!.photoUrl)
                          : null,
                      child: user?.photoUrl.isEmpty != false
                          ? Text(user?.username[0].toUpperCase() ?? '?')
                          : null,
                    ),
                    title: Text(
                      user?.username ?? '...',
                      style: TextStyle(
                        fontWeight:
                            unread > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            unread > 0 ? FontWeight.bold : FontWeight.normal,
                        color: unread > 0 ? null : Colors.grey,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeago.format(lastTime),
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unread.toString(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () => context.push('/chat/$otherUid'),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
