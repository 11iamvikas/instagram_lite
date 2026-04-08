import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/repositories/user_repository.dart';

final newChatQueryProvider = StateProvider<String>((ref) => '');

final newChatResultsProvider = FutureProvider<List<UserModel>>((ref) async {
  final query = ref.watch(newChatQueryProvider).trim().toLowerCase();
  if (query.length < 2) return [];
  final results = await ref.read(userRepositoryProvider).searchUsers(query);
  final me = ref.read(currentUserProvider).value?.uid;
  if (me == null) return results;
  return results.where((u) => u.uid != me).toList();
});

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final results = ref.watch(newChatResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New message'),
      ),
      body: currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Search by username',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      isDense: true,
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _controller.clear();
                                ref.read(newChatQueryProvider.notifier).state =
                                    '';
                                setState(() {});
                              },
                            ),
                    ),
                    onChanged: (val) {
                      ref.read(newChatQueryProvider.notifier).state = val;
                      setState(() {});
                    },
                  ),
                ),
                Expanded(
                  child: results.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (users) {
                      final q = ref.watch(newChatQueryProvider).trim();
                      if (q.length < 2) {
                        return const Center(
                          child: Text(
                            'Search usernames to start a chat',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      if (users.isEmpty) {
                        return Center(
                          child: Text(
                            'No users found for "$q"',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.photoUrl.isNotEmpty
                                  ? NetworkImage(user.photoUrl)
                                  : null,
                              child: user.photoUrl.isEmpty
                                  ? Text(
                                      user.username.isNotEmpty
                                          ? user.username[0].toUpperCase()
                                          : '?',
                                    )
                                  : null,
                            ),
                            title: Text(
                              user.username,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(user.displayName),
                            onTap: () => context.push('/chat/${user.uid}'),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

