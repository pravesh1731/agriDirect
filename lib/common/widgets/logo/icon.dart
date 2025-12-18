import '../../../utils/constants/colors.dart';
import 'package:flutter/material.dart';

Container logo(bool isDark, double height, double width) {
  return Container(
    width: width,
    height: height,
    decoration: const BoxDecoration(
      color: UColors.primary,
      shape: BoxShape.circle,
    ),
    clipBehavior: Clip.antiAlias,
    child: Image.asset(
      isDark
          ? 'assets/logo/logo_lightMode.png'
          : 'assets/logo/logo_darkMode.png',
      fit: BoxFit.contain,
    ),
  );
}
