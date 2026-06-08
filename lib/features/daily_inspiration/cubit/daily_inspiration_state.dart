import 'package:equatable/equatable.dart';
import 'package:wadhakir/data/models/daily_inspiration_item.dart';
import 'package:wadhakir/data/models/daily_inspiration_settings_model.dart';

/// Single immutable state for the daily-inspiration feature: the current
/// settings plus today's resolved item (null while loading / when no content).
class DailyInspirationState extends Equatable {
  final DailyInspirationSettingsModel settings;
  final DailyInspirationItem? todayItem;
  final bool loaded;

  const DailyInspirationState({
    required this.settings,
    required this.todayItem,
    required this.loaded,
  });

  factory DailyInspirationState.initial() => DailyInspirationState(
    settings: DailyInspirationSettingsModel.defaultSettings(),
    todayItem: null,
    loaded: false,
  );

  DailyInspirationState copyWith({
    DailyInspirationSettingsModel? settings,
    DailyInspirationItem? todayItem,
    bool? loaded,
  }) {
    return DailyInspirationState(
      settings: settings ?? this.settings,
      todayItem: todayItem ?? this.todayItem,
      loaded: loaded ?? this.loaded,
    );
  }

  @override
  List<Object?> get props => [settings, todayItem, loaded];
}
