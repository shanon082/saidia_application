import 'package:supabase_flutter/supabase_flutter.dart';


import 'package:flutter/material.dart';
import 'package:saidia_app/screens/admin/adminDashboard.dart';
import 'package:saidia_app/screens/customers/customerDashboard.dart';
import 'package:saidia_app/screens/provider/providerDashboard.dart';
import 'package:saidia_app/services/firestore_services.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String _normalizeRole(dynamic rawRole) {
    final role = rawRole?.toString().trim().toLowerCase() ?? '';
    if (role.contains('admin')) return 'admin';
    if (role.contains('provider')) return 'provider';
    return 'customer';
  }

  String _normalizeProviderStatus(dynamic rawStatus) {
    return rawStatus?.toString().trim().toLowerCase() ?? '';
  }

  String _friendlyLoadError(Object? error) {
    final raw = (error?.toString() ?? '').toLowerCase();
    if (raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('network is unreachable') ||
        raw.contains('connection refused') ||
        raw.contains('timed out')) {
      return 'No internet connection. Please check your network and try again.';
    }
    return 'Failed to load your profile right now. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      _friendlyLoadError(snapshot.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        }
                      },
                      child: const Text('Back to Login'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'User profile not found. Please login again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        }
                      },
                      child: const Text('Go to Login'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final data = snapshot.data!.data()!;
        final role = _normalizeRole(data['role']);
        final providerStatus = _normalizeProviderStatus(data['providerStatus']);

        if (role == 'admin') return const AdminDashboard();
        if (role == 'provider' && providerStatus == 'approved') {
          return const ProviderDashboard();
        }
        if (role == 'provider') return const CustomerDashboard();
        if (providerStatus == 'approved') return const ProviderDashboard();
        return const CustomerDashboard();
      },
    );
  }
}
