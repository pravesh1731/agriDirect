import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';

class UOutlinedButtonTheme{
  UOutlinedButtonTheme._();

  static final lightOutlinedButtonTheme = OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        foregroundColor: UColors.dark,
        side: BorderSide(color: UColors.borderPrimary),
        padding: EdgeInsets.symmetric(vertical: USizes.buttonHeight, horizontal: 20),
        textStyle: TextStyle(fontSize: 16, color: UColors.black, fontWeight: FontWeight.w100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(USizes.buttonRadius)),
      )
  );

  static final darkOutlinedButtonTheme = OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        foregroundColor: UColors.light,
        side: BorderSide(color: UColors.borderPrimary),
        padding: EdgeInsets.symmetric(vertical: USizes.buttonHeight, horizontal: 20),
        textStyle: TextStyle(fontSize: 16, color: UColors.textWhite, fontWeight: FontWeight.w100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(USizes.buttonRadius)),
      )
  );
}