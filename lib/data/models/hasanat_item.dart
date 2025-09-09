import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'hasanat_item.g.dart';

@HiveType(typeId: 1)
enum HasanatCategory {
  @HiveField(0)
  fard, // فرائض
  @HiveField(1)
  sunnah, // سنن
  @HiveField(2)
  nafl, // نوافل
  @HiveField(3)
  other // أخرى
}

@HiveType(typeId: 2)
class HasanatItem extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final int points;

  @HiveField(4)
  final HasanatCategory category;

  @HiveField(5)
  final bool isDefault; // If true, this is a default item that can't be deleted

  const HasanatItem({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.category,
    this.isDefault = false,
  });

  HasanatItem copyWith({
    String? id,
    String? title,
    String? description,
    int? points,
    HasanatCategory? category,
    bool? isDefault,
  }) {
    return HasanatItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      points: points ?? this.points,
      category: category ?? this.category,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points': points,
      'category': category.toString().split('.').last,
      'isDefault': isDefault,
    };
  }

  factory HasanatItem.fromJson(Map<String, dynamic> json) {
    return HasanatItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      points: json['points'],
      category: HasanatCategory.values.firstWhere(
        (c) => c.toString().split('.').last == json['category'],
        orElse: () => HasanatCategory.other,
      ),
      isDefault: json['isDefault'] ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, description, points, category, isDefault];
}
