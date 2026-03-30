// lib/features/search/screens/search_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/user_model.dart';
import '../../../core/repositories/user_repository.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<UserModel>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.length < 2) return [];
  return ref.read(userRepositoryProvider).searchUsers(query);
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: false,
          decoration: InputDecoration(
            hintText: 'Search users...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            isDense: true,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
          ),
          onChanged: (val) =>
              ref.read(searchQueryProvider.notifier).state = val,
        ),
      ),
      body: results.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (users) {
          final query = ref.watch(searchQueryProvider);
          if (query.length < 2) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Search for users',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }
          if (users.isEmpty) {
            return Center(
              child: Text('No users found for "$query"',
                  style: const TextStyle(color: Colors.grey)),
            );
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.photoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(user.photoUrl)
                      : null,
                  child: user.photoUrl.isEmpty
                      ? Text(user.username[0].toUpperCase())
                      : null,
                ),
                title: Text(
                  user.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(user.displayName),
                trailing: Text(
                  '${user.followers.length} followers',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                onTap: () => context.push('/profile/${user.uid}'),
              );
            },
          );
        },
      ),
    );
  }
}
