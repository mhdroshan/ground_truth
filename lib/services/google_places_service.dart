import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/geofence_math.dart';
import 'api_service.dart';

class PlacePrediction {
  final String placeId;
  final String text;
  final String mainText;
  final String secondaryText;
  final List<String> types;

  PlacePrediction({
    required this.placeId,
    required this.text,
    required this.mainText,
    required this.secondaryText,
    this.types = const [],
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['placeId'] ?? '',
      text: json['text'] ?? '',
      mainText: json['mainText'] ?? '',
      secondaryText: json['secondaryText'] ?? '',
      types: (json['types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class GooglePlacesService {
  static const String apiKey = 'AIzaSyBycwvUgtnMcL03IkDesXju5vc18IjAWqM';

  /// Fetch autocomplete suggestions
  /// First attempts proxy via local backend (/api/places/autocomplete).
  /// Falls back to direct Google Places API (New) if backend is unreachable.
  static Future<List<PlacePrediction>> getAutocomplete(String input) async {
    if (input.trim().isEmpty) return [];

    // 1. Try Backend Proxy
    try {
      final backendUrl = Uri.parse('${ApiService.baseUrl}/places/autocomplete?query=${Uri.encodeComponent(input.trim())}');
      final response = await http.get(backendUrl).timeout(const Duration(milliseconds: 2500));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['suggestions'] as List<dynamic>?) ?? [];
        return list.map((item) => PlacePrediction.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Backend places proxy error/skipped: $e');
    }

    // 2. Direct Fallback to Google Places (New) API
    try {
      final url = Uri.parse('https://places.googleapis.com/v1/places:autocomplete');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
        },
        body: json.encode({
          'input': input.trim(),
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final suggestions = (data['suggestions'] as List<dynamic>?) ?? [];
        return suggestions.map((s) {
          final pred = s['placePrediction'] ?? {};
          final textObj = pred['text'] ?? {};
          final structured = pred['structuredFormat'] ?? {};
          return PlacePrediction(
            placeId: (pred['placeId'] as String?) ??
                (pred['place'] as String?)?.replaceFirst('places/', '') ?? '',
            text: textObj['text'] ?? '',
            mainText: structured['mainText']?['text'] ?? textObj['text'] ?? '',
            secondaryText: structured['secondaryText']?['text'] ?? '',
            types: (pred['types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Direct Google Places API autocomplete error: $e');
    }

    return [];
  }

  /// Fetch place details (latitude, longitude, name, formatted address)
  static Future<GeoPoint?> getPlaceDetails(String placeId) async {
    if (placeId.isEmpty) return null;

    final cleanId = placeId.startsWith('places/') ? placeId.replaceFirst('places/', '') : placeId;

    // 1. Try Backend Proxy
    try {
      final backendUrl = Uri.parse('${ApiService.baseUrl}/places/details?placeId=${Uri.encodeComponent(cleanId)}');
      final response = await http.get(backendUrl).timeout(const Duration(milliseconds: 2500));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final double? lat = (data['latitude'] as num?)?.toDouble();
        final double? lng = (data['longitude'] as num?)?.toDouble();
        final String name = data['name'] ?? data['formattedAddress'] ?? 'Selected Place';
        if (lat != null && lng != null) {
          return GeoPoint(lat, lng, name);
        }
      }
    } catch (e) {
      debugPrint('Backend places details proxy error/skipped: $e');
    }

    // 2. Direct Fallback to Google Places (New) API
    try {
      final url = Uri.parse('https://places.googleapis.com/v1/places/$cleanId?fields=id,displayName,formattedAddress,location&key=$apiKey');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final loc = data['location'] ?? {};
        final double? lat = (loc['latitude'] as num?)?.toDouble();
        final double? lng = (loc['longitude'] as num?)?.toDouble();
        final String name = data['displayName']?['text'] ?? data['formattedAddress'] ?? 'Selected Place';
        if (lat != null && lng != null) {
          return GeoPoint(lat, lng, name);
        }
      }
    } catch (e) {
      debugPrint('Direct Google Places API details error: $e');
    }

    return null;
  }
}
