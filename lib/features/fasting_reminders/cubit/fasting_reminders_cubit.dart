import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/data/models/fasting/fasting_reminder_settings_model.dart';
import 'package:wadhakir/data/models/fasting/islamic_fasting_day_model.dart';
import 'package:wadhakir/domain/usecases/get_fasting_reminder_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/set_fasting_reminder_settings_usecase.dart';
import 'package:wadhakir/domain/usecases/get_fasting_reminder_settings_stream_usecase.dart';
import 'package:wadhakir/features/fasting_reminders/cubit/fasting_reminders_state.dart';
import 'package:wadhakir/features/fasting_reminders/services/hijri_date_calculator_service.dart';
import 'package:wadhakir/features/fasting_reminders/services/fasting_notification_service.dart';

/// Cubit for managing fasting reminders state
class FastingRemindersCubit extends Cubit<FastingRemindersState> {
  final HijriDateCalculatorService _hijriCalculator;
  final GetFastingReminderSettingsUseCase _getSettingsUseCase;
  final SetFastingReminderSettingsUseCase _setSettingsUseCase;
  final GetFastingReminderSettingsStreamUseCase _getSettingsStreamUseCase;
  final FastingNotificationService _notificationService;

  StreamSubscription? _settingsSubscription;

  FastingRemindersCubit({
    HijriDateCalculatorService? hijriCalculator,
    required GetFastingReminderSettingsUseCase getSettingsUseCase,
    required SetFastingReminderSettingsUseCase setSettingsUseCase,
    required GetFastingReminderSettingsStreamUseCase getSettingsStreamUseCase,
    FastingNotificationService? notificationService,
  })  : _hijriCalculator = hijriCalculator ?? HijriDateCalculatorService(),
        _getSettingsUseCase = getSettingsUseCase,
        _setSettingsUseCase = setSettingsUseCase,
        _getSettingsStreamUseCase = getSettingsStreamUseCase,
        _notificationService =
            notificationService ?? FastingNotificationService(),
        super(const FastingRemindersInitial()) {
    loadSettings();
    _listenToSettingsChanges();
  }

  /// Listen to settings changes from repository
  void _listenToSettingsChanges() {
    _settingsSubscription = _getSettingsStreamUseCase().listen(
      (settings) => _updateStateWithSettings(settings),
      onError: (error) => emit(FastingRemindersError(error.toString())),
    );
  }

  /// Update state with new settings
  void _updateStateWithSettings(FastingReminderSettings settings) {
    final currentHijri = _hijriCalculator.getCurrentHijriDate();

    // Calculate upcoming days for 2 months (for notifications and widgets)
    final upcomingDays = _hijriCalculator.getUpcomingFastingDaysForMonth(
      ayyamAlBidEnabled: settings.ayyamAlBidEnabled,
      ninthTenthEnabled: settings.ninthTenthEnabled,
      specialDaysEmphasis: settings.specialDaysEmphasis,
    );

    // Calculate upcoming days for the entire year (for calendar display only)
    final yearDays = _hijriCalculator.getUpcomingFastingDaysForYear(
      ayyamAlBidEnabled: settings.ayyamAlBidEnabled,
      ninthTenthEnabled: settings.ninthTenthEnabled,
      specialDaysEmphasis: settings.specialDaysEmphasis,
      mondayFastingEnabled: settings.mondayFastingEnabled,
      thursdayFastingEnabled: settings.thursdayFastingEnabled,
    );

    final nextFastingDay = _hijriCalculator.getNextFastingDay(
      ayyamAlBidEnabled: settings.ayyamAlBidEnabled,
      ninthTenthEnabled: settings.ninthTenthEnabled,
      specialDaysEmphasis: settings.specialDaysEmphasis,
    );

    final daysUntilNext = nextFastingDay != null
        ? _hijriCalculator.getDaysUntilFastingDay(nextFastingDay)
        : null;

    emit(FastingRemindersLoaded(
      settings: settings,
      upcomingFastingDays: upcomingDays,
      yearFastingDays: yearDays,
      daysUntilNext: daysUntilNext,
      nextFastingDay: nextFastingDay,
      currentHijriMonth: currentHijri.month,
      currentHijriYear: currentHijri.year,
      currentHijriDay: currentHijri.day,
    ));
  }

  /// Load settings and calculate upcoming fasting days.
  ///
  /// Emits Loaded as soon as we have the settings (so the UI shows the
  /// toggles right away). Notification scheduling is fired off as a
  /// background task — it can take 100–1500ms on Android (channel reg +
  /// cancel + schedule). Previously this was awaited inline, which left
  /// the section stuck on the loading spinner the entire time.
  Future<void> loadSettings() async {
    log('🟦 FastingRemindersCubit.loadSettings: START, emitting Loading');
    emit(const FastingRemindersLoading());

    try {
      log('🟦 FastingRemindersCubit.loadSettings: reading settings from repo…');
      final sw = Stopwatch()..start();
      final settings = await _getSettingsUseCase();
      log('🟦 FastingRemindersCubit.loadSettings: settings loaded in ${sw.elapsedMilliseconds}ms '
          '(monthly=${settings.monthlyFastingRemindersEnabled} '
          'mon=${settings.mondayFastingEnabled} '
          'thu=${settings.thursdayFastingEnabled})');

      // Emit Loaded FIRST so the UI shows immediately. The user can
      // already interact with the settings even before notification
      // scheduling finishes.
      _updateStateWithSettings(settings);
      log('🟦 FastingRemindersCubit.loadSettings: Loaded state emitted, '
          'kicking off background notification scheduling');

      // Fire-and-forget. Errors here are logged but never bubble up to
      // the UI — scheduling failing isn't a reason to hide the settings.
      unawaited(_scheduleSafely(settings, source: 'loadSettings'));
    } catch (e, st) {
      log('🟥 FastingRemindersCubit.loadSettings: ERROR $e\n$st');
      emit(FastingRemindersError(e.toString()));
    }
  }

  /// Update fasting reminder settings.
  ///
  /// Same pattern as loadSettings: persist + emit synchronously, schedule
  /// in the background. The user sees the toggle flip immediately instead
  /// of waiting for the platform-side notification work.
  Future<void> updateSettings(FastingReminderSettings settings) async {
    log('🟦 FastingRemindersCubit.updateSettings: START '
        '(monthly=${settings.monthlyFastingRemindersEnabled} '
        'mon=${settings.mondayFastingEnabled} '
        'thu=${settings.thursdayFastingEnabled})');
    try {
      final sw = Stopwatch()..start();
      await _setSettingsUseCase(settings);
      log('🟦 FastingRemindersCubit.updateSettings: persisted in ${sw.elapsedMilliseconds}ms');

      // State updates automatically via settings stream; no need to wait
      // for scheduling.
      unawaited(_scheduleSafely(settings, source: 'updateSettings'));
    } catch (e, st) {
      log('🟥 FastingRemindersCubit.updateSettings: ERROR $e\n$st');
      emit(FastingRemindersError(e.toString()));
    }
  }

  /// Run notification scheduling and absorb any failure. The UI has
  /// already been updated by the time this runs, so a scheduling failure
  /// (e.g. permission revoked, plugin crash) should not destroy the
  /// section's visible state.
  Future<void> _scheduleSafely(
    FastingReminderSettings settings, {
    required String source,
  }) async {
    final sw = Stopwatch()..start();
    log('🟪 _scheduleSafely[$source]: START');
    try {
      await _notificationService.scheduleAllFastingNotifications(settings);
      log('🟪 _scheduleSafely[$source]: DONE in ${sw.elapsedMilliseconds}ms');
    } catch (e, st) {
      log('🟥 _scheduleSafely[$source]: scheduling failed after '
          '${sw.elapsedMilliseconds}ms: $e\n$st');
    }
  }

  /// Toggle monthly fasting reminders
  Future<void> toggleMonthlyReminders(bool enabled) async {
    final currentState = state;
    if (currentState is! FastingRemindersLoaded) return;

    final updatedSettings = currentState.settings.copyWith(
      monthlyFastingRemindersEnabled: enabled,
    );

    await updateSettings(updatedSettings);
  }

  /// Toggle Ayyam al-Bid reminders
  Future<void> toggleAyyamAlBid(bool enabled) async {
    final currentState = state;
    if (currentState is! FastingRemindersLoaded) return;

    final updatedSettings = currentState.settings.copyWith(
      ayyamAlBidEnabled: enabled,
    );

    await updateSettings(updatedSettings);
  }

  /// Toggle 9th and 10th day reminders
  Future<void> toggleNinthTenth(bool enabled) async {
    final currentState = state;
    if (currentState is! FastingRemindersLoaded) return;

    final updatedSettings = currentState.settings.copyWith(
      ninthTenthEnabled: enabled,
    );

    await updateSettings(updatedSettings);
  }

  /// Toggle special days emphasis
  Future<void> toggleSpecialDays(bool enabled) async {
    final currentState = state;
    if (currentState is! FastingRemindersLoaded) return;

    final updatedSettings = currentState.settings.copyWith(
      specialDaysEmphasis: enabled,
    );

    await updateSettings(updatedSettings);
  }

  /// Set days before notification
  Future<void> setDaysBeforeNotification(int days) async {
    final currentState = state;
    if (currentState is! FastingRemindersLoaded) return;

    if (days < 1 || days > 7) return; // Validate range 1-7 days

    final updatedSettings = currentState.settings.copyWith(
      daysBeforeNotification: days,
    );

    await updateSettings(updatedSettings);
  }

  /// Toggle eve reminder
  Future<void> toggleEveReminder(bool enabled) async {
    final currentState = state;
    if (currentState is! FastingRemindersLoaded) return;

    final updatedSettings = currentState.settings.copyWith(
      eveReminder: enabled,
    );

    await updateSettings(updatedSettings);
  }

  /// Toggle morning reminder
  Future<void> toggleMorningReminder(bool enabled) async {
    final currentState = state;
    if (currentState is! FastingRemindersLoaded) return;

    final updatedSettings = currentState.settings.copyWith(
      morningReminder: enabled,
    );

    await updateSettings(updatedSettings);
  }

  /// Toggle advance reminder
  Future<void> toggleAdvanceReminder(bool enabled) async {
    final currentState = state;
    if (currentState is! FastingRemindersLoaded) return;

    final updatedSettings = currentState.settings.copyWith(
      advanceReminder: enabled,
    );

    await updateSettings(updatedSettings);
  }

  /// Update advance reminder settings (days, time, and enabled state) in one call
  /// This avoids multiple state emissions and reschedules
  Future<void> updateAdvanceReminderSettings({
    required int days,
    required String time,
    required bool enabled,
  }) async {
    final currentState = state;
    if (currentState is! FastingRemindersLoaded) return;

    // Validate days range
    if (days < 1 || days > 7) return;

    final updatedSettings = currentState.settings.copyWith(
      daysBeforeNotification: days,
      advanceReminderTime: time,
      advanceReminder: enabled,
    );

    await updateSettings(updatedSettings);
  }

  // === Weekly Fasting Toggles ===

  /// Toggle Monday fasting reminders
  Future<void> toggleMondayFasting(bool enabled) async {
    final currentState = state;
    if (currentState is! FastingRemindersLoaded) return;

    final updatedSettings = currentState.settings.copyWith(
      mondayFastingEnabled: enabled,
    );

    await updateSettings(updatedSettings);
  }

  /// Toggle Thursday fasting reminders
  Future<void> toggleThursdayFasting(bool enabled) async {
    final currentState = state;
    if (currentState is! FastingRemindersLoaded) return;

    final updatedSettings = currentState.settings.copyWith(
      thursdayFastingEnabled: enabled,
    );

    await updateSettings(updatedSettings);
  }

  /// Toggle vibration for notifications
  Future<void> toggleVibration(bool enabled) async {
    final currentState = state;
    if (currentState is! FastingRemindersLoaded) return;

    final updatedSettings = currentState.settings.copyWith(
      vibration: enabled,
    );

    await updateSettings(updatedSettings);
  }

  /// Set weekly notification time (HH:mm format)
  Future<void> setWeeklyNotificationTime(String time) async {
    final currentState = state;
    if (currentState is! FastingRemindersLoaded) return;

    final updatedSettings = currentState.settings.copyWith(
      weeklyNotificationTime: time,
    );

    await updateSettings(updatedSettings);
  }

  /// Set eve reminder time (HH:mm format)
  Future<void> setEveReminderTime(String time) async {
    final currentState = state;
    if (currentState is! FastingRemindersLoaded) return;

    final updatedSettings = currentState.settings.copyWith(
      eveReminderTime: time,
    );

    await updateSettings(updatedSettings);
  }

  /// Set morning reminder time (HH:mm format)
  Future<void> setMorningReminderTime(String time) async {
    final currentState = state;
    if (currentState is! FastingRemindersLoaded) return;

    final updatedSettings = currentState.settings.copyWith(
      morningReminderTime: time,
    );

    await updateSettings(updatedSettings);
  }

  /// Set advance reminder time (HH:mm format)
  Future<void> setAdvanceReminderTime(String time) async {
    final currentState = state;
    if (currentState is! FastingRemindersLoaded) return;

    final updatedSettings = currentState.settings.copyWith(
      advanceReminderTime: time,
    );

    await updateSettings(updatedSettings);
  }

  /// Refresh fasting days (call daily or on app resume)
  Future<void> refresh() async {
    await loadSettings();
  }

  /// Get all special days for the year
  List<IslamicFastingDay> getSpecialDays() {
    return _hijriCalculator.getSpecialDaysForYear();
  }

  /// Check if today is a fasting day
  bool isTodayFastingDay() {
    final currentState = state;
    if (currentState is! FastingRemindersLoaded) return false;

    final currentHijri = _hijriCalculator.getCurrentHijriDate();

    return _hijriCalculator.isFastingDay(
      hijriDay: currentHijri.day,
      hijriMonth: currentHijri.month,
      ayyamAlBidEnabled: currentState.settings.ayyamAlBidEnabled,
      ninthTenthEnabled: currentState.settings.ninthTenthEnabled,
      specialDaysEmphasis: currentState.settings.specialDaysEmphasis,
    );
  }

  @override
  Future<void> close() {
    _settingsSubscription?.cancel();
    return super.close();
  }
}
