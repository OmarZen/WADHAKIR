import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF9F9F9);
  static const Color darkBackground = Color(0xFF121212);
  static const Color textColor = Color(0xFF0D1122);
  static const Color darkTextColor = Colors.white;

  // Getter theme colors
  static Color getTextColor(bool isDarkMode) =>
      isDarkMode ? darkTextColor : textColor;
  static Color getBackgroundColor(bool isDarkMode) =>
      isDarkMode ? darkBackground : background;
}
