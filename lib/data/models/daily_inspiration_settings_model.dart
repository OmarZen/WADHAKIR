import 'package:equatable/equatable.dart';
import 'package:wadhakir/data/models/daily_inspiration_item.dart';

/// User preferences for the "Verse/Dua of the Day" feature.
///
/// [enabled] controls only the daily notification — the home card and the
/// home-screen widget always surface today's item regardless.
class DailyInspirationSettingsModel extends Equatable {
  final bool enabled;
  final int hour;
  final int minute;
  final DailyContentType contentType;

  const DailyInspirationSettingsModel({
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.contentType,
  });

  factory DailyInspirationSettingsModel.defaultSettings() {
    return const DailyInspirationSettingsModel(
      enabled: false,
      hour: 8,
      minute: 0,
      contentType: DailyContentType.mixed,
    );
  }

  DailyInspirationSettingsModel copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    DailyContentType? contentType,
  }) {
    return DailyInspirationSettingsModel(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      contentType: contentType ?? this.contentType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'hour': hour,
      'minute': minute,
      'contentType': contentType.index,
    };
  }

  factory DailyInspirationSettingsModel.fromJson(Map<String, dynamic> json) {
    final typeIndex =
        json['contentType'] as int? ?? DailyContentType.mixed.index;
    return DailyInspirationSettingsModel(
      enabled: json['enabled'] as bool? ?? false,
      hour: json['hour'] as int? ?? 8,
      minute: json['minute'] as int? ?? 0,
      contentType: DailyContentType.values[typeIndex.clamp(
        0,
        DailyContentType.values.length - 1,
      )],
    );
  }

  @override
  List<Object?> get props => [enabled, hour, minute, contentType];
}
