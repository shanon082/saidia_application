import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:saidia_app/screens/homepage.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _name = '';
  String _email = '';
  String _phone = '';
  String _password = '';
  String _role = 'customer'; 
  String _category = '';
  String _city = '';

  bool _isLoading = false;
  bool _isProvider = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _email.trim(),
        password: _password,
      );

      // Save user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': _name,
        'email': _email.trim(),
        'phone': _phone,
        'role': _role,
        'createdAt': FieldValue.serverTimestamp(),
        if (_role == 'provider') ...{
          'category': _category,
          'city': _city,
          'isVerified': false,
        },
      });
      // Navigate to home or appropriate page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Signup failed')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join SaidiA',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Sign up as a customer or service provider', style: TextStyle(color: Colors.grey)),

                const SizedBox(height: 32),

                // Role Selection
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() {
                          _role = 'customer';
                          _isProvider = false;
                        }),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _role == 'customer' ? Colors.blue : null,
                          foregroundColor: _role == 'customer' ? Colors.white : null,
                        ),
                        child: const Text('Customer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() {
                          _role = 'provider';
                          _isProvider = true;
                        }),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _role == 'provider' ? Colors.blue : null,
                          foregroundColor: _role == 'provider' ? Colors.white : null,
                        ),
                        child: const Text('Service Provider'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                TextFormField(
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  onSaved: (v) => _name = v!,
                ),

                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  onSaved: (v) => _email = v!,
                ),

                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Phone (optional)'),
                  keyboardType: TextInputType.phone,
                  onSaved: (v) => _phone = v ?? '',
                ),

                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => v!.length < 6 ? 'At least 6 characters' : null,
                  onSaved: (v) => _password = v!,
                ),

                if (_isProvider) ...[
                  const SizedBox(height: 24),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Service Category (e.g., Plumbing, Cleaning)'),
                    validator: (v) => _isProvider && v!.isEmpty ? 'Required for providers' : null,
                    onSaved: (v) => _category = v!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (v) => _isProvider && v!.isEmpty ? 'Required' : null,
                    onSaved: (v) => _city = v!,
                  ),
                ],

                const SizedBox(height: 32),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Sign Up', style: TextStyle(fontSize: 18)),
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}