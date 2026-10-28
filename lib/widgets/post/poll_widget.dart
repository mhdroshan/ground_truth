import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../theme/app_colors.dart';

class PollWidget extends StatelessWidget {
  final List<PollOption> options;
  final String? userVotedOptionId;
  final bool isInsideGeofence;
  final bool isOwnPost;
  final Function(String optionId) onVote;

  const PollWidget({
    super.key,
    required this.options,
    this.userVotedOptionId,
    this.isInsideGeofence = true,
    this.isOwnPost = false,
    required this.onVote,
  });

  static const List<String> _optionLetters = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  Widget build(BuildContext context) {
    final totalVotes = options.fold<int>(0, (sum, opt) => sum + opt.votes);
    final hasVoted = userVotedOptionId != null;
    // Anyone physically inside geofence boundary can vote & change vote anytime.
    // Others (outside geofence) can only view the results.
    final showResults = !isInsideGeofence || hasVoted;
    final canVote = isInsideGeofence;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bentoSurfaceSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.bentoBorder, width: 0.9),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bento Poll Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.how_to_vote_rounded,
                      size: 13,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'EYEWITNESS POLL',
                    style: TextStyle(
                      color: AppColors.primaryNavy,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: !isInsideGeofence
                      ? const Color(0xFFF1F5F9)
                      : (hasVoted ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !isInsideGeofence
                        ? const Color(0xFFCBD5E1)
                        : (hasVoted ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE)),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      !isInsideGeofence
                          ? Icons.lock_outline_rounded
                          : (hasVoted ? Icons.check_circle_rounded : Icons.location_on),
                      size: 11,
                      color: !isInsideGeofence
                          ? AppColors.textMuted
                          : (hasVoted ? const Color(0xFF15803D) : const Color(0xFF1D4ED8)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      !isInsideGeofence
                          ? 'Results Only (Outside Geofence)'
                          : (hasVoted ? 'Voted (Change Anytime)' : 'On-Site Eyewitness Vote'),
                      style: TextStyle(
                        color: !isInsideGeofence
                            ? AppColors.textMuted
                            : (hasVoted ? const Color(0xFF15803D) : const Color(0xFF1D4ED8)),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Options List
          ...options.asMap().entries.map((entry) {
            final idx = entry.key;
            final option = entry.value;
            final isSelected = userVotedOptionId == option.id;
            final percentage = totalVotes > 0 ? (option.votes / totalVotes) : 0.0;
            final letter = idx < _optionLetters.length ? _optionLetters[idx] : '${idx + 1}';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: Tooltip(
                  message: !canVote
                      ? 'Poll voting locked: Physical presence inside geofence required. You can view results.'
                      : (hasVoted
                          ? (isSelected ? 'Your current vote' : 'Tap to change vote to this option')
                          : 'Tap to vote on-site'),
                  child: InkWell(
                    onTap: () => onVote(option.id),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : (showResults ? AppColors.border : const Color(0xFFCBD5E1)),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Background base
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),

                          // Progress fill bar when viewing results
                          if (showResults)
                            FractionallySizedBox(
                              widthFactor: percentage.clamp(totalVotes > 0 ? 0.015 : 0.0, 1.0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutCubic,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFD1FAE5)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                            ),

                          // Option Content & Stats
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                // Letter / Checkmark circle
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF10B981)
                                        : (showResults ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9)),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: isSelected
                                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                                      : Text(
                                          letter,
                                          style: TextStyle(
                                            color: showResults ? AppColors.textSecondary : AppColors.primaryNavy,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 10),

                                // Option Title Text
                                Expanded(
                                  child: Text(
                                    option.text,
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFF065F46)
                                          : AppColors.textPrimary,
                                      fontSize: 13.5,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                // Percentage & Vote Count
                                if (showResults) ...[
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${(percentage * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          color: isSelected
                                              ? const Color(0xFF10B981)
                                              : AppColors.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        '${option.votes} ${option.votes == 1 ? 'vote' : 'votes'}',
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 6),

          // Bottom Info Footer
          Row(
            children: [
              Icon(
                isInsideGeofence ? Icons.how_to_vote_rounded : Icons.visibility_outlined,
                size: 12,
                color: isInsideGeofence ? AppColors.primaryNavy : AppColors.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                '$totalVotes verified votes',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
              Expanded(
                child: Text(
                  !isInsideGeofence
                      ? 'Physical boundary restricted • View results only'
                      : (hasVoted
                          ? 'Vote recorded • Tap any option to change anytime'
                          : 'Physical GNSS boundary attested • Tap to vote'),
                  style: TextStyle(
                    color: !isInsideGeofence
                        ? AppColors.textMuted
                        : (hasVoted ? const Color(0xFF15803D) : AppColors.textMuted),
                    fontSize: 10.5,
                    fontWeight: hasVoted ? FontWeight.w700 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
