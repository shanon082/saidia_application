import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:saidia_app/auth/loginPage.dart';
import 'package:saidia_app/services/firestore_services.dart';

class CreateAdminPage extends StatefulWidget {
  const CreateAdminPage({Key? key}) : super(key: key);

  @override
  State<CreateAdminPage> createState() => _CreateAdminPageState();
}

class _CreateAdminPageState extends State<CreateAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _dataService = FirestoreService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  Future<void> _createAdminAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      print('🔄 Creating admin account...');

      // Step 1: Create user with signUp
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
        },
      );

      final user = authResponse.user;
      if (user == null) throw Exception('Failed to create user');

      print('✅ Auth user created. ID: ${user.id}');

      // Step 2: Confirm email immediately (bypasses verification)
      await Supabase.instance.client.auth.admin.updateUserById(
        user.id,
        attributes: AdminUserAttributes(
          emailConfirm: true,
        ),
      );

      // Step 3: Create user profile in 'users' table
      await _dataService.createUserProfile(
        uid: user.id,
        username: name,
        email: email,
        phone: phone,
      );

      // Step 4: Set role to admin
      await Supabase.instance.client
          .from('users')
          .update({'role': 'admin'})
          .eq('id', user.id);

      print('🎉 Admin account created successfully!');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin account created successfully! You can now login.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      // Navigate back to login
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      print('AuthException: ${e.message}');
      String msg = e.message;
      if (e.message.contains('already in use') || e.message.contains('already exists')) {
        msg = 'Email is already registered';
      } else if (e.message.contains('weak')) {
        msg = 'Password is too weak';
      }
      setState(() => _errorMessage = msg);
    } catch (e, stackTrace) {
      print('Error creating admin: $e');
      print('Stack trace: $stackTrace');
      setState(() => _errorMessage = 'Failed to create admin: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Admin Account'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  size: 60,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Create Admin Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Set up the first admin account for SaidiA platform',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person, color: Colors.red),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter full name' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email, color: Colors.red),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter email';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone, color: Colors.red),
                  border: OutlineInputBorder(),
                  hintText: '07xx xxx xxx',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter phone number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock, color: Colors.red),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter password';
                  if (value.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock, color: Colors.red),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please confirm password';
                  if (value != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text('Important Note', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This will create a super admin account with full access. Keep credentials secure.',
                      style: TextStyle(color: Color.fromARGB(255, 239, 108, 0), fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAdminAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Create Admin Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: const Text('Back to Login', style: TextStyle(color: Colors.red, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}