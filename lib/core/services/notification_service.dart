// lib/core/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  print('Background message: ${message.messageId}');
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> initialize(String uid) async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and save token
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(uid, token);

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) => _saveToken(uid, token));

    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        // Show local notification using flutter_local_notifications
        print('Foreground: ${notification.title}');
      }
    });

    // Background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  static Future<void> _saveToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }

  static Future<void> sendNotification({
    required String targetUid,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    // Get target user's FCM tokens
    final doc = await _firestore.collection('users').doc(targetUid).get();
    final tokens = List<String>.from(doc.data()?['fcmTokens'] ?? []);

    // Save notification to Firestore
    await _firestore.collection('notifications').add({
      'uid': targetUid,
      'title': title,
      'body': body,
      'data': data ?? {},
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Note: Send FCM via Cloud Functions in production
  }
}
