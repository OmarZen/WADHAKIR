import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../data/models/mosque_model.dart';

class MasjidNearMeService {
  static const String _baseUrl = 'https://api.masjidnear.me/v1/masjids';
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const int _defaultRadiusMeters = 2000;

  /// In-memory cache so we don't hammer Overpass — keyed by quantised
  /// lat/lng/radius. Entries expire after one hour.
  static final Map<String, _CachedResult> _overpassCache = {};

  /// Search mosques near a coordinate using OpenStreetMap's Overpass API.
  /// OSM tags include localised names (`name:ar`, `name:en`) so results stay
  /// usable in Arabic regions where the legacy English-biased API returns
  /// poor matches. Falls back to the masjidnear.me API on failure.
  Future<List<MosqueModel>> searchNearby({
    required double lat,
    required double lng,
    int radius = _defaultRadiusMeters,
    String preferredLanguage = 'ar',
  }) async {
    final cacheKey = '${lat.toStringAsFixed(3)},'
        '${lng.toStringAsFixed(3)},$radius';
    final cached = _overpassCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.mosques;
    }

    try {
      final query = '''
[out:json][timeout:25];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,$lat,$lng);
  way["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,$lat,$lng);
  relation["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,$lat,$lng);
);
out center tags;
''';

      final response = await http.post(
        Uri.parse(_overpassUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'data': query},
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Overpass returned ${response.statusCode}');
      }

      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final elements = (jsonData['elements'] as List?) ?? [];

      final mosques = <MosqueModel>[];
      for (final element in elements) {
        if (element is! Map) continue;
        final model = MosqueModel.fromOverpassElement(
          element.cast<String, dynamic>(),
          preferredLanguage: preferredLanguage,
        );
        if (model != null) mosques.add(model);
      }

      mosques.sort((a, b) {
        final distA = a.distanceFromPoint(lat, lng);
        final distB = b.distanceFromPoint(lat, lng);
        return distA.compareTo(distB);
      });

      _overpassCache[cacheKey] = _CachedResult(mosques);
      return mosques;
    } catch (e) {
      debugPrint('Overpass mosque search failed, falling back: $e');
      // Fall back to the legacy English-biased API so the feature still
      // returns *something* rather than erroring out.
      try {
        return await searchByCoordinates(lat: lat, lng: lng, radius: radius);
      } catch (fallbackError) {
        throw Exception('Mosque search failed: $fallbackError');
      }
    }
  }

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
      ).timeout(const Duration(seconds: 15));

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
            'API returned error: ${jsonData['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to fetch mosques. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching mosques: $e');
    }
  }

  /// Search for mosques by name
  /// [name] - Name of the mosque to search for
  Future<List<MosqueModel>> searchByName(String name) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/search',
      ).replace(queryParameters: {'name': name});

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

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
            'API returned error: ${jsonData['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to fetch mosques. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching mosques: $e');
    }
  }

  /// Search for mosques by city
  /// [city] - Name of the city to search in
  Future<List<MosqueModel>> searchByCity(String city) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/search',
      ).replace(queryParameters: {'city': city});

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

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
            'API returned error: ${jsonData['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to fetch mosques. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching mosques: $e');
    }
  }
}

class _CachedResult {
  static const Duration _ttl = Duration(hours: 1);

  final List<MosqueModel> mosques;
  final DateTime fetchedAt;

  _CachedResult(this.mosques) : fetchedAt = DateTime.now();

  bool get isExpired => DateTime.now().difference(fetchedAt) > _ttl;
}
