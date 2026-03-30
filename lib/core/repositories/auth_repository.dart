// lib/core/repositories/auth_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    // Check username uniqueness
    final usernameCheck = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    if (usernameCheck.docs.isNotEmpty) {
      throw Exception('Username already taken');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;

    final userModel = UserModel(
      uid: user.uid,
      email: email,
      username: username,
      displayName: displayName,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
    return userModel;
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final doc =
        await _firestore.collection('users').doc(credential.user!.uid).get();
    return UserModel.fromMap(doc.data()!);
  }

  Future<UserModel> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        // Safely clean username — remove dots, spaces, special chars
        final rawUsername = (user.email ?? user.uid)
            .split('@')[0]
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9_]'), '_');

        // Ensure username is not empty
        final username = rawUsername.isEmpty
            ? 'user_${user.uid.substring(0, 6)}'
            : rawUsername;

        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          username: username,
          displayName: user.displayName ?? username,
          photoUrl: user.photoURL ?? '',
          createdAt: DateTime.now(),
          followers: const [],
          following: const [],
          postsCount: 0,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
        return userModel;
      }

      // Document exists — return it
      final data = doc.data();
      if (data == null) throw Exception('User data is null');
      return UserModel.fromMap(data);
    } catch (e) {
      // If Firestore fails, still return a basic user so app doesn't crash
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        username: 'user_${user.uid.substring(0, 6)}',
        displayName: user.displayName ?? 'User',
        photoUrl: user.photoURL ?? '',
        createdAt: DateTime.now(),
        followers: const [],
        following: const [],
        postsCount: 0,
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);
}

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());
