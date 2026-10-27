import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/geofence_math.dart';

class VerificationRestrictedSheet extends StatelessWidget {
  final EventModel event;
  final double distanceMeters;
  final VoidCallback? onOpenComments;
  final String? customTitle;
  final String? customMessage;

  const VerificationRestrictedSheet({
    super.key,
    required this.event,
    required this.distanceMeters,
    this.onOpenComments,
    this.customTitle,
    this.customMessage,
  });

  static void show(BuildContext context, {
    required EventModel event,
    required double distanceMeters,
    VoidCallback? onOpenComments,
    String? customTitle,
    String? customMessage,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => VerificationRestrictedSheet(
        event: event,
        distanceMeters: distanceMeters,
        onOpenComments: onOpenComments,
        customTitle: customTitle,
        customMessage: customMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Lock Radar Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFDE68A), width: 2),
            ),
            child: const Icon(
              Icons.lock_person_rounded,
              size: 32,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            customTitle ?? 'On-Site Verification Required',
            style: const TextStyle(
              color: AppColors.primaryNavy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Tag Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD0E1FD),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              event.tagName,
              style: const TextStyle(
                color: AppColors.primaryNavy,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Mission Statement Explanation
          Text(
            customMessage ??
                'The sole purpose of GroundTruth is to verify what really happens. To eliminate bot manipulation and rumors, only users physically located inside this event radius (${event.formattedRadius}) can like, dislike, or participate in polls to verify ground truth.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),

          // Geofence Distance Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_off_rounded, color: AppColors.alertRed, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR STATUS: OUTSIDE EVENT RADIUS',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'You are ${GeofenceMath.formatDistance(distanceMeters)} away from the verified boundary.',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (onOpenComments != null) onOpenComments!();
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text(
                    'Add Comment Instead',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
