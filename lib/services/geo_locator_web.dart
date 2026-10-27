import 'dart:js_interop';
import 'package:web/web.dart' as web;

void requestPhysicalLocation({
  required void Function(double lat, double lng, double accuracy) onSuccess,
  required void Function(String error) onError,
}) {
  try {
    web.window.navigator.geolocation.getCurrentPosition(
      ((web.GeolocationPosition pos) {
        final coords = pos.coords;
        onSuccess(
          coords.latitude.toDouble(),
          coords.longitude.toDouble(),
          coords.accuracy.toDouble(),
        );
      }).toJS,
      ((web.GeolocationPositionError err) {
        onError(err.message);
      }).toJS,
      web.PositionOptions(
        enableHighAccuracy: true,
        timeout: 10000,
      ),
    );
  } catch (e) {
    onError(e.toString());
  }
}
