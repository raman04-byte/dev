import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color primaryBlue = Color(0xFF09AEC6); // Brand Cyan
  static const Color secondaryBlue = Color(0xFF3DC4DB); // Light Cyan
  static const Color darkBlue = Color(0xFF078BA0); // Dark Cyan

  // Accent colors
  static const Color accentPurple = Color(0xFF5856D6);
  static const Color accentPink = Color(0xFFFF2D55);
  static const Color accentOrange = Color(0xFFFF9500);
  static const Color accentGreen = Color(0xFF34C759);

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color systemGray = Color(0xFF8E8E93);
  static const Color systemGray2 = Color(0xFFAEAEB2);
  static const Color systemGray3 = Color(0xFFC7C7CC);
  static const Color systemGray4 = Color(0xFFD1D1D6);
  static const Color systemGray5 = Color(0xFFE5E5EA);
  static const Color systemGray6 = Color(0xFFF2F2F7);

  // Background colors
  static const Color backgroundPrimary = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF2F2F7);
  static const Color backgroundTertiary = Color(0xFFFFFFFF);

  // Glassmorphism colors
  static const Color glassBackground = Color(0xFFFAFAFA);
  static const Color glassBorder = Color(0xFFE5E5EA);
  static const Color glassShadow = Color(0x0F000000);

  // Text colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF3C3C43);
  static const Color textTertiary = Color(0xFF8E8E93);
  static const Color textQuaternary = Color(0xFFAEAEB2);

  // Legacy colors for compatibility
  static const Color primaryCyan = primaryBlue;
  static const Color primaryNavy = Color(0xFF1C1C1E);
  static const Color grey = systemGray;
  static const Color lightGrey = systemGray6;
  static const Color textHint = systemGray3;
}
