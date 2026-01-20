import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      color: Colors.blue.shade700,
                      size: 32,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '3 New Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Stay updated with your service requests',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Mark all read',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final notifications = [
                  {
                    'title': 'Booking Confirmed!',
                    'message': 'Your plumbing service with John Doe has been confirmed',
                    'time': 'Just now',
                    'icon': Icons.check_circle,
                    'color': Colors.green,
                    'read': false,
                  },
                  {
                    'title': 'New Message',
                    'message': 'Sarah Johnson sent you a message about your booking',
                    'time': '2 hours ago',
                    'icon': Icons.chat,
                    'color': Colors.blue,
                    'read': false,
                  },
                  {
                    'title': 'Payment Received',
                    'message': 'UGX 2,500 has been credited to your account',
                    'time': 'Yesterday',
                    'icon': Icons.payment,
                    'color': Colors.purple,
                    'read': true,
                  },
                  {
                    'title': 'New Review',
                    'message': 'You received a 5-star review from Michael',
                    'time': '2 days ago',
                    'icon': Icons.star,
                    'color': Colors.amber,
                    'read': true,
                  },
                  {
                    'title': 'Service Reminder',
                    'message': 'Your electrical service appointment is tomorrow at 10 AM',
                    'time': '1 week ago',
                    'icon': Icons.access_alarm,
                    'color': Colors.orange,
                    'read': true,
                  },
                ];
                
                final notification = notifications[index];
                
                return Dismissible(
                  key: ValueKey(index),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (notification['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          notification['icon'] as IconData,
                          color: notification['color'] as Color,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        notification['title'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: notification['read'] as bool ? Colors.grey.shade600 : Colors.black,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(
                            notification['message'] as String,
                            style: TextStyle(
                              color: notification['read'] as bool ? Colors.grey.shade500 : Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(width: 4),
                              Text(
                                notification['time'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              Spacer(),
                              if (!(notification['read'] as bool))
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
                        ],
                      ),
                      onTap: () {
                        // Handle notification tap
                      },
                    ),
                  ),
                );
              },
              childCount: 5,
            ),
          ),
        ],
      ),
    );
  }
}