import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> requestPhysicalLocation({
  required void Function(double lat, double lng, double accuracy) onSuccess,
  required void Function(String error) onError,
}) async {
  final completer = Completer<void>();
  try {
    web.window.navigator.geolocation.getCurrentPosition(
      ((web.GeolocationPosition pos) {
        final coords = pos.coords;
        onSuccess(
          coords.latitude.toDouble(),
          coords.longitude.toDouble(),
          coords.accuracy.toDouble(),
        );
        if (!completer.isCompleted) completer.complete();
      }).toJS,
      ((web.GeolocationPositionError err) {
        onError(err.message);
        if (!completer.isCompleted) completer.complete();
      }).toJS,
      web.PositionOptions(
        enableHighAccuracy: true,
        timeout: 10000,
      ),
    );
  } catch (e) {
    onError(e.toString());
    if (!completer.isCompleted) completer.complete();
  }
  return completer.future;
}
