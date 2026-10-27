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
      bgColor = AppColors.alertRed.withValues(alpha: 0.15);
      borderColor = AppColors.alertRed.withValues(alpha: 0.5);
      accentColor = AppColors.alertRed;
      iconData = Icons.gpp_bad_rounded;
      statusTitle = 'SECURITY INTEGRITY VIOLATION DETECTED';
      statusSubtitle = eval.mockLocationPassed
          ? 'Device environment compromised (Root/Jailbreak flagged)'
          : 'Mock GPS / Fake location provider active. Posting blocked.';
    } else if (isInside) {
      bgColor = AppColors.verifiedGreen.withValues(alpha: 0.12);
      borderColor = AppColors.verifiedGreen.withValues(alpha: 0.4);
      accentColor = AppColors.verifiedGreen;
      iconData = Icons.verified_user_rounded;
      statusTitle = 'GEOFENCE VERIFIED • ON-SITE EYEWITNESS';
      statusSubtitle = 'GNSS Precision <${locationService.gpsAccuracyMeters.toStringAsFixed(1)}m • Authorized to contribute posts & comments';
    } else {
      bgColor = AppColors.surfaceElevated;
      borderColor = AppColors.border;
      accentColor = AppColors.alertAmber;
      iconData = Icons.visibility_outlined;
      statusTitle = 'OBSERVER MODE (READ-ONLY)';
      statusSubtitle = 'You are ${GeofenceMath.formatDistance(eval.distanceMeters)} away. Submissions restricted to physical eyewitnesses.';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
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
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isInside && isClean) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.verifiedGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  statusSubtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (onInspectVerification != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
              onPressed: onInspectVerification,
              tooltip: 'Verification Audit',
            ),
          ],
        ],
      ),
    );
  }
}
