import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../providers/app_state.dart';
import '../../providers/location_service.dart';
import '../../theme/app_colors.dart';
import '../common/glass_card.dart';
import '../common/trust_badge.dart';
import '../common/safe_image.dart';
import 'voice_note_player.dart';
import 'poll_widget.dart';
import '../../screens/profile_screen.dart';
import '../../screens/event_detail_screen.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final bool? isInsideGeofence;
  final bool? isOwnPost;
  final Function(int direction) onVote;
  final Function(String optionId)? onPollVote;
  final VoidCallback onOpenComments;
  final bool showTagName;

  const PostCard({
    super.key,
    required this.post,
    this.isInsideGeofence,
    this.isOwnPost,
    required this.onVote,
    this.onPollVote,
    required this.onOpenComments,
    this.showTagName = true,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTimestamp(post.createdAt);
    final appState = Provider.of<AppState>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);
    final bool effectiveIsOwn = isOwnPost ?? appState.isCurrentUserPost(post);
    final bool isGeofenceAllowed = isInsideGeofence ??
        appState.isUserInsidePostGeofence(post, locationService.currentLocation);
    final bool canVote = !effectiveIsOwn && isGeofenceAllowed;
    final event = appState.getEventForPost(post);
    String locationText = post.locationDisplayName;
    if (event != null) {
      final tagLocation = event.country.isNotEmpty && !event.city.toLowerCase().contains(event.country.toLowerCase())
          ? '${event.city}, ${event.country}'
          : event.city;
      final isGeneric = locationText.isEmpty ||
          locationText.toLowerCase().contains('physical location') ||
          locationText.toLowerCase().contains('verification');
      locationText = isGeneric ? tagLocation : locationText;
    } else if (locationText.isEmpty ||
        locationText.toLowerCase().contains('physical location') ||
        locationText.toLowerCase().contains('verification')) {
      locationText = 'Verified Location';
    }

    final String? resolvedTagName = (event?.tagName != null && event!.tagName.isNotEmpty)
        ? event.tagName
        : (post.tagName != null && post.tagName!.trim().isNotEmpty
            ? (post.tagName!.trim().startsWith('#')
                ? post.tagName!.trim()
                : '#${post.tagName!.trim()}')
            : null);

    final targetEvent = event ?? (resolvedTagName != null
        ? appState.events.where((e) =>
            e.tagName.replaceAll('#', '').trim().toLowerCase() ==
            resolvedTagName.replaceAll('#', '').trim().toLowerCase()).firstOrNull
        : null);

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tag Name Pill Header (Clickable to open Event Detail)
          if (showTagName && resolvedTagName != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: InkWell(
                    onTap: targetEvent != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventDetailScreen(eventId: targetEvent.id),
                              ),
                            );
                          }
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEEF4FF), Color(0xFFE2EDFE)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryNavy.withValues(alpha: 0.18),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryNavy.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryNavy.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.tag_rounded,
                              size: 11,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              resolvedTagName,
                              style: const TextStyle(
                                color: AppColors.primaryNavy,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (targetEvent != null && targetEvent.city.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 3.5,
                              height: 3.5,
                              decoration: BoxDecoration(
                                color: AppColors.primaryNavy.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                targetEvent.city,
                                style: TextStyle(
                                  color: AppColors.primaryNavy.withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (targetEvent != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: AppColors.primaryNavy.withValues(alpha: 0.5),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (targetEvent != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      targetEvent.category.label.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],
          // Author & Trust Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Author Avatar with verified badge (Clickable to open profile)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        userId: post.authorId,
                        initialAuthorName: post.authorName,
                        initialAuthorAvatar: post.authorAvatar,
                        initialAuthorTrustScore: post.authorTrustScore,
                        isVerifiedJournalist: post.authorIsVerifiedJournalist,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Stack(
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
              ),
              const SizedBox(width: 10),

              // Name & Location (Clickable to open profile)
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          userId: post.authorId,
                          initialAuthorName: post.authorName,
                          initialAuthorAvatar: post.authorAvatar,
                          initialAuthorTrustScore: post.authorTrustScore,
                          isVerifiedJournalist: post.authorIsVerifiedJournalist,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
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
                          if (post.authorIsVerifiedJournalist) ...[
                            const SizedBox(width: 6),
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
                              locationText,
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
              ),

              // Quick Follow / Following Button (when post not by current user)
              if (post.authorId != appState.currentUser.id) ...[
                Builder(
                  builder: (context) {
                    final isFollowed = appState.isFollowing(post.authorId);
                    return InkWell(
                      onTap: () async {
                        final nowFollowing = await appState.toggleFollowUser(
                          post.authorId,
                          userName: post.authorName,
                          userAvatar: post.authorAvatar,
                          userTrustScore: post.authorTrustScore,
                          isJournalist: post.authorIsVerifiedJournalist,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                nowFollowing
                                    ? 'Following ${post.authorName}'
                                    : 'Unfollowed ${post.authorName}',
                              ),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: isFollowed
                              ? const Color(0xFFDCFCE7)
                              : AppColors.primaryNavy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFollowed
                                ? const Color(0xFF86EFAC)
                                : AppColors.primaryNavy.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isFollowed ? Icons.check : Icons.add,
                              size: 11,
                              color: isFollowed ? const Color(0xFF15803D) : AppColors.primaryNavy,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isFollowed ? 'Following' : 'Follow',
                              style: TextStyle(
                                color: isFollowed ? const Color(0xFF15803D) : AppColors.primaryNavy,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],

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
              isInsideGeofence: isGeofenceAllowed,
              isOwnPost: effectiveIsOwn,
              onVote: onPollVote ?? (_) {},
            ),

          const SizedBox(height: 14),

          // Bottom Action Bar: Upvote, Downvote, Comments
          Row(
            children: [
              // Voting pill
              Container(
                decoration: BoxDecoration(
                  color: canVote
                      ? AppColors.surfaceElevated
                      : const Color(0xFFF1F5F9).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: canVote ? AppColors.border : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    // Upvote
                    Tooltip(
                      message: effectiveIsOwn
                          ? 'Voting disabled for your own post'
                          : (canVote
                              ? (post.userVote == 1 ? 'Remove verification' : 'Verify true (+20 XP)')
                              : 'Voting disabled: Outside post geofence radius'),
                      child: InkWell(
                        onTap: canVote ? () => onVote(1) : null,
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
                                color: !canVote
                                    ? AppColors.textMuted
                                    : (post.userVote == 1
                                        ? AppColors.upvote
                                        : AppColors.textSecondary),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.score}',
                                style: TextStyle(
                                  color: !canVote
                                      ? AppColors.textMuted
                                      : (post.userVote == 1
                                          ? AppColors.upvote
                                          : (post.userVote == -1
                                              ? AppColors.downvote
                                              : AppColors.textPrimary)),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 16,
                      color: canVote ? AppColors.border : const Color(0xFFE2E8F0),
                    ),
                    // Downvote
                    Tooltip(
                      message: effectiveIsOwn
                          ? 'Voting disabled for your own post'
                          : (canVote
                              ? (post.userVote == -1 ? 'Remove dispute' : 'Dispute false (+20 XP)')
                              : 'Voting disabled: Outside post geofence radius'),
                      child: InkWell(
                        onTap: canVote ? () => onVote(-1) : null,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Icon(
                            post.userVote == -1
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_downward_outlined,
                            size: 16,
                            color: !canVote
                                ? AppColors.textMuted
                                : (post.userVote == -1
                                    ? AppColors.downvote
                                    : AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Outside Geofence indicator badge OR Own Post badge if disabled
              if (!canVote)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Tooltip(
                    message: effectiveIsOwn
                        ? 'Authors cannot verify or dispute their own reports'
                        : 'Physical presence inside geofence required to vote',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: effectiveIsOwn ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: effectiveIsOwn ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            effectiveIsOwn ? Icons.person_rounded : Icons.lock_outline_rounded,
                            size: 11,
                            color: effectiveIsOwn ? const Color(0xFF1D4ED8) : AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            effectiveIsOwn ? 'Your Post' : 'Outside Radius',
                            style: TextStyle(
                              fontSize: 10,
                              color: effectiveIsOwn ? const Color(0xFF1D4ED8) : AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
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
