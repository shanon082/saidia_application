import 'package:saidia_app/screens/customers/aboutAppPage.dart';
import 'package:saidia_app/screens/customers/privacySecurityPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:saidia_app/services/firestore_services.dart';
import 'package:flutter/material.dart';


import 'package:saidia_app/screens/customers/notificationpage.dart';
import 'package:saidia_app/screens/customers/editProfilePage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = Supabase.instance.client.auth;
  final _supabase = Supabase.instance.client;
  
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int _savedCount = 0;
  int _bookingsCount = 0;
  double _rating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _supabase.from('users').select().eq('id', user.id).maybeSingle();
        if (doc != null) {
          final userId = user.id;
          
          final savedSnap = await _supabase
              .from('saved_services')
              .select()
              .eq('userId', userId);
          
          final bookingsSnap = await _supabase
              .from('bookings')
              .select()
              .eq('customerId', userId);
          
          setState(() {
            _userData = doc;
            _savedCount = savedSnap.length;
            _bookingsCount = bookingsSnap.length;
            _rating = (doc['rating'] as num?)?.toDouble() ?? 0.0;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationPage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.blue.shade700,
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.lightBlue.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          backgroundImage: _userData?['profileImageUrl'] != null
                              ? NetworkImage(_userData!['profileImageUrl'])
                              : null,
                          child: _userData?['profileImageUrl'] == null
                              ? Icon(
                                  Icons.person,
                                  size: 70,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        SizedBox(height: 20),
                        Text(
                          _userData?['username'] ?? 'User',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _userData?['phone'] ?? 'No phone number',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats Cards
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.bookmark,
                            value: _savedCount.toString(),
                            label: 'Saved',
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.history,
                            value: _bookingsCount.toString(),
                            label: 'Bookings',
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.star,
                            value: _rating > 0 ? _rating.toStringAsFixed(1) : 'N/A',
                            label: 'Rating',
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu Items
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.person_outline,
                          title: 'Personal Information',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EditProfilePage()),
                            ).then((_) => _loadUserData());
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.lock_outline,
                          title: 'Privacy & Security',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PrivacySecurityPage())
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.payment,
                          title: 'Payment Methods',
                          onTap: () {},
                        ),
                        _buildMenuItem(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => NotificationPage()),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          onTap: () {},
                        ),
                        _buildMenuItem(
                          icon: Icons.info_outline,
                          title: 'About SaidiA',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AboutAppPage())
                            );
                          },
                        ),
                        SizedBox(height: 24),
                        
                        // Logout Button
                        Container(
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
                            onTap: () {
                              // Logout logic
                            },
                          ),
                        ),
                        SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
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
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
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
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
}
