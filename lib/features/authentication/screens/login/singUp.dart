import 'package:agri_direct/common/widgets/logo/icon.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../common/widgets/buttons/elevated_button.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../common/widgets/location_field.dart';

import 'signIn.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool isPasswordVisible = false;
  String selectedTab = 'Farmer'; // 'Farmer' or 'Buyer'
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  bool _isValidEmail(String email) {
    final emailReg = RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}");
    return emailReg.hasMatch(email);
  }

  String _friendlyAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in or use a different email.';
      case 'invalid-email':
        return 'The email address is invalid. Please correct it.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign up method is not enabled. Check Firebase console.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication error: ${e.code}';
    }
  }

  Future<void> signUpWithEmail() async {
    setState(() { isLoading = true; errorMessage = null; });

    // client-side validation
    if (fullNameController.text.trim().isEmpty) {
      setState((){ isLoading = false; });
      showSnackBar(context, 'Please enter your full name');
      return;
    }
    if (emailController.text.trim().isEmpty || !_isValidEmail(emailController.text.trim())) {
      setState((){ isLoading = false; });
      showSnackBar(context, 'Please enter a valid email address');
      return;
    }
    if (passwordController.text.trim().length < 6) {
      setState((){ isLoading = false; });
      showSnackBar(context, 'Password must be at least 6 characters');
      return;
    }

    try {
      final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final uid = userCred.user?.uid;
      if (uid != null) {
        // Show success immediately after authentication succeeds
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Signup successful. Please sign in.'),
            duration: Duration(seconds: 2),
          ));
        }
        // Attempt to save profile to Firestore in background. If it fails, show a warning but continue.
        _writeUserDocWithRetry(uid, {
          'uid': uid,
          'email': emailController.text.trim(),
          'displayName': fullNameController.text.trim(),
          'location': locationController.text.trim(),
          'role': selectedTab,
          'createdAt': FieldValue.serverTimestamp(),
        }).catchError((e) {
          // If permission error, show actionable message
          final msg = (e is FirebaseException && e.code == 'permission-denied')
              ? 'Profile save failed: Firestore permission denied. Please check your security rules.'
              : 'Profile save failed: ${e.toString()}';
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));
        });
        // Small delay so the user sees the snackbar
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        // After signup, show success message then navigate user to the Sign In screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignInScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      final msg = _friendlyAuthMessage(e);
      setState(() { errorMessage = msg; });
      showSnackBar(context, msg);
    } on FirebaseException catch (e) {
      // Catch Firestore permission errors and show a more actionable message
      if (e.code == 'permission-denied') {
        setState(() { errorMessage = 'Firestore permission denied — check your security rules (users collection write requires authenticated user).'; });
      } else {
        setState(() { errorMessage = e.message; });
      }
    } catch (e) {
      final msg = e.toString();
      setState(() { errorMessage = msg; });
      showSnackBar(context, msg);
    } finally {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  Future<void> _writeUserDocWithRetry(String uid, Map<String, dynamic> data) async {
    const int maxAttempts = 4;
    int attempt = 0;
    int delayMs = 300;
    while (attempt < maxAttempts) {
      attempt++;
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set(data);
        return;
      } on FirebaseException catch (e) {
        // If permission-denied, it may be a transient auth token propagation issue right after sign-up.
        if (e.code == 'permission-denied' && attempt < maxAttempts) {
          // wait and retry
          await Future.delayed(Duration(milliseconds: delayMs));
          delayMs *= 2;
          continue;
        }
        rethrow;
      }
    }
    // If we exit loop without returning, throw a generic exception
    throw FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied', message: 'Max retries reached');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: UColors.backgroundLight,
      appBar: AppBar(backgroundColor: UColors.backgroundLight, elevation: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(USizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Center(child: logo(isDark, 80, 80)),
              SizedBox(height: USizes.spaceBteSections),

              // Join FarmChain Text
              const Center(
                child: Text(
                  'Join AgriDirect',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: UColors.textPrimaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Start your farming revolution',
                  style: TextStyle(
                    fontSize: 14,
                    color: UColors.textSecondaryLight,
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                SizedBox(height: 12),
                Center(child: Text(errorMessage!, style: TextStyle(color: Colors.red))),
              ],
              SizedBox(height: USizes.spaceBteSections),

              // Farmer/Buyer Toggle
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: UColors.gray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedTab = 'Farmer'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedTab == 'Farmer'
                                ? Colors.blue.shade300
                                : UColors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Farmer',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: selectedTab == 'Farmer'
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: selectedTab == 'Farmer'
                                  ? UColors.textPrimaryLight
                                  : UColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedTab = 'Buyer'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedTab == 'Buyer'
                                ? Colors.blue.shade300
                                : UColors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Buyer',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: selectedTab == 'Buyer'
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: selectedTab == 'Buyer'
                                  ? UColors.textPrimaryLight
                                  : UColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: USizes.spaceBtwItems),

              // Subtitle
              Center(
                child: Text(
                  selectedTab == 'Farmer'
                      ? 'Sign up to sell your produce'
                      : 'Sign up to purchase fresh produce',
                  style: const TextStyle(
                    fontSize: 13,
                    color: UColors.textSecondaryLight,
                  ),
                ),
              ),
              SizedBox(height: USizes.spaceBteSections),

              // Full Name Field
              const Text(
                'Full Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: UColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: fullNameController,
                decoration: InputDecoration(
                  hintText: 'Enter your full name',
                  prefixIcon: const Icon(
                    Icons.person_outlined,
                    color: UColors.textSecondaryLight,
                  ),
                  filled: true,
                  fillColor: UColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: UColors.borderPrimaryLight),
                  ),
                ),
              ),
               SizedBox(height: USizes.spaceBtwItems),

              // Email Field
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: UColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: UColors.textSecondaryLight,
                  ),
                  filled: true,
                  fillColor: UColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: UColors.borderPrimaryLight),
                  ),
                ),
              ),
              const SizedBox(height: USizes.spaceBtwItems),

              // Location Field
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: UColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              LocationField(
                controller: locationController,
                onSelected: (address, lat, lng) {
                  // you can store lat/lng in state if needed
                },
              ),
              const SizedBox(height: USizes.spaceBtwItems),

              // Password Field
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: UColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: UColors.textSecondaryLight,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: UColors.textSecondaryLight,
                    ),
                    onPressed: () =>
                        setState(() => isPasswordVisible = !isPasswordVisible),
                  ),
                  filled: true,
                  fillColor: UColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: UColors.borderPrimaryLight,
                    ),
                  ),
                ),
              ),
              SizedBox(height: USizes.spaceBteSections),

              // Create Account Button
              UElevatedButton(
                gradient: UColors.primaryGradient,
                onPressed: () { if (isLoading) return; signUpWithEmail(); },
                child: isLoading ? const Text('Creating...') : const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: UColors.textWhite,
                  ),
                ),
              ),
              const SizedBox(height: USizes.spaceBtwItems),

              // Sign In Link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: UColors.textSecondaryLight,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignInScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: UColors.primary,
                        ),
                      ),
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
}
