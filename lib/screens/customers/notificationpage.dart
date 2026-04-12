import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saidia_app/screens/customers/chatPage.dart';
import 'package:saidia_app/services/firestore_services.dart';

class NotificationPage extends StatelessWidget {
  NotificationPage({super.key});

  final FirestoreService _service = FirestoreService();

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return 'Just now';
    final now = DateTime.now();
    final dt = ts.toDate();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'booking':
        return Icons.book_online;
      case 'payment':
        return Icons.payments;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'chat':
        return Icons.chat_bubble;
      case 'provider_application':
        return Icons.verified;
      case 'review':
        return Icons.rate_review_outlined;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'booking':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'wallet':
        return Colors.teal;
      case 'chat':
        return Colors.orange;
      case 'provider_application':
        return Colors.purple;
      case 'review':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Future<String?> _resolveProviderName(String providerId) async {
    try {
      final appDoc = await Supabase.instance.client
          .from('provider_applications')
          .select()
          .eq('userId', providerId)
          .maybeSingle();
      
      final specialization = appDoc?['specialization']?.toString();
      if (specialization != null && specialization.trim().isNotEmpty) {
        return specialization.trim();
      }

      final userDoc = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', providerId)
          .maybeSingle();
      
      final userName = userDoc?['name']?.toString();
      if (userName != null && userName.trim().isNotEmpty) {
        return userName.trim();
      }
    } catch (_) {}
    return null;
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    String docId,
    Map<String, dynamic> notificationData,
  ) async {
    final isRead = (notificationData['isRead'] as bool?) ?? false;
    if (!isRead) {
      await _service.markNotificationAsRead(docId);
    }

    final type = (notificationData['type'] as String?) ?? '';
    final payloadRaw = notificationData['data'];
    final payload = payloadRaw is Map<String, dynamic>
        ? payloadRaw
        : <String, dynamic>{};

    if (type == 'chat') {
      final senderId = payload['senderId']?.toString() ?? '';
      if (senderId.isEmpty) return;
      final providerName = await _resolveProviderName(senderId);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ChatPage(providerId: senderId, providerName: providerName),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _service.markAllNotificationsAsRead,
            icon: const Icon(Icons.mark_email_read_outlined),
            tooltip: 'Mark all read',
          ),
          IconButton(
            onPressed: _service.clearAllNotifications,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load notifications: ${snapshot.error}'),
            );
          }

          final docs = [...(snapshot.data?.docs ?? [])];
          docs.sort((a, b) {
            final aTs = a.data()['createdAt'] as Timestamp?;
            final bTs = b.data()['createdAt'] as Timestamp?;
            final aMs = aTs?.millisecondsSinceEpoch ?? 0;
            final bMs = bTs?.millisecondsSinceEpoch ?? 0;
            return bMs.compareTo(aMs);
          });
          final unreadCount = docs
              .where((d) => (d.data()['isRead'] as bool?) == false)
              .length;

          if (docs.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$unreadCount unread notification(s)'),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final type = (data['type'] as String?) ?? 'system';
                    final title = (data['title'] as String?) ?? 'Notification';
                    final message = (data['message'] as String?) ?? '';
                    final isRead = (data['isRead'] as bool?) ?? false;
                    final createdAt = data['createdAt'] as Timestamp?;
                    final color = _colorForType(type);

                    return Dismissible(
                      key: ValueKey(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _service.deleteNotification(doc.id),
                      child: ListTile(
                        tileColor: isRead ? Colors.white : Colors.blue.shade50,
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.12),
                          child: Icon(_iconForType(type), color: color),
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '$message\n${_formatTimestamp(createdAt)}',
                        ),
                        isThreeLine: true,
                        trailing: !isRead
                            ? const Icon(
                                Icons.brightness_1,
                                size: 10,
                                color: Colors.blue,
                              )
                            : null,
                        onTap: () =>
                            _handleNotificationTap(context, doc.id, data),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
