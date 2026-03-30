// lib/core/models/message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image }

class MessageModel {
  final String messageId;
  final String senderId;
  final String text;
  final MessageType type;
  final DateTime createdAt;
  final bool isRead;

  const MessageModel({
    required this.messageId,
    required this.senderId,
    required this.text,
    this.type = MessageType.text,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
        messageId: map['messageId'] ?? '',
        senderId: map['senderId'] ?? '',
        text: map['text'] ?? '',
        type: map['type'] == 'image' ? MessageType.image : MessageType.text,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        isRead: map['isRead'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'messageId': messageId,
        'senderId': senderId,
        'text': text,
        'type': type.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRead': isRead,
      };
}
