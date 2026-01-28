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
import 'package:wadhakir/features/pray_times/services/prayer_notification_service.dart';
import 'package:wadhakir/features/pray_times/services/persistent_notification_manager.dart';
import 'package:wadhakir/features/home_screen_widgets/presentation/widgets/prayer_times_home_widget.dart';
import 'package:wadhakir/features/home_screen_widgets/presentation/widgets/hijri_calendar_home_widget.dart';

class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  final GetPrayerTimesUseCase _getPrayerTimesUseCase;
  final GetPrayerTimesRangeUseCase _getPrayerTimesRangeUseCase;
  final GetCalculationMethodUseCase _getCalculationMethodUseCase;
  final SetCalculationMethodUseCase _setCalculationMethodUseCase;
  final PrayerTimesRepository _repository;
  final PrayerNotificationService _notificationService;
  final PersistentNotificationManager _persistentManager;

  Timer? _prayerTimesTimer;

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

  PrayerTimesCubit(
    this._getPrayerTimesUseCase,
    this._getPrayerTimesRangeUseCase,
    this._getCalculationMethodUseCase,
    this._setCalculationMethodUseCase, {
    required PrayerTimesRepository repository,
    PrayerNotificationService? notificationService,
    PersistentNotificationManager? persistentManager,
  })  : _repository = repository,
        _notificationService =
            notificationService ?? PrayerNotificationService(),
        _persistentManager =
            persistentManager ?? PersistentNotificationManager(),
        super(const PrayerTimesInitial()) {
    // Load saved time adjustments
    _loadSavedTimeAdjustments();
  }

  // Load prayer times for a week centered around today
  Future<void> loadPrayerTimes() async {
    emit(const PrayerTimesLoading());

    try {
      final today = DateTime.now();
      final startDate = today.subtract(const Duration(days: 3));
      final endDate = today.add(const Duration(days: 3));

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

  /// Schedule notifications for today's prayer times
  Future<void> _scheduleNotificationsForToday(
    PrayerTimesModel prayerTimes,
  ) async {
    try {
      // This method is called automatically when prayer times are loaded
      // Actual scheduling happens through scheduleNotificationsWithSettings
      debugPrint('Prayer times loaded, ready to schedule notifications');
    } catch (e) {
      debugPrint('Error in _scheduleNotificationsForToday: $e');
    }
  }

  /// Schedule notifications with current settings
  /// This should be called from SettingsCubit when settings change
  Future<void> scheduleNotificationsWithSettings(
    NotificationSettingsModel settings,
  ) async {
    try {
      if (state is! PrayerTimesLoaded) {
        debugPrint('Cannot schedule notifications: prayer times not loaded');
        return;
      }

      final currentState = state as PrayerTimesLoaded;
      final today = DateTime.now();
      final dateKey = DateTime(today.year, today.month, today.day);
      final todayPrayerTimes = currentState.prayerTimes[dateKey];

      if (todayPrayerTimes == null) {
        debugPrint('Cannot schedule notifications: no prayer times for today');
        return;
      }

      // Create prayer times map for notification service
      final prayerTimesMap = {
        'Fajr': todayPrayerTimes.fajr,
        'Dhuhr': todayPrayerTimes.dhuhr,
        'Asr': todayPrayerTimes.asr,
        'Maghrib': todayPrayerTimes.maghrib,
        'Isha': todayPrayerTimes.isha,
      };

      // Get current location name
      final locationName = await getCurrentLocationName();

      debugPrint('\n🔄 Notification Settings Changed');
      debugPrint('Master Enabled: ${settings.masterEnabled}');
      debugPrint(
        'Persistent Enabled: ${settings.persistentNotificationEnabled}',
      );
      debugPrint('Location: $locationName');

      // Schedule all prayer notifications
      await _notificationService.schedulePrayerNotifications(
        prayerTimes: prayerTimesMap,
        settings: settings,
        locationName: locationName,
      );

      // Manage persistent notification
      if (settings.persistentNotificationEnabled) {
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
      await loadPrayerTimes();

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
      await loadPrayerTimes();
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
      await loadPrayerTimes();
    } catch (e) {
      emit(PrayerTimesError(e.toString()));
    }
  }

  // Start a timer to update the UI every minute for the countdown
  void _startTimer() {
    _prayerTimesTimer?.cancel();

    _prayerTimesTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (state is PrayerTimesLoaded) {
        final currentState = state as PrayerTimesLoaded;

        // Re-emit the state to update the countdown timer
        emit(
          PrayerTimesLoaded(
            prayerTimes: currentState.prayerTimes,
            selectedDate: currentState.selectedDate,
          ),
        );
      }
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
        await loadPrayerTimes();
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
