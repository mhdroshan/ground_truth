import '../utils/geofence_math.dart';

enum EventCategory {
  protest('Protest'),
  naturalDisaster('Natural Disaster'),
  war('War / Conflict'),
  fire('Fire Emergency'),
  election('Election'),
  accident('Accident'),
  crime('Crime'),
  weather('Extreme Weather'),
  publicGathering('Public Gathering'),
  breakingNews('Breaking News');

  final String label;
  const EventCategory(this.label);
}

enum EventScope {
  cityWide(
    'City Wide',
    'City-Wide Scope',
    'Local venue, neighborhood, municipal area, or metro center',
    0.5,
    30.0,
    0.3,
    20.0,
  ),
  stateWide(
    'State Wide',
    'State-Wide Scope',
    'Regional disaster, state-wide demonstrations, or multi-district movement',
    10.0,
    350.0,
    6.0,
    220.0,
  ),
  nationWide(
    'Nation Wide',
    'Nation-Wide Scope',
    'Federal election, nationwide crisis, extreme weather front, or country-wide event',
    50.0,
    3000.0,
    30.0,
    1800.0,
  );

  final String label;
  final String title;
  final String description;
  final double minKm;
  final double maxKm;
  final double minMi;
  final double maxMi;

  const EventScope(
    this.label,
    this.title,
    this.description,
    this.minKm,
    this.maxKm,
    this.minMi,
    this.maxMi,
  );
}

enum RiskLevel {
  critical('CRITICAL RISK', 0xFFEF4444),
  high('HIGH RISK', 0xFFFF9F43),
  moderate('MODERATE RISK', 0xFFEAB308),
  low('LOW RISK', 0xFF10B981);

  final String label;
  final int colorValue;
  const RiskLevel(this.label, this.colorValue);
}

enum EventStatus {
  live('LIVE EVENT'),
  breaking('BREAKING'),
  active('ACTIVE'),
  monitoring('MONITORING'),
  concluded('CONCLUDED');

  final String label;
  const EventStatus(this.label);
}

class EventModel {
  final String id;
  final String title;
  final String tagName; // e.g., "#DelhiProtest"
  final String description;
  final EventCategory category;
  final EventScope scope;
  final RiskLevel riskLevel;
  final EventStatus status;
  final String city;
  final String country;
  final GeoPoint center;
  final double radiusMeters;
  final String radiusUnit; // 'km' or 'mi'
  final List<GeoPoint> polygonVertices;
  final String bannerImageUrl;
  final DateTime startTime;
  final DateTime? endTime;
  final int activeContributors;
  final int totalPosts;
  final int totalVideos;
  final String verificationLevel;
  final bool isTrending;
  final bool isHighActivity;

  EventModel({
    required this.id,
    required this.title,
    String? tagName,
    required this.description,
    required this.category,
    this.scope = EventScope.cityWide,
    required this.riskLevel,
    required this.status,
    required this.city,
    required this.country,
    required this.center,
    required this.radiusMeters,
    this.radiusUnit = 'km',
    this.polygonVertices = const [],
    required this.bannerImageUrl,
    required this.startTime,
    this.endTime,
    required this.activeContributors,
    required this.totalPosts,
    required this.totalVideos,
    this.verificationLevel = 'Multi-Layer Level 3 Enforced',
    this.isTrending = false,
    this.isHighActivity = false,
  }) : tagName = tagName ?? (title.startsWith('#') ? title : '#${title.replaceAll(' ', '')}');

  factory EventModel.fromJson(Map<String, dynamic> json) {
    // Parse coordinates [lng, lat]
    final centerData = json['center'];
    double lat = 28.6274;
    double lng = 77.2185;
    if (centerData is Map && centerData['coordinates'] is List) {
      final coords = centerData['coordinates'] as List;
      if (coords.length >= 2) {
        lng = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      }
    } else if (json['latitude'] != null && json['longitude'] != null) {
      lat = (json['latitude'] as num).toDouble();
      lng = (json['longitude'] as num).toDouble();
    }

    // Category
    EventCategory cat = EventCategory.breakingNews;
    final catStr = (json['category'] as String?)?.toLowerCase() ?? '';
    for (final c in EventCategory.values) {
      if (c.label.toLowerCase() == catStr || c.name.toLowerCase() == catStr) {
        cat = c;
        break;
      }
    }

    // Scope
    EventScope scp = EventScope.cityWide;
    final scpStr = (json['scope'] as String?)?.toLowerCase() ?? '';
    for (final s in EventScope.values) {
      if (s.label.toLowerCase() == scpStr ||
          s.name.toLowerCase() == scpStr ||
          scpStr.replaceAll('-', ' ').contains(s.label.toLowerCase())) {
        scp = s;
        break;
      }
    }

    // RiskLevel
    RiskLevel rsk = RiskLevel.high;
    final rskStr = (json['riskLevel'] as String?)?.toUpperCase() ?? '';
    for (final r in RiskLevel.values) {
      if (r.label.toUpperCase() == rskStr || r.name.toUpperCase() == rskStr) {
        rsk = r;
        break;
      }
    }

    // Status
    EventStatus st = EventStatus.live;
    final stStr = (json['status'] as String?)?.toUpperCase() ?? '';
    for (final s in EventStatus.values) {
      if (s.label.toUpperCase() == stStr || s.name.toUpperCase() == stStr) {
        st = s;
        break;
      }
    }

    // Polygon
    List<GeoPoint> poly = [];
    if (json['geofencePolygon'] is Map && json['geofencePolygon']['coordinates'] is List) {
      final rings = json['geofencePolygon']['coordinates'] as List;
      if (rings.isNotEmpty && rings[0] is List) {
        for (final pt in (rings[0] as List)) {
          if (pt is List && pt.length >= 2) {
            poly.add(GeoPoint((pt[1] as num).toDouble(), (pt[0] as num).toDouble()));
          }
        }
      }
    }

    final id = json['_id'] ?? json['id'] ?? '';
    final title = json['title'] ?? 'Untitled Tag';
    final tagName = json['tagName'] as String?;

    return EventModel(
      id: id.toString(),
      title: title,
      tagName: tagName,
      description: json['description'] ?? '',
      category: cat,
      scope: scp,
      riskLevel: rsk,
      status: st,
      city: json['city'] ?? 'Metro Region',
      country: json['country'] ?? 'Global',
      center: GeoPoint(lat, lng, json['city']),
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 2000.0,
      radiusUnit: json['radiusUnit'] ?? 'km',
      polygonVertices: poly,
      bannerImageUrl: json['bannerImageUrl'] ??
          'https://images.unsplash.com/photo-1541872703-74c5e44368f9?w=800&auto=format&fit=crop&q=80',
      startTime: DateTime.tryParse(json['startTime'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime']) : null,
      activeContributors: (json['activeContributors'] as num?)?.toInt() ?? 1,
      totalPosts: (json['totalPosts'] as num?)?.toInt() ?? 0,
      totalVideos: (json['totalVideos'] as num?)?.toInt() ?? 0,
      verificationLevel: json['verificationLevel'] ?? 'Multi-Layer Level 3 Enforced',
      isTrending: json['isTrending'] ?? false,
      isHighActivity: json['isHighActivity'] ?? false,
    );
  }

  double get radiusKm => radiusMeters / 1000.0;
  double get radiusMiles => radiusMeters / 1609.344;

  String get formattedRadius => radiusUnit == 'mi'
      ? '${radiusMiles.toStringAsFixed(radiusMiles < 10 ? 1 : 0)} mi'
      : '${radiusKm.toStringAsFixed(radiusKm < 10 ? 1 : 0)} km';

  String get cleanLocation {
    String cleanCity = city.replaceAll(RegExp(r',?\s*verified ground\s*', caseSensitive: false), '').trim();
    if (cleanCity.endsWith(',')) {
      cleanCity = cleanCity.substring(0, cleanCity.length - 1).trim();
    }
    String cleanCountry = country.replaceAll(RegExp(r',?\s*verified ground\s*', caseSensitive: false), '').trim();
    if (cleanCountry.endsWith(',')) {
      cleanCountry = cleanCountry.substring(0, cleanCountry.length - 1).trim();
    }
    final isVGround = cleanCountry.toLowerCase() == 'verified ground' || cleanCountry.toLowerCase() == 'live';

    if (cleanCountry.isNotEmpty && !isVGround && !cleanCity.toLowerCase().contains(cleanCountry.toLowerCase())) {
      if (cleanCity.isEmpty) return cleanCountry;
      return '$cleanCity, $cleanCountry';
    }
    return cleanCity.isNotEmpty ? cleanCity : (isVGround ? '' : cleanCountry);
  }

  bool isUserInside(GeoPoint userLocation) {
    if (polygonVertices.isNotEmpty && polygonVertices.length >= 3) {
      return GeofenceMath.isPointInPolygon(userLocation, polygonVertices) ||
          GeofenceMath.isPointInCircle(userLocation, center, radiusMeters);
    }
    return GeofenceMath.isPointInCircle(userLocation, center, radiusMeters);
  }

  double distanceFromUser(GeoPoint userLocation) {
    if (polygonVertices.isNotEmpty) {
      return GeofenceMath.distanceToNearestPoint(userLocation, polygonVertices);
    }
    return GeofenceMath.distanceBetweenMeters(
      userLocation.latitude,
      userLocation.longitude,
      center.latitude,
      center.longitude,
    );
  }
}
