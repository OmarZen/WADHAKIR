import 'package:equatable/equatable.dart';

/// Represents a user-created collection of bookmarks
class UserCollectionModel extends Equatable {
  final String id; // UUID
  final String name;
  final String? description;
  final String icon; // Emoji or icon name
  final String color; // Hex color code
  final DateTime createdAt;
  final int bookmarkCount; // Cached count
  final bool isDefault; // Favorites is default collection

  const UserCollectionModel({
    required this.id,
    required this.name,
    this.description,
    this.icon = '📚',
    this.color = '#3B82F6',
    required this.createdAt,
    this.bookmarkCount = 0,
    this.isDefault = false,
  });

  /// Default Favorites collection
  static UserCollectionModel favorites() {
    return UserCollectionModel(
      id: 'favorites',
      name: 'Favorites',
      icon: '⭐',
      color: '#FFD700',
      createdAt: DateTime.now(),
      isDefault: true,
    );
  }

  /// Convert to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'created_at': createdAt.millisecondsSinceEpoch,
      'is_default': isDefault ? 1 : 0,
    };
  }

  /// Create from SQLite Map
  factory UserCollectionModel.fromMap(Map<String, dynamic> map) {
    return UserCollectionModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      icon: map['icon'] as String? ?? '📚',
      color: map['color'] as String? ?? '#3B82F6',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      bookmarkCount: map['bookmark_count'] as int? ?? 0,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
    );
  }

  /// Copy with method for updating fields
  UserCollectionModel copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    DateTime? createdAt,
    int? bookmarkCount,
    bool? isDefault,
  }) {
    return UserCollectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      bookmarkCount: bookmarkCount ?? this.bookmarkCount,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    icon,
    color,
    createdAt,
    bookmarkCount,
    isDefault,
  ];
}
