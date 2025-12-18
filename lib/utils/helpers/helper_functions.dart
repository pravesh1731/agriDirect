
import 'package:flutter/material.dart';

class UHelperFunctions{
  UHelperFunctions._();

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}