
import 'package:agri_direct/utils/constants/colors.dart';
import 'package:agri_direct/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

class UCheckBoxTheme{
  UCheckBoxTheme._();

  static CheckboxThemeData lightCheckBoxTheme = CheckboxThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(USizes.xs)),
    checkColor: WidgetStateProperty.resolveWith((states) {
      if(states.contains(WidgetState.selected)){
        return UColors.white;
      }else {
        return UColors.black;
      }
    }),
    fillColor: WidgetStateProperty.resolveWith((states){
      if(states.contains(WidgetState.selected)){
        return UColors.primary;
      }else {
        return UColors.transparent;
      }
    })
  );

  static CheckboxThemeData darkCheckBoxTheme = CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(USizes.xs)),
      checkColor: WidgetStateProperty.resolveWith((states) {
        if(states.contains(WidgetState.selected)){
          return UColors.white;
        }else {
          return UColors.black;
        }
      }),
      fillColor: WidgetStateProperty.resolveWith((states){
        if(states.contains(WidgetState.selected)){
          return UColors.primary;
        }else {
          return UColors.transparent;
        }
      })
  );
}