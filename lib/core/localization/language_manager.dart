import 'package:flutter/material.dart';

class LanguageManager {
  static const List<Locale> supportedLocales = [
    Locale('ar'), // Arabic
    Locale('en'), // English
  ];

  static const Locale fallbackLocale = Locale('ar');
}
