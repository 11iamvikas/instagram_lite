// lib/core/repositories/post_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
//import '../models/comment_model.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const int _pageSize = 10;

  // Paginated feed query
  Query<Map<String, dynamic>> get feedQuery => _firestore
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .limit(_pageSize);

  Future<List<PostModel>> getFeedPage({
    DocumentSnapshot? lastDoc,
    List<String> followingIds = const [],
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(_pageSize);

    if (followingIds.isNotEmpty) {
      query = query.where('uid', whereIn: followingIds);
    }
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((d) => PostModel.fromMap(d.data())).toList();
  }

  Future<String> uploadMedia(File file, String postType) async {
    final id = const Uuid().v4();
    final ref = _storage.ref('posts/$postType/$id');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<PostModel> createPost({
    required String uid,
    required String username,
    required String userPhotoUrl,
    required File mediaFile,
    required PostType postType,
    required String caption,
    List<String> tags = const [],
  }) async {
    final postId = const Uuid().v4();
    final mediaUrl = await uploadMedia(mediaFile, postType.name);

    final post = PostModel(
      postId: postId,
      uid: uid,
      username: username,
      userPhotoUrl: userPhotoUrl,
      mediaUrl: mediaUrl,
      postType: postType,
      caption: caption,
      createdAt: DateTime.now(),
      tags: tags,
    );

    final batch = _firestore.batch();
    batch.set(_firestore.collection('posts').doc(postId), post.toMap());
    batch.update(_firestore.collection('users').doc(uid), {
      'postsCount': FieldValue.increment(1),
    });
    await batch.commit();
    return post;
  }

  Future<void> toggleLike({
    required String postId,
    required String userId,
    required bool isLiked,
  }) async {
    await _firestore.collection('posts').doc(postId).update({
      'likes': isLiked
          ? FieldValue.arrayRemove([userId])
          : FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> deletePost(String postId, String uid) async {
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('posts').doc(postId));
    batch.update(_firestore.collection('users').doc(uid), {
      'postsCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  // Comments
  Future<void> addComment({
    required String postId,
    required String uid,
    required String username,
    required String userPhotoUrl,
    required String text,
  }) async {
    final commentId = const Uuid().v4();
    final batch = _firestore.batch();

    batch.set(
      _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId),
      {
        'commentId': commentId,
        'uid': uid,
        'username': username,
        'userPhotoUrl': userPhotoUrl,
        'text': text,
        'createdAt': Timestamp.now(),
        'likes': [],
      },
    );
    batch.update(_firestore.collection('posts').doc(postId), {
      'commentsCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  Stream<QuerySnapshot> commentsStream(String postId) => _firestore
      .collection('posts')
      .doc(postId)
      .collection('comments')
      .orderBy('createdAt')
      .snapshots();
}

final postRepositoryProvider =
    Provider<PostRepository>((ref) => PostRepository());
