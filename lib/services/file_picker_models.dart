class PickedAttachment {
  final String name;
  final String? dataUrl; // Base64 data URL or URL
  final int sizeBytes;
  final String mimeType;

  const PickedAttachment({
    required this.name,
    this.dataUrl,
    required this.sizeBytes,
    required this.mimeType,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
