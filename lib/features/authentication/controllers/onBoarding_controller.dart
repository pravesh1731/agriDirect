import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider exposing a PageController and disposing it when no longer used
final pageControllerProvider = Provider<PageController>((ref) {
  final controller = PageController();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});

/// Notifier for onboarding page index
class OnboardingIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int value) {
    state = value;
  }
}

/// Provider exposing the onboarding index notifier
final onBoardingIndexProvider = NotifierProvider<OnboardingIndexNotifier, int>(
  OnboardingIndexNotifier.new,
);
