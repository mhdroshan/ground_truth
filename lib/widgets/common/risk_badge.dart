import 'package:flutter/material.dart';
import '../../models/event_model.dart';

/// 2026 Liquid Glass Risk Badge with micro-indicator dot and crisp tracked typography
class RiskBadge extends StatelessWidget {
  final RiskLevel riskLevel;

  const RiskBadge({super.key, required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    final color = Color(riskLevel.colorValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            riskLevel.label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}
