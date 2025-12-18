import 'package:agri_direct/features/authentication/screens/login/signIn.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../common/widgets/buttons/elevated_button.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../controllers/onBoarding_controller.dart';

class onBoardingNextButton extends ConsumerWidget {
  const onBoardingNextButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final index = ref.watch(onBoardingIndexProvider);
  final pageController = ref.watch(pageControllerProvider);

    return Positioned(
      left: 0,
      right: 0,
      bottom: USizes.spaceBtwItems / 2,
      child: UElevatedButton(
        gradient: UColors.primaryGradient,
        onPressed: () async {
          if (index < 2) {
            ref.read(onBoardingIndexProvider.notifier).setIndex(index + 1);
            pageController.jumpToPage(index + 1);
          } else {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('seenOnboarding', true);
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => const SignInScreen()),
            );
          }
        },
        child: Text(
          index == 2 ? 'Get Started →' : 'Next',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
