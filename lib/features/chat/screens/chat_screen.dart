// lib/features/chat/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/message_model.dart';
import '../../../core/repositories/chat_repository.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/repositories/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String targetUid;
  const ChatScreen({super.key, required this.targetUid});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final String _chatId;

  @override
  void initState() {
    super.initState();
    final currentUid = ref.read(currentUserProvider).value?.uid ?? '';
    _chatId = ref
        .read(chatRepositoryProvider)
        .getChatRoomId(currentUid, widget.targetUid);
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final currentUid = ref.read(currentUserProvider).value?.uid ?? '';
    ref.read(chatRepositoryProvider).sendMessage(
          currentUid: currentUid,
          targetUid: widget.targetUid,
          text: text,
        );
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(currentUserProvider).value?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder(
          future:
              ref.read(userRepositoryProvider).getUserById(widget.targetUid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text('Chat');
            final user = snapshot.data!;
            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: user.photoUrl.isNotEmpty
                      ? NetworkImage(user.photoUrl)
                      : null,
                  child: user.photoUrl.isEmpty
                      ? Text(user.username[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 8),
                Text(user.username),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ref.read(chatRepositoryProvider).messagesStream(_chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final msg = MessageModel.fromMap(
                        docs[index].data() as Map<String, dynamic>);
                    final isMe = msg.senderId == currentUid;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color: isMe
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
