import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wadhakir/data/models/radio_station_model.dart';
import 'package:wadhakir/domain/repositories/radio_repository.dart';

class RadioRepositoryImpl implements RadioRepository {
  static const String _baseUrl = 'https://mp3quran.net/api/v3/radios';

  @override
  Future<List<RadioStationModel>> fetchRadios({String? language}) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        if (language != null && language.isNotEmpty) 'language': language,
      },
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load radios (${response.statusCode})');
    }

    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    final List<dynamic> list = data['radios'] as List<dynamic>? ?? [];
    return list
        .map((e) => RadioStationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
