class RadioStationModel {
  final int id;
  final String name;
  final String nameEn;
  final String url;
  final String? category;
  final String? categoryEn;

  RadioStationModel({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.url,
    this.category,
    this.categoryEn,
  });

  factory RadioStationModel.fromJson(Map<String, dynamic> json) {
    return RadioStationModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      category: json['category'] as String?,
      categoryEn: json['category_en'] as String?,
    );
  }

  String getLocalizedName(String languageCode) {
    return languageCode == 'en' ? nameEn : name;
  }

  String? getLocalizedCategory(String languageCode) {
    if (category == null) return null;
    return languageCode == 'en' ? (categoryEn ?? category) : category;
  }
}
