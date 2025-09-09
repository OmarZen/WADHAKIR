import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'hasanat_record.g.dart';

@HiveType(typeId: 3)
class HasanatRecord extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String itemId;

  @HiveField(3)
  final int points;

  @HiveField(4)
  final String notes; // Optional notes

  const HasanatRecord({
    required this.id,
    required this.date,
    required this.itemId,
    required this.points,
    this.notes = '',
  });

  HasanatRecord copyWith({
    String? id,
    DateTime? date,
    String? itemId,
    int? points,
    String? notes,
  }) {
    return HasanatRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      itemId: itemId ?? this.itemId,
      points: points ?? this.points,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'itemId': itemId,
      'points': points,
      'notes': notes,
    };
  }

  factory HasanatRecord.fromJson(Map<String, dynamic> json) {
    return HasanatRecord(
      id: json['id'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      itemId: json['itemId'],
      points: json['points'],
      notes: json['notes'] ?? '',
    );
  }

  @override
  List<Object> get props => [id, date, itemId, points, notes];
}
