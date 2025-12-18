import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agri_direct/common/widgets/logo/icon.dart';
import 'package:agri_direct/features/home/Farmer/navigatorMenu/farmerNavigator_menu.dart';
import 'package:agri_direct/features/home/Buyer/navigatorMenu/buyerNavigator_menu.dart';
import '../../../../common/widgets/buttons/elevated_button.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import 'singUp.dart';

// Top-level helper to show snack bars from anywhere in this file
void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 3),
  ));
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool isPasswordVisible = false;
  String selectedTab = 'Farmer'; // 'Farmer' or 'Buyer'
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future<void> _navigateToRole(String role) async {
    if (!mounted) return;
    if (role.toLowerCase() == 'farmer') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NavigatorMenu()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BuyerNavigatorMenu()));
    }
  }

  Future<void> signInWithEmail() async {
    setState(() { isLoading = true; errorMessage = null; });

    final email = emailController.text.trim();
    final password = passwordController.text;

    // Client-side validations
    if (email.isEmpty) {
      setState(() { isLoading = false; });
      showSnackBar(context, 'Please enter your email address.');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() { isLoading = false; });
      showSnackBar(context, 'Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() { isLoading = false; });
      showSnackBar(context, 'Please enter your password.');
      return;
    }

    try {
      final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCred.user?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          final role = (doc.data()?['role'] ?? '').toString();
          await _navigateToRole(role.isNotEmpty ? role : selectedTab);
        } else {
          // no profile saved, fallback to selectedTab
          await _navigateToRole(selectedTab);
        }
      }
    } on FirebaseAuthException catch (e) {
      final msg = _friendlyAuthMessage(e);
      setState(() { errorMessage = msg; });
      showSnackBar(context, msg);
    } on FirebaseException catch (e) {
      final msg = e.message ?? 'Firestore error: ${e.code}';
      setState(() { errorMessage = msg; });
      showSnackBar(context, msg);
    } catch (e) {
      final msg = e.toString();
      setState(() { errorMessage = msg; });
      showSnackBar(context, msg);
    } finally {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  bool _isValidEmail(String email) {
    final emailReg = RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}");
    return emailReg.hasMatch(email);
  }

  String _friendlyAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for that email. Please sign up.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is invalid. Please correct it.';
      case 'user-disabled':
        return 'This user has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Authentication error: ${e.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(USizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Center(child: logo(isDark, 80, 80)),
              SizedBox(height: USizes.spaceBteSections),

              // Welcome Back Text
              const Center(
                child: Text(
                  'Welcome Back',
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
                  'Sign in to your account',
                  style: TextStyle(
                    fontSize: 14,
                    color: UColors.textSecondaryLight,
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red))),
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
                      ? 'Login to manage your products'
                      : 'Login to purchase fresh produce',
                  style: const TextStyle(
                    fontSize: 13,
                    color: UColors.textSecondaryLight,
                  ),
                ),
              ),
              SizedBox(height: USizes.spaceBteSections),

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
                decoration: const InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: UColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: UColors.borderPrimaryLight),
                  ),
                ),
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
                  hintText: 'Enter password',
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
                    onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
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

              // Sign In Button (email/password)
              UElevatedButton(
                gradient: UColors.primaryGradient,
                onPressed: () { if (isLoading) return; signInWithEmail(); },
                child: Text(
                  isLoading ? 'Signing In...' : 'Sign In',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: UColors.textWhite,
                  ),
                ),
              ),
              const SizedBox(height: USizes.spaceBtwItems),

              // Sign Up Link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
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
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign up',
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
