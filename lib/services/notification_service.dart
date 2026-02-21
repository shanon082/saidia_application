import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await _saveToken();
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          _saveToken();
        }
      });

      _messaging.onTokenRefresh.listen((_) {
        _saveToken();
      });

      FirebaseMessaging.onMessage.listen((message) async {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;

        final title =
            message.notification?.title ?? message.data['title']?.toString();
        final body =
            message.notification?.body ?? message.data['body']?.toString();
        if (title == null || body == null) return;

        await _firestore.collection('notifications').add({
          'userId': uid,
          'title': title,
          'message': body,
          'type': message.data['type']?.toString() ?? 'system',
          'isRead': false,
          'data': message.data,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      // Keep app startup healthy on web dev if service worker isn't ready yet.
      if (!kIsWeb || e.code != 'failed-service-worker-registration') {
        rethrow;
      }
    }

    _initialized = true;
  }

  Future<void> _saveToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _firestore.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
