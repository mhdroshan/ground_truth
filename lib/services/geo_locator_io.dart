void requestPhysicalLocation({
  required void Function(double lat, double lng, double accuracy) onSuccess,
  required void Function(String error) onError,
}) {
  // Fallback for IO / unit testing environment
  onError('Platform native GPS handled via system service');
}
