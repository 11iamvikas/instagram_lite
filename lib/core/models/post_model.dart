// lib/core/models/post_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum PostType { image, video }

class PostModel extends Equatable {
  final String postId;
  final String uid;
  final String username;
  final String userPhotoUrl;
  final String mediaUrl;
  final PostType postType;
  final String caption;
  final List<String> likes;
  final int commentsCount;
  final DateTime createdAt;
  final List<String> tags;

  const PostModel({
    required this.postId,
    required this.uid,
    required this.username,
    required this.userPhotoUrl,
    required this.mediaUrl,
    required this.postType,
    this.caption = '',
    this.likes = const [],
    this.commentsCount = 0,
    required this.createdAt,
    this.tags = const [],
  });

  bool get isLikedBy => false; // overridden per-user in UI
  bool isLikedByUser(String userId) => likes.contains(userId);

  factory PostModel.fromMap(Map<String, dynamic> map) => PostModel(
        postId: map['postId'] ?? '',
        uid: map['uid'] ?? '',
        username: map['username'] ?? '',
        userPhotoUrl: map['userPhotoUrl'] ?? '',
        mediaUrl: map['mediaUrl'] ?? '',
        postType: map['postType'] == 'video' ? PostType.video : PostType.image,
        caption: map['caption'] ?? '',
        likes: List<String>.from(map['likes'] ?? []),
        commentsCount: map['commentsCount'] ?? 0,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        tags: List<String>.from(map['tags'] ?? []),
      );

  Map<String, dynamic> toMap() => {
        'postId': postId,
        'uid': uid,
        'username': username,
        'userPhotoUrl': userPhotoUrl,
        'mediaUrl': mediaUrl,
        'postType': postType.name,
        'caption': caption,
        'likes': likes,
        'commentsCount': commentsCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'tags': tags,
      };

  @override
  List<Object?> get props => [postId];
}
