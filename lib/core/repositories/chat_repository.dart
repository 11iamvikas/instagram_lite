// lib/core/repositories/chat_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatRoomId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<void> sendMessage({
    required String currentUid,
    required String targetUid,
    required String text,
    MessageType type = MessageType.text,
  }) async {
    final chatId = getChatRoomId(currentUid, targetUid);
    final messageId = const Uuid().v4();
    final now = Timestamp.now();

    final message = {
      'messageId': messageId,
      'senderId': currentUid,
      'text': text,
      'type': type.name,
      'createdAt': now,
      'isRead': false,
    };

    final batch = _firestore.batch();
    batch.set(
      _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId),
      message,
    );
    batch.set(
        _firestore.collection('chats').doc(chatId),
        {
          'participants': [currentUid, targetUid],
          'lastMessage': text,
          'lastMessageTime': now,
          'lastSenderId': currentUid,
          'unreadCount_$targetUid': FieldValue.increment(1),
        },
        SetOptions(merge: true));
    await batch.commit();
  }

  Stream<QuerySnapshot> messagesStream(String chatId) => _firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots();

  Stream<QuerySnapshot> chatListStream(String uid) => _firestore
      .collection('chats')
      .where('participants', arrayContains: uid)
      .orderBy('lastMessageTime', descending: true)
      .snapshots();

  Future<void> markAsRead(String chatId, String uid) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount_$uid': 0,
    });
    // Mark all messages as read
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: uid)
        .get();
    for (final doc in messages.docs) {
      doc.reference.update({'isRead': true});
    }
  }
}

final chatRepositoryProvider =
    Provider<ChatRepository>((ref) => ChatRepository());
