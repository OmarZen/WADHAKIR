import 'package:equatable/equatable.dart';

/// Represents a user's bookmark of a hadith
class BookmarkModel extends Equatable {
  final String id; // UUID
  final String hadithId; // Reference to HadithModel.id
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> collectionIds; // User collections this bookmark belongs to
  final String? note; // Personal note about the hadith
  final List<String> tags; // User-defined tags
  final bool isFavorite; // Quick favorite flag

  const BookmarkModel({
    required this.id,
    required this.hadithId,
    required this.createdAt,
    this.updatedAt,
    this.collectionIds = const [],
    this.note,
    this.tags = const [],
    this.isFavorite = false,
  });

  /// Convert to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hadith_id': hadithId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
      'note': note,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  /// Create from SQLite Map
  factory BookmarkModel.fromMap(Map<String, dynamic> map) {
    return BookmarkModel(
      id: map['id'] as String,
      hadithId: map['hadith_id'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
      note: map['note'] as String?,
      isFavorite: (map['is_favorite'] as int) == 1,
    );
  }

  /// Copy with method for updating fields
  BookmarkModel copyWith({
    String? id,
    String? hadithId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? collectionIds,
    String? note,
    List<String>? tags,
    bool? isFavorite,
  }) {
    return BookmarkModel(
      id: id ?? this.id,
      hadithId: hadithId ?? this.hadithId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      collectionIds: collectionIds ?? this.collectionIds,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [
        id,
        hadithId,
        createdAt,
        updatedAt,
        collectionIds,
        note,
        tags,
        isFavorite,
      ];
}
