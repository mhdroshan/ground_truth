import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../providers/location_service.dart';
import '../theme/app_colors.dart';
import '../widgets/map/tactical_radar_map.dart';
import '../widgets/common/glass_card.dart';
import 'create_post_screen.dart';

class VerifyLocationScreen extends StatelessWidget {
  final EventModel event;

  const VerifyLocationScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final locationService = context.watch<LocationService>();
    final eval = locationService.evaluateVerificationForEvent(event);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify Location',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.verified, color: AppColors.primaryNavy, size: 22),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Upper Map Section
            SizedBox(
              height: 290,
              child: TacticalRadarMap(
                event: event,
                userLocation: locationService.currentLocation,
                height: 290,
                eventLabel: 'CENTRAL PLAZA EVENT',
              ),
            ),

            // Main Verification Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 2026 Bento Identity Verification Percentage Card
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 24,
                    hasGlow: true,
                    glowColor: eval.isInsideGeofence
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'IDENTITY VERIFICATION',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              '${eval.confidenceScore.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: eval.isInsideGeofence ? const Color(0xFF10B981) : AppColors.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // 2026 Sleek Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (eval.confidenceScore / 100).clamp(0.05, 1.0),
                            minHeight: 7,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              eval.isInsideGeofence ? const Color(0xFF10B981) : AppColors.primaryNavy,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'GroundTruth ensures every report comes from someone physically at the scene.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2026 Bento Security Checklist Container
                  GlassCard(
                    padding: EdgeInsets.zero,
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(23)),
                            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          child: const Text(
                            'SECURITY CHECKLIST',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        _buildChecklistRow('GPS Signal', eval.accuracyPassed ? 'STRONG' : 'WEAK', eval.accuracyPassed),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildChecklistRow('Device Integrity', eval.rootJailbreakPassed && eval.mockLocationPassed ? 'VERIFIED' : 'FAILED', eval.rootJailbreakPassed && eval.mockLocationPassed),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildChecklistRow('Inside Event Boundary', eval.isInsideGeofence ? 'CONFIRMED' : 'OUTSIDE', eval.isInsideGeofence),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildChecklistRow('Ready to Publish', eval.canPost ? 'YES' : 'NO', eval.canPost),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Continue to Post Button (Strictly gated by geofence radius)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: eval.isInsideGeofence ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
                        foregroundColor: eval.isInsideGeofence ? Colors.white : const Color(0xFF64748B),
                        elevation: eval.isInsideGeofence ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: eval.isInsideGeofence ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      onPressed: eval.isInsideGeofence
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreatePostScreen(event: event),
                                ),
                              );
                            }
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.alertRed,
                                  behavior: SnackBarBehavior.floating,
                                  content: Row(
                                    children: [
                                      const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Cannot enter post: You are outside ${event.tagName} (${event.formattedRadius} radius). Physical presence required.',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            eval.isInsideGeofence ? Icons.arrow_forward_rounded : Icons.lock_outline_rounded,
                            size: 18,
                            color: eval.isInsideGeofence ? Colors.white : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            eval.isInsideGeofence ? 'Continue to Post' : 'Outside Radius • Cannot Enter Post',
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistRow(String title, String status, bool isSuccess) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check : Icons.close,
              color: isSuccess ? AppColors.verifiedGreen : AppColors.alertRed,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: isSuccess ? const Color(0xFF15803D) : AppColors.alertRed,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
