import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../providers/location_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/geofence_math.dart';

class GeofenceStatusBar extends StatelessWidget {
  final EventModel event;
  final LocationService locationService;
  final VoidCallback? onInspectVerification;

  const GeofenceStatusBar({
    super.key,
    required this.event,
    required this.locationService,
    this.onInspectVerification,
  });

  @override
  Widget build(BuildContext context) {
    final eval = locationService.evaluateVerificationForEvent(event);
    final isInside = eval.isInsideGeofence;
    final isClean = eval.mockLocationPassed && eval.rootJailbreakPassed;

    Color bgColor;
    Color borderColor;
    Color accentColor;
    IconData iconData;
    String statusTitle;
    String statusSubtitle;

    if (!isClean) {
      bgColor = AppColors.alertRed.withValues(alpha: 0.12);
      borderColor = AppColors.alertRed.withValues(alpha: 0.4);
      accentColor = AppColors.alertRed;
      iconData = Icons.gpp_bad_rounded;
      statusTitle = 'SECURITY INTEGRITY VIOLATION DETECTED';
      statusSubtitle = eval.mockLocationPassed
          ? 'Device environment compromised (Root/Jailbreak flagged)'
          : 'Mock GPS / Fake location provider active. Posting blocked.';
    } else if (isInside) {
      bgColor = const Color(0xFFE8F7F0);
      borderColor = AppColors.verifiedGreen.withValues(alpha: 0.35);
      accentColor = AppColors.verifiedGreen;
      iconData = Icons.verified_user_rounded;
      statusTitle = 'GEOFENCE VERIFIED • ON-SITE EYEWITNESS';
      statusSubtitle = 'GNSS Precision <${locationService.gpsAccuracyMeters.toStringAsFixed(1)}m • Authorized to contribute posts & comments';
    } else {
      bgColor = AppColors.bentoSurfaceSecondary;
      borderColor = AppColors.border;
      accentColor = AppColors.alertAmber;
      iconData = Icons.visibility_outlined;
      statusTitle = 'OBSERVER MODE (READ-ONLY)';
      statusSubtitle = 'You are ${GeofenceMath.formatDistance(eval.distanceMeters)} away. Submissions restricted to physical eyewitnesses.';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        statusTitle,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isInside && isClean) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  statusSubtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (onInspectVerification != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryNavy),
              onPressed: onInspectVerification,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}
