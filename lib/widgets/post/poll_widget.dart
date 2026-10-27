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

  static const List<String> _optionLetters = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  Widget build(BuildContext context) {
    final totalVotes = options.fold<int>(0, (sum, opt) => sum + opt.votes);
    final hasVoted = userVotedOptionId != null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poll Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0E1FD),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.how_to_vote_rounded,
                      size: 14,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'EYEWITNESS POLL',
                    style: TextStyle(
                      color: AppColors.primaryNavy,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasVoted ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasVoted ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasVoted ? Icons.check_circle_rounded : Icons.location_on,
                      size: 11,
                      color: hasVoted ? const Color(0xFF15803D) : const Color(0xFF1D4ED8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasVoted ? 'Voted On-Site' : 'On-Site Only',
                      style: TextStyle(
                        color: hasVoted ? const Color(0xFF15803D) : const Color(0xFF1D4ED8),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
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
              margin: const EdgeInsets.only(bottom: 9),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: hasVoted ? null : () => onVote(option.id),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF15803D)
                            : (hasVoted ? AppColors.border : const Color(0xFFCBD5E1)),
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
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),

                        // Progress fill bar when voted
                        if (hasVoted)
                          FractionallySizedBox(
                            widthFactor: percentage.clamp(0.015, 1.0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(11),
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
                                      ? const Color(0xFF15803D)
                                      : (hasVoted ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9)),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF15803D) : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: isSelected
                                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                                    : Text(
                                        letter,
                                        style: TextStyle(
                                          color: hasVoted ? AppColors.textSecondary : AppColors.primaryNavy,
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
                                        ? const Color(0xFF0F5132)
                                        : AppColors.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // Percentage & Vote Count
                              if (hasVoted) ...[
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${(percentage * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF15803D)
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
            );
          }),

          const SizedBox(height: 4),

          // Bottom Info Footer
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(
                '$totalVotes verified votes',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
              const Expanded(
                child: Text(
                  'Physical GNSS boundary attested',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
