// lib/core/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

// Raw Firebase auth stream
final firebaseAuthProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Current user model provider — never throws, returns null safely
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authAsync = ref.watch(firebaseAuthProvider);

  return authAsync.when(
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
    data: (firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);

      // Stream the user doc, but handle errors gracefully
      return FirebaseAuth.instance.authStateChanges().asyncMap((user) async {
        if (user == null) return null;
        try {
          final doc =
              await ref.read(userRepositoryProvider).getUserById(user.uid);
          return doc;
        } catch (e) {
          // Return a basic user model if Firestore fails
          return UserModel(
            uid: user.uid,
            email: user.email ?? '',
            username: user.email?.split('@')[0] ?? 'user',
            displayName: user.displayName ?? 'User',
            photoUrl: user.photoURL ?? '',
            createdAt: DateTime.now(),
            followers: const [],
            following: const [],
            postsCount: 0,
          );
        }
      });
    },
  );
});

// Auth notifier for login/signup actions
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._repo) : super(const AsyncValue.data(null));

  final AuthRepository _repo;

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.signUpWithEmail(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
      ),
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.signInWithEmail(email: email, password: password),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.signInWithGoogle);
  }

  Future<void> signOut() async {
    try {
      await _repo.signOut();
    } catch (e) {
      // ignore sign out errors
    }
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);
