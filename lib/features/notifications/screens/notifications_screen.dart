// lib/features/notifications/screens/notifications_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/providers/auth_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (currentUser) {
        // Not logged in yet
        if (currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Activity')),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('uid', isEqualTo: currentUser.uid)
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snap) {
              // Error from Firestore
              if (snap.hasError) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No activity yet',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Likes and comments will show up here',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                );
              }

              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snap.data!.docs;

              if (docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No activity yet',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Likes and comments will show up here',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  try {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isRead = data['isRead'] ?? false;
                    final title = data['title'] ?? '';
                    final body = data['body'] ?? '';
                    final createdAt = data['createdAt'] != null
                        ? (data['createdAt'] as Timestamp).toDate()
                        : DateTime.now();

                    if (!isRead) {
                      docs[index].reference.update({'isRead': true});
                    }

                    return Container(
                      color: isRead ? null : Colors.blue.withOpacity(0.05),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.notifications,
                              color: Colors.blue, size: 20),
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            fontWeight:
                                isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (body.isNotEmpty) Text(body),
                            Text(
                              timeago.format(createdAt),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: isRead
                            ? null
                            : Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                      ),
                    );
                  } catch (e) {
                    return const SizedBox.shrink();
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}
