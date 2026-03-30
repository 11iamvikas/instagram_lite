// lib/core/repositories/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getUserById(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Stream<UserModel?> userStream(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _firestore.collection('users').doc(uid).snapshots().map((d) {
      if (!d.exists || d.data() == null) return null;
      try {
        return UserModel.fromMap(d.data()!);
      } catch (e) {
        return null;
      }
    });
  }

  Future<void> followUser(String currentUid, String targetUid) async {
    if (currentUid.isEmpty || targetUid.isEmpty) return;
    try {
      final batch = _firestore.batch();
      batch.update(_firestore.collection('users').doc(currentUid), {
        'following': FieldValue.arrayUnion([targetUid]),
      });
      batch.update(_firestore.collection('users').doc(targetUid), {
        'followers': FieldValue.arrayUnion([currentUid]),
      });
      await batch.commit();
    } catch (e) {
      // ignore
    }
  }

  Future<void> unfollowUser(String currentUid, String targetUid) async {
    if (currentUid.isEmpty || targetUid.isEmpty) return;
    try {
      final batch = _firestore.batch();
      batch.update(_firestore.collection('users').doc(currentUid), {
        'following': FieldValue.arrayRemove([targetUid]),
      });
      batch.update(_firestore.collection('users').doc(targetUid), {
        'followers': FieldValue.arrayRemove([currentUid]),
      });
      await batch.commit();
    } catch (e) {
      // ignore
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();
      return snapshot.docs.map((d) => UserModel.fromMap(d.data())).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? photoUrl,
  }) async {
    if (uid.isEmpty) return;
    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
      }
    } catch (e) {
      // ignore
    }
  }
}

final userRepositoryProvider =
    Provider<UserRepository>((ref) => UserRepository());
