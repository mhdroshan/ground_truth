import 'dart:convert';
import 'package:http/http.dart' as http;

void requestPhysicalLocation({
  required void Function(double lat, double lng, double accuracy) onSuccess,
  required void Function(String error) onError,
}) async {
  try {
    final response = await http
        .get(Uri.parse('http://ip-api.com/json/'))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        final double lat = (data['lat'] as num).toDouble();
        final double lon = (data['lon'] as num).toDouble();
        onSuccess(lat, lon, 8.5);
        return;
      }
    }
    onError('Unable to acquire network coordinates');
  } catch (e) {
    onError(e.toString());
  }
}

