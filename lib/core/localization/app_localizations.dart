import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  Future<bool> load() async {
    // Load the language JSON file from the assets folder
    String jsonString =
        await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    // Flatten nested JSON structure
    _localizedStrings = _flattenMap(jsonMap);

    return true;
  }

  Map<String, String> _flattenMap(Map<String, dynamic> map,
      [String prefix = '']) {
    Map<String, String> result = {};

    map.forEach((key, value) {
      String newKey = prefix.isEmpty ? key : '$prefix.$key';

      if (value is Map<String, dynamic>) {
        // Recursively flatten nested maps
        result.addAll(_flattenMap(value, newKey));
      } else {
        // Convert value to string
        result[newKey] = value.toString();
      }
    });

    return result;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}

// Extension method for easier access to AppLocalizations
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations? get l10n => AppLocalizations.of(this);
}
