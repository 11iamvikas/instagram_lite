// lib/core/repositories/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isUsernameAvailable(String username, {String? excludeUid}) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    try {
      final snap = await _firestore
          .collection('users')
          .where('username', isEqualTo: normalized)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return true;

      if (excludeUid == null) return false;
      final existing = snap.docs.first.data();
      return existing['uid'] == excludeUid;
    } catch (e) {
      return false;
    }
  }

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

  Future<void> followUser({
    required String currentUid,
    required String targetUid,
    required String fromUsername,
  }) async {
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

      if (currentUid != targetUid) {
        await NotificationService.sendNotification(
          targetUid: targetUid,
          title: 'New follower',
          body: '$fromUsername started following you',
          data: {
            'type': 'follow',
            'fromUid': currentUid,
          },
        );
      }
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
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: normalized)
          .where('username', isLessThanOrEqualTo: '$normalized\uf8ff')
          .limit(20)
          .get();
      return snapshot.docs.map((d) => UserModel.fromMap(d.data())).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> completeProfile({
    required String uid,
    required String username,
    required String phoneNumber,
    required int age,
    String bio = '',
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    if (uid.isEmpty) {
      throw Exception('Invalid user');
    }
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(normalizedUsername) ||
        normalizedUsername.length < 3) {
      throw Exception(
          'Username must be at least 3 characters and use a-z, 0-9, _ only');
    }
    if (phoneNumber.trim().isEmpty) {
      throw Exception('Phone number is required');
    }
    if (age < 13 || age > 120) {
      throw Exception('Enter a valid age');
    }

    final available =
        await isUsernameAvailable(normalizedUsername, excludeUid: uid);
    if (!available) {
      throw Exception('Username already taken');
    }

    await _firestore.collection('users').doc(uid).set(
      {
        'uid': uid,
        'username': normalizedUsername,
        'phoneNumber': phoneNumber.trim(),
        'age': age,
        'bio': bio.trim(),
        'profileCompleted': true,
      },
      SetOptions(merge: true),
    );
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
