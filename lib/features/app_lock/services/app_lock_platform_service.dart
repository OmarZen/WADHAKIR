import 'package:flutter/services.dart';
import 'package:wadhakir/features/app_lock/models/installed_app_model.dart';
import 'package:wadhakir/features/app_lock/models/app_lock_permission_status.dart';

class AppLockPlatformService {
  static const MethodChannel _channel = MethodChannel(
    'com.bloom.wadhakir/app_lock',
  );

  const AppLockPlatformService();

  Future<List<InstalledAppModel>> getInstalledApps() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
    final apps = (raw ?? const <dynamic>[])
        .map((e) => InstalledAppModel.fromMap(e as Map<dynamic, dynamic>))
        .toList();

    apps.sort(
      (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
    );
    return apps;
  }

  Future<AppLockPermissionStatus> getPermissionStatus() async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getPermissionStatus',
    );

    return AppLockPermissionStatus.fromMap(raw ?? const <dynamic, dynamic>{});
  }

  Future<void> openUsageAccessSettings() async {
    await _channel.invokeMethod('openUsageAccessSettings');
  }

  Future<void> openOverlaySettings() async {
    await _channel.invokeMethod('openOverlaySettings');
  }

  Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  Future<void> openAppDetailsSettings() async {
    await _channel.invokeMethod('openAppDetailsSettings');
  }

  Future<Uint8List?> getAppIcon(String packageName) async {
    return _channel.invokeMethod<Uint8List>('getAppIcon', <String, dynamic>{
      'packageName': packageName,
    });
  }

  Future<void> startLockMonitor({
    required List<String> lockedPackages,
    required String overlayMessage,
    required Map<String, String> overlayTexts,
    List<String>? overlayMessages,
    List<String>? overlayReferences,
    int? lockDurationMinutes,
    required bool emergencyBypassEnabled,
    required bool overlayIsDark,
    required int prayerWindowStartMs,
    required int nextPrayerStartMs,
  }) async {
    await _channel.invokeMethod('startLockMonitor', <String, dynamic>{
      'lockedPackages': lockedPackages,
      'overlayMessage': overlayMessage,
      'overlayTexts': overlayTexts,
      if (overlayMessages != null) 'overlayMessages': overlayMessages,
      if (overlayReferences != null) 'overlayReferences': overlayReferences,
      'lockDurationMinutes': lockDurationMinutes,
      'emergencyBypassEnabled': emergencyBypassEnabled,
      'overlayIsDark': overlayIsDark,
      'prayerWindowStartMs': prayerWindowStartMs,
      'nextPrayerStartMs': nextPrayerStartMs,
    });
  }

  Future<void> stopLockMonitor() async {
    await _channel.invokeMethod('stopLockMonitor');
  }

  Future<void> updateLockedPackages(List<String> lockedPackages) async {
    await _channel.invokeMethod('updateLockedPackages', <String, dynamic>{
      'lockedPackages': lockedPackages,
    });
  }

  Future<void> updateMonitorConfig({
    required List<String> lockedPackages,
    Map<String, String>? overlayTexts,
    List<String>? overlayMessages,
    List<String>? overlayReferences,
    int? lockDurationMinutes,
    required bool emergencyBypassEnabled,
    required bool overlayIsDark,
    required int prayerWindowStartMs,
    required int nextPrayerStartMs,
  }) async {
    await _channel.invokeMethod('updateMonitorConfig', <String, dynamic>{
      'lockedPackages': lockedPackages,
      if (overlayTexts != null) 'overlayTexts': overlayTexts,
      if (overlayMessages != null) 'overlayMessages': overlayMessages,
      if (overlayReferences != null) 'overlayReferences': overlayReferences,
      'lockDurationMinutes': lockDurationMinutes,
      'emergencyBypassEnabled': emergencyBypassEnabled,
      'overlayIsDark': overlayIsDark,
      'prayerWindowStartMs': prayerWindowStartMs,
      'nextPrayerStartMs': nextPrayerStartMs,
    });
  }

  Future<void> updatePrayerWindow({
    required int prayerWindowStartMs,
    required int nextPrayerStartMs,
  }) async {
    await _channel.invokeMethod('updatePrayerWindow', <String, dynamic>{
      'prayerWindowStartMs': prayerWindowStartMs,
      'nextPrayerStartMs': nextPrayerStartMs,
    });
  }

  Future<void> showTestOverlay({
    required String overlayMessage,
    required Map<String, String> overlayTexts,
    required bool overlayIsDark,
  }) async {
    await _channel.invokeMethod('showTestOverlay', <String, dynamic>{
      'overlayMessage': overlayMessage,
      'overlayTexts': overlayTexts,
      'overlayIsDark': overlayIsDark,
    });
  }

  Future<bool> isLockMonitorRunning() async {
    final running = await _channel.invokeMethod<bool>('isLockMonitorRunning');
    return running ?? false;
  }
}
