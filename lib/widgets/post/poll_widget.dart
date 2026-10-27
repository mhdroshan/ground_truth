import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../theme/app_colors.dart';

class PollWidget extends StatelessWidget {
  final List<PollOption> options;
  final String? userVotedOptionId;
  final Function(String optionId) onVote;

  const PollWidget({
    super.key,
    required this.options,
    this.userVotedOptionId,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final totalVotes = options.fold<int>(0, (sum, opt) => sum + opt.votes);
    final hasVoted = userVotedOptionId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...options.map((option) {
          final isSelected = userVotedOptionId == option.id;
          final percentage = totalVotes > 0 ? (option.votes / totalVotes) : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: hasVoted ? null : () => onVote(option.id),
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  // Progress background bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.verifiedGreen : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                  ),
                  if (hasVoted)
                    FractionallySizedBox(
                      widthFactor: percentage.clamp(0.02, 1.0),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.verifiedGreen.withValues(alpha: 0.22)
                              : AppColors.border.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  // Option Text & Percent
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (isSelected)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: AppColors.verifiedGreen,
                                  ),
                                ),
                              Flexible(
                                child: Text(
                                  option.text,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.verifiedGreen
                                        : AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasVoted)
                          Text(
                            '${(percentage * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.verifiedGreen
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        Padding(
          padding: const EdgeInsets.only(top: 2, left: 4),
          child: Text(
            '$totalVotes verified votes • Eyewitness consensus poll',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
