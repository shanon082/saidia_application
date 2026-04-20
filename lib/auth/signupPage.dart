import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:saidia_app/auth/loginPage.dart';
import 'package:saidia_app/services/firestore_services.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = Supabase.instance.client.auth;
  final _dataService = FirestoreService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  DateTime? _lastOtpRequestAt;

  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-]+'), '');

    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    if (cleaned.startsWith('0') && cleaned.length == 10) {
      return '+256${cleaned.substring(1)}';
    } else if ((cleaned.startsWith('7') || cleaned.startsWith('1')) &&
        cleaned.length == 9) {
      return '+256$cleaned';
    } else if (cleaned.startsWith('256') && cleaned.length == 12) {
      return '+$cleaned';
    } else if (cleaned.length == 9 && RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return '+256$cleaned';
    }

    return '+$cleaned';
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final formatted = _formatPhoneNumber(phone);
    return RegExp(r'^\+256[0-9]{9}$').hasMatch(formatted);
  }

  String _mapAuthError(AuthException e) {
    final message = e.message.toLowerCase();

    if (message.contains('over_email_send_rate_limit') ||
        message.contains('email rate limit exceeded')) {
      return 'Email send rate limit reached. Wait a few minutes before retrying.';
    }

    if (message.contains('already registered') ||
        message.contains('user already registered')) {
      return 'Email is already registered. Please login instead.';
    }

    if (message.contains('otp_disabled') ||
        message.contains('email provider') ||
        message.contains('confirmations are disabled')) {
      return 'Email OTP is not enabled in Supabase Auth settings.';
    }

    if (message.contains('otp') && message.contains('expired')) {
      return 'OTP expired. Request a new OTP.';
    }

    if (message.contains('invalid') && message.contains('otp')) {
      return 'Invalid OTP. Please check and try again.';
    }

    if (message.contains('429') || message.contains('too many')) {
      return 'Too many requests. Wait a few minutes and try again.';
    }

    if (message.contains('500') ||
        message.contains('unexpected_failure') ||
        message.contains('database error saving new user') ||
        message.contains('error creating user') ||
        message.contains('smtp') ||
        message.contains('error sending email') ||
        message.contains('failed to send email')) {
      return 'Supabase signup/email provider error. Check Auth logs for exact failure (SMTP or database trigger).';
    }

    return e.message;
  }

  Future<void> _submitForm() async {
    if (_isLoading || _isOtpSent) return;
    final now = DateTime.now();
    if (_lastOtpRequestAt != null &&
        now.difference(_lastOtpRequestAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastOtpRequestAt = now;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final formattedPhone = _formatPhoneNumber(_phoneController.text);

      print('Starting signup process...');
      print('Email: $email');
      print('Formatted Phone: $formattedPhone');

      if (!_isValidEmail(email)) {
        throw 'Please enter a valid email address';
      }
      if (!_isValidPhone(_phoneController.text)) {
        throw 'Please enter a valid phone number (e.g., 07xx xxx xxx)';
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        throw 'Passwords do not match';
      }
      if (_passwordController.text.length < 6) {
        throw 'Password must be at least 6 characters';
      }

      print('Checking for duplicate accounts...');
      bool emailTaken = false;
      bool phoneTaken = false;
      try {
        emailTaken = await _dataService.isEmailTaken(email);
        phoneTaken = await _dataService.isPhoneTaken(formattedPhone);
      } catch (e) {
        // If signup lookup is blocked by RLS, continue and rely on DB unique constraints.
        print('Duplicate pre-check skipped: $e');
      }

      if (emailTaken) {
        throw 'Email is already registered. Please use a different email or login.';
      }
      if (phoneTaken) {
        throw 'Phone number is already registered. Please use a different phone number.';
      }

      print('No duplicates found. Creating auth account + sending verification code...');
      final signUpRes = await _auth.signUp(
        email: email,
        password: _passwordController.text,
        data: {
          'name': _nameController.text.trim(),
          'phone': formattedPhone,
          'role': 'customer',
        },
      );
      if (signUpRes.user == null) {
        throw 'Signup failed. Please try again.';
      }

      if (!mounted) return;
      setState(() {
        _isOtpSent = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification code sent to $email. Enter the OTP to verify your account.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _mapAuthError(e);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is String ? e : 'Signup failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    if (_isLoading) return;

    final otp = _otpController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    if (otp.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(otp)) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit OTP');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final verifyRes = await _auth.verifyOTP(
        type: OtpType.signup,
        email: email,
        token: otp,
      );

      final user = verifyRes.user;
      if (user == null) {
        throw 'OTP verification failed. Please request a new OTP.';
      }

      try {
        await _dataService.createUserProfile(
          uid: user.id,
          name: _nameController.text.trim(),
          email: email,
          phone: _formatPhoneNumber(_phoneController.text),
        );
      } on PostgrestException catch (e) {
        final message = e.message.toLowerCase();
        if (message.contains('users_email_key')) {
          throw 'Email is already registered. Please login instead.';
        }
        if (message.contains('users_phone_key')) {
          throw 'Phone number is already registered. Please login instead.';
        }
        rethrow;
      }

      if (!mounted) return;

      await _auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account verified successfully. Please login.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _mapAuthError(e);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            e is String ? e : 'Failed to verify OTP. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOTP() async {
    if (_isLoading) return;

    final now = DateTime.now();
    if (_lastOtpRequestAt != null &&
        now.difference(_lastOtpRequestAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastOtpRequestAt = now;

    final email = _emailController.text.trim().toLowerCase();

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await _auth.resend(
        type: OtpType.signup,
        email: email,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification code resent to $email'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _mapAuthError(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not resend OTP. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _backToForm() {
    setState(() {
      _isOtpSent = false;
      _otpController.clear();
      _errorMessage = null;
      _isLoading = false;
    });
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.blue,
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }

  Widget _buildOtpCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_user_outlined, size: 80, color: Colors.blue),
          const SizedBox(height: 20),
          const Text(
            'Verify Email',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the 6-digit OTP sent to',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          Text(
            _emailController.text.trim().toLowerCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _otpController,
            decoration: InputDecoration(
              labelText: 'Enter OTP',
              labelStyle: const TextStyle(color: Colors.blue),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 8,
            ),
            onChanged: (value) {
              if (value.length == 6 && !_isLoading) {
                _verifyOTP();
              }
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _isLoading ? null : _backToForm,
                icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                label: const Text('Change Email'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                ),
              ),
              TextButton.icon(
                onPressed: _isLoading ? null : _resendOTP,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Resend OTP'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                const SizedBox(height: 20),
                const Text(
                  'Create your account to get started',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_isOtpSent) ...[
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your full name';
                            }
                            if (value.trim().split(' ').length < 2) {
                              return 'Please enter your full name (first and last name)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email address';
                            }
                            if (!_isValidEmail(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          hintText: '07xx xxx xxx',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (!_isValidPhone(value)) {
                              return 'Please enter a valid phone number (e.g., 07xx xxx xxx)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildPasswordField(
                          controller: _passwordController,
                          label: 'Password',
                          obscureText: _obscurePassword,
                          onToggleVisibility: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          obscureText: _obscureConfirmPassword,
                          onToggleVisibility: () {
                            setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            );
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        _buildOtpCard(),
                      ],
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(top: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : (_isOtpSent ? _verifyOTP : _submitForm),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                _isOtpSent ? 'Verify OTP' : 'Create Account',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: _navigateToLogin,
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
