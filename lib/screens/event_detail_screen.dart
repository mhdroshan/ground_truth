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
import 'comments_sheet.dart';
import 'create_post_screen.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.tagName,
              style: const TextStyle(
                color: AppColors.primaryNavy,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '${event.category.label} • ${event.formattedRadius} Radius',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            // Presence Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUserInside ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                border: Border(
                  bottom: BorderSide(
                    color: isUserInside ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isUserInside ? Icons.verified_user_rounded : Icons.info_outline_rounded,
                    size: 18,
                    color: isUserInside ? const Color(0xFF15803D) : const Color(0xFF1E40AF),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isUserInside
                          ? 'You are inside ${event.tagName} (${event.formattedRadius}). You can post & verify news on-site.'
                          : 'Observer Mode (${GeofenceMath.formatDistance(distanceMeters)} away). Verification is restricted to on-site users. Comments are open to all.',
                      style: TextStyle(
                        color: isUserInside ? const Color(0xFF14532D) : const Color(0xFF1E3A8A),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Telemetry Metric Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric('Scope', event.scope.label, isAccent: false),
                  _buildMetricDivider(),
                  _buildMetric('Radius', event.formattedRadius, isAccent: false),
                  _buildMetricDivider(),
                  _buildMetric('Reports', '${event.totalPosts}', isAccent: false),
                  _buildMetricDivider(),
                  _buildMetric('Eyewitnesses', '${event.activeContributors}', isAccent: true),
                ],
              ),
            ),

            // Tab Navigation Bar
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: _tabs.asMap().entries.map((entry) {
                  final isSelected = entry.key == _selectedTabIndex;
                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTabIndex = entry.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected ? AppColors.primaryNavy : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isUserInside
                            ? 'You are currently inside this event radius! Be the first eyewitness to report.'
                            : 'Original posts must be submitted from inside the ${event.formattedRadius} boundary.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      if (isUserInside) ...[
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006C35),
                            foregroundColor: Colors.white,
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
                          label: Text(_selectedTabIndex == 3 ? 'Create First Poll' : 'Write First Report'),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF006C35),
              elevation: 5,
              icon: const Icon(Icons.rate_review_rounded, color: Colors.white, size: 20),
              label: const Text(
                'Write Verified Post',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreatePostScreen(event: event!),
                  ),
                );
              },
            )
          : null,
    );
  }

  Widget _buildMetric(String label, String value, {bool isAccent = false}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: isAccent ? const Color(0xFF006C35) : AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(width: 1, height: 28, color: AppColors.border);
  }

  Widget _buildPostCard(
    BuildContext context, {
    required PostModel post,
    required EventModel event,
    required GeoPoint userLoc,
    required AppState appState,
  }) {
    final bool isUserInside = event.isUserInside(userLoc);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFF1F5F9),
                backgroundImage: NetworkImage(post.authorAvatar),
                onBackgroundImageError: (error, stack) {},
              ),
              const SizedBox(width: 10),
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
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                                'ON-SITE',
                                style: TextStyle(
                                  color: Color(0xFF15803D),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTimeAgo(post.createdAt),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 2),
                        Text(
                          post.locationDisplayName,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Trust: ${post.authorTrustScore}%',
                          style: const TextStyle(color: AppColors.primaryNavy, fontSize: 11, fontWeight: FontWeight.w700),
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
            ),
          ),
          const SizedBox(height: 12),

          // Attachments
          if (post.type == PostType.photo && post.mediaUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SafeImageWidget(
                urlOrData: post.mediaUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
              ),
            ),

          if (post.type == PostType.video && post.videoThumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
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
                      color: Colors.black.withValues(alpha: 0.65),
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
              onVote: (optId) {
                if (!isUserInside) {
                  VerificationRestrictedSheet.show(
                    context,
                    event: event,
                    distanceMeters: event.distanceFromUser(userLoc),
                    customTitle: 'On-Site Poll Voting Required',
                    customMessage: 'The sole purpose of GroundTruth is to verify ground reality. Only eyewitnesses physically located inside ${event.tagName} (${event.formattedRadius} radius) can participate in polls.',
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
                    const SnackBar(
                      backgroundColor: Color(0xFF0D652D),
                      content: Text('Eyewitness poll vote recorded! (+15 XP)'),
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

          // Verification Action Bar: Like & Dislike (ON-SITE RESTRICTED) + Comments (OPEN)
          Row(
            children: [
              // Like / Dislike Container
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    // LIKE (Verify True)
                    InkWell(
                      onTap: () {
                        final res = appState.votePost(
                          eventId: event.id,
                          postId: post.id,
                          direction: 1,
                          userLocation: userLoc,
                        );
                        if (!res.allowed) {
                          VerificationRestrictedSheet.show(
                            context,
                            event: event,
                            distanceMeters: res.distanceMeters ?? event.distanceFromUser(userLoc),
                            onOpenComments: () => CommentsSheet.show(context, event, post),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFF0D652D),
                              content: Text('News verified on-site! +20 XP awarded.'),
                            ),
                          );
                        }
                      },
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              post.userVote == 1 ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
                              size: 15,
                              color: post.userVote == 1 ? const Color(0xFF15803D) : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.upvotes}',
                              style: TextStyle(
                                color: post.userVote == 1 ? const Color(0xFF15803D) : AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, height: 16, color: AppColors.border),

                    // DISLIKE (Dispute False)
                    InkWell(
                      onTap: () {
                        final res = appState.votePost(
                          eventId: event.id,
                          postId: post.id,
                          direction: -1,
                          userLocation: userLoc,
                        );
                        if (!res.allowed) {
                          VerificationRestrictedSheet.show(
                            context,
                            event: event,
                            distanceMeters: res.distanceMeters ?? event.distanceFromUser(userLoc),
                            onOpenComments: () => CommentsSheet.show(context, event, post),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFF991B1B),
                              content: Text('Dispute recorded from on-site position. +20 XP awarded.'),
                            ),
                          );
                        }
                      },
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              post.userVote == -1 ? Icons.thumb_down_rounded : Icons.thumb_down_alt_outlined,
                              size: 15,
                              color: post.userVote == -1 ? const Color(0xFFDC2626) : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.downvotes}',
                              style: TextStyle(
                                color: post.userVote == -1 ? const Color(0xFFDC2626) : AppColors.textSecondary,
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
              ),
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
                    border: Border.all(color: AppColors.border),
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

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }
}
