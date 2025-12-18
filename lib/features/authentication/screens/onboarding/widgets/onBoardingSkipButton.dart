import 'package:agri_direct/utils/constants/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../utils/helpers/device_helper.dart';
import '../../../controllers/onBoarding_controller.dart';
import 'package:agri_direct/features/authentication/screens/login/signIn.dart';

class onBoardingSkipButton extends ConsumerWidget {
  const onBoardingSkipButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(onBoardingIndexProvider);
    final pageController = ref.watch(pageControllerProvider);
    return index == 2
        ? const SizedBox()
        : Positioned(
            top: UDeviceHelper.getAppBarHeight(),
            right: 0,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: UColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () async {
                // Mark onboarding as seen and navigate to SignIn
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('seenOnboarding', true);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                );
              },
              child: const Text('Skip'),
            ),
          );
  }
}
