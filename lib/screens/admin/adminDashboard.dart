import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:saidia_app/services/firestore_services.dart';
import 'package:saidia_app/auth/loginPage.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late TabController _tabController;
  int _currentIndex = 0;
  
  final List<Map<String, dynamic>> _quickStats = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardStats();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDashboardStats() async {
    try {
      final stats = await _firestoreService.getDashboardStats();
      setState(() {
        _quickStats.addAll([
          {
            'title': 'Total Users',
            'value': stats['totalUsers'].toString(),
            'icon': Icons.people,
            'color': Colors.blue,
          },
          {
            'title': 'Providers',
            'value': stats['totalProviders'].toString(),
            'icon': Icons.handyman,
            'color': Colors.green,
          },
          {
            'title': 'Pending Apps',
            'value': stats['pendingApplications'].toString(),
            'icon': Icons.pending_actions,
            'color': Colors.orange,
          },
          {
            'title': 'Total Apps',
            'value': stats['totalApplications'].toString(),
            'icon': Icons.description,
            'color': Colors.purple,
          },
        ]);
      });
    } catch (e) {
      print('Error loading stats: $e');
    }
  }
  
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }
  
  Future<void> _showLogoutConfirmation() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showApplicationDetails(Map<String, dynamic> application) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Application Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Name:', application['userEmail']?.toString().split('@').first ?? 'N/A'),
              _buildDetailItem('Email:', application['userEmail'] ?? 'N/A'),
              _buildDetailItem('Category:', application['serviceCategory'] ?? 'N/A'),
              _buildDetailItem('Specialization:', application['specialization'] ?? 'N/A'),
              _buildDetailItem('Experience:', '${application['experience'] ?? 'N/A'} years'),
              _buildDetailItem('City:', application['city'] ?? 'N/A'),
              _buildDetailItem('Hourly Rate:', 'KES ${application['hourlyRate'] ?? 'N/A'}/hr'),
              _buildDetailItem('Description:', application['description'] ?? 'N/A'),
              _buildDetailItem('Address:', application['address'] ?? 'N/A'),
              const SizedBox(height: 10),
              if (application['serviceAreas'] != null)
                _buildListDetail('Service Areas:', application['serviceAreas']),
              if (application['workingDays'] != null)
                _buildListDetail('Working Days:', application['workingDays']),
              const SizedBox(height: 10),
              _buildDetailItem('Status:', application['status'] ?? 'N/A'),
              if (application['appliedAt'] != null)
                _buildDetailItem(
                  'Applied:', 
                  DateFormat('dd MMM yyyy, hh:mm a').format((application['appliedAt'] as Timestamp).toDate()),
                ),
            ],
          ),
        ),
        actions: [
          if (application['status'] == 'pending')
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _processApplication(application['userId'], 'approved', null),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Approve'),
                ),
                ElevatedButton(
                  onPressed: () => _showRejectDialog(application['userId']),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Reject'),
                ),
              ],
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _processApplication(String userId, String status, String? notes) async {
    try {
      await _firestoreService.updateProviderApplicationStatus(userId, status, notes);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application $status successfully'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
  
  Future<void> _showRejectDialog(String userId) async {
    final notesController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection (optional):'),
            const SizedBox(height: 10),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Reason for rejection...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processApplication(userId, 'rejected', notesController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
  
  Widget _buildListDetail(String label, List<dynamic> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: items.map((item) => Chip(
              label: Text(item.toString()),
              backgroundColor: Colors.blue.shade50,
            )).toList(),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmation,
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) => setState(() => _currentIndex = index),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.pending_actions), text: 'Applications'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _auth.currentUser?.email ?? 'admin@saidia.com',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: _currentIndex == 0,
              onTap: () {
                _tabController.animateTo(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pending_actions),
              title: const Text('Applications'),
              selected: _currentIndex == 1,
              onTap: () {
                _tabController.animateTo(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('User Management'),
              selected: _currentIndex == 2,
              onTap: () {
                _tabController.animateTo(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: _showLogoutConfirmation,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Dashboard Tab
          _buildDashboardTab(),
          // Applications Tab
          _buildApplicationsTab(),
          // Users Tab
          _buildUsersTab(),
        ],
      ),
    );
  }
  
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome, Admin!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now())}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Manage your platform effectively. Review applications, manage users, and monitor platform activity.',
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Quick Stats
          const Text(
            'Platform Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: _quickStats.length,
            itemBuilder: (context, index) {
              final stat = _quickStats[index];
              return Card(
                elevation: 2,
                color: stat['color'].withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        stat['icon'] as IconData,
                        size: 40,
                        color: stat['color'] as Color,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        stat['value'] as String,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: stat['color'] as Color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stat['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Quick Actions
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.pending_actions, size: 18),
                        label: const Text('View Pending Applications'),
                        onPressed: () => _tabController.animateTo(1),
                        backgroundColor: Colors.orange.shade50,
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.people, size: 18),
                        label: const Text('Manage Users'),
                        onPressed: () => _tabController.animateTo(2),
                        backgroundColor: Colors.blue.shade50,
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.settings, size: 18),
                        label: const Text('System Settings'),
                        onPressed: () {},
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildApplicationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getAllProviderApplications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final applications = snapshot.data?.docs ?? [];
        
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Provider Applications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: Text('${applications.length} total'),
                    backgroundColor: Colors.blue.shade50,
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                itemCount: applications.length,
                itemBuilder: (context, index) {
                  final doc = applications[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'pending';
                  
                  Color statusColor = Colors.grey;
                  IconData statusIcon = Icons.pending;
                  
                  switch (status) {
                    case 'pending':
                      statusColor = Colors.orange;
                      statusIcon = Icons.pending_actions;
                      break;
                    case 'approved':
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                      break;
                    case 'rejected':
                      statusColor = Colors.red;
                      statusIcon = Icons.cancel;
                      break;
                  }
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.2),
                        child: Icon(statusIcon, color: statusColor),
                      ),
                      title: Text(
                        data['serviceCategory'] ?? 'Unknown Category',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(data['specialization'] ?? 'No specialization'),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  data['userEmail'] ?? 'Unknown user',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(
                          status.toUpperCase(),
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                        backgroundColor: statusColor,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onTap: () => _showApplicationDetails(data),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final users = snapshot.data?.docs ?? [];
        
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'User Management',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: Text('${users.length} users'),
                    backgroundColor: Colors.blue.shade50,
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final doc = users[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final role = data['role'] ?? 'customer';
                  final email = data['email'] ?? 'No email';
                  final name = data['name'] ?? 'Unknown';
                  
                  Color roleColor = Colors.grey;
                  IconData roleIcon = Icons.person;
                  
                  switch (role) {
                    case 'admin':
                      roleColor = Colors.red;
                      roleIcon = Icons.admin_panel_settings;
                      break;
                    case 'provider':
                      roleColor = Colors.green;
                      roleIcon = Icons.handyman;
                      break;
                    case 'customer':
                      roleColor = Colors.blue;
                      roleIcon = Icons.person;
                      break;
                  }
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: roleColor.withOpacity(0.2),
                        child: Icon(roleIcon, color: roleColor),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(email),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                data['phone'] ?? 'No phone',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit User'),
                              ],
                            ),
                          ),
                          if (role != 'admin')
                            PopupMenuItem(
                              value: 'make_admin',
                              child: Row(
                                children: [
                                  const Icon(Icons.admin_panel_settings, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Make Admin'),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility, size: 18),
                                SizedBox(width: 8),
                                Text('View Details'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'make_admin') {
                            _showMakeAdminConfirmation(doc.id, name);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _showMakeAdminConfirmation(String userId, String userName) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make Admin'),
        content: Text('Are you sure you want to make "$userName" an admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestoreService.updateUserRole(userId, 'admin');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User role updated to admin'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Make Admin'),
          ),
        ],
      ),
    );
  }
}