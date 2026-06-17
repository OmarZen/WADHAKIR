import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/data/models/azkar_reminder_settings_model.dart';
import 'package:wadhakir/data/repositories/azkar_reminder_settings_repository_impl.dart';
import 'package:wadhakir/features/azkar_reminders/cubit/azkar_reminders_state.dart';
import 'package:wadhakir/features/azkar_reminders/services/azkar_notification_service.dart';

/// Owns daily-azkar-reminder settings and (re)schedules the REPEATING reminders
/// (morning, evening, witr, sleep, Friday Al-Kahf, fixed-mode Qiyam) on every
/// change. Eager (created in main.dart) so they reschedule at cold start.
///
/// The PRAYER-DRIVEN reminders (after-prayer, Duha, last-third Qiyam) are
/// scheduled by [PrayerTimesCubit] because they need the day's prayer times;
/// main.dart bridges azkar-settings changes to a prayer-driven reschedule.
class AzkarRemindersCubit extends Cubit<AzkarRemindersState> {
  final AzkarReminderSettingsRepositoryImpl _repo;
  final AzkarNotificationService _service;
  StreamSubscription? _sub;

  AzkarRemindersCubit(this._repo, {AzkarNotificationService? service})
    : _service = service ?? AzkarNotificationService(),
      super(AzkarRemindersState.initial()) {
    _sub = _repo.settingsStream.listen(
      (s) => unawaited(_apply(s)),
      onError: (_) {},
    );
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await _repo.getSettings();
      await _apply(settings);
    } catch (e, st) {
      log('🟥 AzkarRemindersCubit._load: $e\n$st');
    }
  }

  Future<void> _apply(AzkarReminderSettingsModel settings) async {
    emit(AzkarRemindersState(settings: settings, loaded: true));
    unawaited(_service.applyRepeating(settings));
  }

  // ── Persist helpers — each saves through the repo, whose stream re-applies
  //    (reschedules) so there's a single scheduling path. ────────────────────

  Future<void> save(AzkarReminderSettingsModel settings) =>
      _repo.saveSettings(settings);

  Future<void> setMorningEnabled(bool v) =>
      save(state.settings.copyWith(morningEnabled: v));
  Future<void> setMorningTime(int h, int m) =>
      save(state.settings.copyWith(morningHour: h, morningMinute: m));

  Future<void> setEveningEnabled(bool v) =>
      save(state.settings.copyWith(eveningEnabled: v));
  Future<void> setEveningTime(int h, int m) =>
      save(state.settings.copyWith(eveningHour: h, eveningMinute: m));

  Future<void> setAfterPrayerEnabled(bool v) =>
      save(state.settings.copyWith(afterPrayerEnabled: v));
  Future<void> setAfterPrayerDelay(int minutes) =>
      save(state.settings.copyWith(afterPrayerDelayMinutes: minutes));

  Future<void> setQiyamEnabled(bool v) =>
      save(state.settings.copyWith(qiyamEnabled: v));
  Future<void> setQiyamMode(QiyamMode mode) =>
      save(state.settings.copyWith(qiyamMode: mode));
  Future<void> setQiyamTime(int h, int m) =>
      save(state.settings.copyWith(qiyamHour: h, qiyamMinute: m));

  Future<void> setFridayKahfEnabled(bool v) =>
      save(state.settings.copyWith(fridayKahfEnabled: v));
  Future<void> setFridayKahfTime(int h, int m) =>
      save(state.settings.copyWith(fridayKahfHour: h, fridayKahfMinute: m));

  Future<void> setWitrEnabled(bool v) =>
      save(state.settings.copyWith(witrEnabled: v));
  Future<void> setWitrTime(int h, int m) =>
      save(state.settings.copyWith(witrHour: h, witrMinute: m));

  Future<void> setDuhaEnabled(bool v) =>
      save(state.settings.copyWith(duhaEnabled: v));

  Future<void> setSleepEnabled(bool v) =>
      save(state.settings.copyWith(sleepEnabled: v));
  Future<void> setSleepTime(int h, int m) =>
      save(state.settings.copyWith(sleepHour: h, sleepMinute: m));

  Future<bool> sendTest() => _service.sendTestNotification();

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
