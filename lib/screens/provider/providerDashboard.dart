import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

import 'package:saidia_app/auth/loginPage.dart';
import 'package:intl/intl.dart';
import 'package:saidia_app/screens/provider/earningspage.dart';
import 'package:saidia_app/screens/provider/schedulepage.dart';
import 'package:saidia_app/screens/provider/messagesPage.dart';
import 'package:saidia_app/screens/provider/reviewspage.dart';
import 'package:saidia_app/screens/provider/analyticspage.dart';
import 'package:saidia_app/screens/provider/portfolioPage.dart';
import 'package:saidia_app/screens/provider/providerEditProfilePage.dart';
import 'package:saidia_app/screens/provider/settingspage.dart';
import 'package:saidia_app/screens/provider/helppage.dart';
import 'package:saidia_app/screens/provider/notificationspage.dart';
import 'package:saidia_app/services/firestore_services.dart';

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  final _supabase = Supabase.instance.client;
  final FirestoreService _service = FirestoreService();
  int _selectedIndex = 0;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _providerDataStream;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _bookingsStream;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _reviewsStream;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _providerDataStream = _service.getProviderApplicationStream();
    _bookingsStream = _service.getProviderBookingsStream();
    _reviewsStream = _service.getProviderReviewsStream();
    _messagesStream = _service.getProviderChatsStream();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _getProviderDataStream() {
    return _service.getProviderApplicationStream();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getBookingsStream() {
    return _service.getProviderBookingsStream();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getReviewsStream() {
    return _service.getProviderReviewsStream();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getMessagesStream() {
    return _service.getProviderChatsStream();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Dashboard'
              : _selectedIndex == 1
              ? 'Bookings'
              : _selectedIndex == 2
              ? 'Messages'
              : 'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.blue.shade700),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          StreamBuilder<int>(
            stream: _service.getUnreadNotificationsCountStream(),
            builder: (context, snapshot) {
              final unread = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: Colors.grey.shade700,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => NotificationsPage()),
                      );
                    },
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _getBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildBookings();
      case 2:
        return MessagesPage();
      case 3:
        return _buildProfile();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        children: [
          // Header
          StreamBuilder<DocumentSnapshot>(
            stream: _providerDataStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildDrawerHeader(
                  'Provider',
                  'Profile unavailable',
                  '',
                  0.0,
                  0.0,
                );
              }

              if (!snapshot.hasData) {
                return _buildDrawerHeader(
                  'Loading...',
                  'Loading...',
                  '',
                  0.0,
                  0.0,
                );
              }

              final providerData = snapshot.data!.data() as Map<String, dynamic>?;
              final category = providerData?['serviceCategory'] ?? 'Service';
              final image = providerData?['imageUrl'] ?? '';
              final rawRate = providerData?['hourlyRate'];
              final rate = rawRate is num
                  ? rawRate.toDouble()
                  : double.tryParse(rawRate?.toString() ?? '0') ?? 0.0;
              final rating = (providerData?['rating'] as num?)?.toDouble() ?? 0.0;

              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _service.getUserStream(),
                builder: (context, userSnapshot) {
                  final userData = userSnapshot.data?.data();
                  final userName = (userData?['username']?.toString().trim().isNotEmpty ?? false)
                      ? userData!['username'].toString().trim()
                      : 'Provider';
                  return _buildDrawerHeader(
                    userName,
                    category,
                    image,
                    rate,
                    rating,
                  );
                },
              );
            },
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = 0);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.calendar_today_outlined,
                  title: 'Schedule',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SchedulePage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.book_online_outlined,
                  title: 'Bookings',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = 1);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.chat_outlined,
                  title: 'Messages',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = 2);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.attach_money_outlined,
                  title: 'Earnings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EarningsPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.star_outline,
                  title: 'Reviews',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ReviewsPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.analytics_outlined,
                  title: 'Analytics',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AnalyticsPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  title: 'My Profile',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = 3);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.photo_library_outlined,
                  title: 'Portfolio Images',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PortfolioPage()),
                    );
                  },
                ),
                Divider(thickness: 1, height: 32, indent: 20, endIndent: 20),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SettingsPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => HelpPage()),
                    );
                  },
                ),
              ],
            ),
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.logout, color: Colors.red),
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.red),
                onTap: () => _logout(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(
    String name,
    String category,
    String image,
    double rate,
    double rating,
  ) {
    return Container(
      padding: EdgeInsets.only(top: 40, bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.lightBlue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
            child: image.isEmpty
                ? Icon(Icons.handyman, size: 50, color: Colors.white)
                : null,
          ),
          SizedBox(height: 16),
          Text(
            name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            category,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.star, color: Colors.yellow, size: 20),
              SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(width: 16),
              Text(
                'UGX ${rate.toInt()}/hr',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? badge,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue.shade700),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.lightBlue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _bookingsStream,
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    final today = DateFormat(
                      'yyyy-MM-dd',
                    ).format(DateTime.now());
                    final todaysBookings = docs.where((b) {
                      final data = b.data() as Map<String, dynamic>;
                      return data['date'] == today;
                    }).length;
                    final pending = docs.where((b) {
                      final data = b.data() as Map<String, dynamic>;
                      return (data['status']?.toString().toLowerCase() ?? '') ==
                          'pending';
                    }).length;

                    return Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'Today\'s Bookings',
                            '$todaysBookings',
                            Icons.calendar_today,
                            Colors.white.withOpacity(0.2),
                            Colors.white,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _statCard(
                            'Pending',
                            '$pending',
                            Icons.pending,
                            Colors.white.withOpacity(0.2),
                            Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Quick Stats
          Text(
            'Overview',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _bookingsStream,
            builder: (context, bookingSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: _reviewsStream,
                builder: (context, reviewSnapshot) {
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _service.getProviderPaymentsStream(),
                    builder: (context, paymentSnapshot) {
                      final bookings = bookingSnapshot.data?.docs ?? [];
                      final reviews = reviewSnapshot.data?.docs ?? [];
                      final payments = paymentSnapshot.data?.docs ?? [];

                      final earnings = payments
                          .where((p) => p.data()['type'] == 'booking_earning')
                          .fold<double>(
                            0,
                            (total, p) =>
                                total +
                                ((p.data()['amount'] as num?)?.toDouble() ?? 0),
                          );

                      final ratingVals = reviews
                          .map(
                            (r) =>
                                ((r.data() as Map<String, dynamic>)['rating']
                                        as num?)
                                    ?.toDouble() ??
                                0.0,
                          )
                          .where((v) => v > 0)
                          .toList();
                      final avgRating = ratingVals.isEmpty
                          ? 0.0
                          : ratingVals.reduce((a, b) => a + b) /
                                ratingVals.length;

                      return GridView.count(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: [
                          _quickStatCard(
                            'Total Bookings',
                            '${bookings.length}',
                            Icons.book_online,
                            Colors.green,
                          ),
                          _quickStatCard(
                            'Earnings',
                            'UGX ${earnings.toStringAsFixed(0)}',
                            Icons.attach_money,
                            Colors.blue,
                          ),
                          _quickStatCard(
                            'Rating',
                            avgRating.toStringAsFixed(1),
                            Icons.star,
                            Colors.amber,
                          ),
                          _quickStatCard(
                            'Reviews',
                            '${reviews.length}',
                            Icons.reviews,
                            Colors.purple,
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          SizedBox(height: 24),

          // Today's Schedule
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Schedule",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SchedulePage()),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.blue.shade700,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _bookingsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _emptyState(
                  'Error loading schedule: ${snapshot.error}',
                  Icons.error_outline,
                );
              }
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final bookings = snapshot.data!.docs;
              final todayBookings = bookings.where((booking) {
                final raw = booking.data() as Map<String, dynamic>;
                final data = {...raw, 'bookingId': booking.id};
                final date = data['date'] as String?;
                return date == DateFormat('yyyy-MM-dd').format(DateTime.now());
              }).toList();

              if (todayBookings.isEmpty) {
                return _emptyState(
                  'No bookings scheduled for today',
                  Icons.calendar_today,
                );
              }

              return Column(
                children: todayBookings.take(2).map((booking) {
                  final raw = booking.data() as Map<String, dynamic>;
                  final data = {...raw, 'bookingId': booking.id};
                  return _bookingCard(data);
                }).toList(),
              );
            },
          ),
          SizedBox(height: 24),

          // Recent Reviews
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Reviews",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReviewsPage()),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.blue.shade700,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _reviewsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _emptyState(
                  'Error loading reviews: ${snapshot.error}',
                  Icons.error_outline,
                );
              }
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final reviews = snapshot.data!.docs;

              if (reviews.isEmpty) {
                return _emptyState('No reviews yet', Icons.reviews);
              }

              return Column(
                children: reviews.take(2).map((review) {
                  final data = review.data() as Map<String, dynamic>;
                  final customerId = data['customerId']?.toString();
                  if (customerId == null || customerId.isEmpty) {
                    return _reviewCard(data, customerName: 'Customer');
                  }

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: _supabase
                        .from('users')
                        .select('username')
                        .eq('id', customerId)
                        .maybeSingle(),
                    builder: (context, userSnapshot) {
                      final fetchedName =
                          userSnapshot.data?['username']?.toString().trim();
                      final customerName =
                          (fetchedName != null && fetchedName.isNotEmpty)
                          ? fetchedName
                          : 'Customer';
                      return _reviewCard(data, customerName: customerName);
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: color.withOpacity(0.9), fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _customerFallbackName(Map<String, dynamic> data) {
    final username = data['customerUsername']?.toString().trim();
    if (username != null && username.isNotEmpty) return username;
    final legacyName = data['customerName']?.toString().trim();
    if (legacyName != null && legacyName.isNotEmpty) return legacyName;
    return 'Customer';
  }

  Future<String> _loadCustomerDisplayName(Map<String, dynamic> data) async {
    final fallback = _customerFallbackName(data);
    final customerId = data['customerId']?.toString().trim();
    if (customerId == null || customerId.isEmpty) return fallback;
    try {
      final row = await _supabase
          .from('users')
          .select('username')
          .eq('id', customerId)
          .maybeSingle();
      final username = row?['username']?.toString().trim();
      if (username != null && username.isNotEmpty) return username;
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  Widget _customerNameText(
    Map<String, dynamic> data, {
    required TextStyle style,
  }) {
    return FutureBuilder<String>(
      future: _loadCustomerDisplayName(data),
      builder: (context, snapshot) {
        return Text(snapshot.data ?? _customerFallbackName(data), style: style);
      },
    );
  }

  Widget _quickStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _bookingCard(Map<String, dynamic> data) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue.shade100,
            child: Icon(Icons.person, color: Colors.blue.shade700),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _customerNameText(
                  data,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  '${data['date']} • ${data['time']}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                SizedBox(height: 4),
                Text(
                  data['details'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  (data['status'] == 'confirmed' ? Colors.green : Colors.orange)
                      .withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data['status'] ?? 'pending',
              style: TextStyle(
                color: data['status'] == 'confirmed'
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(
    Map<String, dynamic> data, {
    required String customerName,
  }) {
    final reviewText = ((data['comment'] ?? data['review'] ?? data['message'])
                ?.toString()
                .trim() ??
            '')
        .trim();

    DateTime? reviewDate;
    final rawDate = data['createdAt'] ?? data['timestamp'] ?? data['reviewedAt'];
    if (rawDate is Timestamp) {
      reviewDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      reviewDate = rawDate;
    } else if (rawDate is String) {
      try {
        reviewDate = DateTime.parse(rawDate);
      } catch (_) {}
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                child: Icon(
                  Icons.person,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          Icons.star,
                          size: 16,
                          color: index < (data['rating'] ?? 0)
                              ? Colors.yellow
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            reviewText.isEmpty ? 'No written review provided.' : reviewText,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
          ),
          SizedBox(height: 8),
          Text(
            reviewDate == null
                ? '-'
                : DateFormat('dd MMM yyyy').format(reviewDate),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildBookings() {
    return Column(
      children: [
        // Filter Tabs
        Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  ['All', 'Pending', 'Confirmed', 'Completed', 'Cancelled']
                      .map(
                        (status) => Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _bookingsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _emptyState('No bookings yet', Icons.calendar_today);
              }

              final bookings = snapshot.data!.docs;

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final raw = bookings[index].data() as Map<String, dynamic>;
                  final data = {...raw, 'bookingId': bookings[index].id};
                  return _bookingListItem(data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _bookingListItem(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () => _showBookingDetails(data),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _customerNameText(
                          data,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          data['serviceType'] ?? 'General Service',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (data['status'] == 'confirmed'
                                      ? Colors.green
                                      : data['status'] == 'cancelled'
                                      ? Colors.red
                                      : Colors.orange)
                                  .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          data['status'] ?? 'pending',
                          style: TextStyle(
                            color: data['status'] == 'confirmed'
                                ? Colors.green
                                : data['status'] == 'cancelled'
                                ? Colors.red
                                : Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'UGX ${data['price'] ?? data['hourlyRate'] ?? '0'}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey.shade200),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 6),
                      Text(
                        data['date'] ?? 'No date',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 6),
                      Text(
                        data['time'] ?? 'No time',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                data['details'] ?? 'No details provided',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              SizedBox(height: 12),
              if (data['status'] == 'pending' || data['status'] == 'confirmed')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateBookingStatus(
                          data['bookingId'] ?? '',
                          data['status'] == 'pending'
                              ? 'confirmed'
                              : 'completed',
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(
                            color: data['status'] == 'pending'
                                ? Colors.green
                                : Colors.teal,
                          ),
                        ),
                        child: Text(
                          data['status'] == 'pending'
                              ? 'Confirm'
                              : 'Request Customer Confirmation',
                          style: TextStyle(
                            color: data['status'] == 'pending'
                                ? Colors.green
                                : Colors.teal,
                          ),
                        ),
                      ),
                    ),
                    if (data['status'] == 'pending') ...[
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateBookingStatus(
                            data['bookingId'] ?? '',
                            'cancelled',
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(color: Colors.red),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfile() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _providerDataStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.lightBlue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: data?['imageUrl'] != null
                          ? NetworkImage(data!['imageUrl'])
                          : null,
                      child: data?['imageUrl'] == null
                          ? Icon(Icons.handyman, size: 60, color: Colors.white)
                          : null,
                    ),
                    SizedBox(height: 16),
                    Text(
                      data?['specialization'] ?? 'Service Provider',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      data?['serviceCategory'] ?? 'General Service',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, color: Colors.yellow, size: 20),
                        SizedBox(width: 4),
                        Text(
                          ((data?['rating'] as num?)?.toDouble() ?? 0.0)
                              .toStringAsFixed(1),
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'UGX ${data?['hourlyRate'] ?? '0'}/hr',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Profile Details
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    SizedBox(height: 16),
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _service.getCurrentUserData(),
                      builder: (context, userSnapshot) {
                        final userData = userSnapshot.data;
                        final username =
                            userData?['username']?.toString().trim().isNotEmpty ==
                                true
                            ? userData!['username'].toString().trim()
                            : 'Provider';
                        final phone =
                            userData?['phone']?.toString().trim().isNotEmpty ==
                                true
                            ? userData!['phone'].toString().trim()
                            : (data?['phonenumber']?.toString() ?? 'N/A');
                        final email =
                            userData?['email']?.toString().trim() ?? '';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _profileDetailItem('Username', username),
                            _profileDetailItem('Phone', phone),
                            if (email.isNotEmpty)
                              _profileDetailItem('Email', email),
                          ],
                        );
                      },
                    ),
                    _profileDetailItem(
                      'Experience',
                      '${data?['experience'] ?? 'N/A'} years',
                    ),
                    _profileDetailItem('City', data?['city'] ?? 'N/A'),
                    _profileDetailItem('Address', data?['address'] ?? 'N/A'),
                    SizedBox(height: 20),
                    Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      data?['description'] ?? 'No description provided.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProviderEditProfilePage(),
                          ),
                        );
                      },
                      icon: Icon(Icons.edit),
                      label: Text('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.blue.shade700),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Share profile
                      },
                      icon: Icon(Icons.share),
                      label: Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _profileDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade400),
          SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(
                    Icons.person,
                    color: Colors.blue.shade700,
                    size: 30,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _customerNameText(
                        data,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        data['serviceType'] ?? 'General Service',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        (data['status'] == 'confirmed'
                                ? Colors.green
                                : data['status'] == 'cancelled'
                                ? Colors.red
                                : Colors.orange)
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data['status'] ?? 'pending',
                    style: TextStyle(
                      color: data['status'] == 'confirmed'
                          ? Colors.green
                          : data['status'] == 'cancelled'
                          ? Colors.red
                          : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'Booking Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
            SizedBox(height: 16),
            _bookingDetailItem(
              Icons.calendar_today,
              'Date',
              data['date'] ?? 'N/A',
            ),
            _bookingDetailItem(
              Icons.access_time,
              'Time',
              data['time'] ?? 'N/A',
            ),
            _bookingDetailItem(
              Icons.attach_money,
              'Amount',
              'UGX ${data['price'] ?? data['hourlyRate'] ?? '0'}',
            ),
            SizedBox(height: 16),
            Text(
              'Service Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              data['details'] ?? 'No details provided.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24),
            if (data['status'] == 'pending' || data['status'] == 'confirmed')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _updateBookingStatus(
                          data['bookingId'] ?? '',
                          data['status'] == 'pending'
                              ? 'confirmed'
                              : 'completed',
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: data['status'] == 'pending'
                            ? Colors.green
                            : Colors.teal,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        data['status'] == 'pending'
                            ? 'Confirm Booking'
                            : 'Request Customer Confirmation',
                      ),
                    ),
                  ),
                  if (data['status'] == 'pending') ...[
                    SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _updateBookingStatus(
                            data['bookingId'] ?? '',
                            'cancelled',
                          );
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.red),
                        ),
                        child: Text('Cancel'),
                      ),
                    ),
                  ],
                ],
              ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _bookingDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 20),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    if (bookingId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing booking id'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _service.updateBookingStatusAsProvider(
        bookingId: bookingId,
        status: status,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'confirmed'
                ? 'Booking confirmed successfully'
                : status == 'completed'
                ? 'Customer has been asked to confirm completion and pay'
                : 'Booking $status successfully',
          ),
          backgroundColor: status == 'cancelled' ? Colors.red : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
