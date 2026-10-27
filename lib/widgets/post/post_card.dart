import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/post_model.dart';
import '../../theme/app_colors.dart';
import '../common/glass_card.dart';
import '../common/trust_badge.dart';
import '../common/safe_image.dart';
import 'voice_note_player.dart';
import 'poll_widget.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final Function(int direction) onVote;
  final Function(String optionId)? onPollVote;
  final VoidCallback onOpenComments;

  const PostCard({
    super.key,
    required this.post,
    required this.onVote,
    this.onPollVote,
    required this.onOpenComments,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTimestamp(post.createdAt);

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author & Trust Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Author Avatar with verified badge
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.surfaceElevated,
                    backgroundImage: NetworkImage(post.authorAvatar),
                    onBackgroundImageError: (err, stack) {},
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: AppColors.verifiedGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 9,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),

              // Name & Trust Score
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.authorName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shield, size: 10, color: AppColors.verifiedGreen),
                              const SizedBox(width: 3),
                              Text(
                                '${post.authorTrustScore}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (post.authorIsVerifiedJournalist) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PRESS',
                              style: TextStyle(
                                color: AppColors.accentBlue,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          timeStr,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                        const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                        const Icon(Icons.location_on, size: 11, color: AppColors.radarCyan),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            post.locationDisplayName,
                            style: const TextStyle(
                              color: AppColors.radarCyan,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Trust Pill
              TrustBadge(
                confidenceScore: post.verification.confidenceScore,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Post Text Content
          Text(
            post.content,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),

          // Post Media Attachments based on type
          if (post.type == PostType.photo && post.mediaUrl != null)
            _buildPhotoAttachment(context),

          if (post.type == PostType.video && post.videoThumbnailUrl != null)
            _buildVideoAttachment(context),

          if (post.type == PostType.voiceNote && post.audioDurationSeconds != null)
            VoiceNotePlayer(
              durationSeconds: post.audioDurationSeconds!,
              waveform: post.waveform,
            ),

          if (post.type == PostType.poll && post.pollOptions != null)
            PollWidget(
              options: post.pollOptions!,
              userVotedOptionId: post.userVotedPollOptionId,
              onVote: onPollVote ?? (_) {},
            ),

          const SizedBox(height: 14),

          // Bottom Action Bar: Upvote, Downvote, Comments
          Row(
            children: [
              // Voting pill
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    // Upvote
                    InkWell(
                      onTap: () => onVote(1),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              post.userVote == 1
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_upward_outlined,
                              size: 16,
                              color: post.userVote == 1
                                  ? AppColors.upvote
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.score}',
                              style: TextStyle(
                                color: post.userVote == 1
                                    ? AppColors.upvote
                                    : (post.userVote == -1
                                        ? AppColors.downvote
                                        : AppColors.textPrimary),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, height: 16, color: AppColors.border),
                    // Downvote
                    InkWell(
                      onTap: () => onVote(-1),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Icon(
                          post.userVote == -1
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_downward_outlined,
                          size: 16,
                          color: post.userVote == -1
                              ? AppColors.downvote
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Comments Button
              InkWell(
                onTap: onOpenComments,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 5),
                      Text(
                        '${post.commentsCount}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoAttachment(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SafeImageWidget(
        urlOrData: post.mediaUrl!,
        height: 210,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildVideoAttachment(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SafeImageWidget(
            urlOrData: post.videoThumbnailUrl!,
            height: 210,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Container(
            height: 210,
            width: double.infinity,
            color: Colors.black.withValues(alpha: 0.35),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.verifiedGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.verifiedGreen.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 30),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.videocam, size: 12, color: AppColors.verifiedGreen),
                  SizedBox(width: 4),
                  Text(
                    'GROUND VIDEO • DEVICE ATTESTED',
                    style: TextStyle(
                      color: AppColors.verifiedGreen,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(dt);
  }
}
