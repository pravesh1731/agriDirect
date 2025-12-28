
import 'package:agri_direct/common/widgets/logo/icon.dart';
import 'package:agri_direct/features/home/Farmer/navigatorMenu/farmerNavigator_menu.dart';
import 'package:agri_direct/features/home/Buyer/navigatorMenu/buyerNavigator_menu.dart';
import 'package:flutter/material.dart';
import '../../../../common/widgets/buttons/elevated_button.dart';
import '../../../../common/widgets/textField/UtextField.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import 'singUp.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool isPasswordVisible = false;
  String selectedTab = 'Farmer'; // 'Farmer' or 'Buyer'

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
              UTextField("Enter your email",Icons.email_outlined),
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
              TextField(
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  hintText: "Enter password",
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
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: UColors.borderPrimaryLight,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: UColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: USizes.spaceBteSections),

              // Sign In Button
              UElevatedButton(
                gradient: UColors.primaryGradient,
                onPressed: () {
                  if (selectedTab == 'Buyer') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BuyerNavigatorMenu(),
                      ),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NavigatorMenu(),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Sign In',
                  style: TextStyle(
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
