import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/data/models/notification_settings_model.dart';
import 'package:wadhakir/data/repositories/app_settings_repository_impl.dart';
import 'package:wadhakir/features/backup/services/backup_keys.dart';

/// The settings blob as a 3.4.3 install saved it: «يتجاوز الوضع الصامت» on
/// for every prayer, because that was the default and toJson writes it.
String _savedWithOverride(bool enabled) => jsonEncode(
  NotificationSettingsModel.defaultSettings()
      .withOverrideSilentMode(enabled)
      .toJson(),
);

bool _allFive(NotificationSettingsModel s, bool expected) => [
  s.fajrSettings,
  s.dhuhrSettings,
  s.asrSettings,
  s.maghribSettings,
  s.ishaSettings,
].every((p) => p.overrideSilentMode == expected);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a new install respects silent mode', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final settings = await AppSettingsRepositoryImpl(prefs).getSettings();

    expect(_allFive(settings.notificationSettings, false), isTrue);
  });

  test('an upgraded install has the override turned off once', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.notificationSettingsKey: _savedWithOverride(true),
    });
    final prefs = await SharedPreferences.getInstance();

    final settings = await AppSettingsRepositoryImpl(prefs).getSettings();

    expect(_allFive(settings.notificationSettings, false), isTrue);
    // And saved, so the prayer plan and the next launch see it too.
    final saved = NotificationSettingsModel.fromJson(
      jsonDecode(prefs.getString(AppConstants.notificationSettingsKey)!)
          as Map<String, dynamic>,
    );
    expect(_allFive(saved, false), isTrue);
  });

  test('the reset flag travels in backups with the settings it describes', () {
    // Restore removes every allowlisted key a backup does not carry, so a
    // backup from 3.4.3 (no flag) clears it and the reset runs again on the
    // next launch, while a newer backup keeps the user's own choice.
    expect(BackupKeys.specFor('adhan_respects_silent_migrated_v1'), isNotNull);
    expect(BackupKeys.specFor(AppConstants.notificationSettingsKey), isNotNull);
  });

  test('restoring a 3.4.3 backup resets the override again', () async {
    // What restore() leaves behind for an old backup: its `true` blob, and no
    // flag (removed, because the backup did not carry it).
    SharedPreferences.setMockInitialValues({
      AppConstants.notificationSettingsKey: _savedWithOverride(true),
    });
    final prefs = await SharedPreferences.getInstance();

    final settings = await AppSettingsRepositoryImpl(prefs).getSettings();

    expect(_allFive(settings.notificationSettings, false), isTrue);
  });

  test('turning it back on afterwards sticks', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.notificationSettingsKey: _savedWithOverride(true),
    });
    final prefs = await SharedPreferences.getInstance();
    final repository = AppSettingsRepositoryImpl(prefs);
    final settings = await repository.getSettings();
    await repository.setNotificationSettings(
      settings.notificationSettings.withOverrideSilentMode(true),
    );

    // A later launch: a fresh repository over the same storage.
    final relaunched = await AppSettingsRepositoryImpl(prefs).getSettings();

    expect(_allFive(relaunched.notificationSettings, true), isTrue);
  });
}
