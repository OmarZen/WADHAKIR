import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/data/models/daily_inspiration_item.dart';
import 'package:wadhakir/data/models/daily_inspiration_settings_model.dart';
import 'package:wadhakir/data/repositories/daily_inspiration_settings_repository_impl.dart';
import 'package:wadhakir/features/daily_inspiration/cubit/daily_inspiration_state.dart';
import 'package:wadhakir/features/daily_inspiration/services/daily_inspiration_notification_service.dart';
import 'package:wadhakir/features/daily_inspiration/services/daily_inspiration_service.dart';
import 'package:wadhakir/features/home_screen_widgets/presentation/widgets/daily_inspiration_home_widget.dart';

/// Owns the "Verse/Dua of the Day" settings + today's item, and keeps the three
/// surfaces (notification, home widget, in-app card) in sync. Eager (created in
/// main.dart) so the notification is (re)scheduled with today's body and the
/// widget is pushed at cold start. Mirrors [WirdCubit]'s persist→schedule→push.
class DailyInspirationCubit extends Cubit<DailyInspirationState> {
  final DailyInspirationSettingsRepositoryImpl _repo;
  final DailyInspirationService _service;
  final DailyInspirationNotificationService _notif;
  StreamSubscription? _sub;

  /// Notification title (Arabic-first, like the wird/fasting services).
  static const String _notifTitle = 'آية وذِكر اليوم';

  DailyInspirationCubit(
    this._repo, {
    DailyInspirationService? service,
    DailyInspirationNotificationService? notificationService,
  }) : _service = service ?? DailyInspirationService(),
       _notif = notificationService ?? DailyInspirationNotificationService(),
       super(DailyInspirationState.initial()) {
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
      log('🟥 DailyInspirationCubit._load: $e\n$st');
    }
  }

  Future<void> _apply(DailyInspirationSettingsModel settings) async {
    final item = await _service.todayItem(settings.contentType);
    emit(
      DailyInspirationState(settings: settings, todayItem: item, loaded: true),
    );
    unawaited(_scheduleAndPush(settings, item));
  }

  String _bodyFor(DailyInspirationItem? item) {
    if (item == null) return '';
    return item.reference.isEmpty
        ? item.arabic
        : '${item.arabic}\n— ${item.reference}';
  }

  Future<void> _scheduleAndPush(
    DailyInspirationSettingsModel settings,
    DailyInspirationItem? item,
  ) async {
    try {
      await _notif.scheduleDaily(
        enabled: settings.enabled,
        hour: settings.hour,
        minute: settings.minute,
        title: _notifTitle,
        body: _bodyFor(item),
      );
    } catch (e) {
      log('🟥 DailyInspirationCubit._scheduleAndPush (notif): $e');
    }
    try {
      final items = await _service.filteredItems(settings.contentType);
      await DailyInspirationHomeWidget.update(items, _notifTitle);
    } catch (e) {
      log('🟥 DailyInspirationCubit._scheduleAndPush (widget): $e');
    }
  }

  Future<void> setEnabled(bool enabled) =>
      _repo.saveSettings(state.settings.copyWith(enabled: enabled));

  Future<void> updateTime(int hour, int minute) =>
      _repo.saveSettings(state.settings.copyWith(hour: hour, minute: minute));

  Future<void> setContentType(DailyContentType type) =>
      _repo.saveSettings(state.settings.copyWith(contentType: type));

  /// Recompute today's item + reschedule + re-push — call on resume / day
  /// rollover so a backgrounded device still advances at midnight.
  Future<void> refreshForToday() => _apply(state.settings);

  Future<bool> sendTest() => _notif.sendTestNotification(
    title: _notifTitle,
    body: _bodyFor(state.todayItem),
  );

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
