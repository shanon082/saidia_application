import 'package:flutter/material.dart';
import 'package:saidia_app/screens/customers/profilepage.dart';
import 'package:saidia_app/screens/customers/servicesList.dart';
import 'package:saidia_app/screens/provider/becomeProvider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saidia_app/auth/loginPage.dart';
import 'package:saidia_app/screens/customers/notificationpage.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({Key? key}) : super(key: key);

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  // Initialize categories list directly
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Plumbing',
      'icon': Icons.plumbing,
      'color': Colors.blue,
      'image':
          'https://www.quickfixplumbers.co.ke/_next/image?url=%2Fassets%2Fimg%2Fservices%2Fbanners%2Fbroken-pipes.jpg&w=3840&q=75',
    },
    {
      'name': 'Electrical',
      'icon': Icons.electrical_services,
      'color': Colors.amber,
      'image':
          'https://dannytechservices.co.ke/wp-content/uploads/2024/11/rein_0019_rewiring-work.webp',
    },
    {
      'name': 'Cleaning',
      'icon': Icons.cleaning_services,
      'color': Colors.lightBlue,
      'image':
          'https://i.ytimg.com/vi/krpQpX-2Pg4/hq720.jpg?sqp=-oaymwEhCK4FEIIDSFryq4qpAxMIARUAAAAAGAElAADIQj0AgKJD&rs=AOn4CLDgUahYRmKsmtHjSULrx1YkuuAx9w',
    },
    {
      'name': 'Carpentry',
      'icon': Icons.carpenter,
      'color': Colors.brown,
      'image':
          'https://kuaventures.org/wp-content/uploads/2024/09/AKN00811-1-5-scaled.jpg',
    },
    {
      'name': 'Painting',
      'icon': Icons.format_paint,
      'color': Colors.deepPurple,
      'image':
          'https://bestcareservices.co.ke/wp-content/uploads/2022/10/exterior-painting-services-in-Nairobi-Kenya.jpg',
    },
    {
      'name': 'Gardening',
      'icon': Icons.nature,
      'color': Colors.green,
      'image':
          'https://africasolutionsmediahub.org/wp-content/uploads/2024/01/Kenyas-gardening-teacher-1-scaled.jpg',
    },
    {
      'name': 'AC Repair',
      'icon': Icons.ac_unit,
      'color': Colors.cyan,
      'image': 'https://via.placeholder.com/150?text=AC+Repair',
    },
    {
      'name': 'Appliances',
      'icon': Icons.kitchen,
      'color': Colors.orange,
      'image': 'https://via.placeholder.com/150?text=Appliances',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, user),

            // Search Bar
            _buildSearchBar(),

            // Welcome Section
            _buildWelcomeSection(user),

            // Categories Section
            _buildCategoriesSection(),
          ],
        ),
      ),
      drawer: _buildDrawer(context, user),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Hamburger Menu
            IconButton(
              icon: Icon(Icons.menu, color: Colors.blue.shade700),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
            // icon and App Name
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.lightBlue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/logos/rounded_logo_tp.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.broken_image,
                      color: Colors.red,
                      size: 40,
                    );
                  },
                ),
              ),
            ),

            // App Name
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SaidiA',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                Text(
                  'Service Marketplace',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),

            Spacer(),

            // Notification Icon with Badge
            Stack(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NotificationPage()),
                    );
                  },
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: Colors.grey.shade700,
                      size: 24,
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '3',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
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
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for services...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: Colors.blue.shade700),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: IconButton(
              icon: Icon(Icons.tune, color: Colors.blue.shade700),
              onPressed: () {
                // Filter functionality
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(User? user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String userName = 'Customer';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          userName = data?['name']?.split(' ').first ?? 'Customer';
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $userName! 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Find trusted professionals for your needs',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              SizedBox(height: 16),
              // Become Provider Banner
              Container(
                width: double.infinity,
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
                child: Row(
                  children: [
                    Icon(Icons.handyman, color: Colors.white, size: 40),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Become a Service Provider',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Earn money by offering your skills',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BecomeProviderPage(),
                          ),
                        );
                      },
                      icon: Icon(Icons.arrow_forward_ios, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriesSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Service Categories',
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
                      MaterialPageRoute(builder: (_) => ServicesListPage()),
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
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
          ),
          SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _buildCategoryItem(category);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServicesListPage(categoryFilter: category['name']),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (category['color'] as Color).withOpacity(0.1),
                  (category['color'] as Color).withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (category['color'] as Color).withOpacity(0.2),
              ),
            ),
            child: Icon(
              category['icon'] as IconData,
              size: 32,
              color: category['color'] as Color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            category['name'] as String,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, User? user) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        children: [
          // Header
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _buildDrawerHeader('Loading...', 'Loading...', '');
              }

              final data = snapshot.data!.data() as Map<String, dynamic>?;
              final String name = data?['name'] ?? 'User';
              final String phone = data?['phone'] ?? 'No phone';
              final String email = user?.email ?? 'No email';

              return _buildDrawerHeader(name, email, phone);
            },
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.home_outlined,
                  title: 'Home',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  title: 'My Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfilePage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.bookmark_outline,
                  title: 'Saved Services',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.history,
                  title: 'Booking History',
                  onTap: () {
                    
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.payments_outlined,
                  title: 'Payments',
                  onTap: () {},
                ),
                Divider(thickness: 1, height: 32, indent: 20, endIndent: 20),
                _buildDrawerItem(
                  icon: Icons.handyman_outlined,
                  title: 'Become a Provider',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BecomeProviderPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {},
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
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => _logout(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(String name, String email, String phone) {
  return Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color.fromARGB(255, 20, 98, 187), Color.fromARGB(255, 3, 153, 228)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 25, 24, 24), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white.withOpacity(0.25),
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              email,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              phone,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
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
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
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
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
