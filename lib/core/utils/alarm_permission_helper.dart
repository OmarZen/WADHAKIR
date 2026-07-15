import 'dart:io';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

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
      builder: (context, style, animation) => FDialog(
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
    await openAppSettings();

    // Check permission status after user returns
    final newStatus = await Permission.notification.status;
    debugPrint('🔔 Permission status after settings: $newStatus');
    debugPrint('🔔 Is granted: ${newStatus.isGranted}');

    return newStatus.isGranted;
  }

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
      await maybePromptBatteryOptimizationsOnce(context);
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
      builder: (ctx, style, animation) => FDialog(
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

  /// Prompt for the battery-optimization exemption at most once (persisted via
  /// SharedPreferences) so the user isn't nagged on every enable.
  static Future<void> maybePromptBatteryOptimizationsOnce(
    BuildContext context,
  ) async {
    if (!Platform.isAndroid) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('battery_opt_prompted') ?? false) return;
    await prefs.setBool('battery_opt_prompted', true);
    if (!context.mounted) return;
    await requestIgnoreBatteryOptimizations(context);
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
