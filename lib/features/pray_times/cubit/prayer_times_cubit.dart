import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'package:wadhakir/domain/usecases/get_prayer_times_usecase.dart';
import 'package:wadhakir/domain/repositories/prayer_times_repository.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_state.dart';
import 'package:wadhakir/domain/usecases/get_calculation_method_usecase.dart';
import 'package:wadhakir/domain/usecases/get_prayer_times_range_usecase.dart';
import 'package:wadhakir/domain/usecases/set_calculation_method_usecase.dart';

class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  final GetPrayerTimesUseCase _getPrayerTimesUseCase;
  final GetPrayerTimesRangeUseCase _getPrayerTimesRangeUseCase;
  final GetCalculationMethodUseCase _getCalculationMethodUseCase;
  final SetCalculationMethodUseCase _setCalculationMethodUseCase;
  final PrayerTimesRepository _repository;

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
  })  : _repository = repository,
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

      emit(PrayerTimesLoaded(
        prayerTimes: adjustedPrayerTimes,
        selectedDate: today,
      ));

      
      // Start a timer to update the UI every minute for the countdown
      _startTimer();
    } catch (e) {
      emit(PrayerTimesError(e.toString()));
    }
  }

  // Apply time adjustments to all prayer times
  Map<DateTime, PrayerTimesModel> _applyTimeAdjustments(
      Map<DateTime, PrayerTimesModel> prayerTimes) {
    final result = <DateTime, PrayerTimesModel>{};

    prayerTimes.forEach((date, model) {
      result[date] = _applyTimeAdjustmentToModel(model);
    });

    return result;
  }

  // Apply time adjustments to a single prayer times model
  PrayerTimesModel _applyTimeAdjustmentToModel(PrayerTimesModel model) {
    // Apply minutes adjustments to each prayer time
    final adjustedFajr =
        _adjustTime(model.fajr, _timeAdjustments['الفجر'] ?? 0);
    final adjustedSunrise =
        _adjustTime(model.sunrise, _timeAdjustments['الشروق'] ?? 0);
    final adjustedDhuhr =
        _adjustTime(model.dhuhr, _timeAdjustments['الظهر'] ?? 0);
    final adjustedAsr = _adjustTime(model.asr, _timeAdjustments['العصر'] ?? 0);
    final adjustedMaghrib =
        _adjustTime(model.maghrib, _timeAdjustments['المغرب'] ?? 0);
    final adjustedIsha =
        _adjustTime(model.isha, _timeAdjustments['العشاء'] ?? 0);

    // Create a new model with adjusted times
    return PrayerTimesModel(
      fajr: adjustedFajr,
      sunrise: adjustedSunrise,
      dhuhr: adjustedDhuhr,
      asr: adjustedAsr,
      maghrib: adjustedMaghrib,
      isha: adjustedIsha,
      date: model.date,
      calculationMethod: model.calculationMethod,
      coordinates: model.coordinates,
    );
  }

  // Helper to adjust a DateTime by adding minutes
  DateTime _adjustTime(DateTime time, int minutes) {
    return time.add(Duration(minutes: minutes));
  }


  // Refresh prayer times and notifications
  Future<void> refreshPrayerTimes() async {
    await loadPrayerTimes();
  }

 

  // Change the selected date
  void selectDate(DateTime date) async {
    if (state is PrayerTimesLoaded) {
      final currentState = state as PrayerTimesLoaded;

      // Check if we already have this date in our cache
      final dateKey = DateTime(date.year, date.month, date.day);
      if (currentState.prayerTimes.containsKey(dateKey)) {
        emit(PrayerTimesLoaded(
          prayerTimes: currentState.prayerTimes,
          selectedDate: date,
        ));
        return;
      }

      // If not, fetch prayer times for this date
      try {
        final prayerTimesForDate = await _getPrayerTimesUseCase(date: date);

        // Apply time adjustments to the new prayer times
        final adjustedPrayerTimes =
            _applyTimeAdjustmentToModel(prayerTimesForDate);

        // Add the new date to our map
        final updatedPrayerTimes =
            Map<DateTime, PrayerTimesModel>.from(currentState.prayerTimes);
        updatedPrayerTimes[dateKey] = adjustedPrayerTimes;

        emit(PrayerTimesLoaded(
          prayerTimes: updatedPrayerTimes,
          selectedDate: date,
        ));
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
      final previousDate =
          currentState.selectedDate.subtract(const Duration(days: 1));
      selectDate(previousDate);
    }
  }

  // Change calculation method
  Future<void> setCalculationMethod(CalculationMethod method) async {
    try {
      await _setCalculationMethodUseCase(method);

      // Reload prayer times with new method
      await loadPrayerTimes();
    } catch (e) {
      emit(PrayerTimesError(e.toString()));
    }
  }

  // Get the current calculation method
  Future<CalculationMethod> getCalculationMethod() async {
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
        emit(PrayerTimesLoaded(
          prayerTimes: currentState.prayerTimes,
          selectedDate: currentState.selectedDate,
        ));
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
        final Map<String, dynamic> jsonMap =
            Map<String, dynamic>.from(jsonString
                .split(',')
                .map((entry) {
                  final parts = entry.split(':');
                  return MapEntry(parts[0], int.parse(parts[1]));
                })
                .toList()
                .fold({}, (map, entry) {
                  map[entry.key] = entry.value;
                  return map;
                }));

        // Convert to Map<String, int> and update the cache
        _timeAdjustments =
            jsonMap.map((key, value) => MapEntry(key, value as int));

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
        final adjustedPrayerTimes =
            _applyTimeAdjustments(currentState.prayerTimes);

        // Emit updated state
        emit(PrayerTimesLoaded(
          prayerTimes: adjustedPrayerTimes,
          selectedDate: currentState.selectedDate,
        ));
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
      // Here you would get the current location name
      // For now returning a placeholder
      return "المدينة الحالية";
    } catch (e) {
      debugPrint('Error getting current location name: $e');
      return "غير معروف";
    }
  }

  Future<void> updateLocation() async {
    try {
      // Here you would update the location
      // For now just refreshing prayer times
      await refreshPrayerTimes();
    } catch (e) {
      debugPrint('Error updating location: $e');
      throw Exception('فشل تحديث الموقع');
    }
  }

  @override
  Future<void> close() {
    _prayerTimesTimer?.cancel();
    return super.close();
  }
}
