// lib/core/models/comment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class CommentModel extends Equatable {
  final String commentId;
  final String uid;
  final String username;
  final String userPhotoUrl;
  final String text;
  final List<String> likes;
  final DateTime createdAt;

  const CommentModel({
    required this.commentId,
    required this.uid,
    required this.username,
    required this.userPhotoUrl,
    required this.text,
    this.likes = const [],
    required this.createdAt,
  });

  bool isLikedByUser(String userId) => likes.contains(userId);

  factory CommentModel.fromMap(Map<String, dynamic> map) => CommentModel(
        commentId: map['commentId'] ?? '',
        uid: map['uid'] ?? '',
        username: map['username'] ?? '',
        userPhotoUrl: map['userPhotoUrl'] ?? '',
        text: map['text'] ?? '',
        likes: List<String>.from(map['likes'] ?? []),
        createdAt: (map['createdAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'commentId': commentId,
        'uid': uid,
        'username': username,
        'userPhotoUrl': userPhotoUrl,
        'text': text,
        'likes': likes,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  CommentModel copyWith({
    String? commentId,
    String? uid,
    String? username,
    String? userPhotoUrl,
    String? text,
    List<String>? likes,
    DateTime? createdAt,
  }) =>
      CommentModel(
        commentId: commentId ?? this.commentId,
        uid: uid ?? this.uid,
        username: username ?? this.username,
        userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
        text: text ?? this.text,
        likes: likes ?? this.likes,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [commentId, uid, text, createdAt];
}
