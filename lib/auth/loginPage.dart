import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:saidia_app/auth/signupPage.dart';
import 'package:saidia_app/screens/homepage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = Supabase.instance.client.auth;
  final _supabase = Supabase.instance.client;

  String _identifier = '';
  String _password = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  String _normalizeRole(dynamic rawRole) {
    final role = rawRole?.toString().trim().toLowerCase() ?? '';
    if (role.contains('admin')) return 'admin';
    if (role.contains('provider')) return 'provider';
    return 'customer';
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String _normalizeIdentifier(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  Future<Map<String, dynamic>?> _resolveUserByUsername(String input) async {
    final normalizedInput = _normalizeIdentifier(input);
    final parts = normalizedInput
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();

    // Try exact case-sensitive match first.
    final exact = await _supabase
        .from('users')
        .select('email, phone, username')
        .eq('username', input.trim())
        .maybeSingle();
    if (exact != null) return exact;

    // Finally, do case-insensitive/manual-normalized matching.
    final usernameCandidates = await _supabase
        .from('users')
        .select('email, phone, username')
        .ilike('username', input.trim())
        .limit(20);
    for (final row in usernameCandidates) {
      final username = _normalizeIdentifier(row['username']?.toString() ?? '');
      if (username == normalizedInput) {
        return row;
      }
    }

    if (parts.isNotEmpty) {
      final pattern = '%${parts.join('%')}%';
      final broadCandidates = await _supabase
          .from('users')
          .select('email, phone, username')
          .ilike('username', pattern)
          .limit(50);
      for (final row in broadCandidates) {
        final username = _normalizeIdentifier(row['username']?.toString() ?? '');
        if (username == normalizedInput) {
          return row;
        }
      }
    }

    return null;
  }

  Future<Map<String, dynamic>?> _resolveLoginIdentifier(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Preferred path: RPC that can safely resolve username for anon users.
    try {
      final rpcRes = await _supabase.rpc(
        'resolve_login_identifier',
        params: {'p_identifier': trimmed},
      );
      if (rpcRes is Map<String, dynamic>) {
        return rpcRes;
      }
      if (rpcRes is List && rpcRes.isNotEmpty && rpcRes.first is Map<String, dynamic>) {
        return rpcRes.first as Map<String, dynamic>;
      }
    } catch (_) {
      // Fallback to direct table lookup below (works only if policies allow anon read).
    }

    return _resolveUserByUsername(trimmed);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);
    final input = _identifier.trim();
    String? credentialEmail;
    String? credentialPhone;

    try {
      if (_isValidEmail(input)) {
        credentialEmail = input.toLowerCase();
      } else {
        final userByUsername = await _resolveLoginIdentifier(input);
        if (userByUsername == null) {
          throw Exception(
            'Username login is not available for this account right now. Use email login, then enable username lookup on Supabase.',
          );
        }

        final resolvedEmail =
            userByUsername['email']?.toString().trim().toLowerCase() ?? '';
        final resolvedPhone = userByUsername['phone']?.toString().trim() ?? '';
        if (resolvedEmail.isNotEmpty) {
          credentialEmail = resolvedEmail;
        } else if (resolvedPhone.isNotEmpty) {
          credentialPhone = resolvedPhone;
        } else {
          throw Exception(
            'Account is missing both email and phone credentials. Please contact support.',
          );
        }
      }

      print(
        'Attempting login with ${credentialEmail != null ? 'email' : 'phone'}',
      );

      final userCredential = await _auth.signInWithPassword(
        email: credentialEmail,
        phone: credentialPhone,
        password: _password,
      );
      final user = userCredential.user!;
      print('Auth successful. UID: ${user.id}');

      Map<String, dynamic>? userDoc = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (userDoc == null) {
        final metadata = user.userMetadata ?? {};
        final fallbackUsername = metadata['username']?.toString().trim().isNotEmpty ==
                true
            ? metadata['username'].toString().trim()
            : ((user.email ?? user.phone ?? 'User').toString().split('@').first);
        final String? fallbackPhone =
            metadata['phone']?.toString().trim().isNotEmpty == true
                ? metadata['phone'].toString().trim()
                : user.phone?.toString().trim();
        final fallbackEmail = metadata['email']?.toString().trim().isNotEmpty ==
                true
            ? metadata['email'].toString().trim().toLowerCase()
            : (user.email ?? '').toString().trim().toLowerCase();

        final upsertData = <String, dynamic>{
          'id': user.id,
          'username': fallbackUsername,
          'role': 'customer',
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        };
        if (fallbackEmail.isNotEmpty) {
          upsertData['email'] = fallbackEmail;
        }
        if (fallbackPhone != null && fallbackPhone.isNotEmpty) {
          upsertData['phone'] = fallbackPhone;
        }
        await _supabase.from('users').upsert(upsertData);

        userDoc = await _supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();
      }

      if (userDoc == null) {
        await _auth.signOut();
        throw Exception('Unable to initialize your user profile. Try again.');
      }

      final role = _normalizeRole(userDoc['role']);
      final providerStatus = userDoc['providerStatus']
          ?.toString()
          .trim()
          .toLowerCase();
      final username = userDoc['username']?.toString() ?? 'User';

      print('User role: $role, Provider status: $providerStatus');

      if (role == 'provider' && providerStatus == 'pending') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your provider application is under review'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        });
      } else if (role == 'provider' && providerStatus == 'rejected') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your provider application was rejected'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        });
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, $username!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      });
    } on AuthException catch (e) {
      print('AuthException: ${e.message}');

      String errorMessage = 'Login failed';
      final lower = e.message.toLowerCase();

      if (lower.contains('invalid login credentials')) {
        errorMessage = 'Invalid username/email or password';
      } else if (lower.contains('email not confirmed')) {
        errorMessage =
            'Email not verified yet. Verify your code during signup, then login.';
      } else if (lower.contains('too many')) {
        errorMessage = 'Too many login attempts. Please try again later.';
      } else {
        errorMessage = e.message;
      }

      _showErrorDialog(errorMessage);
    } catch (e, stackTrace) {
      print('Unexpected error: $e');
      print('Stack trace: $stackTrace');
      _showErrorDialog('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword() async {
    final input = _identifier.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your username or email first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_isValidEmail(input)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      await _auth.resetPasswordForEmail(input.toLowerCase());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Check your inbox'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } on AuthException catch (e) {
      String errorMessage = 'Failed to send reset email';
      final lower = e.message.toLowerCase();
      if (lower.contains('invalid email')) {
        errorMessage = 'Invalid email address';
      } else if (lower.contains('too many')) {
        errorMessage = 'Too many requests. Try again later';
      } else {
        errorMessage = e.message;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reset email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignUpPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          height: MediaQuery.of(context).size.width * 0.4,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/logos/vertical_with_word.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Login to Your Account',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Enter your credentials to continue',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Username or Email',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF6A11CB),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6A11CB),
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: TextInputType.text,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Username or email is required';
                        }
                        return null;
                      },
                      onSaved: (v) => _identifier = v!.trim(),
                      onChanged: (v) => _identifier = v.trim(),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF6A11CB),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6A11CB),
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      onSaved: (v) => _password = v!,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _resetPassword,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2575FC),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: Colors.blue.shade200,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey.shade300,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.grey.shade300,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _navigateToSignUp,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create New Account',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'By continuing, you agree to our Terms of Service and Privacy Policy',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
