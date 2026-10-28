import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/post_model.dart';
import '../providers/app_state.dart';
import '../providers/location_service.dart';
import '../theme/app_colors.dart';
import '../utils/geofence_math.dart';
import '../widgets/post/poll_widget.dart';
import '../widgets/post/voice_note_player.dart';
import '../widgets/post/verification_restricted_sheet.dart';
import '../widgets/common/safe_image.dart';
import '../widgets/common/glass_card.dart';
import 'comments_sheet.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['All Reports', 'Photos', 'Videos', 'Polls'];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final locationService = context.watch<LocationService>();
    final userLoc = locationService.currentLocation;

    EventModel? event;
    try {
      event = appState.events.firstWhere((e) => e.id == widget.eventId);
    } catch (_) {
      event = appState.events.isNotEmpty ? appState.events.first : null;
    }

    if (event == null) {
      return const Scaffold(body: Center(child: Text('Event Tag not found')));
    }

    final bool isUserInside = event.isUserInside(userLoc);
    final double distanceMeters = event.distanceFromUser(userLoc);

    // Get posts for this event
    final allPosts = appState.getPostsForEvent(event.id);
    List<PostModel> displayPosts = allPosts;

    if (_selectedTabIndex == 1) {
      displayPosts = allPosts.where((p) => p.type == PostType.photo).toList();
    } else if (_selectedTabIndex == 2) {
      displayPosts = allPosts.where((p) => p.type == PostType.video).toList();
    } else if (_selectedTabIndex == 3) {
      displayPosts = allPosts.where((p) => p.type == PostType.poll).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.tagName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '${event.category.label.toUpperCase()} • ${event.formattedRadius} RADIUS',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 2026 Liquid Glass Presence Status Hero Banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                borderRadius: 20,
                backgroundColor: isUserInside
                    ? const Color(0xFFF0FDF4).withValues(alpha: 0.92)
                    : const Color(0xFFEFF6FF).withValues(alpha: 0.92),
                borderColor: isUserInside ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE),
                hasGlow: isUserInside,
                glowColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isUserInside ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isUserInside ? Icons.verified_user_rounded : Icons.radar_rounded,
                        size: 20,
                        color: isUserInside ? const Color(0xFF15803D) : const Color(0xFF1E40AF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isUserInside ? 'ON-SITE EYEWITNESS' : 'OBSERVER MODE',
                                style: TextStyle(
                                  color: isUserInside ? const Color(0xFF14532D) : const Color(0xFF1E3A8A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              if (!isUserInside) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDBEAFE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${GeofenceMath.formatDistance(distanceMeters)} away',
                                    style: const TextStyle(
                                      color: Color(0xFF1E40AF),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isUserInside
                                ? 'You are inside ${event.tagName} (${event.formattedRadius}). You can post reports & verify truth on-site.'
                                : 'Verification votes are restricted to on-site eyewitnesses. Comments are open worldwide.',
                            style: TextStyle(
                              color: isUserInside ? const Color(0xFF15803D) : const Color(0xFF3B82F6),
                              fontSize: 11.5,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2026 Bento Telemetry Metric Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                borderRadius: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetric('SCOPE', event.scope.label, isAccent: false),
                    _buildMetricDivider(),
                    _buildMetric('RADIUS', event.formattedRadius, isAccent: false),
                    _buildMetricDivider(),
                    _buildMetric('REPORTS', '${event.totalPosts}', isAccent: false),
                    _buildMetricDivider(),
                    _buildMetric('EYEWITNESSES', '${event.activeContributors}', isAccent: true),
                  ],
                ),
              ),
            ),

            // 2026 Floating Segmented Tab Navigation Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: _tabs.asMap().entries.map((entry) {
                  final isSelected = entry.key == _selectedTabIndex;
                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTabIndex = entry.key),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryNavy : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Live Posts Timeline
            if (displayPosts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.rate_review_outlined, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'No reports under ${_tabs[_selectedTabIndex]} yet.',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isUserInside
                            ? 'You are currently inside this event radius! Be the first eyewitness to report.'
                            : 'Original posts must be submitted from inside the ${event.formattedRadius} boundary.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                      ),
                      if (isUserInside) ...[
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreatePostScreen(
                                  event: event!,
                                  initialType: _selectedTabIndex == 3 ? PostType.poll : PostType.text,
                                ),
                              ),
                            );
                          },
                          icon: Icon(_selectedTabIndex == 3 ? Icons.how_to_vote : Icons.edit_note, size: 18),
                          label: Text(
                            _selectedTabIndex == 3 ? 'Create First Poll' : 'Write First Report',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayPosts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final post = displayPosts[index];
                    return _buildPostCard(
                      context,
                      post: post,
                      event: event!,
                      userLoc: userLoc,
                      appState: appState,
                    );
                  },
                ),
              ),

            const SizedBox(height: 90),
          ],
        ),
      ),

      // Floating Action Button: Strictly available if user is inside this tag's area
      floatingActionButton: isUserInside
          ? Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: FloatingActionButton.extended(
                backgroundColor: const Color(0xFF10B981),
                elevation: 4,
                icon: const Icon(Icons.rate_review_rounded, color: Colors.white, size: 20),
                label: const Text(
                  'Write Post',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreatePostScreen(event: event!),
                    ),
                  );
                },
              ),
            )
          : null,
    );
  }

  Widget _buildMetric(String label, String value, {bool isAccent = false}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: isAccent ? const Color(0xFF10B981) : AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(width: 1, height: 26, color: const Color(0xFFE2E8F0));
  }

  Widget _buildPostCard(
    BuildContext context, {
    required PostModel post,
    required EventModel event,
    required GeoPoint userLoc,
    required AppState appState,
  }) {
    final bool isUserInside = event.isUserInside(userLoc);
    final bool isOwnPost = appState.isCurrentUserPost(post);
    final bool canVote = isUserInside && !isOwnPost;
    final tagLocation = event.country.isNotEmpty && !event.city.toLowerCase().contains(event.country.toLowerCase())
        ? '${event.city}, ${event.country}'
        : event.city;
    final isGeneric = post.locationDisplayName.isEmpty ||
        post.locationDisplayName.toLowerCase().contains('physical location') ||
        post.locationDisplayName.toLowerCase().contains('verification');
    final displayLocation = isGeneric ? tagLocation : post.locationDisplayName;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Row(
            children: [
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
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFF1F5F9),
                  backgroundImage: NetworkImage(post.authorAvatar),
                  onBackgroundImageError: (error, stack) {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
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
                                  child: Text(
                                    post.authorName,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 10, color: Color(0xFF15803D)),
                                    SizedBox(width: 3),
                                    Text(
                                      'VERIFIED',
                                      style: TextStyle(
                                        color: Color(0xFF15803D),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (post.authorId != appState.currentUser.id) ...[
                          const SizedBox(width: 8),
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
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isFollowed ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isFollowed ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Text(
                                    isFollowed ? 'Following' : '+ Follow',
                                    style: TextStyle(
                                      color: isFollowed ? const Color(0xFF15803D) : AppColors.primaryNavy,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          _formatTimeAgo(post.createdAt),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            displayLocation,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Post Content Text
          Text(
            post.content,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Attachments
          if (post.type == PostType.photo && post.mediaUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SafeImageWidget(
                urlOrData: post.mediaUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
              ),
            ),

          if (post.type == PostType.video && post.videoThumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SafeImageWidget(
                    urlOrData: post.videoThumbnailUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                  ),
                ],
              ),
            ),

          if (post.type == PostType.voiceNote && post.audioDurationSeconds != null)
            VoiceNotePlayer(
              durationSeconds: post.audioDurationSeconds!,
              waveform: post.waveform,
            ),

          if (post.type == PostType.poll && post.pollOptions != null)
            PollWidget(
              options: post.pollOptions!,
              userVotedOptionId: post.userVotedPollOptionId,
              isInsideGeofence: isUserInside,
              isOwnPost: isOwnPost,
              onVote: (optId) {
                if (!isUserInside) {
                  VerificationRestrictedSheet.show(
                    context,
                    event: event,
                    distanceMeters: event.distanceFromUser(userLoc),
                    customTitle: 'On-Site Poll Voting Required',
                    customMessage: 'The sole purpose of GroundTruth is to verify ground reality. Only eyewitnesses physically located inside ${event.tagName} (${event.formattedRadius} radius) can participate in polls. Others can only view results.',
                  );
                  return;
                }
                final res = appState.votePoll(
                  eventId: event.id,
                  postId: post.id,
                  optionId: optId,
                  userLocation: userLoc,
                );
                if (res.allowed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 2),
                      backgroundColor: const Color(0xFF0D652D),
                      content: Text(res.isChanged
                          ? 'Eyewitness poll vote updated!'
                          : 'Eyewitness poll vote recorded! (+15 XP)'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.alertRed,
                      content: Text(res.message ?? 'Vote could not be recorded.'),
                    ),
                  );
                }
              },
            ),

          const SizedBox(height: 14),

          // 2026 Asymmetric Verification Action Capsule
          Row(
            children: [
              // Like / Dislike Container
              Container(
                decoration: BoxDecoration(
                  color: canVote ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: canVote ? const Color(0xFFE2E8F0) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    // LIKE (Verify True)
                    Tooltip(
                      message: isOwnPost
                          ? 'Voting disabled for your own post'
                          : (canVote
                              ? (post.userVote == 1 ? 'Remove verification' : 'Verify true (+20 XP)')
                              : 'Voting disabled: Outside ${event.tagName} geofence radius'),
                      child: InkWell(
                        onTap: canVote
                            ? () {
                                final res = appState.votePost(
                                  eventId: event.id,
                                  postId: post.id,
                                  direction: 1,
                                  userLocation: userLoc,
                                );
                                if (!res.allowed) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppColors.alertRed,
                                      content: Text(res.message ?? 'Action restricted by physical geofence.'),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: res.isRemoved
                                          ? AppColors.primaryNavy
                                          : const Color(0xFF0D652D),
                                      content: Text(
                                        res.isRemoved
                                            ? 'Verification vote removed.'
                                            : 'News verified! +20 XP awarded.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                post.userVote == 1 ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
                                size: 15,
                                color: !canVote
                                    ? AppColors.textMuted
                                    : (post.userVote == 1 ? const Color(0xFF15803D) : AppColors.textSecondary),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.upvotes}',
                                style: TextStyle(
                                  color: !canVote
                                      ? AppColors.textMuted
                                      : (post.userVote == 1 ? const Color(0xFF15803D) : AppColors.textPrimary),
                                  fontSize: 12,
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
                      color: const Color(0xFFE2E8F0),
                    ),

                    // DISLIKE (Dispute False)
                    Tooltip(
                      message: isOwnPost
                          ? 'Voting disabled for your own post'
                          : (canVote
                              ? (post.userVote == -1 ? 'Remove dispute' : 'Dispute false (+20 XP)')
                              : 'Voting disabled: Outside ${event.tagName} geofence radius'),
                      child: InkWell(
                        onTap: canVote
                            ? () {
                                final res = appState.votePost(
                                  eventId: event.id,
                                  postId: post.id,
                                  direction: -1,
                                  userLocation: userLoc,
                                );
                                if (!res.allowed) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppColors.alertRed,
                                      content: Text(res.message ?? 'Action restricted by physical geofence.'),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: res.isRemoved
                                          ? AppColors.primaryNavy
                                          : const Color(0xFF991B1B),
                                      content: Text(
                                        res.isRemoved
                                            ? 'Dispute vote removed.'
                                            : 'Dispute recorded from on-site position. +20 XP awarded.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                post.userVote == -1 ? Icons.thumb_down_rounded : Icons.thumb_down_alt_outlined,
                                size: 15,
                                color: !canVote
                                    ? AppColors.textMuted
                                    : (post.userVote == -1 ? const Color(0xFFDC2626) : AppColors.textSecondary),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.downvotes}',
                                style: TextStyle(
                                  color: !canVote
                                      ? AppColors.textMuted
                                      : (post.userVote == -1 ? const Color(0xFFDC2626) : AppColors.textPrimary),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Indicator badge if disabled
              if (!canVote && !isOwnPost) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Only eyewitnesses inside ${event.tagName} (${event.formattedRadius}) can vote',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 11,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Outside Radius',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 10),

              // COMMENTS BUTTON (OPEN TO ALL USERS FROM ANYWHERE)
              InkWell(
                onTap: () => CommentsSheet.show(context, event, post),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 5),
                      Text(
                        '${post.commentsCount}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
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

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }
}
