import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      default:
        return Colors.grey;
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
                        onTap: () {
                          if (!isRead) {
                            _service.markNotificationAsRead(doc.id);
                          }
                        },
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
