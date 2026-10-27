import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../providers/location_service.dart';
import '../theme/app_colors.dart';
import '../widgets/map/tactical_radar_map.dart';
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
        title: const Text('Verify Location'),
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
                  // Identity Verification Percentage Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'IDENTITY VERIFICATION',
                              style: TextStyle(
                                color: AppColors.primaryNavy,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              '${eval.confidenceScore.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: AppColors.primaryNavy,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Royal Blue Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (eval.confidenceScore / 100).clamp(0.05, 1.0),
                            minHeight: 8,
                            backgroundColor: AppColors.surfaceMuted,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'GroundTruth ensures every report comes from someone physically at the scene.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Security Checklist Container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            border: Border(bottom: BorderSide(color: AppColors.border)),
                          ),
                          child: const Text(
                            'SECURITY CHECKLIST',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        _buildChecklistRow('GPS Signal', eval.accuracyPassed ? 'STRONG' : 'WEAK', eval.accuracyPassed),
                        const Divider(height: 1),
                        _buildChecklistRow('Device Integrity', eval.rootJailbreakPassed && eval.mockLocationPassed ? 'VERIFIED' : 'FAILED', eval.rootJailbreakPassed && eval.mockLocationPassed),
                        const Divider(height: 1),
                        _buildChecklistRow('Inside Event Boundary', eval.isInsideGeofence ? 'CONFIRMED' : 'OUTSIDE', eval.isInsideGeofence),
                        const Divider(height: 1),
                        _buildChecklistRow('Ready to Publish', eval.canPost ? 'YES' : 'NO', eval.canPost),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Continue to Post Button (Strictly gated by geofence radius)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: eval.isInsideGeofence ? AppColors.primaryNavy : const Color(0xFFF1F5F9),
                        foregroundColor: eval.isInsideGeofence ? Colors.white : const Color(0xFF64748B),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: eval.isInsideGeofence ? AppColors.primaryNavy : const Color(0xFFE2E8F0),
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
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: isSuccess ? AppColors.verifiedGreenText : AppColors.alertRed,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
