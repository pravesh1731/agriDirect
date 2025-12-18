import 'package:agri_direct/utils/constants/colors.dart';
import 'package:flutter/material.dart';

class UChipTheme{
  UChipTheme._();

  static ChipThemeData lightChipTheme = ChipThemeData(
    disabledColor: UColors.gray.withValues(alpha: 0.4),
    labelStyle: const TextStyle(color: UColors.black),
    selectedColor: UColors.primary,
    padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 12),
    checkmarkColor: UColors.white
  );

  static ChipThemeData darkChipTheme = ChipThemeData(
      disabledColor: UColors.darkerGray,
      labelStyle: const TextStyle(color: UColors.white),
      selectedColor: UColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 12),
      checkmarkColor: UColors.white
  );
}