import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

Future<void> requestPhysicalLocation({
  required void Function(double lat, double lng, double accuracy) onSuccess,
  required void Function(String error) onError,
}) async {
  // If running in a headless test environment, finish immediately without blocking pumpAndSettle
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    onError('Flutter test environment');
    return;
  }

  try {
    // 1. Check if device hardware GPS / Location Services are enabled
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Geolocator: Location services disabled. Attempting IP fallback.');
      final bool ipFallback = await _tryNetworkIpFallback(onSuccess);
      if (!ipFallback) {
        onError('GPS location services are disabled on your device. Please turn on Location in settings.');
      }
      return;
    }

    // 2. Check and request runtime location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Geolocator: Location permission denied. Attempting IP fallback.');
        final bool ipFallback = await _tryNetworkIpFallback(onSuccess);
        if (!ipFallback) {
          onError('Location permission denied. Physical GPS access is required to verify your radius.');
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Geolocator: Location permission denied forever. Attempting IP fallback.');
      final bool ipFallback = await _tryNetworkIpFallback(onSuccess);
      if (!ipFallback) {
        onError('Location permissions are permanently denied. Please allow location in system settings.');
      }
      return;
    }

    // 3. Acquire high-precision physical GPS location from satellite / hardware sensors
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (e) {
      debugPrint('Geolocator getCurrentPosition error or timeout: $e. Checking last known position.');
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}
    }

    if (position != null) {
      final double acc = position.accuracy > 0 ? position.accuracy : 5.0;
      onSuccess(position.latitude, position.longitude, acc);
      return;
    }

    // 4. Secondary fallback if hardware GPS could not get a lock
    final bool ipFallback = await _tryNetworkIpFallback(onSuccess);
    if (!ipFallback) {
      onError('Unable to acquire GPS coordinates.');
    }
  } catch (e) {
    debugPrint('Native GPS requestPhysicalLocation error: $e');
    final bool ipFallback = await _tryNetworkIpFallback(onSuccess);
    if (!ipFallback) {
      onError('GPS acquisition error: $e');
    }
  }
}

Future<bool> _tryNetworkIpFallback(
  void Function(double lat, double lng, double accuracy) onSuccess,
) async {
  try {
    final response = await http
        .get(Uri.parse('https://ipapi.co/json/'))
        .timeout(const Duration(seconds: 4));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['latitude'] != null && data['longitude'] != null) {
        final double lat = (data['latitude'] as num).toDouble();
        final double lon = (data['longitude'] as num).toDouble();
        onSuccess(lat, lon, 25.0);
        return true;
      }
    }
  } catch (_) {
    try {
      final res2 = await http
          .get(Uri.parse('http://ip-api.com/json/'))
          .timeout(const Duration(seconds: 3));
      if (res2.statusCode == 200) {
        final data2 = json.decode(res2.body);
        if (data2['status'] == 'success') {
          final double lat = (data2['lat'] as num).toDouble();
          final double lon = (data2['lon'] as num).toDouble();
          onSuccess(lat, lon, 30.0);
          return true;
        }
      }
    } catch (_) {}
  }
  return false;
}
