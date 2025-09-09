import 'package:wadhakir/data/models/azkar_item.dart';

class AzkarCategory {
  final int id;
  final String title;
  final String? audio;
  final String? filename;
  final List<AdhkarItem> items;

  AzkarCategory({
    required this.id,
    required this.title,
    this.audio,
    this.filename,
    required this.items,
  });

  factory AzkarCategory.fromAdhkarJson(Map<String, dynamic> json) {
    final List<AdhkarItem> items = [];
    if (json['array'] != null) {
      for (var item in json['array']) {
        items.add(AdhkarItem.fromJson(item));
      }
    }

    return AzkarCategory(
      id: json['id'] as int,
      title: json['category'] as String,
      audio: json['audio'] as String?,
      filename: json['filename'] as String?,
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': title,
      'audio': audio,
      'filename': filename,
      'array': items.map((item) => item.toJson()).toList(),
    };
  }
}
