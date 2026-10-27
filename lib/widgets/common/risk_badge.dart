import 'package:flutter/material.dart';
import '../../models/event_model.dart';

class RiskBadge extends StatelessWidget {
  final RiskLevel riskLevel;

  const RiskBadge({super.key, required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    final color = Color(riskLevel.colorValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            riskLevel == RiskLevel.critical
                ? Icons.warning_rounded
                : Icons.shield_outlined,
            color: color,
            size: 11,
          ),
          const SizedBox(width: 4),
          Text(
            riskLevel.label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
