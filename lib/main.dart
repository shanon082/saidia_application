import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:saidia_app/auth/loginPage.dart';
import 'package:saidia_app/auth/signupPage.dart';
import 'package:saidia_app/screens/admin/adminDashboard.dart';
import 'package:saidia_app/screens/customers/customerDashboard.dart';
import 'package:saidia_app/screens/provider/providerDashboard.dart';
import 'package:saidia_app/services/notification_service.dart';
import 'package:saidia_app/splashscreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  static const String _supabaseUrl =
      'https://qgcaaikhgizzwcvozwbl.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFnY2FhaWtoZ2l6endjdm96d2JsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3NDAxMjYsImV4cCI6MjA5MTMxNjEyNn0.IQ9N0j2KvEyZJJf25FjUHzE0QehTcuibSLhzRDoeKyE';

  bool _loading = true;
  bool _offline = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<bool> _canReachSupabase() async {
    try {
      final uri = Uri.parse('$_supabaseUrl/rest/v1/');
      final res = await http
          .get(
            uri,
            headers: {
              'apikey': _supabaseAnonKey,
              'Authorization': 'Bearer $_supabaseAnonKey',
            },
          )
          .timeout(const Duration(seconds: 8));

      // Any non-5xx response confirms the Supabase host is reachable.
      return res.statusCode < 500;
    } on TimeoutException {
      return false;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('failed host lookup') ||
          msg.contains('socketexception') ||
          msg.contains('xmlhttprequest error') ||
          msg.contains('networkerror') ||
          msg.contains('connection refused') ||
          msg.contains('timed out')) {
        return false;
      }
      return false;
    }
  }

  Future<void> _initialize() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final canReachSupabase = await _canReachSupabase();
    if (!mounted) return;
    if (!canReachSupabase) {
      setState(() {
        _loading = false;
        _offline = true;
      });
      return;
    }

    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
      );
      await NotificationService.instance.initialize();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _offline = false;
      });
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('already initialized')) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _offline = false;
          _error = null;
        });
        return;
      }

      final isNetworkIssue =
          message.contains('socketexception') ||
          message.contains('failed host lookup') ||
          message.contains('network is unreachable') ||
          message.contains('timed out');

      if (!mounted) return;
      setState(() {
        _loading = false;
        _offline = isNetworkIssue;
        _error = isNetworkIssue ? null : 'Unable to start the app right now.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (_offline) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _StartupMessagePage(
          title: 'Cannot Reach Server',
          message:
              'Your internet may be on, but the app cannot access Supabase right now. Tap Retry.',
          onRetry: _initialize,
        ),
      );
    }

    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _StartupMessagePage(
          title: 'Startup Error',
          message: _error!,
          onRetry: _initialize,
        ),
      );
    }

    return const MyApp();
  }
}

class _StartupMessagePage extends StatelessWidget {
  final String title;
  final String message;
  final Future<void> Function() onRetry;

  const _StartupMessagePage({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 72, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaidiA App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 73, 4, 192),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/customer-dashboard': (context) => const CustomerDashboard(),
        '/provider-dashboard': (context) => const ProviderDashboard(),
      },
    );
  }
}
