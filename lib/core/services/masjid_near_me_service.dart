import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/mosque_model.dart';

class MasjidNearMeService {
  static const String _baseUrl = 'https://api.masjidnear.me/v1/masjids';
  static const int _defaultRadiusMeters = 2000;

  /// Search for mosques by coordinates (latitude and longitude)
  /// [lat] - Latitude of the search location
  /// [lng] - Longitude of the search location
  /// [radius] - Search radius in meters (default: 2000m = 2km)
  Future<List<MosqueModel>> searchByCoordinates({
    required double lat,
    required double lng,
    int radius = _defaultRadiusMeters,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'lat': lat.toString(),
          'lng': lng.toString(),
          'radius': radius.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;

        if (jsonData['code'] == 200 && jsonData['status'] == 'OK') {
          final data = jsonData['data'] as Map<String, dynamic>?;
          final masjids = data?['masjids'] as List<dynamic>? ?? [];

          final mosques = masjids
              .map((m) => MosqueModel.fromJson(m as Map<String, dynamic>))
              .toList();

          // Sort by distance from search point
          mosques.sort((a, b) {
            final distA = a.distanceFromPoint(lat, lng);
            final distB = b.distanceFromPoint(lat, lng);
            return distA.compareTo(distB);
          });

          return mosques;
        } else {
          throw Exception(
              'API returned error: ${jsonData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to fetch mosques. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching mosques: $e');
    }
  }

  /// Search for mosques by name
  /// [name] - Name of the mosque to search for
  Future<List<MosqueModel>> searchByName(String name) async {
    try {
      final uri = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'name': name,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;

        if (jsonData['code'] == 200 && jsonData['status'] == 'OK') {
          final data = jsonData['data'] as Map<String, dynamic>?;
          final masjids = data?['masjids'] as List<dynamic>? ?? [];

          return masjids
              .map((m) => MosqueModel.fromJson(m as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(
              'API returned error: ${jsonData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to fetch mosques. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching mosques: $e');
    }
  }

  /// Search for mosques by city
  /// [city] - Name of the city to search in
  Future<List<MosqueModel>> searchByCity(String city) async {
    try {
      final uri = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'city': city,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;

        if (jsonData['code'] == 200 && jsonData['status'] == 'OK') {
          final data = jsonData['data'] as Map<String, dynamic>?;
          final masjids = data?['masjids'] as List<dynamic>? ?? [];

          return masjids
              .map((m) => MosqueModel.fromJson(m as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(
              'API returned error: ${jsonData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to fetch mosques. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching mosques: $e');
    }
  }
}
