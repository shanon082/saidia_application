import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saidia_app/auth/loginPage.dart';
import 'package:saidia_app/services/firestore_services.dart';

enum _AdminTab { dashboard, applications, users, operations, settings }

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirestoreService _firestore = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  _AdminTab _tab = _AdminTab.dashboard;
  int _refreshKey = 0;
  bool _savingSettings = false;
  bool _settingsInitialized = false;

  bool _maintenanceMode = false;
  bool _allowNewSignups = true;
  final TextEditingController _supportEmailController = TextEditingController();
  final TextEditingController _announcementController = TextEditingController();
  final TextEditingController _platformFeeController = TextEditingController();

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  String _tabTitle(_AdminTab tab) {
    switch (tab) {
      case _AdminTab.dashboard:
        return 'Dashboard';
      case _AdminTab.applications:
        return 'Applications';
      case _AdminTab.users:
        return 'Users';
      case _AdminTab.operations:
        return 'Operations';
      case _AdminTab.settings:
        return 'App Settings';
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
      case 'confirmed':
      case 'success':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
      case 'failed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(dynamic t) {
    if (t is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(t.toDate());
    }
    return 'N/A';
  }

  void _setTab(_AdminTab nextTab) {
    if (_tab == nextTab) return;
    setState(() => _tab = nextTab);
  }

  @override
  void dispose() {
    _supportEmailController.dispose();
    _announcementController.dispose();
    _platformFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = _isDesktop(context);

    if (desktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: true,
              selectedIndex: _tab.index,
              onDestinationSelected: (i) => _setTab(_AdminTab.values[i]),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.pending_actions_outlined),
                  selectedIcon: Icon(Icons.pending_actions),
                  label: Text('Applications'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text('Users'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.fact_check_outlined),
                  selectedIcon: Icon(Icons.fact_check),
                  label: Text('Operations'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      onPressed: _confirmLogout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      _tabTitle(_tab),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(_auth.currentUser?.email ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => setState(() => _refreshKey++),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(child: _buildBody(desktop)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitle(_tab)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _refreshKey++),
          ),
          IconButton(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.admin_panel_settings, size: 36, color: Colors.blue),
                  SizedBox(height: 8),
                  Text(
                    'Admin Console',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                _setTab(_AdminTab.dashboard);
              },
            ),
            ListTile(
              title: const Text('Applications'),
              onTap: () {
                Navigator.pop(context);
                _setTab(_AdminTab.applications);
              },
            ),
            ListTile(
              title: const Text('Users'),
              onTap: () {
                Navigator.pop(context);
                _setTab(_AdminTab.users);
              },
            ),
            ListTile(
              title: const Text('Operations'),
              onTap: () {
                Navigator.pop(context);
                _setTab(_AdminTab.operations);
              },
            ),
            ListTile(
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _setTab(_AdminTab.settings);
              },
            ),
          ],
        ),
      ),
      body: _buildBody(desktop),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab.index,
        onDestinationSelected: (i) => _setTab(_AdminTab.values[i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(
            icon: Icon(Icons.pending_actions),
            label: 'Applications',
          ),
          NavigationDestination(icon: Icon(Icons.people), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.fact_check), label: 'Operations'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildBody(bool desktop) {
    switch (_tab) {
      case _AdminTab.dashboard:
        return _buildDashboard(desktop);
      case _AdminTab.applications:
        return _buildApplications(desktop);
      case _AdminTab.users:
        return _buildUsers(desktop);
      case _AdminTab.operations:
        return _buildOperations(desktop);
      case _AdminTab.settings:
        return _buildSettings(desktop);
    }
  }

  Future<void> _confirmLogout() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _auth.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Future<void> _showApplicationDetails(Map<String, dynamic> data) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Application Details'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field('Email', data['userEmail']?.toString() ?? 'N/A'),
                _field('Category', data['serviceCategory']?.toString() ?? 'N/A'),
                _field(
                  'Specialization',
                  data['specialization']?.toString() ?? 'N/A',
                ),
                _field('Experience', '${data['experience'] ?? 'N/A'} years'),
                _field('City', data['city']?.toString() ?? 'N/A'),
                _field('Address', data['address']?.toString() ?? 'N/A'),
                _field('Hourly Rate', 'UGX ${data['hourlyRate'] ?? 'N/A'}'),
                _field('Status', data['status']?.toString() ?? 'N/A'),
                _field('Applied', _formatDate(data['appliedAt'])),
              ],
            ),
          ),
        ),
        actions: [
          if ((data['status'] ?? '').toString().toLowerCase() == 'pending')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _processApplication(data['userId'].toString(), 'approved', null);
              },
              child: const Text('Approve'),
            ),
          if ((data['status'] ?? '').toString().toLowerCase() == 'pending')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showRejectDialog(data['userId'].toString());
              },
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRejectDialog(String userId) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Reason (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final note = controller.text.trim();
              _processApplication(userId, 'rejected', note.isEmpty ? null : note);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _processApplication(
    String userId,
    String status,
    String? notes,
  ) async {
    try {
      await _firestore.updateProviderApplicationStatus(userId, status, notes);
      if (!mounted) return;
      setState(() => _refreshKey++);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application $status successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _makeAdmin(String uid, String name) async {
    final rootContext = context;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Make Admin'),
        content: Text('Make "$name" an admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _firestore.updateUserRole(uid, 'admin');
                if (!mounted) return;
                if (!rootContext.mounted) return;
                setState(() => _refreshKey++);
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(content: Text('User promoted to admin')),
                );
              } catch (e) {
                if (!mounted) return;
                if (!rootContext.mounted) return;
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _moderateBooking({
    required String bookingId,
    required String currentStatus,
  }) async {
    String selectedStatus = currentStatus.toLowerCase();
    final noteController = TextEditingController();
    const statuses = ['pending', 'confirmed', 'completed', 'cancelled'];

    if (!statuses.contains(selectedStatus)) {
      selectedStatus = 'pending';
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Moderate Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedStatus,
              items: statuses
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  selectedStatus = value;
                }
              },
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Admin note',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _firestore.updateBookingStatusAsAdmin(
                  bookingId: bookingId,
                  status: selectedStatus,
                  adminNote: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                );
                if (!mounted) return;
                setState(() => _refreshKey++);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking updated')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    final supportEmail = _supportEmailController.text.trim();
    final announcement = _announcementController.text.trim();
    final fee = double.tryParse(_platformFeeController.text.trim()) ?? 0.0;

    setState(() => _savingSettings = true);
    try {
      await _firestore.updateAppSettings(
        values: {
          'maintenanceMode': _maintenanceMode,
          'allowNewSignups': _allowNewSignups,
          'supportEmail': supportEmail,
          'announcement': announcement,
          'platformFeePercent': fee,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _savingSettings = false);
      }
    }
  }

  Widget _buildDashboard(bool desktop) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey(_refreshKey),
      future: Future.wait([
        _firestore.getDashboardStats(),
        _firestore.getAdminReportSummary(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load dashboard: ${snapshot.error}'));
        }

        final stats = snapshot.data?[0] ?? {};
        final reports = snapshot.data?[1] ?? {};
        final cards = [
          ['Users', '${stats['totalUsers'] ?? 0}', Icons.people, Colors.blue],
          ['Providers', '${stats['totalProviders'] ?? 0}', Icons.handyman, Colors.green],
          [
            'Pending Apps',
            '${stats['pendingApplications'] ?? 0}',
            Icons.pending_actions,
            Colors.orange,
          ],
          ['Bookings', '${reports['totalBookings'] ?? 0}', Icons.book_online, Colors.indigo],
          ['Payments', '${reports['totalPayments'] ?? 0}', Icons.payments, Colors.teal],
          [
            'Revenue',
            'UGX ${((reports['totalRevenue'] as num?) ?? 0).toStringAsFixed(0)}',
            Icons.trending_up,
            Colors.purple,
          ],
        ];

        final crossAxisCount = desktop ? 3 : 2;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: ListTile(
                  title: const Text(
                    'Admin Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: desktop ? 2.1 : 1.3,
                ),
                itemBuilder: (_, i) {
                  final c = cards[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(c[2] as IconData, color: c[3] as Color),
                          const SizedBox(height: 8),
                          Text(
                            c[1] as String,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(c[0] as String),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Review Applications'),
                    onPressed: () => _setTab(_AdminTab.applications),
                  ),
                  ActionChip(
                    label: const Text('Moderate Bookings'),
                    onPressed: () => _setTab(_AdminTab.operations),
                  ),
                  ActionChip(
                    label: const Text('Manage Settings'),
                    onPressed: () => _setTab(_AdminTab.settings),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildApplications(bool desktop) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.getAllProviderApplications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No provider applications found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data();
            final status = (d['status'] ?? 'pending').toString();
            return Card(
              child: ListTile(
                onTap: () => _showApplicationDetails(d),
                title: Text(d['serviceCategory']?.toString() ?? 'Unknown'),
                subtitle: Text(d['userEmail']?.toString() ?? 'N/A'),
                trailing: Chip(
                  label: Text(
                    status.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _statusColor(status),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUsers(bool desktop) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final d = doc.data();
            final role = (d['role'] ?? 'customer').toString();
            return Card(
              child: ListTile(
                title: Text(d['name']?.toString() ?? 'Unknown'),
                subtitle: Text(d['email']?.toString() ?? 'N/A'),
                trailing: role.toLowerCase() == 'admin'
                    ? const Chip(label: Text('ADMIN'))
                    : TextButton(
                        onPressed: () =>
                            _makeAdmin(doc.id, d['name']?.toString() ?? 'Unknown'),
                        child: const Text('Make Admin'),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOperations(bool desktop) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const SizedBox(height: 8),
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.book_online), text: 'Bookings Moderation'),
              Tab(icon: Icon(Icons.payments), text: 'Payments & Reports'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              children: [
                _buildBookingsModeration(desktop),
                _buildPaymentsReports(desktop),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsModeration(bool desktop) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.getAllBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No bookings found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final d = doc.data();
            final status = (d['status'] ?? 'pending').toString();
            final amount = (d['estimatedAmount'] as num?)?.toDouble() ?? 0;
            return Card(
              child: ListTile(
                title: Text(d['serviceType']?.toString() ?? 'Booking'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer: ${d['customerId'] ?? 'N/A'}'),
                    Text('Provider: ${d['providerId'] ?? 'N/A'}'),
                    Text('Amount: UGX ${amount.toStringAsFixed(0)}'),
                    Text('Created: ${_formatDate(d['createdAt'])}'),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Chip(
                      label: Text(
                        status.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      backgroundColor: _statusColor(status),
                    ),
                    TextButton(
                      onPressed: () => _moderateBooking(
                        bookingId: doc.id,
                        currentStatus: status,
                      ),
                      child: const Text('Moderate'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentsReports(bool desktop) {
    return Column(
      children: [
        FutureBuilder<Map<String, dynamic>>(
          key: ValueKey(_refreshKey),
          future: _firestore.getAdminReportSummary(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Report error: ${snapshot.error}'),
              );
            }

            final d = snapshot.data ?? {};
            final cards = [
              [
                'Revenue',
                'UGX ${((d['totalRevenue'] as num?) ?? 0).toStringAsFixed(0)}',
                Icons.account_balance_wallet,
              ],
              ['Total Payments', '${d['totalPayments'] ?? 0}', Icons.payments],
              ['Completed', '${d['completedPayments'] ?? 0}', Icons.check_circle],
              ['Pending', '${d['pendingPayments'] ?? 0}', Icons.pending_actions],
            ];

            return SizedBox(
              height: desktop ? 180 : 220,
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: desktop ? 4 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: desktop ? 2 : 1.4,
                ),
                itemBuilder: (_, i) {
                  final c = cards[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(c[2] as IconData, color: Colors.teal),
                          const SizedBox(height: 6),
                          Text(
                            c[1] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(c[0] as String),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore.getAllPayments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No payments found.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i].data();
                  final amount = (d['amount'] as num?)?.toDouble() ?? 0;
                  final status = (d['status'] ?? 'unknown').toString();
                  final currency = (d['currency'] ?? 'UGX').toString();
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: Text(
                        '$currency ${amount.toStringAsFixed(0)} - ${d['type'] ?? 'payment'}',
                      ),
                      subtitle: Text(
                        'Method: ${d['method'] ?? 'N/A'} | ${_formatDate(d['createdAt'])}',
                      ),
                      trailing: Chip(
                        label: Text(
                          status.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                        backgroundColor: _statusColor(status),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettings(bool desktop) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore.getAppSettingsStream(),
      builder: (context, snapshot) {
        if (!_settingsInitialized &&
            snapshot.hasData &&
            snapshot.data?.data() != null) {
          final data = snapshot.data!.data()!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _settingsInitialized) return;
            setState(() {
              _maintenanceMode = (data['maintenanceMode'] as bool?) ?? false;
              _allowNewSignups = (data['allowNewSignups'] as bool?) ?? true;
              _supportEmailController.text =
                  (data['supportEmail'] ?? '').toString();
              _announcementController.text =
                  (data['announcement'] ?? '').toString();
              _platformFeeController.text =
                  ((data['platformFeePercent'] as num?) ?? 0).toString();
              _settingsInitialized = true;
            });
          });
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'General Settings',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _maintenanceMode,
                      onChanged: (v) => setState(() => _maintenanceMode = v),
                      title: const Text('Maintenance Mode'),
                      subtitle: const Text(
                        'Temporarily disable normal app operations.',
                      ),
                    ),
                    SwitchListTile(
                      value: _allowNewSignups,
                      onChanged: (v) => setState(() => _allowNewSignups = v),
                      title: const Text('Allow New Signups'),
                      subtitle: const Text('Enable or disable account creation.'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _supportEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Support Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _platformFeeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Platform Fee (%)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _announcementController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Global Announcement',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _savingSettings ? null : _saveSettings,
                        icon: _savingSettings
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(_savingSettings ? 'Saving...' : 'Save Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Safety',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Only trusted admins should have access to this console. '
                      'Review admin users regularly and rotate credentials.',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _setTab(_AdminTab.users),
                      icon: const Icon(Icons.admin_panel_settings),
                      label: const Text('Review Admin Users'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
