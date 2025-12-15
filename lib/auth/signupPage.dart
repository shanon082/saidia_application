import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:saidia_app/auth/loginPage.dart';
import 'package:saidia_app/screens/homepage.dart';
import 'package:saidia_app/services/firestore_services.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestoreService = FirestoreService();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  // State
  String _verificationId = '';
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-]+'), '');
    
    // Remove leading + if present
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }
    
    // Handle different formats
    if (cleaned.startsWith('0') && cleaned.length == 10) {
      return '+256${cleaned.substring(1)}';
    } else if ((cleaned.startsWith('7') || cleaned.startsWith('1')) && cleaned.length == 9) {
      return '+256$cleaned';
    } else if (cleaned.startsWith('256') && cleaned.length == 12) {
      return '+$cleaned';
    } else if (cleaned.length == 9 && RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return '+256$cleaned';
    }
    
    return '+$cleaned';
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    String formatted = _formatPhoneNumber(phone);
    return RegExp(r'^\+256[0-9]{9}$').hasMatch(formatted);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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

      // Validate email format
      if (!_isValidEmail(email)) {
        throw 'Please enter a valid email address';
      }

      // Validate phone format
      if (!_isValidPhone(_phoneController.text)) {
        throw 'Please enter a valid phone number (e.g., 07xx xxx xxx)';
      }

      // Validate passwords match
      if (_passwordController.text != _confirmPasswordController.text) {
        throw 'Passwords do not match';
      }

      // Validate password strength
      if (_passwordController.text.length < 6) {
        throw 'Password must be at least 6 characters';
      }

      print('Checking for duplicate accounts...');
      
      // Check duplicates with better error handling
      final emailTaken = await _firestoreService.isEmailTaken(email);
      final phoneTaken = await _firestoreService.isPhoneTaken(formattedPhone);
      
      if (emailTaken) {
        throw 'Email is already registered. Please use a different email or login.';
      }
      
      if (phoneTaken) {
        throw 'Phone number is already registered. Please use a different phone number.';
      }

      print('No duplicates found. Sending OTP to $formattedPhone...');

      // Send OTP with better error handling
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('Verification auto-completed');
          await _completeSignup(credential, formattedPhone);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.code} - ${e.message}');
          
          String errorMessage = 'Phone verification failed';
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Invalid phone number format';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many attempts. Please try again later';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded. Please try again later';
              break;
          }
          
          if (mounted) {
            setState(() {
              _errorMessage = errorMessage;
              _isLoading = false;
            });
          }
        },
        codeSent: (verificationId, resendToken) {
          print('OTP sent successfully. Verification ID: $verificationId');
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _isOtpSent = true;
              _isLoading = false;
            });
          }
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP sent to $formattedPhone'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
          print('Code auto-retrieval timeout');
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      print('Error in submitForm: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    
    if (otp.isEmpty || otp.length != 6) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit OTP');
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(otp)) {
      setState(() => _errorMessage = 'OTP must contain only numbers');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      print('Verifying OTP...');
      
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );

      final formattedPhone = _formatPhoneNumber(_phoneController.text);
      await _completeSignup(credential, formattedPhone);
    } on FirebaseAuthException catch (e) {
      print('OTP verification error: ${e.code} - ${e.message}');
      
      String errorMessage = 'Invalid OTP';
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP. Please check and try again';
          break;
        case 'session-expired':
          errorMessage = 'OTP session expired. Please request a new OTP';
          break;
      }
      
      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    } catch (e) {
      print('Unexpected error in verifyOTP: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please try again';
        _isLoading = false;
      });
    }
  }

  Future<void> _completeSignup(PhoneAuthCredential phoneCredential, String formattedPhone) async {
    try {
      print('Starting complete signup process...');
      
      // 1. Sign in with phone credential
      print('Signing in with phone credential...');
      final phoneUserCredential = await _auth.signInWithCredential(phoneCredential);
      final user = phoneUserCredential.user!;
      
      print('Successfully signed in with phone. UID: ${user.uid}');

      // 2. Link email/password credential
      print('Linking email/password credential...');
      final emailCredential = EmailAuthProvider.credential(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      try {
        await user.linkWithCredential(emailCredential);
        print('Email/password linked successfully');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'provider-already-linked') {
          print('Email provider already linked, continuing...');
        } else if (e.code == 'email-already-in-use') {
          throw 'This email is already associated with another account';
        } else {
          rethrow;
        }
      }

      // 3. Update user profile
      print('Updating user profile...');
      await user.updateDisplayName(_nameController.text);
      await user.verifyBeforeUpdateEmail(_emailController.text.trim());
      
      // 4. Wait for auth state to propagate
      await Future.delayed(const Duration(milliseconds: 300));

      // 5. Create user profile in Firestore
      print('Creating Firestore user profile...');
      await _firestoreService.createUserProfile(
        name: _nameController.text,
        email: _emailController.text.trim(),
        phone: formattedPhone,
      );
      
      print('User profile created successfully!');

      // 6. Navigate to home page
      if (mounted) {
        print('Navigating to HomePage...');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to SaidiA, ${_nameController.text}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Complete signup error: $e');
      print('Stack trace: $stackTrace');
      
      // Sign out if there's an error to clean up
      try {
        await _auth.signOut();
      } catch (e) {
        print('Error signing out: $e');
      }
      
      String errorMessage = 'Signup failed. Please try again';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'Email already in use';
            break;
          case 'weak-password':
            errorMessage = 'Password is too weak';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address';
            break;
          default:
            errorMessage = e.message ?? 'Authentication failed';
        }
      }
      
      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  void _backToForm() {
    setState(() {
      _isOtpSent = false;
      _otpController.clear();
      _errorMessage = null;
    });
  }

  void _resendOTP() {
    if (!_isLoading) {
      _submitForm();
    }
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
      appBar: AppBar(
        title: const Text('Create Account'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const SizedBox(height: 20),
              const Text(
                'Join SaidiA',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your account to get started',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isOtpSent) ...[
                      // Registration Form
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
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () {
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
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
                      // OTP Verification
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade100, width: 1),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 80,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Verify Phone Number',
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
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              _phoneController.text,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Error Message
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
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

                            // OTP Input
                            TextFormField(
                              controller: _otpController,
                              decoration: InputDecoration(
                                labelText: 'Enter OTP',
                                labelStyle: const TextStyle(color: Colors.blue),
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.grey),
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
                                if (value.length == 6) {
                                  _verifyOTP();
                                }
                              },
                            ),
                            const SizedBox(height: 24),

                            // Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton.icon(
                                  onPressed: _backToForm,
                                  icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                                  label: const Text('Change Phone'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.grey.shade700,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _isLoading ? null : _resendOTP,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Resend OTP'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Error Message for registration form
                    if (_errorMessage != null && !_isOtpSent)
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
                            Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
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

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : (_isOtpSent ? _verifyOTP : _submitForm),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
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
                            : Text(
                                _isOtpSent ? 'Verify OTP' : 'Create Account',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => _navigateToLogin(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
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
    );
  }

  void _navigateToLogin() {
    Navigator.push(
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
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey.shade600,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      validator: validator,
    );
  }
}