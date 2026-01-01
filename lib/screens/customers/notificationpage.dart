// [file name]: notifications.dart
import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _notificationItem(
            'New Booking Request',
            'John Doe requested your plumbing service',
            'Just now',
            Icons.book_online,
            Colors.blue,
          ),
          _notificationItem(
            'Booking Confirmed',
            'Your booking with Jane Smith is confirmed',
            '2 hours ago',
            Icons.check_circle,
            Colors.green,
          ),
          _notificationItem(
            'Payment Received',
            'KES 2,500 received for completed service',
            'Yesterday',
            Icons.payment,
            Colors.green,
          ),
          _notificationItem(
            'New Review',
            'You received a 5-star review',
            '2 days ago',
            Icons.star,
            Colors.orange,
          ),
          _notificationItem(
            'System Update',
            'New features available in the app',
            '1 week ago',
            Icons.system_update,
            Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _notificationItem(String title, String subtitle, String time, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: Text(time, style: TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }
}