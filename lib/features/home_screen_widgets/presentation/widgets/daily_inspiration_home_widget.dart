import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:wadhakir/data/models/daily_inspiration_item.dart';

/// Pushes the filtered daily-inspiration list to the native Android
/// home-screen widget (`DailyInspirationWidgetProvider`).
///
/// The whole filtered list is pushed (as JSON) plus a title; the native
/// provider recomputes the daily index so the widget stays fresh between app
/// launches. `home_widget` stores everything as a String.
class DailyInspirationHomeWidget {
  static const String provider = 'DailyInspirationWidgetProvider';

  static bool get _unsupportedPlatform =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  static Future<void> update(
    List<DailyInspirationItem> items,
    String title,
  ) async {
    if (_unsupportedPlatform) return;

    try {
      final payload = items
          .map((e) => {'arabic': e.arabic, 'reference': e.reference})
          .toList();
      await HomeWidget.saveWidgetData('daily_items', jsonEncode(payload));
      await HomeWidget.saveWidgetData('daily_title', title);
      await HomeWidget.updateWidget(
        androidName: provider,
        qualifiedAndroidName: 'com.bloom.wadhakir.$provider',
        // iOS requires a widget name; harmless no-op until the WidgetKit
        // extension ships a widget of this kind.
        iOSName: 'DailyInspirationWidget',
      );
    } catch (e) {
      debugPrint('❌ DailyInspirationHomeWidget.update error: $e');
    }
  }
}
