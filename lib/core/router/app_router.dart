// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/feed/screens/post_detail_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/create_post/screens/create_post_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../shared/screens/main_scaffold.dart';
import '../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(firebaseAuthProvider);

  return GoRouter(
    initialLocation: '/feed',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && isAuthRoute) return '/feed';
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/auth/register', builder: (_, __) => const RegisterScreen()),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/feed', builder: (_, __) => const FeedScreen()),
          GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
          GoRoute(
              path: '/create', builder: (_, __) => const CreatePostScreen()),
          GoRoute(
              path: '/notifications',
              builder: (_, __) => const NotificationsScreen()),
          GoRoute(
            path: '/profile/:uid',
            builder: (_, state) =>
                ProfileScreen(uid: state.pathParameters['uid']!),
          ),
        ],
      ),

      // Standalone routes
      GoRoute(
        path: '/post/:postId',
        builder: (_, state) =>
            PostDetailScreen(postId: state.pathParameters['postId']!),
      ),
      GoRoute(
        path: '/chat/:uid',
        builder: (_, state) =>
            ChatScreen(targetUid: state.pathParameters['uid']!),
      ),
      GoRoute(path: '/chats', builder: (_, __) => const ChatListScreen()),
    ],
  );
});
