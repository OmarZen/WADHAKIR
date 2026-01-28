import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:wadhakir/data/models/radio_station_model.dart';
import 'package:wadhakir/domain/repositories/radio_repository.dart';

class RadioRepositoryImpl implements RadioRepository {
  @override
  Future<List<RadioStationModel>> fetchRadios({String? language}) async {
    // Load from local JSON file with bilingual support
    final String jsonString = await rootBundle.loadString(
      'lib/features/radio/api_response.json',
    );

    final Map<String, dynamic> data =
        json.decode(jsonString) as Map<String, dynamic>;
    final List<dynamic> list = data['radios'] as List<dynamic>? ?? [];
    return list
        .map((e) => RadioStationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
