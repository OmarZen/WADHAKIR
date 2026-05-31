import 'dart:math' as math;

class MosqueModel {
  final String id;
  final String name;
  final MosqueAddress address;
  final MosqueLocation location;
  final MosqueTimings timings;

  MosqueModel({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.timings,
  });

  factory MosqueModel.fromJson(Map<String, dynamic> json) {
    return MosqueModel(
      id: json['_id'] as String? ?? '',
      name: json['masjidName'] as String? ?? 'Unknown Masjid',
      address: MosqueAddress.fromJson(
        json['masjidAddress'] as Map<String, dynamic>? ?? {},
      ),
      location: MosqueLocation.fromJson(
        json['masjidLocation'] as Map<String, dynamic>? ?? {},
      ),
      timings: MosqueTimings.fromJson(
        json['masjidTimings'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  /// Build a MosqueModel from an OpenStreetMap Overpass API element.
  /// Overpass tags are bilingual (`name:ar`, `name:en`) so we can surface the
  /// localised name based on the user's UI language. The element is either a
  /// `node` (with `lat`/`lon` directly) or a `way`/`relation` (with `center`).
  /// Returns `null` if the element has no usable coordinates.
  static MosqueModel? fromOverpassElement(
    Map<String, dynamic> element, {
    String preferredLanguage = 'ar',
  }) {
    final tags = (element['tags'] as Map?)?.cast<String, dynamic>() ?? {};

    double? lat;
    double? lon;
    if (element['lat'] != null && element['lon'] != null) {
      lat = (element['lat'] as num?)?.toDouble();
      lon = (element['lon'] as num?)?.toDouble();
    } else if (element['center'] is Map) {
      final center = element['center'] as Map;
      lat = (center['lat'] as num?)?.toDouble();
      lon = (center['lon'] as num?)?.toDouble();
    }
    if (lat == null || lon == null) return null;

    String? pickLocalisedName() {
      final key = 'name:$preferredLanguage';
      final localised = tags[key];
      if (localised is String && localised.isNotEmpty) return localised;
      // Fall back to Arabic, then English, then the unqualified `name`.
      for (final k in ['name:ar', 'name:en', 'name']) {
        final v = tags[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return null;
    }

    final name = pickLocalisedName() ?? 'مسجد';
    final id = '${element['type'] ?? 'node'}/${element['id'] ?? ''}';

    final address = MosqueAddress(
      description: '',
      street: (tags['addr:street'] as String?) ?? '',
      zipcode: (tags['addr:postcode'] as String?) ?? '',
      country: (tags['addr:country'] as String?) ?? '',
      state: (tags['addr:state'] as String?) ?? '',
      city: (tags['addr:city'] as String?) ?? '',
      locality: (tags['addr:suburb'] as String?) ?? '',
      phone:
          (tags['contact:phone'] as String?) ??
          (tags['phone'] as String?) ??
          '',
      googlePlaceId: '',
    );

    return MosqueModel(
      id: id,
      name: name,
      address: address,
      location: MosqueLocation(type: 'Point', latitude: lat, longitude: lon),
      timings: MosqueTimings(
        fajr: '',
        zuhr: '',
        asr: '',
        maghrib: '',
        isha: '',
        jumah: '',
      ),
    );
  }

  /// Calculate distance from a given point in kilometers
  double distanceFromPoint(double lat, double lng) {
    return _calculateDistance(lat, lng, location.latitude, location.longitude);
  }

  /// Calculate distance between two points using Haversine formula
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}

class MosqueAddress {
  final String description;
  final String street;
  final String zipcode;
  final String country;
  final String state;
  final String city;
  final String locality;
  final String phone;
  final String googlePlaceId;

  MosqueAddress({
    required this.description,
    required this.street,
    required this.zipcode,
    required this.country,
    required this.state,
    required this.city,
    required this.locality,
    required this.phone,
    required this.googlePlaceId,
  });

  factory MosqueAddress.fromJson(Map<String, dynamic> json) {
    return MosqueAddress(
      description: json['description'] as String? ?? '',
      street: json['street'] as String? ?? '',
      zipcode: json['zipcode'] as String? ?? '',
      country: json['country'] as String? ?? '',
      state: json['state'] as String? ?? '',
      city: json['city'] as String? ?? '',
      locality: json['locality'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      googlePlaceId: json['googlePlaceId'] as String? ?? '',
    );
  }

  /// Get formatted address string
  String get formattedAddress {
    final parts = <String>[];

    if (description.isNotEmpty) parts.add(description);
    if (street.isNotEmpty) parts.add(street);
    if (locality.isNotEmpty) parts.add(locality);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (zipcode.isNotEmpty) parts.add(zipcode);

    return parts.isEmpty ? 'Address not available' : parts.join(', ');
  }
}

class MosqueLocation {
  final String type;
  final double longitude;
  final double latitude;

  MosqueLocation({
    required this.type,
    required this.longitude,
    required this.latitude,
  });

  factory MosqueLocation.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'] as List<dynamic>? ?? [0.0, 0.0];
    return MosqueLocation(
      type: json['type'] as String? ?? 'Point',
      longitude: (coordinates[0] as num?)?.toDouble() ?? 0.0,
      latitude: (coordinates[1] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MosqueTimings {
  final String fajr;
  final String zuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String jumah;

  MosqueTimings({
    required this.fajr,
    required this.zuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.jumah,
  });

  factory MosqueTimings.fromJson(Map<String, dynamic> json) {
    return MosqueTimings(
      fajr: json['fajr'] as String? ?? '',
      zuhr: json['zuhr'] as String? ?? '',
      asr: json['asr'] as String? ?? '',
      maghrib: json['maghrib'] as String? ?? '',
      isha: json['isha'] as String? ?? '',
      jumah: json['jumah'] as String? ?? '',
    );
  }

  /// Check if any prayer time is available
  bool get hasTimings {
    return fajr.isNotEmpty ||
        zuhr.isNotEmpty ||
        asr.isNotEmpty ||
        maghrib.isNotEmpty ||
        isha.isNotEmpty ||
        jumah.isNotEmpty;
  }
}
