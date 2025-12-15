import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:saidia_app/auth/loginPage.dart';
import 'package:saidia_app/auth/signupPage.dart';
import 'package:saidia_app/firebase_options.dart';
import 'package:saidia_app/screens/admin/adminDashboard.dart';
import 'package:saidia_app/screens/customers/customerDashboard.dart';
import 'package:saidia_app/screens/provider/providerDashboard.dart';
import 'package:saidia_app/splashscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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