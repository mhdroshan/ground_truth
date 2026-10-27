import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SafeImageWidget extends StatelessWidget {
  final String urlOrData;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const SafeImageWidget({
    super.key,
    required this.urlOrData,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (urlOrData.startsWith('data:video')) {
      child = Container(
        width: width,
        height: height,
        color: const Color(0xFF0F172A),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_rounded, color: Colors.white70, size: 36),
              SizedBox(height: 6),
              Text(
                'Eyewitness Video Footage',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (urlOrData.startsWith('data:image')) {
      try {
        final commaIndex = urlOrData.indexOf(',');
        final base64Str = commaIndex != -1 ? urlOrData.substring(commaIndex + 1) : urlOrData;
        final bytes = base64Decode(base64Str);
        child = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _errorPlaceholder(),
        );
      } catch (_) {
        child = _errorPlaceholder();
      }
    } else {
      child = Image.network(
        urlOrData,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFF1F5F9),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNavy),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _errorPlaceholder(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }
    return child;
  }

  Widget _errorPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 28),
      ),
    );
  }
}
