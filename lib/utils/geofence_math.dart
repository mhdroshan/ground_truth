import 'dart:math';

class GeoPoint {
  final double latitude;
  final double longitude;
  final String? label;

  const GeoPoint(this.latitude, this.longitude, [this.label]);

  @override
  String toString() => '$latitude, $longitude';
}

class GeofenceMath {
  static const double earthRadiusMeters = 6371000.0;

  /// Haversine distance between two coordinates in meters
  static double distanceBetweenMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Check if a coordinate is inside a polygon using ray-casting algorithm
  static bool isPointInPolygon(GeoPoint point, List<GeoPoint> polygon) {
    if (polygon.length < 3) return false;

    bool isInside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final pi = polygon[i];
      final pj = polygon[j];

      final intersect = ((pi.longitude > point.longitude) != (pj.longitude > point.longitude)) &&
          (point.latitude <
              (pj.latitude - pi.latitude) *
                      (point.longitude - pi.longitude) /
                      (pj.longitude - pi.longitude) +
                  pi.latitude);

      if (intersect) {
        isInside = !isInside;
      }
      j = i;
    }

    return isInside;
  }

  /// Check if point is inside a circular geofence
  static bool isPointInCircle(
    GeoPoint userPoint,
    GeoPoint center,
    double radiusMeters,
  ) {
    final distance = distanceBetweenMeters(
      userPoint.latitude,
      userPoint.longitude,
      center.latitude,
      center.longitude,
    );
    return distance <= radiusMeters;
  }

  /// Calculates shortest distance from point to polygon vertices or center
  static double distanceToNearestPoint(GeoPoint point, List<GeoPoint> points) {
    if (points.isEmpty) return 0;
    double minDistance = double.infinity;
    for (final p in points) {
      final d = distanceBetweenMeters(
        point.latitude,
        point.longitude,
        p.latitude,
        p.longitude,
      );
      if (d < minDistance) {
        minDistance = d;
      }
    }
    return minDistance;
  }

  /// Format distance into human-readable string
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }
}
