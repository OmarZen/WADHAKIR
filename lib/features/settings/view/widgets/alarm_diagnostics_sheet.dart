import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/features/pray_times/services/prayer_notification_service.dart';

/// The escape hatch for the native alarm path, and nothing else.
///
/// Reached by long-pressing the version number in About — deliberately not a
/// visible setting. Nobody should be choosing this; it exists so a device that
/// turns out to mis-handle `AlarmManager` can be put back on
/// `awesome_notifications` over a phone call, without waiting for a release to
/// reach the user through Play.
///
/// Changing it takes effect on the next launch, because which gateway owns the
/// alarm table is decided once during `NotificationRepository.initialize()`.
/// Re-deciding it mid-session would mean two owners believing they hold the
/// table, and neither one's cancel sweep reaches the other's alarms.
class AlarmDiagnosticsSheet extends StatefulWidget {
  const AlarmDiagnosticsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const AlarmDiagnosticsSheet(),
    );
  }

  @override
  State<AlarmDiagnosticsSheet> createState() => _AlarmDiagnosticsSheetState();
}

class _AlarmDiagnosticsSheetState extends State<AlarmDiagnosticsSheet> {
  bool? _nativeEnabled;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nativeEnabled =
          !(prefs.getBool(AppConstants.nativePrayerAlarmsDisabledKey) ?? false);
    });
  }

  Future<void> _setNative(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    // Stored inverted, so an install that has never seen this screen — and a
    // fresh one — defaults to the native path with no key written.
    await prefs.setBool(AppConstants.nativePrayerAlarmsDisabledKey, !enabled);
    if (!mounted) return;
    setState(() {
      _nativeEnabled = enabled;
      _changed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = PrayerNotificationService().nativeAlarmsActive;
    final enabled = _nativeEnabled;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تشخيص تنبيهات الصلاة',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              active
                  ? 'المنبّه الحالي: منبّه النظام (AlarmManager)'
                  : 'المنبّه الحالي: إضافة الإشعارات',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (!Platform.isAndroid)
              Text(
                'منبّه النظام متاح على أندرويد فقط.',
                style: theme.textTheme.bodyMedium,
              )
            else if (enabled == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: enabled,
                onChanged: _setNative,
                title: const Text('استخدام منبّه النظام للأذان'),
                subtitle: const Text(
                  'يجعل الأذان يعمل حتى لو لم تفتح التطبيق لأسابيع. '
                  'أطفئه فقط لو ظهرت مشكلة في التنبيهات على هذا الجهاز.',
                ),
              ),
              if (_changed) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'أعد تشغيل التطبيق حتى يسري التغيير.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
