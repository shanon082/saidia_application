// [file name]: providerDashboard.dart (Updated)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saidia_app/auth/loginPage.dart';
import 'package:intl/intl.dart';
import 'package:saidia_app/screens/provider/earningspage.dart';
import 'package:saidia_app/screens/provider/schedulepage.dart';

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  late Stream<DocumentSnapshot> _providerDataStream;
  late Stream<QuerySnapshot> _bookingsStream;
  late Stream<QuerySnapshot> _reviewsStream;

  @override
  void initState() {
    super.initState();
    _providerDataStream = _getProviderDataStream();
    _bookingsStream = _getBookingsStream();
    _reviewsStream = _getReviewsStream();
  }

  Stream<DocumentSnapshot> _getProviderDataStream() {
    return _firestore
        .collection('provider_applications')
        .doc(_auth.currentUser!.uid)
        .snapshots();
  }

  Stream<QuerySnapshot> _getBookingsStream() {
    return _firestore
        .collection('bookings')
        .where('providerId', isEqualTo: _auth.currentUser!.uid)
        .orderBy('date')
        .snapshots();
  }

  Stream<QuerySnapshot> _getReviewsStream() {
    return _firestore
        .collection('reviews')
        .where('providerId', isEqualTo: _auth.currentUser!.uid)
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotifications(context),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _selectedIndex == 0 ? _buildDashboard() : _buildBookings(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF0D47A1),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: _providerDataStream,
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final name = data?['specialization'] ?? 'Provider';
              final category = data?['serviceCategory'] ?? 'Service';
              final image = data?['imageUrl'] ?? '';

              return DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: image.isNotEmpty
                          ? NetworkImage(image)
                          : null,
                      child: image.isEmpty
                          ? Icon(
                              Icons.handyman,
                              size: 40,
                              color: Color(0xFF0D47A1),
                            )
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.yellow, size: 16),
                        const SizedBox(width: 4),
                        const Text('4.8', style: TextStyle(color: Colors.white)),
                        const SizedBox(width: 16),
                        Text(
                          'KES ${data?['hourlyRate'] ?? '0'}/hr',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          _drawerItem(Icons.dashboard, 'Dashboard', () => setState(() => _selectedIndex = 0)),
          _drawerItem(Icons.calendar_today, 'Schedule', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => SchedulePage()));
          }),
          _drawerItem(Icons.book_online, 'Bookings', () => setState(() => _selectedIndex = 1)),
          _drawerItem(Icons.chat, 'Messages', () => setState(() => _selectedIndex = 2)),
          _drawerItem(Icons.attach_money, 'Earnings', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => EarningsPage()));
          }),
          _drawerItem(Icons.star, 'Reviews', () {
            Navigator.pop(context);
            _showReviews(context);
          }),
          _drawerItem(Icons.analytics, 'Analytics', () {
            Navigator.pop(context);
            _showAnalytics(context);
          }),
          _drawerItem(Icons.person, 'My Profile', () => setState(() => _selectedIndex = 3)),
          const Divider(),
          _drawerItem(Icons.settings, 'Settings', () {
            Navigator.pop(context);
            _showSettings(context);
          }),
          _drawerItem(Icons.help, 'Help & Support', () {
            Navigator.pop(context);
            _showHelp(context);
          }),
          const Divider(),
          _drawerItem(Icons.logout, 'Logout', () => _logout(context), isLogout: true),
        ],
      ),
    );
  }

  ListTile _drawerItem(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Color(0xFF0D47A1)),
      title: Text(title, style: TextStyle(color: isLogout ? Colors.red : Colors.black87)),
      onTap: onTap,
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard('Today\'s Bookings', '3', Icons.calendar_today, Color(0xFF2196F3)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _statCard('Pending', '2', Icons.pending, Color(0xFFFF9800)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Quick Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _quickStatCard('Total Bookings', '45', Icons.book_online, Color(0xFF4CAF50)),
              _quickStatCard('Earnings', 'KES 12,500', Icons.attach_money, Color(0xFF2196F3)),
              _quickStatCard('Rating', '4.8', Icons.star, Color(0xFFFF9800)),
              _quickStatCard('Reviews', '28', Icons.reviews, Color(0xFF9C27B0)),
            ],
          ),

          const SizedBox(height: 24),

          // Today's Schedule
          const Text(
            "Today's Schedule",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _bookingsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final bookings = snapshot.data!.docs;
              final todayBookings = bookings.where((booking) {
                final data = booking.data() as Map<String, dynamic>;
                final date = data['date'] as String?;
                return date == DateFormat('yyyy-MM-dd').format(DateTime.now());
              }).toList();

              if (todayBookings.isEmpty) {
                return _emptyState('No bookings scheduled for today', Icons.calendar_today);
              }

              return Column(
                children: todayBookings.take(3).map((booking) {
                  final data = booking.data() as Map<String, dynamic>;
                  return _bookingCard(data);
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // Recent Reviews
          const Text(
            "Recent Reviews",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _reviewsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final reviews = snapshot.data!.docs;

              if (reviews.isEmpty) {
                return _emptyState('No reviews yet', Icons.reviews);
              }

              return Column(
                children: reviews.map((review) {
                  final data = review.data() as Map<String, dynamic>;
                  return _reviewCard(data);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookingCard(Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF0D47A1),
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          data['customerName'] ?? 'Customer',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${data['date']} • ${data['time']}'),
            Text(data['details'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Chip(
          label: Text(
            data['status'] ?? 'pending',
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
          backgroundColor: data['status'] == 'confirmed' ? Colors.green : Colors.orange,
        ),
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  data['customerName'] ?? 'Anonymous',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Row(
                  children: List.generate(5, (index) => Icon(
                    Icons.star,
                    size: 16,
                    color: index < (data['rating'] ?? 0) ? Colors.yellow : Colors.grey[300],
                  )),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(data['comment'] ?? ''),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd MMM yyyy').format(
                (data['timestamp'] as Timestamp).toDate(),
              ),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookings() {
    return StreamBuilder<QuerySnapshot>(
      stream: _bookingsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState('No bookings yet', Icons.calendar_today);
        }

        final bookings = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final data = bookings[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF0D47A1),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  data['customerName'] ?? 'Customer',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${data['date']} • ${data['time']}'),
                    Text(data['details'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Chip(
                      label: Text(
                        data['status'] ?? 'pending',
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                      backgroundColor: data['status'] == 'confirmed' 
                          ? Colors.green 
                          : data['status'] == 'cancelled'
                            ? Colors.red
                            : Colors.orange,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'KES ${data['price'] ?? data['hourlyRate'] ?? '0'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                onTap: () => _showBookingDetails(data),
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailItem('Customer:', data['customerName'] ?? 'N/A'),
            _detailItem('Date:', data['date'] ?? 'N/A'),
            _detailItem('Time:', data['time'] ?? 'N/A'),
            _detailItem('Status:', data['status'] ?? 'pending'),
            _detailItem('Amount:', 'KES ${data['price'] ?? data['hourlyRate'] ?? '0'}'),
            const SizedBox(height: 8),
            const Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(data['details'] ?? 'No details provided'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (data['status'] == 'pending')
            ElevatedButton(
              onPressed: () => _updateBookingStatus(data['bookingId'] ?? '', 'confirmed'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Confirm'),
            ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking $status'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showNotifications(BuildContext context) {
    // TODO: Implement notifications dialog
  }

  void _showReviews(BuildContext context) {
    // TODO: Implement reviews page
  }

  void _showAnalytics(BuildContext context) {
    // TODO: Implement analytics page
  }

  void _showSettings(BuildContext context) {
    // TODO: Implement settings page
  }

  void _showHelp(BuildContext context) {
    // TODO: Implement help page
  }
}