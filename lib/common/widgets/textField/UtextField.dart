import '../../../utils/constants/colors.dart';
import 'package:flutter/material.dart';

TextField UTextField(String hintText,IconData prefixIcon) {
  return TextField(
    decoration: InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(
        prefixIcon,
        color: UColors.textSecondaryLight,
      ),
      filled: true,
      fillColor: UColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: UColors.borderPrimaryLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: UColors.borderPrimaryLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: UColors.primary, width: 2),
      ),
    ),
  );
}




