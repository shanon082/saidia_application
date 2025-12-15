import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:saidia_app/screens/admin/adminDashboard.dart';
import 'package:saidia_app/screens/customers/customerDashboard.dart';
import 'package:saidia_app/screens/provider/providerDashboard.dart';
import 'package:saidia_app/services/firestore_services.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreService().getUserStream(),
      builder: (context, snapshot) {
        print('HomePage StreamBuilder state: ${snapshot.connectionState}');
        print('HomePage StreamBuilder hasData: ${snapshot.hasData}');
        print('HomePage StreamBuilder error: ${snapshot.error}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          print('HomePage error details: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 20),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    },
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          print('User document does not exist or has no data');

          // Try to get current user data to debug
          final currentUser = FirebaseAuth.instance.currentUser;
          print('Current auth user: ${currentUser?.uid}');

          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('User profile not found'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      // Try to create profile if it doesn't exist
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        try {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .set({
                                'uid': user.uid,
                                'name': user.displayName ?? 'User',
                                'email': user.email ?? '',
                                'role': 'customer',
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                          // Refresh
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const HomePage()),
                          );
                        } catch (e) {
                          print('Failed to create profile: $e');
                        }
                      }
                    },
                    child: const Text('Create Profile'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        print('User data retrieved: ${data['uid']}, role: ${data['role']}');

        final role = data['role'] as String? ?? 'customer';
        final providerStatus = data['providerStatus'] as String?;

        print('Routing based on role: $role, providerStatus: $providerStatus');

        if (role == 'provider' && providerStatus != 'approved') {
          print('Provider not approved, showing customer dashboard');
          return const CustomerDashboard();
        }

        switch (role) {
          case 'admin':
            print('Routing to admin dashboard');
            return const AdminDashboard();
          case 'provider':
            print('Routing to provider dashboard');
            return const ProviderDashboard();
          default:
            print('Routing to customer dashboard');
            return const CustomerDashboard();
        }
      },
    );
  }
}

@override
Widget build(BuildContext context) {
  return StreamBuilder<DocumentSnapshot>(
    stream: FirestoreService().getUserStream(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (snapshot.hasError) {
        return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
      }

      if (!snapshot.hasData || !snapshot.data!.exists) {
        // Should not happen if signup is correct
        FirebaseAuth.instance.signOut();
        return const Scaffold(
          body: Center(child: Text('Session expired. Please login again.')),
        );
      }

      final data = snapshot.data!.data() as Map<String, dynamic>;
      final role = data['role'] as String? ?? 'customer';
      final providerStatus = data['providerStatus'] as String?;

      if (role == 'provider' && providerStatus != 'approved') {
        return const CustomerDashboard(); // Pending or rejected
      }

      return switch (role) {
        'admin' => const AdminDashboard(),
        'provider' => const ProviderDashboard(),
        _ => const CustomerDashboard(),
      };
    },
  );
}
