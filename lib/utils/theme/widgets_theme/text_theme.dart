
import 'package:agri_direct/utils/constants/colors.dart';
import 'package:agri_direct/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

class UTextTheme{
  UTextTheme._();

  static TextTheme lightTextTheme = TextTheme(
    headlineLarge: TextStyle().copyWith(fontSize: 32, fontWeight: FontWeight.bold, color: UColors.dark),
    headlineMedium: const TextStyle().copyWith(fontSize: 24, fontWeight: FontWeight.w600, color: UColors.dark),
    headlineSmall: const TextStyle().copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: UColors.dark),

    titleLarge: const TextStyle().copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: UColors.dark),
    titleMedium: const TextStyle().copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: UColors.dark),
    titleSmall: const TextStyle().copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: UColors.dark),

    bodyLarge: const TextStyle().copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: UColors.dark),
    bodyMedium: const TextStyle().copyWith(fontSize: 14, fontWeight: FontWeight.normal, color: UColors.dark),
    bodySmall: const TextStyle().copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: UColors.dark),

    labelLarge: const TextStyle().copyWith(fontSize: 12, fontWeight: FontWeight.normal, color: UColors.dark),
    labelMedium: const TextStyle().copyWith(fontSize: 12, fontWeight: FontWeight.normal, color: UColors.dark),
    labelSmall: const TextStyle().copyWith(fontSize: 12, fontWeight: FontWeight.normal, color: UColors.dark),

  );
  static TextTheme darkTextTheme = TextTheme(
    headlineLarge: TextStyle().copyWith(fontSize: 32, fontWeight: FontWeight.bold, color: UColors.light),
    headlineMedium: const TextStyle().copyWith(fontSize: 24, fontWeight: FontWeight.w600, color: UColors.light),
    headlineSmall: const TextStyle().copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: UColors.light),

    titleLarge: const TextStyle().copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: UColors.light),
    titleMedium: const TextStyle().copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: UColors.light),
    titleSmall: const TextStyle().copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: UColors.light),

    bodyLarge: const TextStyle().copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: UColors.light),
    bodyMedium: const TextStyle().copyWith(fontSize: 14, fontWeight: FontWeight.normal, color: UColors.light),
    bodySmall: const TextStyle().copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: UColors.light),

    labelLarge: const TextStyle().copyWith(fontSize: 12, fontWeight: FontWeight.normal, color: UColors.light),
    labelMedium: const TextStyle().copyWith(fontSize: 12, fontWeight: FontWeight.normal, color: UColors.light),
    labelSmall: const TextStyle().copyWith(fontSize: 12, fontWeight: FontWeight.normal, color: UColors.light),

  );
}