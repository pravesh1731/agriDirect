
import 'package:agri_direct/utils/constants/colors.dart';
import 'package:agri_direct/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

class UTextFieldTheme{

  static InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    prefixIconColor: UColors.darkerGray,
    suffixIconColor: UColors.darkerGray,
    labelStyle: TextStyle().copyWith(fontSize: USizes.fontSizeMd, color: UColors.black),
    hintStyle: TextStyle().copyWith(fontSize: USizes.fontSizeSm, color: UColors.black),
    errorStyle: TextStyle().copyWith(fontStyle: FontStyle.normal),
    floatingLabelStyle: TextStyle().copyWith(color: UColors.black.withValues(alpha:2)),
    border: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(USizes.inputFieldRadius),
      borderSide: BorderSide(width: 1, color: UColors.gray),
    ),
    enabledBorder: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(USizes.inputFieldRadius),
      borderSide: BorderSide(width: 1, color: UColors.gray),
    ),
    focusedBorder: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(USizes.inputFieldRadius),
      borderSide: BorderSide(width: 1, color: UColors.dark),
    ),
    errorBorder: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(USizes.inputFieldRadius),
      borderSide: BorderSide(width: 1, color: UColors.warning),
    ),
    focusedErrorBorder: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(USizes.inputFieldRadius),
      borderSide: BorderSide(width: 1, color: UColors.warning),
    ),
  );

  static InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    prefixIconColor: UColors.white,
    suffixIconColor: UColors.white,
    labelStyle: TextStyle().copyWith(fontSize: USizes.fontSizeMd, color: UColors.black),
    hintStyle: TextStyle().copyWith(fontSize: USizes.fontSizeSm, color: UColors.black),
    errorStyle: TextStyle().copyWith(fontStyle: FontStyle.normal),
    floatingLabelStyle: TextStyle().copyWith(color: UColors.white.withValues(alpha:2)),
    border: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(USizes.inputFieldRadius),
      borderSide: BorderSide(width: 1, color: UColors.white),
    ),
    enabledBorder: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(USizes.inputFieldRadius),
      borderSide: BorderSide(width: 1, color: UColors.white),
    ),
    focusedBorder: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(USizes.inputFieldRadius),
      borderSide: BorderSide(width: 1, color: UColors.dark),
    ),
    errorBorder: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(USizes.inputFieldRadius),
      borderSide: BorderSide(width: 1, color: UColors.warning),
    ),
    focusedErrorBorder: OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(USizes.inputFieldRadius),
      borderSide: BorderSide(width: 1, color: UColors.warning),
    ),
  );
}