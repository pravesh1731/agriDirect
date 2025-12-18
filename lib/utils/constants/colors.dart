
import 'dart:ui';
import 'package:flutter/material.dart';

class UColors{

  // ===== PRIMARY & ACCENT =====
  static const Color primary = Color(0xFF00B36B); // Main FarmChain green
  static const Color accent = Color(0xFF4ADE80); // Lighter accent green

  // ===== LIGHT THEME =====
  static const Color backgroundLight = Color(0xFFF9FAFB); // Screen background
  static const Color cardLight = Color(0xFFFFFFFF); // Card surfaces

  static const Color textPrimaryLight = Color(0xFF1E1E1E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textWhite = Colors.white;
  static const Color textWhite70 = Colors.white70;

  static const Color buttonPrimaryLight = Color(0xFF00B36B);
  static const Color buttonDisabledLight = Color(0xFFE5E7EB);

  static const Color borderPrimaryLight = Color(0xFFE5E7EB);
  static const Color borderSecondaryLight = Color(0xFFF3F4F6);

  // ===== DARK THEME =====
  static const Color backgroundDark = Color(0xFF111827);
  static const Color cardDark = Color(0xFF1F2937);

  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  static const Color buttonPrimaryDark = Color(0xFF00C77A);
  static const Color buttonDisabledDark = Color(0xFF374151);

  static const Color borderPrimaryDark = Color(0xFF374151);
  static const Color borderSecondaryDark = Color(0xFF1F2937);

  // ===== STATUS / INFO COLORS =====
  static const Color success = Color(0xFF10B981); // Active
  static const Color info = Color(0xFF3B82F6); // +12%
  static const Color warning = Color(0xFFF59E0B); // Secure
  static const Color purple = Color(0xFF8B5CF6); // +8%

  // ===== GRADIENTS =====
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00B36B), Color(0xFF4ADE80)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient infoGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color black = Color(0xFF232323);
  static const Color darkerGray = Color(0xFF4F4F4F);
  static const Color darkGray = Color(0xFF939393);
  static const Color gray = Color(0xFFE0E0E0);
  static const Color lightGray = Color(0xFFF9F9F9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);

  static const Color light = Color(0xFFF6F6F6);
  static const Color dark = Color(0xFF272727);

    static const Color borderPrimary = Color(0xFFD9D9D9);
  static const Color borderSecondary = Color(0xFFE6E6E6);
}