import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saidia_app/WelcomePage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Check user authentication and navigate accordingly
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Add a minimum delay for splash screen
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Check if user is already logged in
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        // No user logged in, go to WelcomePage
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const WelcomePage()),
          );
        }
      } else {
        // User is logged in, check their role and go to appropriate dashboard
        await _navigateBasedOnUserRole(currentUser);
      }
    } catch (e) {
      print('Error in splash screen navigation: $e');
      // If any error occurs, go to WelcomePage as fallback
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomePage()),
        );
      }
    }
  }

  Future<void> _navigateBasedOnUserRole(User user) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) {
        // User document doesn't exist, log out and go to WelcomePage
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const WelcomePage()),
          );
        }
        return;
      }
      
      final userData = userDoc.data()!;
      final role = userData['role']?.toString() ?? 'customer';
      final providerStatus = userData['providerStatus']?.toString();
      
      if (mounted) {
        switch (role) {
          case 'admin':
            Navigator.of(context).pushReplacementNamed('/admin-dashboard');
            break;
          case 'provider':
            if (providerStatus == 'approved') {
              Navigator.of(context).pushReplacementNamed('/provider-dashboard');
            } else {
              // Provider not approved yet, show customer dashboard
              Navigator.of(context).pushReplacementNamed('/customer-dashboard');
            }
            break;
          default:
            Navigator.of(context).pushReplacementNamed('/customer-dashboard');
        }
      }
    } catch (e) {
      print('Error navigating based on role: $e');
      // Fallback to WelcomePage
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomePage()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A11CB), 
              Color(0xFF2575FC), 
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo 
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.handyman,
                    size: 100,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 30),

                // App Name
                const Text(
                  'SaidiA',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 10),

                // Tagline
                const Text(
                  'Connect. Book. Get It Done.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 60),

                // Animated loader
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}