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
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      blur: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Bento Header: Tag Name Pill + Category Chip
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
                          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryNavy.withValues(alpha: 0.15),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryNavy.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
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
                                fontSize: 11.5,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      targetEvent.category.label.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],

          // 2. Bento Author & Credibility Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Author Avatar with verified sentinel
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
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFE2E8F0),
                      backgroundImage: getUserAvatarProvider(post.authorAvatar),
                      onBackgroundImageError: (err, stack) {},
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.verifiedGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Name & Location
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
                  borderRadius: BorderRadius.circular(8),
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
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (post.authorIsVerifiedJournalist) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryNavy.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.primaryNavy.withValues(alpha: 0.2),
                                  width: 0.8,
                                ),
                              ),
                              child: const Text(
                                'PRESS',
                                style: TextStyle(
                                  color: AppColors.primaryNavy,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
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
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                          const Icon(Icons.location_on_rounded, size: 11, color: AppColors.radarCyan),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              locationText,
                              style: const TextStyle(
                                color: AppColors.radarCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
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

              // Quick Follow / Following Button
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isFollowed
                              ? const Color(0xFFDCFCE7)
                              : AppColors.primaryNavy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFollowed
                                ? const Color(0xFF86EFAC)
                                : AppColors.primaryNavy.withValues(alpha: 0.2),
                            width: 0.9,
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
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],

              // 2026 Liquid Trust Pill
              TrustBadge(
                confidenceScore: post.verification.confidenceScore,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Post Text Content (Exaggerated Minimalism)
          Text(
            post.content,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              height: 1.48,
              letterSpacing: -0.1,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),

          // 4. Media Attachments based on type
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

          // 5. Asymmetric Bento Action Bar
          Row(
            children: [
              // Liquid Voting Capsule
              Container(
                decoration: BoxDecoration(
                  color: canVote
                      ? Colors.white
                      : const Color(0xFFF1F5F9).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: canVote ? AppColors.border : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: [
                    if (canVote)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    // Upvote / Verify
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
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
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
                              const SizedBox(width: 5),
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
                                  fontWeight: FontWeight.w800,
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
                    // Downvote / Dispute
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
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
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

              // Outside Geofence indicator badge if disabled
              if (!canVote && !effectiveIsOwn)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Tooltip(
                    message: 'Physical presence inside geofence required to vote',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 11,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Outside Radius',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),

              // Comments Pill
              InkWell(
                onTap: onOpenComments,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${post.commentsCount}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeImageWidget(
          urlOrData: post.mediaUrl!,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildVideoAttachment(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SafeImageWidget(
            urlOrData: post.videoThumbnailUrl!,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Container(
            height: 220,
            width: double.infinity,
            color: Colors.black.withValues(alpha: 0.35),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.verifiedGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.verifiedGreen.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.videocam_rounded, size: 12, color: AppColors.verifiedGreen),
                  SizedBox(width: 5),
                  Text(
                    'GROUND VIDEO • DEVICE ATTESTED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
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
