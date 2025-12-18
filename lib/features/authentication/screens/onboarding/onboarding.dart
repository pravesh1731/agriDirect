
import 'package:agri_direct/features/authentication/screens/onboarding/widgets/onBoardingDotNavigation.dart';
import 'package:agri_direct/features/authentication/screens/onboarding/widgets/onBoardingNextButton.dart';
import 'package:agri_direct/features/authentication/screens/onboarding/widgets/onBoardingSkipButton.dart';
import 'package:agri_direct/features/authentication/screens/onboarding/widgets/onBoardingPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../utils/constants/images.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/texts.dart';
import '../../controllers/onBoarding_controller.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final pageController = ref.watch(pageControllerProvider);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: USizes.defaultSpace),
        child: Stack(
          children: [
            PageView(
            controller: pageController,
            onPageChanged: (value) => ref.read(onBoardingIndexProvider.notifier).setIndex(value),
            children: [
                OnBoardingPage(
                  animation: UImage.onboardingAnimation1,
                  title: UText.onBoardingTitle1,
                  subtitle: UText.onBoardingSubTitle1,
                ),
                OnBoardingPage(
                  animation: UImage.onboardingAnimation2,
                  title: UText.onBoardingTitle2,
                  subtitle: UText.onBoardingSubTitle2,
                ),
                OnBoardingPage(
                  animation: UImage.onboardingAnimation3,
                  title: UText.onBoardingTitle3,
                  subtitle: UText.onBoardingSubTitle3,
                ),
              ],
            ),

          // Smooth Page Indicator
          onBoardingDotNavigation(),

          // Skip Button
          onBoardingSkipButton(),

          // Circular Button / Next Button
          onBoardingNextButton()
        ],
      ),
    ),
    );
  }
}



