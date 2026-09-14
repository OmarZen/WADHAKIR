import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:wadhakir/data/models/wird/wird_plan_model.dart';
import 'package:wadhakir/features/wird/services/quran_structure.dart';
import 'package:wadhakir/features/wird/services/wird_format.dart';
import 'package:wadhakir/features/wird/services/wird_motivations.dart';
import 'package:wadhakir/features/wird/services/wird_schedule_service.dart';

/// Pushes wird-progress data to the native Android home-screen widget
/// (`WirdProgressWidgetProvider`). Mirrors the prayer-times bridge pattern.
///
/// Only the *raw* inputs needed for the date-dependent pace (start epoch,
/// completed/total days) are pushed — the native provider recomputes
/// late/ahead against the current date so the widget stays fresh between app
/// launches. Date-independent display strings (current-day line, percent) are
/// pre-built here so the Kotlin side stays small.
class WirdHomeWidget {
  static const String provider = 'WirdProgressWidgetProvider';

  static const WirdScheduleService _service = WirdScheduleService();

  static bool get _unsupportedPlatform =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  static Future<void> update(
    WirdPlanModel plan,
    List<WirdDay> schedule,
    WirdProgressStatus status,
  ) async {
    if (_unsupportedPlatform) return;

    try {
      // Always push the message buckets so the native side can rotate the line.
      await HomeWidget.saveWidgetData(
        'wird_messages',
        jsonEncode(WirdMotivations.buckets),
      );
      await HomeWidget.saveWidgetData('wird_title', 'وردك اليومي');

      final isActive =
          plan.isActive && schedule.isNotEmpty && plan.planStartDate != null;
      await HomeWidget.saveWidgetData('wird_active', isActive.toString());

      if (!isActive) {
        await _pushUpdate();
        return;
      }

      final total = schedule.length;
      final completed = plan.completedDayIndices
          .where((i) => i >= 0 && i < total)
          .length;
      final percent = total == 0 ? 0 : ((completed / total) * 100).round();

      await HomeWidget.saveWidgetData('wird_total_days', total.toString());
      await HomeWidget.saveWidgetData(
        'wird_completed_days',
        completed.toString(),
      );
      await HomeWidget.saveWidgetData(
        'wird_start_epoch',
        plan.planStartDate!.millisecondsSinceEpoch.toString(),
      );
      await HomeWidget.saveWidgetData('wird_percent', percent.toString());
      await HomeWidget.saveWidgetData(
        'wird_pages_read',
        _service.pagesReadCount(plan, schedule).toString(),
      );
      await HomeWidget.saveWidgetData(
        'wird_total_pages',
        kTotalPages.toString(),
      );

      // Pre-built current-day line ("صفحات ٤٥ – ٤٨ • الجزء ٣"). Changes only
      // when completion changes (not with the date), so it's safe to push.
      final idx = status.currentDayIndex;
      final current = (idx >= 0 && idx < schedule.length)
          ? schedule[idx]
          : null;
      final currentLine = current == null
          ? ''
          : 'صفحات ${WirdFormat.toArabicDigits(current.startPage)} – '
                '${WirdFormat.toArabicDigits(current.endPage)}'
                '${current.juzLabel.isNotEmpty ? '  •  ${WirdFormat.toArabicDigits(current.juzLabel)}' : ''}';
      await HomeWidget.saveWidgetData('wird_current_line', currentLine);

      await _pushUpdate();
    } catch (e) {
      debugPrint('❌ WirdHomeWidget.update error: $e');
    }
  }

  static Future<void> _pushUpdate() async {
    await HomeWidget.updateWidget(
      androidName: provider,
      qualifiedAndroidName: 'com.bloom.wadhakir.$provider',
      // iOS requires a widget name; harmless no-op until the WidgetKit
      // extension ships a widget of this kind.
      iOSName: 'WirdProgressWidget',
    );
  }
}
