import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'file_picker_models.dart';

Future<PickedAttachment?> pickFilePlatform({
  String accept = '*/*',
  bool fromCamera = false,
}) async {
  try {
    final picker = ImagePicker();
    final isVideo = accept.toLowerCase().contains('video');
    final source = fromCamera ? ImageSource.camera : ImageSource.gallery;

    final XFile? picked;
    if (isVideo) {
      picked = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );
    } else {
      picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
      );
    }

    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final name = picked.name.isNotEmpty
        ? picked.name
        : (isVideo ? 'eyewitness_video.mp4' : 'eyewitness_photo.jpg');
    final sizeBytes = bytes.length;

    // Detect MIME type
    String mimeType = picked.mimeType ?? '';
    if (mimeType.isEmpty) {
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
      if (isVideo) {
        if (ext == 'mov') {
          mimeType = 'video/quicktime';
        } else {
          mimeType = 'video/mp4';
        }
      } else {
        if (ext == 'png') {
          mimeType = 'image/png';
        } else if (ext == 'webp') {
          mimeType = 'image/webp';
        } else if (ext == 'gif') {
          mimeType = 'image/gif';
        } else {
          mimeType = 'image/jpeg';
        }
      }
    }

    // Build base64 data URL
    // For very large videos (> 5MB), provide placeholder thumbnail to avoid exceeding MongoDB BSON limits
    String? dataUrl;
    if (isVideo && sizeBytes > 5 * 1024 * 1024) {
      dataUrl = 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=800&auto=format&fit=crop&q=80';
    } else {
      final base64String = base64Encode(bytes);
      dataUrl = 'data:$mimeType;base64,$base64String';
    }

    return PickedAttachment(
      name: name,
      dataUrl: dataUrl,
      sizeBytes: sizeBytes,
      mimeType: mimeType,
      path: picked.path,
    );
  } catch (e) {
    if (kDebugMode) {
      print('pickFilePlatform error on mobile: $e');
    }
    return null;
  }
}
