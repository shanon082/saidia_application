import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saidia_app/services/firestore_services.dart';

class NotificationsPage extends StatelessWidget {
  NotificationsPage({super.key});

  final FirestoreService _service = FirestoreService();

  String _format(Timestamp? ts) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: _service.markAllNotificationsAsRead,
            icon: const Icon(Icons.mark_email_read),
          ),
          IconButton(
            onPressed: _service.clearAllNotifications,
            icon: const Icon(Icons.delete_outline),
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
            return Center(child: Text('Failed: ${snapshot.error}'));
          }

          final docs = [...(snapshot.data?.docs ?? [])];
          docs.sort((a, b) {
            final aTs = a.data()['createdAt'] as Timestamp?;
            final bTs = b.data()['createdAt'] as Timestamp?;
            return (bTs?.millisecondsSinceEpoch ?? 0).compareTo(
              aTs?.millisecondsSinceEpoch ?? 0,
            );
          });

          if (docs.isEmpty) {
            return const Center(child: Text('No notifications'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final isRead = (data['isRead'] as bool?) ?? false;
              return Dismissible(
                key: ValueKey(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _service.deleteNotification(doc.id),
                child: ListTile(
                  tileColor: isRead ? Colors.white : Colors.blue.shade50,
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.notifications,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  title: Text(
                    data['title']?.toString() ?? 'Notification',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${data['message'] ?? ''}\n${_format(data['createdAt'] as Timestamp?)}',
                  ),
                  isThreeLine: true,
                  trailing: !isRead
                      ? const Icon(Icons.circle, size: 10, color: Colors.blue)
                      : null,
                  onTap: () => _service.markNotificationAsRead(doc.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
