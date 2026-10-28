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

/// Safely returns an ImageProvider for any URL (http/https) or base64 data string (data:image/...)
ImageProvider? getUserAvatarProvider(String? urlOrData) {
  if (urlOrData == null) return null;
  final clean = urlOrData.trim();
  if (clean.isEmpty) return null;

  if (clean.startsWith('data:image')) {
    try {
      final commaIndex = clean.indexOf(',');
      final base64Str = commaIndex != -1 ? clean.substring(commaIndex + 1) : clean;
      final bytes = base64Decode(base64Str);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  return NetworkImage(clean);
}

/// Clean circular avatar widget that gracefully displays network images,
/// base64 data URLs, or a colored fallback initial letter if loading fails.
class UserAvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final String? name;
  final VoidCallback? onTap;
  final Widget? badge;

  const UserAvatarWidget({
    super.key,
    required this.avatarUrl,
    this.radius = 20,
    this.name,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final provider = getUserAvatarProvider(avatarUrl);
    final initial = (name != null && name!.trim().isNotEmpty)
        ? name!.trim()[0].toUpperCase()
        : 'U';

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE2E8F0),
      backgroundImage: provider,
      onBackgroundImageError: (err, stack) {},
      child: provider == null
          ? Text(
              initial,
              style: TextStyle(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w800,
                fontSize: radius * 0.9,
              ),
            )
          : null,
    );

    if (badge != null) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: badge!,
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }
}
