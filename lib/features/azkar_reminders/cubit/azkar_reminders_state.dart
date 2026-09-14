import 'package:equatable/equatable.dart';
import 'package:wadhakir/data/models/azkar_reminder_settings_model.dart';

class AzkarRemindersState extends Equatable {
  final AzkarReminderSettingsModel settings;
  final bool loaded;

  const AzkarRemindersState({required this.settings, required this.loaded});

  factory AzkarRemindersState.initial() => AzkarRemindersState(
    settings: AzkarReminderSettingsModel.defaultSettings(),
    loaded: false,
  );

  AzkarRemindersState copyWith({
    AzkarReminderSettingsModel? settings,
    bool? loaded,
  }) {
    return AzkarRemindersState(
      settings: settings ?? this.settings,
      loaded: loaded ?? this.loaded,
    );
  }

  @override
  List<Object?> get props => [settings, loaded];
}
