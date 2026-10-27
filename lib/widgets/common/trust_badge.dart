import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TrustBadge extends StatefulWidget {
  final double confidenceScore;
  final bool isGpsVerified;
  final bool isDeviceAttested;
  final bool isPulsing;
  final String label;
  final VoidCallback? onTap;

  const TrustBadge({
    super.key,
    required this.confidenceScore,
    this.isGpsVerified = true,
    this.isDeviceAttested = true,
    this.isPulsing = true,
    this.label = 'VERIFIED',
    this.onTap,
  });

  @override
  State<TrustBadge> createState() => _TrustBadgeState();
}

class _TrustBadgeState extends State<TrustBadge> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.verifiedGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.verifiedGreen.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isPulsing)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.verifiedGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.verifiedGreen.withValues(alpha: 0.6),
                          blurRadius: 4 * _pulseAnimation.value,
                          spreadRadius: 2 * (_pulseAnimation.value - 0.8),
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.verifiedGreen,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: const TextStyle(
                color: AppColors.verifiedGreen,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.verifiedGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${widget.confidenceScore.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.verifiedGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
