import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:saidia_app/services/firestore_services.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize with Supabase auth state changes
      _supabase.auth.onAuthStateChange.listen((data) {
        if (data.session?.user != null) {
          _initializeUserNotifications(data.session!.user.id);
        }
      });

      _initialized = true;
    } catch (e) {
      // Log error but don't crash app startup
      print('Notification service initialization error: $e');
    }
  }

  Future<void> _initializeUserNotifications(String userId) async {
    // When user signs in, set up realtime listener for their notifications
    // This will be used by other parts of the app
  }

  /// Add a new notification to the database
  Future<void> addNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'system',
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'data': data ?? {},
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      print('Error adding notification: $e');
    }
  }

  /// Get stream of unread notifications for current user
  Stream<List<Map<String, dynamic>>> getUnreadNotificationsStream() {
    final uid = FirestoreService.instance.currentUid;
    if (uid == null) return const Stream.empty();

    return _supabase
        .from('notifications')
        .select()
        .eq('userId', uid)
        .eq('isRead', false)
        .order('createdAt', ascending: false)
        .asStream();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'isRead': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }
}
