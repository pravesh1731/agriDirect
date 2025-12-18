import 'package:agri_direct/utils/constants/colors.dart';
import 'package:agri_direct/utils/theme/widgets_theme/appbar_theme.dart';
import 'package:agri_direct/utils/theme/widgets_theme/bottom_sheet_theme.dart';
import 'package:agri_direct/utils/theme/widgets_theme/checkbox_theme.dart';
import 'package:agri_direct/utils/theme/widgets_theme/chip_theme.dart';
import 'package:agri_direct/utils/theme/widgets_theme/elevated_button_theme.dart';
import 'package:agri_direct/utils/theme/widgets_theme/outline_button_theme.dart';
import 'package:agri_direct/utils/theme/widgets_theme/text_field_theme.dart';
import 'package:agri_direct/utils/theme/widgets_theme/text_theme.dart';
import 'package:flutter/material.dart';

class UTheme {
  UTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    brightness: Brightness.light,
    primaryColor: UColors.primary,
    disabledColor: UColors.gray,
    textTheme: UTextTheme.lightTextTheme,
    chipTheme: UChipTheme.lightChipTheme,
    scaffoldBackgroundColor: UColors.backgroundLight,
    appBarTheme: UAppbarTheme.lightAppBarTheme,
    checkboxTheme: UCheckBoxTheme.lightCheckBoxTheme,
    bottomSheetTheme: UBottomSheetTheme.lightBottomSheetTheme,
    elevatedButtonTheme: UElevatedButtonTheme.lightElevatedButtonTheme,
    outlinedButtonTheme: UOutlinedButtonTheme.lightOutlinedButtonTheme,
    inputDecorationTheme: UTextFieldTheme.lightInputDecorationTheme,
  );
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    brightness: Brightness.dark,
    primaryColor: UColors.primary,
    disabledColor: UColors.gray,
    textTheme: UTextTheme.darkTextTheme,
    chipTheme: UChipTheme.darkChipTheme,
    scaffoldBackgroundColor: UColors.backgroundDark,
    appBarTheme: UAppbarTheme.darkAppBarTheme,
    checkboxTheme: UCheckBoxTheme.darkCheckBoxTheme,
    bottomSheetTheme: UBottomSheetTheme.darkBottomSheetTheme,
    elevatedButtonTheme: UElevatedButtonTheme.darkElevatedButtonTheme,
    outlinedButtonTheme: UOutlinedButtonTheme.darkOutlinedButtonTheme,
    inputDecorationTheme: UTextFieldTheme.darkInputDecorationTheme,
  );
}
