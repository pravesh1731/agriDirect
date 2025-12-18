import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../../utils/helpers/device_helper.dart';
import '../../../controllers/onBoarding_controller.dart';

class onBoardingDotNavigation extends ConsumerWidget {
  const onBoardingDotNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = ref.watch(pageControllerProvider);

    return Positioned(
      bottom: UDeviceHelper.getBottomNavigationBarHeight() * 4,
      left: UDeviceHelper.getScreenWidth(context) / 3,
      right: UDeviceHelper.getScreenWidth(context) / 3,
      child: SmoothPageIndicator(
        controller: pageController,
        onDotClicked: (index) {
          ref.read(onBoardingIndexProvider.notifier).setIndex(index);
          ref.read(pageControllerProvider).jumpToPage(index);
        },
        count: 3,
        effect: ExpandingDotsEffect(dotHeight: 6.0),
      ),
    );
  }
}
