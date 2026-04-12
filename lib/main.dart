import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:saidia_app/auth/loginPage.dart';
import 'package:saidia_app/auth/signupPage.dart';
import 'package:saidia_app/screens/admin/adminDashboard.dart';
import 'package:saidia_app/screens/customers/customerDashboard.dart';
import 'package:saidia_app/screens/provider/providerDashboard.dart';
import 'package:saidia_app/services/notification_service.dart';
import 'package:saidia_app/splashscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://qgcaaikhgizzwcvozwbl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFnY2FhaWtoZ2l6endjdm96d2JsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3NDAxMjYsImV4cCI6MjA5MTMxNjEyNn0.IQ9N0j2KvEyZJJf25FjUHzE0QehTcuibSLhzRDoeKyE',
  );
  await NotificationService.instance.initialize();
  runApp(const MyApp());
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
