
import 'package:agri_direct/utils/constants/colors.dart';
import 'package:agri_direct/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

class UElevatedButtonTheme{
  UElevatedButtonTheme._();

  static final lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      foregroundColor: UColors.light,
      backgroundColor: UColors.primary,
      disabledForegroundColor: UColors.darkerGray,
      disabledBackgroundColor: UColors.darkerGray,
      side: BorderSide(color: UColors.light),
      padding: EdgeInsets.symmetric(vertical: USizes.buttonHeight),
      textStyle: TextStyle(fontSize: 16, color: UColors.textWhite, fontWeight: FontWeight.w100),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(USizes.buttonRadius)),
    )
  );

  static final darkElevatedButtonTheme = ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        foregroundColor: UColors.light,
        backgroundColor: UColors.primary,
        disabledForegroundColor: UColors.darkerGray,
        disabledBackgroundColor: UColors.darkerGray,
        side: BorderSide(color: UColors.primary),
        padding: EdgeInsets.symmetric(vertical: USizes.buttonHeight),
        textStyle: TextStyle(fontSize: 16, color: UColors.textWhite, fontWeight: FontWeight.w100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(USizes.buttonRadius)),
      )
  );
}