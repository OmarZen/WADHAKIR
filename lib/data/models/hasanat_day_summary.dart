import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'hasanat_day_summary.g.dart';

@HiveType(typeId: 4)
class HasanatDaySummary extends Equatable {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final int totalPoints;

  @HiveField(2)
  final int completedItems;

  @HiveField(3)
  final Map<String, int> pointsByCategory; // Maps category name to points

  const HasanatDaySummary({
    required this.date,
    required this.totalPoints,
    required this.completedItems,
    required this.pointsByCategory,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.millisecondsSinceEpoch,
      'totalPoints': totalPoints,
      'completedItems': completedItems,
      'pointsByCategory': pointsByCategory,
    };
  }

  factory HasanatDaySummary.fromJson(Map<String, dynamic> json) {
    Map<String, int> pointsByCategoryMap = {};

    if (json.containsKey('pointsByCategory')) {
      final Map<String, dynamic> map = json['pointsByCategory'];
      map.forEach((key, value) {
        pointsByCategoryMap[key] = value as int;
      });
    }

    return HasanatDaySummary(
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      totalPoints: json['totalPoints'],
      completedItems: json['completedItems'],
      pointsByCategory: pointsByCategoryMap,
    );
  }

  // Empty summary for a day with no records
  factory HasanatDaySummary.empty(DateTime date) {
    return HasanatDaySummary(
      date: date,
      totalPoints: 0,
      completedItems: 0,
      pointsByCategory: {},
    );
  }

  @override
  List<Object> get props =>
      [date, totalPoints, completedItems, pointsByCategory];
}
