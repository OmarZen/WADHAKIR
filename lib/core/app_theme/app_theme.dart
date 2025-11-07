import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Primary color palette
const Color _primaryColor = Color(0xFF20497D); // Primary blue
const Color _secondaryColor = Color(0xFF0D1122); // Deep dark blue/black
const Color _neutralGray = Color(0xFF9A9BA8); // Medium gray
const Color _lightGray = Color(0xFFCECACA); // Light gray
// const Color _white = Color(0xFFFFFFFF); // White

// Light theme colors
const Color _backgroundColor = Color(0xFFF9F9F9);
const Color _cardColor = Colors.white;
const Color _textColor = Color(0xFF0D1122);
const Color _secondaryTextColor = Color(0xFF9A9BA8);

// Category colors - harmonized with primary palette
const Color morningAzkarColor = Color(0xFF3498DB); // Bright blue
const Color eveningAzkarColor = Color(0xFF8E44AD); // Purple
const Color sleepAzkarColor = Color(0xFFE74C3C); // Red
const Color prayerAzkarColor = Color(0xFF27AE60); // Green
const Color wakeupAzkarColor = Color(0xFF16A085); // Teal
const Color mosqueAzkarColor = Color(0xFFD35400); // Orange
const Color maathurDuaColor = Color(0xFF7FB069); // Sage green
const Color quranDuaColor = Color(0xFFDAA520); // Golden/Amber

// Dark theme colors
const Color _darkPrimaryColor = Color(0xFF20497D); // Same primary blue
const Color _darkSecondaryColor = Color(0xFF0D1122); // Same deep dark blue
const Color _darkAccentColor = Color(0xFF9A9BA8); // Medium gray
const Color _darkBackgroundColor = Color(0xFF121212);
const Color _darkCardColor = Color(0xFF1E1E1E);
const Color _darkTextColor = Colors.white;
const Color _darkSecondaryTextColor = Color(0xFFCECACA); // Light gray

// Dark category colors - brighter versions for dark mode
const Color darkMorningAzkarColor = Color(0xFF48A7E8); // Brighter blue
const Color darkEveningAzkarColor = Color(0xFFA569BD); // Brighter purple
const Color darkSleepAzkarColor = Color(0xFFF06050); // Brighter red
const Color darkPrayerAzkarColor = Color(0xFF36CF74); // Brighter green
const Color darkWakeupAzkarColor = Color(0xFF1ABC9C); // Brighter teal
const Color darkMosqueAzkarColor = Color(0xFFE67E22); // Brighter orange
const Color darkMaathurDuaColor = Color(0xFF8FC779); // Brighter sage green
const Color darkQuranDuaColor = Color(0xFFF1C40F); // Brighter gold

// Typography settings
const String _primaryFont = 'Almarai';
const String _religiousFont = 'Jomhuria';

final ThemeData lightTheme = ThemeData(
  useMaterial3: false, // Required by quran_library package
  brightness: Brightness.light,
  primaryColor: _primaryColor,
  primaryColorDark: _secondaryColor,
  scaffoldBackgroundColor: _backgroundColor,
  cardColor: _cardColor,
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: _textColor,
      fontWeight: FontWeight.bold,
      fontSize: 32,
      fontFamily: _primaryFont,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      color: _textColor,
      fontWeight: FontWeight.bold,
      fontSize: 28,
      fontFamily: _primaryFont,
      letterSpacing: -0.5,
    ),
    displaySmall: TextStyle(
      color: _textColor,
      fontWeight: FontWeight.bold,
      fontSize: 24,
      fontFamily: _primaryFont,
    ),
    headlineMedium: TextStyle(
      color: _textColor,
      fontWeight: FontWeight.bold,
      fontSize: 20,
      fontFamily: _primaryFont,
    ),
    headlineSmall: TextStyle(
      color: _textColor,
      fontWeight: FontWeight.bold,
      fontSize: 18,
      fontFamily: _primaryFont,
    ),
    titleLarge: TextStyle(
      color: _textColor,
      fontWeight: FontWeight.bold,
      fontSize: 16,
      fontFamily: _primaryFont,
    ),
    bodyLarge: TextStyle(
      color: _textColor,
      fontSize: 16,
      fontFamily: _primaryFont,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      color: _secondaryTextColor,
      fontSize: 14,
      fontFamily: _primaryFont,
      height: 1.5,
    ),
  ),
  iconTheme: const IconThemeData(color: _primaryColor),
  appBarTheme: AppBarTheme(
    backgroundColor: _primaryColor,
    elevation: 0,
    centerTitle: true,
    foregroundColor: Colors.white,
    titleTextStyle: const TextStyle(
      fontFamily: _religiousFont,
      fontSize: 36,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    systemOverlayStyle: SystemUiOverlayStyle.light,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: _primaryColor,
      side: const BorderSide(color: _primaryColor, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
  ),
  cardTheme: CardThemeData(
    color: _cardColor,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    shadowColor: _primaryColor.withValues(alpha: 0.2),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: _primaryColor,
    foregroundColor: Colors.white,
  ),
  colorScheme: ColorScheme.light(
    primary: _primaryColor,
    secondary: _secondaryColor,
    tertiary: _neutralGray,
    surface: _cardColor,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: _textColor,
  ),
  dividerColor: _lightGray,
  disabledColor: _lightGray,
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: false, // Required by quran_library package
  brightness: Brightness.dark,
  primaryColor: _darkPrimaryColor,
  primaryColorDark: _darkSecondaryColor,
  scaffoldBackgroundColor: _darkBackgroundColor,
  cardColor: _darkCardColor,
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: _darkTextColor,
      fontWeight: FontWeight.bold,
      fontSize: 32,
      fontFamily: _primaryFont,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      color: _darkTextColor,
      fontWeight: FontWeight.bold,
      fontSize: 28,
      fontFamily: _primaryFont,
      letterSpacing: -0.5,
    ),
    displaySmall: TextStyle(
      color: _darkTextColor,
      fontWeight: FontWeight.bold,
      fontSize: 24,
      fontFamily: _primaryFont,
    ),
    headlineMedium: TextStyle(
      color: _darkTextColor,
      fontWeight: FontWeight.bold,
      fontSize: 20,
      fontFamily: _primaryFont,
    ),
    headlineSmall: TextStyle(
      color: _darkTextColor,
      fontWeight: FontWeight.bold,
      fontSize: 18,
      fontFamily: _primaryFont,
    ),
    titleLarge: TextStyle(
      color: _darkTextColor,
      fontWeight: FontWeight.bold,
      fontSize: 16,
      fontFamily: _primaryFont,
    ),
    bodyLarge: TextStyle(
      color: _darkTextColor,
      fontSize: 16,
      fontFamily: _primaryFont,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      color: _darkSecondaryTextColor,
      fontSize: 14,
      fontFamily: _primaryFont,
      height: 1.5,
    ),
  ),
  iconTheme: IconThemeData(color: _darkAccentColor),
  appBarTheme: AppBarTheme(
    backgroundColor: _darkPrimaryColor,
    elevation: 0,
    centerTitle: true,
    foregroundColor: Colors.white,
    titleTextStyle: const TextStyle(
      fontFamily: _religiousFont,
      fontSize: 36,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    systemOverlayStyle: SystemUiOverlayStyle.light,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _darkPrimaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: Colors.white, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
  ),
  cardTheme: CardThemeData(
    color: _darkCardColor,
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    shadowColor: Colors.black.withValues(alpha: 0.4),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: _darkPrimaryColor,
    foregroundColor: Colors.white,
  ),
  colorScheme: ColorScheme.dark(
    primary: _darkPrimaryColor,
    secondary: _darkSecondaryColor,
    tertiary: _darkAccentColor,
    surface: _darkCardColor,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: _darkTextColor,
  ),
  dividerColor: _darkSecondaryColor,
  disabledColor: _darkSecondaryColor,
);
