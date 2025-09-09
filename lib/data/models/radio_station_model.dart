class RadioStationModel {
  final int id;
  final String name;
  final String url;

  RadioStationModel({required this.id, required this.name, required this.url});

  factory RadioStationModel.fromJson(Map<String, dynamic> json) {
    return RadioStationModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }
}
