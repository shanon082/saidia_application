import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'New Booking Request',
      'message': 'John Doe has requested your plumbing service for tomorrow',
      'time': DateTime.now().subtract(Duration(minutes: 5)),
      'type': 'booking',
      'read': false,
      'icon': Icons.book_online,
      'color': Colors.blue,
    },
    {
      'id': '2',
      'title': 'Booking Confirmed',
      'message': 'Your booking with Jane Smith has been confirmed',
      'time': DateTime.now().subtract(Duration(hours: 2)),
      'type': 'confirmation',
      'read': false,
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
    {
      'id': '3',
      'title': 'Payment Received',
      'message': 'UGX 2,500 has been credited to your account',
      'time': DateTime.now().subtract(Duration(days: 1)),
      'type': 'payment',
      'read': true,
      'icon': Icons.payment,
      'color': Colors.purple,
    },
    {
      'id': '4',
      'title': 'New Review',
      'message': 'You received a 5-star review from Michael',
      'time': DateTime.now().subtract(Duration(days: 2)),
      'type': 'review',
      'read': true,
      'icon': Icons.star,
      'color': Colors.amber,
    },
    {
      'id': '5',
      'title': 'Service Reminder',
      'message': 'Your electrical service appointment is tomorrow at 10 AM',
      'time': DateTime.now().subtract(Duration(days: 3)),
      'type': 'reminder',
      'read': true,
      'icon': Icons.notifications_active,
      'color': Colors.orange,
    },
    {
      'id': '6',
      'title': 'System Update',
      'message': 'New features available in the latest app update',
      'time': DateTime.now().subtract(Duration(days: 5)),
      'type': 'system',
      'read': true,
      'icon': Icons.system_update,
      'color': Colors.grey,
    },
    {
      'id': '7',
      'title': 'Promotion Available',
      'message': 'Special discount on marketing packages this week',
      'time': DateTime.now().subtract(Duration(days: 7)),
      'type': 'promotion',
      'read': true,
      'icon': Icons.local_offer,
      'color': Colors.red,
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['read'] = true;
      }
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((notification) => notification['id'] == id);
    });
  }

  void _clearAllNotifications() {
    setState(() {
      _notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['read']).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: Icon(Icons.mark_email_read),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: _clearAllNotifications,
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.grey.shade400),
                  SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(0),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Dismissible(
                  key: Key(notification['id']),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: Colors.white, size: 24),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) => _deleteNotification(notification['id']),
                  child: _notificationItem(notification),
                );
              },
            ),
    );
  }

  Widget _notificationItem(Map<String, dynamic> notification) {
    final time = notification['time'] as DateTime;
    final isRead = notification['read'] as bool;

    return Container(
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: notification['color'].withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            notification['icon'],
            color: notification['color'],
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification['title'],
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  color: isRead ? Colors.grey.shade700 : Colors.grey.shade900,
                ),
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              notification['message'],
              style: TextStyle(
                color: isRead ? Colors.grey.shade600 : Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                SizedBox(width: 4),
                Text(
                  _formatTime(time),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    notification['type'],
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          if (!isRead) {
            setState(() {
              notification['read'] = true;
            });
          }
          // Handle notification tap
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('dd MMM yyyy').format(time);
    }
  }
}