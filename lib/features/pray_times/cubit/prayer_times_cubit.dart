import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'package:wadhakir/data/models/notification_settings_model.dart';
import 'package:wadhakir/domain/usecases/get_prayer_times_usecase.dart';
import 'package:wadhakir/domain/repositories/prayer_times_repository.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_state.dart';
import 'package:wadhakir/domain/usecases/get_calculation_method_usecase.dart';
import 'package:wadhakir/domain/usecases/get_prayer_times_range_usecase.dart';
import 'package:wadhakir/domain/usecases/set_calculation_method_usecase.dart';
import 'package:wadhakir/core/time/clock.dart';
import 'package:wadhakir/features/pray_times/services/prayer_schedule_planner.dart';
import 'package:wadhakir/features/pray_times/services/prayer_notification_service.dart';
import 'package:wadhakir/features/pray_times/services/persistent_notification_manager.dart';
import 'package:wadhakir/data/repositories/azkar_reminder_settings_repository_impl.dart';
import 'package:wadhakir/features/azkar_reminders/services/azkar_notification_service.dart';
import 'package:wadhakir/features/home_screen_widgets/presentation/widgets/prayer_times_home_widget.dart';
import 'package:wadhakir/features/home_screen_widgets/presentation/widgets/hijri_calendar_home_widget.dart';
import 'package:wadhakir/features/home_screen_widgets/presentation/widgets/glass_prayer_home_widget.dart';

class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  final GetPrayerTimesUseCase _getPrayerTimesUseCase;
  final GetPrayerTimesRangeUseCase _getPrayerTimesRangeUseCase;
  final GetCalculationMethodUseCase _getCalculationMethodUseCase;
  final SetCalculationMethodUseCase _setCalculationMethodUseCase;
  final PrayerTimesRepository _repository;
  final PrayerNotificationService _notificationService;
  final PersistentNotificationManager _persistentManager;
  // Optional: drives the prayer-time-dependent azkar reminders (after-prayer,
  // Duha, last-third Qiyam). Null in contexts that don't wire it (e.g. tests).
  final AzkarReminderSettingsRepositoryImpl? _azkarReminderRepository;
  final AzkarNotificationService _azkarNotificationService;

  Timer? _prayerTimesTimer;

  // The calendar day the currently-loaded times were computed for. Used by the
  // periodic timer to detect a midnight rollover while the app stays open.
  DateTime? _loadedForDay;

  // True from construction until the eager initial load decides how to run.
  // While set, widget-triggered loads coalesce into the initial load so a
  // returning user never sees a spinner flash on the first frame.
  bool _initialLoadClaimed = false;

  // Store time adjustments cache
  Map<String, int> _timeAdjustments = {
    'الفجر': 0,
    'الشروق': 0,
    'الظهر': 0,
    'العصر': 0,
    'المغرب': 0,
    'العشاء': 0,
  };

  // SharedPreferences keys
  static const String _prefsKeyTimeAdjustments = 'prayer_time_adjustments';

  // Owned by PrayerSchedulePlanner, which documents why iOS is shorter. Read
  // through rather than duplicated: this used to be a private copy, and a
  // horizon that disagreed with the planner's would arm days the cancel sweep
  // did not expect.
  int get _scheduleHorizonDays => PrayerSchedulePlanner.horizonDays(
    isIOS: defaultTargetPlatform == TargetPlatform.iOS,
  );

  // Signature of the last scheduled plan. Redundant reschedule requests with an
  // identical plan are skipped so repeated listener fires don't churn the OS
  // alarm table (a cancel+reschedule race could otherwise drop a notification
  // firing at that exact minute).
  String _lastScheduleSignature = '';

  /// Where "today" and "now" come from on the scheduling path.
  ///
  /// Injected so the horizon this cubit builds — and therefore the ids the
  /// planner allocates — can be pinned to an awkward instant in a test: the
  /// minute before Fajr, a day rollover, the night the clocks change.
  final Clock _clock;

  PrayerTimesCubit(
    this._getPrayerTimesUseCase,
    this._getPrayerTimesRangeUseCase,
    this._getCalculationMethodUseCase,
    this._setCalculationMethodUseCase, {
    required this._repository,
    PrayerNotificationService? notificationService,
    PersistentNotificationManager? persistentManager,
    this._azkarReminderRepository,
    AzkarNotificationService? azkarNotificationService,
    // An initializing formal, unlike the three below: it needs no
    // null-coalescing fallback, so the lint's preferred form actually works.
    this._clock = systemClock,
  }) : _notificationService =
           notificationService ?? PrayerNotificationService(),
       _persistentManager =
           persistentManager ?? PersistentNotificationManager(),
       _azkarNotificationService =
           azkarNotificationService ?? AzkarNotificationService(),
       super(const PrayerTimesInitial()) {
    // Load saved time adjustments
    _loadSavedTimeAdjustments();

    // Eagerly load prayer times at app start. Because the repository now
    // computes from the last saved location instantly (no blocking GPS fix),
    // the state becomes Loaded before the home/prayer screens build — so there
    // is no loading spinner on a returning launch. Then refresh the device
    // location in the background and silently recompute only if it changed.
    //
    // Claim the load synchronously here so a widget-triggered load racing on
    // the first frame coalesces instead of flashing a spinner.
    _initialLoadClaimed = true;
    // ignore: unawaited_futures
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    // Show the loading state only on a genuine first run (no saved location, so
    // a GPS fix is needed). Returning users have a saved location and compute
    // instantly, so load silently.
    final isFirstRun = await _repository.isFirstTimeUser();
    _initialLoadClaimed = false;
    await loadPrayerTimes(silent: !isFirstRun);

    try {
      final locationChanged = await _repository.refreshLocation();
      if (locationChanged) {
        await refreshSilently();
      }
    } catch (e) {
      debugPrint('Background location refresh failed (non-fatal): $e');
    }
  }

  /// Recompute prayer times without showing a loading spinner. Used for
  /// in-app refreshes (location/method/madhab/adjustment changes, app resume,
  /// date rollover) so the user never sees a spinner once times are loaded.
  Future<void> refreshSilently() => loadPrayerTimes(silent: true);

  /// Silently recompute only if the calendar day changed since the last load
  /// (e.g. the app was backgrounded across midnight). No-op otherwise — cheap
  /// to call on every app resume.
  Future<void> refreshIfStale() async {
    if (state is! PrayerTimesLoaded) return;
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);
    if (_loadedForDay == null || todayKey.isAfter(_loadedForDay!)) {
      await refreshSilently();
    }
  }

  // Load prayer times for a week centered around today
  Future<void> loadPrayerTimes({bool silent = false}) async {
    // During the cold-start window the constructor owns the initial load; a
    // widget-triggered load that races in here coalesces (the eager load will
    // run with the right silent/loud choice) so there's no spinner flash.
    if (_initialLoadClaimed) return;

    // Only show the spinner on a genuine first load. Silent refreshes — and any
    // refresh while times are already on screen — recompute in place and emit
    // Loaded directly.
    if (!silent && state is! PrayerTimesLoaded) {
      emit(const PrayerTimesLoading());
    }

    try {
      final today = DateTime.now();
      _loadedForDay = DateTime(today.year, today.month, today.day);
      final startDate = today.subtract(const Duration(days: 3));
      // Load far enough ahead that the multi-day notification scheduler has all
      // the future days it needs (see _scheduleHorizonDays).
      final endDate = today.add(Duration(days: _scheduleHorizonDays));

      final prayerTimes = await _getPrayerTimesRangeUseCase(
        startDate: startDate,
        endDate: endDate,
      );

      // Apply time adjustments to all loaded prayer times
      final adjustedPrayerTimes = _applyTimeAdjustments(prayerTimes);

      // Update state
      emit(
        PrayerTimesLoaded(
          prayerTimes: adjustedPrayerTimes,
          selectedDate: today,
        ),
      );

      // Update home screen widget with today's prayer times
      final dateKey = DateTime(today.year, today.month, today.day);
      final todayPrayerTimes = adjustedPrayerTimes[dateKey];
      if (todayPrayerTimes != null) {
        debugPrint(
          'Updating widget with prayer times for: ${dateKey.toString()}',
        );
        await PrayerTimesHomeWidget.updatePrayerTimes(todayPrayerTimes);

        // Render the two glass prayer widgets (Prayer Detail + Prayer Next)
        await GlassPrayerHomeWidget.updateGlassWidgets(todayPrayerTimes);

        // Update Hijri calendar widget
        await HijriCalendarHomeWidget.updateCalendar();

        // Schedule prayer notifications for today
        await _scheduleNotificationsForToday(todayPrayerTimes);

        // Update persistent notification manager with new prayer times
        if (_persistentManager.isActive) {
          final locationName = await getCurrentLocationName();
          await _persistentManager.updatePrayerTimes(
            prayerTimes: todayPrayerTimes,
            locationName: locationName,
          );
        }
      } else {
        debugPrint('No prayer times found for today: ${dateKey.toString()}');
      }

      // Start a timer to update the UI every minute for the countdown
      _startTimer();
    } catch (e) {
      emit(PrayerTimesError(e.toString()));
    }
  }

  /// Schedule notifications for today's prayer times.
  ///
  /// The prayer adhan notifications themselves are scheduled via
  /// [scheduleNotificationsWithSettings] (driven by SettingsCubit). Here we
  /// (re)schedule the prayer-time-DRIVEN azkar reminders — after-each-prayer,
  /// Duha, and last-third Qiyam — so their times always match the freshly
  /// computed prayer times. Runs on every load/refresh/midnight rollover.
  Future<void> _scheduleNotificationsForToday(
    PrayerTimesModel prayerTimes,
  ) async {
    final azkarRepo = _azkarReminderRepository;
    if (azkarRepo == null) return;
    try {
      final settings = await azkarRepo.getSettings();
      await _azkarNotificationService.applyPrayerDriven(settings, prayerTimes);
    } catch (e) {
      debugPrint('Error scheduling azkar prayer-driven reminders: $e');
    }
  }

  /// Re-schedule the prayer-time-driven azkar reminders using today's prayer
  /// times. Called from main.dart when azkar settings change so the toggles
  /// take effect immediately instead of waiting for the next prayer refresh.
  Future<void> rescheduleAzkarPrayerDriven() async {
    if (state is! PrayerTimesLoaded) return;
    final today = (state as PrayerTimesLoaded).prayerTimes[_clock.today()];
    if (today != null) {
      await _scheduleNotificationsForToday(today);
    }
  }

  /// Schedule notifications with current settings.
  /// This should be called from SettingsCubit when settings change and from the
  /// prayer-times BlocListener when a genuine (re)load happens.
  Future<void> scheduleNotificationsWithSettings(
    NotificationSettingsModel settings,
  ) async {
    try {
      if (state is! PrayerTimesLoaded) {
        debugPrint('Cannot schedule notifications: prayer times not loaded');
        return;
      }

      final currentState = state as PrayerTimesLoaded;
      final todayKey = _clock.today();
      final todayPrayerTimes = currentState.prayerTimes[todayKey];

      // Build the multi-day map (today .. today+horizon) so the adhan keeps
      // firing even if the app isn't reopened for several days.
      final prayerTimesByDay = <DateTime, Map<String, DateTime>>{};
      for (var i = 0; i < _scheduleHorizonDays; i++) {
        final dayKey = DateTime(
          todayKey.year,
          todayKey.month,
          todayKey.day + i,
        );
        final pt = currentState.prayerTimes[dayKey];
        if (pt == null) continue;
        prayerTimesByDay[dayKey] = {
          'Fajr': pt.fajr,
          'Dhuhr': pt.dhuhr,
          'Asr': pt.asr,
          'Maghrib': pt.maghrib,
          'Isha': pt.isha,
        };
      }

      if (prayerTimesByDay.isEmpty) {
        debugPrint('Cannot schedule notifications: no prayer times in horizon');
        return;
      }

      final locationName = await getCurrentLocationName();

      // Skip a redundant cancel+reschedule when nothing about the plan changed.
      final signature = _buildScheduleSignature(
        settings,
        prayerTimesByDay,
        locationName,
      );
      if (signature == _lastScheduleSignature) {
        debugPrint('⏭️  Notification plan unchanged — skipping reschedule');
      } else {
        debugPrint('\n🔄 Rescheduling notifications');
        debugPrint('Master Enabled: ${settings.masterEnabled}');
        debugPrint('Days scheduled: ${prayerTimesByDay.length}');
        await _notificationService.schedulePrayerNotificationsMultiDay(
          prayerTimesByDay: prayerTimesByDay,
          settings: settings,
          locationName: locationName,
        );
        // Only remember the plan as "done" AFTER it actually succeeds. If the
        // await throws (e.g. permission denied, exact-alarm failure), the guard
        // must NOT suppress the next attempt — otherwise a transient failure
        // silently disables reminders for the whole session.
        _lastScheduleSignature = signature;
      }

      // Persistent "next prayer" notification is an Android-only ongoing
      // notification concept — iOS can't pin one. It maintains its own live
      // countdown, so we only start/stop it here, not on every reschedule.
      final isAndroid = defaultTargetPlatform == TargetPlatform.android;
      if (isAndroid &&
          settings.persistentNotificationEnabled &&
          todayPrayerTimes != null) {
        // start() already no-ops when it is running (see
        // PersistentNotificationManager.start).
        await _persistentManager.start(
          prayerTimes: todayPrayerTimes,
          locationName: locationName,
        );
      } else {
        await _persistentManager.stop();
      }
    } catch (e) {
      debugPrint('❌ Error scheduling notifications: $e');
    }
  }

  /// A compact fingerprint of the scheduling plan: the master toggle, location,
  /// each prayer's enabled/timing/sound, and every scheduled day's per-prayer
  /// HH:mm. Identical fingerprint ⇒ nothing to reschedule.
  String _buildScheduleSignature(
    NotificationSettingsModel s,
    Map<DateTime, Map<String, DateTime>> byDay,
    String locationName,
  ) {
    // Signs the INPUTS (settings, times, location), not the resulting plan.
    //
    // PrayerScheduler has its own signature over the plan, and the two are
    // deliberately different. A plan shrinks as the day passes — an entry
    // drops out the moment its prayer fires — so a plan-based guard here would
    // re-arm the whole window roughly once per prayer, and every re-arm is a
    // cancel-then-add with a gap a notification due at that minute can fall
    // into. Signing the inputs makes this layer ask "did anything the user
    // controls change?", which is the question it is actually answering.
    //
    // Deliberately excludes persistentNotificationEnabled: the persistent
    // notification (id 999) is started/stopped separately by the caller and is
    // not part of the prayer schedule, so folding it in here would force a full
    // cancel + re-arm of every prayer notification on an unrelated toggle.
    final buf = StringBuffer()
      ..write(s.masterEnabled ? '1' : '0')
      // Location appears in the notification body, so a location change must
      // trigger a reschedule even when the prayer minutes are unchanged.
      ..write('|loc:$locationName');
    for (final entry in [
      ('F', s.fajrSettings),
      ('D', s.dhuhrSettings),
      ('A', s.asrSettings),
      ('M', s.maghribSettings),
      ('I', s.ishaSettings),
    ]) {
      final ps = entry.$2;
      buf.write(
        '|${entry.$1}:${ps.enabled}:${ps.timing.index}:${ps.customSoundPath ?? ""}',
      );
    }
    final days = byDay.keys.toList()..sort();
    for (final d in days) {
      final m = byDay[d]!;
      buf.write('#${d.year}-${d.month}-${d.day}');
      for (final k in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
        final t = m[k];
        if (t != null) buf.write('$k${t.hour}:${t.minute};');
      }
    }
    return buf.toString();
  }

  // Apply time adjustments to all prayer times
  Map<DateTime, PrayerTimesModel> _applyTimeAdjustments(
    Map<DateTime, PrayerTimesModel> prayerTimes,
  ) {
    final result = <DateTime, PrayerTimesModel>{};

    prayerTimes.forEach((date, model) {
      result[date] = _applyTimeAdjustmentToModel(model);
    });

    return result;
  }

  // Apply time adjustments to a single prayer times model
  PrayerTimesModel _applyTimeAdjustmentToModel(PrayerTimesModel model) {
    // Apply minutes adjustments to each prayer time
    final adjustedFajr = _adjustTime(
      model.fajr,
      _timeAdjustments['الفجر'] ?? 0,
    );
    final adjustedSunrise = _adjustTime(
      model.sunrise,
      _timeAdjustments['الشروق'] ?? 0,
    );
    final adjustedDhuhr = _adjustTime(
      model.dhuhr,
      _timeAdjustments['الظهر'] ?? 0,
    );
    final adjustedAsr = _adjustTime(model.asr, _timeAdjustments['العصر'] ?? 0);
    final adjustedMaghrib = _adjustTime(
      model.maghrib,
      _timeAdjustments['المغرب'] ?? 0,
    );
    final adjustedIsha = _adjustTime(
      model.isha,
      _timeAdjustments['العشاء'] ?? 0,
    );

    // Create a new model with adjusted times
    // Note: Qiyam times (midnight and last third) are kept as-is since they're calculated times
    return PrayerTimesModel(
      fajr: adjustedFajr,
      sunrise: adjustedSunrise,
      dhuhr: adjustedDhuhr,
      asr: adjustedAsr,
      maghrib: adjustedMaghrib,
      isha: adjustedIsha,
      date: model.date,
      calculationParameters: model.calculationParameters,
      coordinates: model.coordinates,
      middleOfTheNight: model.middleOfTheNight,
      lastThirdOfTheNight: model.lastThirdOfTheNight,
    );
  }

  // Helper to adjust a DateTime by adding minutes
  DateTime _adjustTime(DateTime time, int minutes) {
    return time.add(Duration(minutes: minutes));
  }

  // Refresh prayer times and notifications
  Future<void> refreshPrayerTimes() async {
    try {
      await loadPrayerTimes(silent: true);

      // Ensure widget is updated with latest data
      if (state is PrayerTimesLoaded) {
        final currentState = state as PrayerTimesLoaded;
        final today = DateTime.now();
        final dateKey = DateTime(today.year, today.month, today.day);

        final todayPrayerTimes = currentState.prayerTimes[dateKey];
        if (todayPrayerTimes != null) {
          debugPrint(
            'Refreshing widget with prayer times for: ${dateKey.toString()}',
          );
          await PrayerTimesHomeWidget.updatePrayerTimes(todayPrayerTimes);
          await GlassPrayerHomeWidget.updateGlassWidgets(todayPrayerTimes);
        } else {
          debugPrint(
            'No prayer times found for today during refresh: ${dateKey.toString()}',
          );
        }
      }
    } catch (e) {
      debugPrint('Error refreshing prayer times: $e');
    }
  } // Change the selected date

  void selectDate(DateTime date) async {
    if (state is PrayerTimesLoaded) {
      final currentState = state as PrayerTimesLoaded;

      // Check if we already have this date in our cache
      final dateKey = DateTime(date.year, date.month, date.day);
      if (currentState.prayerTimes.containsKey(dateKey)) {
        emit(
          PrayerTimesLoaded(
            prayerTimes: currentState.prayerTimes,
            selectedDate: date,
          ),
        );
        return;
      }

      // If not, fetch prayer times for this date
      try {
        final prayerTimesForDate = await _getPrayerTimesUseCase(date: date);

        // Apply time adjustments to the new prayer times
        final adjustedPrayerTimes = _applyTimeAdjustmentToModel(
          prayerTimesForDate,
        );

        // Add the new date to our map
        final updatedPrayerTimes = Map<DateTime, PrayerTimesModel>.from(
          currentState.prayerTimes,
        );
        updatedPrayerTimes[dateKey] = adjustedPrayerTimes;

        emit(
          PrayerTimesLoaded(
            prayerTimes: updatedPrayerTimes,
            selectedDate: date,
          ),
        );
      } catch (e) {
        emit(PrayerTimesError(e.toString()));
      }
    } else {
      // If we're not in a loaded state, reload all prayer times
      await loadPrayerTimes();
    }
  }

  // Go to next day
  void nextDay() {
    if (state is PrayerTimesLoaded) {
      final currentState = state as PrayerTimesLoaded;
      final nextDate = currentState.selectedDate.add(const Duration(days: 1));
      selectDate(nextDate);
    }
  }

  // Go to previous day
  void previousDay() {
    if (state is PrayerTimesLoaded) {
      final currentState = state as PrayerTimesLoaded;
      final previousDate = currentState.selectedDate.subtract(
        const Duration(days: 1),
      );
      selectDate(previousDate);
    }
  }

  // Change calculation method
  Future<void> setCalculationMethod(CalculationParameters parameters) async {
    try {
      await _setCalculationMethodUseCase(parameters);

      // Reload prayer times with new method
      await loadPrayerTimes(silent: true);
    } catch (e) {
      emit(PrayerTimesError(e.toString()));
    }
  }

  // Get the current calculation parameters
  Future<CalculationParameters> getCalculationMethod() async {
    return await _getCalculationMethodUseCase();
  }

  // Get the current madhab setting
  Future<Madhab> getMadhab() async {
    return await _repository.getMadhab();
  }

  // Set the madhab for Asr calculation
  Future<void> setMadhab(Madhab madhab) async {
    try {
      await _repository.setMadhab(madhab);

      // Reload prayer times with the new madhab setting
      await loadPrayerTimes(silent: true);
    } catch (e) {
      emit(PrayerTimesError(e.toString()));
    }
  }

  // Start a timer to update the UI every minute for the countdown
  void _startTimer() {
    _prayerTimesTimer?.cancel();

    _prayerTimesTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (state is! PrayerTimesLoaded) return;

      // If the calendar day rolled over while the app stayed open, recompute
      // silently (no spinner) so "today" and the countdown stay correct.
      final now = DateTime.now();
      final todayKey = DateTime(now.year, now.month, now.day);
      if (_loadedForDay != null && todayKey.isAfter(_loadedForDay!)) {
        // ignore: unawaited_futures
        refreshSilently();
        return;
      }

      final currentState = state as PrayerTimesLoaded;

      // Re-emit the state to update the countdown timer
      emit(
        PrayerTimesLoaded(
          prayerTimes: currentState.prayerTimes,
          selectedDate: currentState.selectedDate,
        ),
      );
    });
  }

  // Load saved time adjustments from SharedPreferences
  Future<void> _loadSavedTimeAdjustments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKeyTimeAdjustments);

      if (jsonString != null && jsonString.isNotEmpty) {
        // Parse the JSON string to a Map<String, dynamic>
        final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(
          jsonString
              .split(',')
              .map((entry) {
                final parts = entry.split(':');
                return MapEntry(parts[0], int.parse(parts[1]));
              })
              .toList()
              .fold({}, (map, entry) {
                map[entry.key] = entry.value;
                return map;
              }),
        );

        // Convert to Map<String, int> and update the cache
        _timeAdjustments = jsonMap.map(
          (key, value) => MapEntry(key, value as int),
        );

        debugPrint('Loaded time adjustments: $_timeAdjustments');
      }
    } catch (e) {
      debugPrint('Error loading time adjustments: $e');
    }
  }

  // Save time adjustments to SharedPreferences
  Future<void> _saveTimeAdjustments() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert Map to String (simple format like "key1:value1,key2:value2")
      final jsonString = _timeAdjustments.entries
          .map((entry) => '${entry.key}:${entry.value}')
          .join(',');

      await prefs.setString(_prefsKeyTimeAdjustments, jsonString);
      debugPrint('Saved time adjustments: $jsonString');
    } catch (e) {
      debugPrint('Error saving time adjustments: $e');
    }
  }

  // Methods for prayer time adjustments
  Future<Map<String, int>> getPrayerTimeAdjustments() async {
    return _timeAdjustments;
  }

  Future<void> setPrayerTimeAdjustments(Map<String, int> adjustments) async {
    try {
      // Update the cache
      _timeAdjustments = Map<String, int>.from(adjustments);

      // Save to SharedPreferences
      await _saveTimeAdjustments();

      // If in a loaded state, update all prayer times with new adjustments
      if (state is PrayerTimesLoaded) {
        final currentState = state as PrayerTimesLoaded;

        // Apply adjustments to all prayer times
        final adjustedPrayerTimes = _applyTimeAdjustments(
          currentState.prayerTimes,
        );

        // Emit updated state
        emit(
          PrayerTimesLoaded(
            prayerTimes: adjustedPrayerTimes,
            selectedDate: currentState.selectedDate,
          ),
        );
      } else {
        // If not in a loaded state, reload prayer times
        await loadPrayerTimes(silent: true);
      }
    } catch (e) {
      debugPrint('Error setting prayer time adjustments: $e');
    }
  }

  // Methods for location handling
  Future<String> getCurrentLocationName() async {
    try {
      return await _repository.getCurrentLocationName();
    } catch (e) {
      debugPrint('Error getting current location name: $e');
      return "غير معروف";
    }
  }

  Future<bool> isUsingFallbackLocation() async {
    try {
      return await _repository.isUsingFallbackLocation();
    } catch (e) {
      debugPrint('Error checking fallback location: $e');
      return false;
    }
  }

  Future<bool> hasLocationPermission() async {
    try {
      return await _repository.hasLocationPermission();
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

  Future<bool> isFirstTimeUser() async {
    try {
      return await _repository.isFirstTimeUser();
    } catch (e) {
      debugPrint('Error checking first time user: $e');
      return false;
    }
  }

  Future<void> updateLocation() async {
    try {
      // Check if location services are enabled
      final isEnabled = await _repository.isLocationServiceEnabled();

      if (!isEnabled) {
        throw Exception(
          'Location services are disabled. Please enable location services in your device settings to get accurate prayer times.',
        );
      }

      // Force update location
      await _repository.forceLocationUpdate();

      // Refresh prayer times with new location
      await refreshPrayerTimes();
    } catch (e) {
      debugPrint('Error updating location: $e');
      rethrow;
    }
  }

  @override
  Future<void> close() {
    _prayerTimesTimer?.cancel();
    return super.close();
  }
}
