import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wadhakir/core/widgets/app_dialog.dart';

/// Helper class to handle SCHEDULE_EXACT_ALARM permission
/// Required for Android 14+ to schedule exact alarms for prayer times
class AlarmPermissionHelper {
  /// Check if the app can schedule exact alarms
  /// Returns true if permission is granted or not required (Android < 12)
  static Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;

    try {
      // For Android 12 and above, we need to check if exact alarms are allowed
      // This is automatically handled by the permission_handler package
      // For Android 14+, this will return false if user hasn't granted permission

      // Check using AlarmManager (from android_alarm_manager_plus or native code)
      // Since we don't have direct access to AlarmManager.canScheduleExactAlarms()
      // we'll use permission_handler's scheduleExactAlarm permission
      final status = await Permission.scheduleExactAlarm.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking exact alarm permission: $e');
      // On older Android versions, this will fail, so we assume true
      return true;
    }
  }

  /// Request SCHEDULE_EXACT_ALARM permission from user
  /// Shows a dialog explaining why the permission is needed
  static Future<bool> requestExactAlarmPermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    // First check if we already have permission
    final hasPermission = await canScheduleExactAlarms();
    if (hasPermission) return true;

    if (!context.mounted) return false;

    final l10n = context.l10n;

    // Show explanation dialog
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          _PermissionExplanationDialog(l10n: l10n),
    );

    if (shouldRequest != true) return false;

    if (!context.mounted) return false;

    // Show countdown dialog before opening settings
    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) =>
          _SettingsPermissionDialog(l10n: l10n),
    );

    if (shouldOpenSettings != true) return false;

    // Wait for dialog animation to complete
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Request the permission - this will open the exact alarm settings page
      debugPrint('🔔 Opening exact alarm settings...');
      final status = await Permission.scheduleExactAlarm.request();
      debugPrint('🔔 Exact alarm permission status: ${status.isGranted}');
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting exact alarm permission: $e');
      return false;
    }
  }

  /// Show a dialog when permission is denied
  /// Explains to user how to enable it manually in settings
  static Future<void> showPermissionDeniedDialog(BuildContext context) async {
    if (!context.mounted) return;

    final l10n = context.l10n;

    await showFDialog(
      context: context,
      builder: (context, style, animation) => AppDialog(
        title: Text(
          l10n?.translate('settings.permission_required_title') ??
              'الإذن مطلوب',
          textAlign: TextAlign.right,
        ),
        body: Text(
          l10n?.translate('settings.permission_required_message') ??
              'لتلقي تنبيهات أوقات الصلاة في الوقت المحدد، يرجى تفعيل إذن "التنبيهات والتذكيرات" من الإعدادات.\n\nالإعدادات > التطبيقات > واذكِّر > الأذونات > التنبيهات والتذكيرات',
          textAlign: TextAlign.right,
        ),
        actions: [
          FButton(
            onPress: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text(
              l10n?.translate('settings.open_settings') ?? 'فتح الإعدادات',
            ),
          ),
          FButton(
            onPress: () => Navigator.of(context).pop(),
            variant: FButtonVariant.outline,
            child: Text(l10n?.translate('settings.ok') ?? 'حسناً'),
          ),
        ],
      ),
    );
  }

  /// Request notification permission.
  ///
  /// On iOS (and any non-Android platform) this triggers the SYSTEM notification
  /// authorization prompt directly — previously it just returned `true` without
  /// asking, so the master toggle "enabled" notifications while iOS never
  /// granted permission and silently dropped every notification.
  ///
  /// On Android 13+ it now asks the OS **first**.
  ///
  /// It used to show a custom dialog and then send the user to
  /// `openAppSettings()`, which meant a fresh install never saw the one-tap
  /// `POST_NOTIFICATIONS` system prompt at all — the single cheapest grant in
  /// the flow was replaced by a trip through Settings, and every user who did
  /// not complete that trip ended up with notifications silently off.
  ///
  /// The Settings route is still offered whenever the permission is not
  /// granted afterwards, and that breadth is deliberate. Android 12 and below
  /// have no runtime POST_NOTIFICATIONS at all: `status` reads `denied` when
  /// the user has switched notifications off in system settings, `request()`
  /// cannot prompt and returns the same `denied`, and it never reports
  /// `permanentlyDenied`. Gating the Settings route on `permanentlyDenied`
  /// therefore left every pre-13 device with no way back at all — notifications
  /// could be turned off and never turned on again from inside the app. The
  /// cost of asking broadly is one dismissible dialog for an Android 13+ user
  /// who has just declined; the cost of asking narrowly was a whole platform
  /// version that could not re-enable the app's core feature.
  static Future<bool> requestNotificationPermission(
    BuildContext context,
  ) async {
    if (!Platform.isAndroid) {
      final current = await Permission.notification.status;
      if (current.isGranted || current.isLimited || current.isProvisional) {
        return true;
      }
      final status = await Permission.notification.request();
      return status.isGranted || status.isLimited || status.isProvisional;
    }

    final status = await Permission.notification.status;
    debugPrint('🔔 Current notification permission status: $status');

    if (status.isGranted) {
      debugPrint('🔔 Notification permission already granted');
      return true;
    }

    // Ask the OS first, while it can still prompt. On Android 13+ this is the
    // one-tap system dialog; on 12 and below it is a no-op that returns the
    // current setting. Wrapped because it is a platform-channel call on a path
    // reached from a settings toggle — an escaping PlatformException would
    // surface as a red screen instead of a declined permission.
    if (!status.isPermanentlyDenied) {
      try {
        final requested = await Permission.notification.request();
        debugPrint('🔔 Native POST_NOTIFICATIONS result: $requested');
        if (requested.isGranted) return true;
      } catch (e) {
        debugPrint('🔔 POST_NOTIFICATIONS request failed: $e');
      }
    }

    if (!context.mounted) return false;

    final l10n = context.l10n;

    // Show explanation dialog
    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          _NotificationPermissionDialog(l10n: l10n),
    );

    if (shouldOpenSettings != true) {
      debugPrint('🔔 User cancelled notification permission request');
      return false;
    }

    // Directly open app settings page for user to enable notifications manually
    debugPrint('🔔 Opening app settings for manual permission grant...');
    final opened = await openAppSettings();

    if (opened) {
      // `openAppSettings()` completes when the settings screen has been
      // LAUNCHED, not when the user comes back, so reading the status right
      // after it is a race the app usually loses — it reported "still denied"
      // for a user who had just granted it. Wait for this app to be resumed
      // before believing anything.
      //
      // Guarded on `opened`: if the screen never launched, this app was never
      // backgrounded, so no resume is coming and the wait would just block for
      // the full timeout before reading a status that has not moved.
      await _awaitResume();
    } else {
      debugPrint('🔔 Could not open app settings');
    }

    final newStatus = await Permission.notification.status;
    debugPrint('🔔 Permission status after settings: $newStatus');

    return newStatus.isGranted;
  }

  /// Completes the next time the app returns to the foreground.
  ///
  /// Bounded, because the user may never come back: the wait is abandoned
  /// after [_resumeTimeout] and the caller simply re-reads whatever the status
  /// is then, which is no worse than the racy read this replaced.
  static Future<void> _awaitResume() {
    final completer = Completer<void>();
    late final AppLifecycleListener listener;

    void finish() {
      if (completer.isCompleted) return;
      completer.complete();
      listener.dispose();
    }

    listener = AppLifecycleListener(onResume: finish);
    return completer.future.timeout(_resumeTimeout, onTimeout: finish);
  }

  static const Duration _resumeTimeout = Duration(minutes: 2);

  /// Request all required permissions at once
  /// Call this when user enables notifications in settings
  static Future<Map<String, bool>> requestAllPermissions(
    BuildContext context,
  ) async {
    final results = <String, bool>{};

    // 1. Request POST_NOTIFICATIONS first (Android 13+)
    results['notifications'] = await requestNotificationPermission(context);

    if (!context.mounted) return results;

    // 2. Request SCHEDULE_EXACT_ALARM (Android 12+, required on 14+)
    if (results['notifications'] == true) {
      results['exactAlarms'] = await requestExactAlarmPermission(context);
    } else {
      results['exactAlarms'] = false;
    }

    // 3. One-time battery-optimization exemption prompt (improves on-time
    //    delivery on aggressive OEMs / deep Doze).
    if (context.mounted) {
      await maybePromptBatteryOptimizations(context);
    }

    return results;
  }

  /// Ask the user to exempt the app from battery optimization (Doze). Returns
  /// true if already exempt or granted. The system shows its own dialog after
  /// our short explanation.
  static Future<bool> requestIgnoreBatteryOptimizations(
    BuildContext context,
  ) async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isGranted) return true;
    if (!context.mounted) return false;

    final l10n = context.l10n;
    final proceed = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => AppDialog(
        title: Text(
          l10n?.translate('settings.battery_opt_title') ?? 'تحسين البطارية',
        ),
        body: Text(
          l10n?.translate('settings.battery_opt_message') ??
              'للحصول على التنبيهات في وقتها بدقة، يُفضّل استثناء التطبيق من تحسين البطارية.',
        ),
        actions: [
          FButton(
            onPress: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.translate('common.confirm') ?? 'متابعة'),
          ),
          FButton(
            onPress: () => Navigator.of(ctx).pop(false),
            variant: FButtonVariant.outline,
            child: Text(l10n?.translate('common.cancel') ?? 'لاحقاً'),
          ),
        ],
      ),
    );
    if (proceed != true) return false;

    try {
      final result = await Permission.ignoreBatteryOptimizations.request();
      return result.isGranted;
    } catch (e) {
      debugPrint('Error requesting battery optimization exemption: $e');
      return false;
    }
  }

  /// Set once the exemption has actually been granted. Nothing re-asks after
  /// that.
  ///
  /// A NEW key, deliberately. The obvious move was to keep using
  /// `battery_opt_prompted`, and it would have made this whole fix a no-op:
  /// the buggy code wrote that key to `true` before showing the dialog, for
  /// every user who ever reached the permissions flow, whatever they then
  /// answered. Reading it back as "already granted" would mean every existing
  /// install stays silenced forever — the exact bug being fixed, now
  /// undetectable because the code looks right.
  static const String batteryGrantedKey = 'battery_opt_granted';

  /// The old flag. Its real meaning is "the dialog was shown at least once,
  /// answer unknown" — see [batteryGrantedKey].
  ///
  /// Treated as a single deferral rather than a grant, so an existing install
  /// is asked exactly once more and then follows the normal cooling-off
  /// schedule. Kept only for that migration; nothing writes it any more.
  static const String legacyBatteryPromptedKey = 'battery_opt_prompted';

  /// Epoch millis of the last time the user declined. Drives [_batteryCooldown].
  static const String batteryDeferredAtKey = 'battery_opt_deferred_at';

  /// How long to leave someone alone after they decline.
  ///
  /// The old code wrote "prompted" *before* showing the dialog, so a single
  /// tap on "لاحقاً" silenced the prompt permanently — and this is the
  /// exemption that keeps the adhan firing under Doze on aggressive OEM ROMs,
  /// so silencing it permanently silences the app's core promise. Asking again
  /// every time would be nagging; two weeks is long enough not to be, and
  /// short enough that a user who was busy the first time gets another chance.
  static const Duration _batteryCooldown = Duration(days: 14);

  /// Whether the battery-optimization prompt is due.
  ///
  /// Pure and separate from the dialog so the decision can be tested without a
  /// widget tree — the ordering bug this replaces was invisible precisely
  /// because it lived inside an un-testable method.
  @visibleForTesting
  static bool shouldPromptBatteryOptimization({
    required bool alreadyGranted,
    required int? deferredAtMillis,
    required DateTime now,
  }) {
    if (alreadyGranted) return false;
    if (deferredAtMillis == null) return true;
    final deferredAt = DateTime.fromMillisecondsSinceEpoch(deferredAtMillis);
    // A timestamp in the future means the device clock moved backwards. Treat
    // it as due rather than trusting it, so a clock change cannot suppress the
    // prompt indefinitely.
    if (deferredAt.isAfter(now)) return true;
    return now.difference(deferredAt) >= _batteryCooldown;
  }

  /// Prompt for the battery-optimization exemption, at most once per
  /// [_batteryCooldown] while the user keeps declining, and never again once
  /// it is granted.
  static Future<void> maybePromptBatteryOptimizations(
    BuildContext context, {
    DateTime? now,
  }) async {
    if (!Platform.isAndroid) return;
    final prefs = await SharedPreferences.getInstance();
    final at = now ?? DateTime.now();

    if (!shouldPromptBatteryOptimization(
      alreadyGranted: prefs.getBool(batteryGrantedKey) ?? false,
      deferredAtMillis: prefs.getInt(batteryDeferredAtKey),
      now: at,
    )) {
      return;
    }

    // Ask only while there is a live screen to ask on. Returning WITHOUT
    // recording a deferral matters: writing one here would start a two-week
    // silence for a prompt the user was never actually shown.
    if (!context.mounted) return;

    // The flag is written AFTER the user answers, and only records what they
    // actually did. That ordering is the whole fix.
    final granted = await requestIgnoreBatteryOptimizations(context);
    if (granted) {
      await prefs.setBool(batteryGrantedKey, true);
      await prefs.remove(batteryDeferredAtKey);
      await prefs.remove(legacyBatteryPromptedKey);
    } else {
      await prefs.setInt(batteryDeferredAtKey, at.millisecondsSinceEpoch);
      // Consume the legacy flag so the migration ask happens exactly once.
      await prefs.remove(legacyBatteryPromptedKey);
    }
  }
}

/// Notification Permission Dialog
class _NotificationPermissionDialog extends StatelessWidget {
  final dynamic l10n;

  const _NotificationPermissionDialog({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.secondary.withValues(alpha: 0.2),
                    theme.colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications,
                size: 48,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              l10n?.translate('settings.notification_permission_title') ??
                  'إذن الإشعارات',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Text(
              l10n?.translate('settings.notification_permission_message') ??
                  'يحتاج تطبيق واذكِّر إلى إذن الإشعارات لإرسال تنبيهات أوقات الصلاة والأذان والأذكار.\n\nلن يتم إرسال أي إشعارات غير مرغوب فيها.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n?.translate('settings.later') ?? 'لاحقاً',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n?.translate('settings.grant_permission') ??
                          'منح الإذن',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// First dialog - Explains why permission is needed
class _PermissionExplanationDialog extends StatelessWidget {
  final dynamic l10n;

  const _PermissionExplanationDialog({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              l10n?.translate('settings.exact_alarm_permission_title') ??
                  'إذن لتنبيهات أوقات الصلاة',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Text(
              l10n?.translate('settings.exact_alarm_permission_message') ??
                  'تطبيق واذكِّر يحتاج إلى إذن "التنبيهات في الوقت المحدد" لإرسال إشعارات أوقات الصلاة في موعدها الدقيق.\n\nهذا الإذن ضروري لضمان وصول التنبيهات في الوقت الصحيح للصلاة والأذان.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n?.translate('settings.later') ?? 'لاحقاً',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n?.translate('settings.grant_permission') ??
                          'منح الإذن',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom dialog that shows before opening settings
/// Gives user time to read the instruction before settings opens
class _SettingsPermissionDialog extends StatefulWidget {
  final dynamic l10n;

  const _SettingsPermissionDialog({required this.l10n});

  @override
  State<_SettingsPermissionDialog> createState() =>
      _SettingsPermissionDialogState();
}

class _SettingsPermissionDialogState extends State<_SettingsPermissionDialog> {
  int _countdown = 3;
  bool _canProceed = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _countdown = 2;
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          _countdown = 1;
        });

        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          setState(() {
            _countdown = 0;
            _canProceed = true;
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with countdown or checkmark
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _canProceed
                  ? Container(
                      key: const ValueKey('checkmark'),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 48,
                        color: Colors.green,
                      ),
                    )
                  : Container(
                      key: ValueKey('countdown-$_countdown'),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                            theme.colorScheme.primary.withValues(alpha: 0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              value: (3 - _countdown) / 3,
                              strokeWidth: 4,
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          Text(
                            '$_countdown',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              widget.l10n?.translate('settings.activate_permission') ??
                  'تفعيل إذن التنبيهات',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.l10n?.translate('settings.settings_instruction') ??
                        'سيتم فتح إعدادات النظام.\n\nيرجى تفعيل "التنبيهات والتذكيرات" للسماح بإرسال تنبيهات أوقات الصلاة في الوقت المحدد.\n\nالإعدادات ← التنبيهات والتذكيرات ← تفعيل',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.l10n?.translate('common.cancel') ?? 'إلغاء',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _canProceed
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.l10n?.translate('settings.open_settings') ??
                          'فتح الإعدادات',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
