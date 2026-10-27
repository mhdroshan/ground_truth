import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../models/journalist_model.dart';
import '../providers/app_state.dart';
import '../providers/location_service.dart';
import '../theme/app_colors.dart';
import '../widgets/post/post_card.dart';
import '../widgets/post/verification_restricted_sheet.dart';
import 'comments_sheet.dart';
import 'create_post_screen.dart';
import 'event_detail_screen.dart';
import 'settings_screen.dart';
import 'alerts_screen.dart';
import 'login_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final locationService = context.watch<LocationService>();
    final userLoc = locationService.currentLocation;

    // Detect events user is physically inside
    final eventsUserIsInside = appState.getEventsUserIsInside(userLoc);
    final inLocationEvent = appState.getActiveCurrentLocationEvent(userLoc);

    // Posts for home feed
    final homePosts = appState.getHomePosts();
    final followedWriters = appState.followedJournalists;
    final trendingEvents = appState.events.where((e) => e.isTrending || e.isHighActivity).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'GroundTruth',
              style: TextStyle(
                color: AppColors.primaryNavy,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        actions: [
          // Activity & Alerts Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primaryNavy, size: 22),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AlertsScreen()),
                  );
                },
              ),
              if (appState.alerts.any((a) => !a.isRead))
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          if (!appState.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.login_rounded, color: AppColors.primaryNavy, size: 21),
              tooltip: 'Log In',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.primaryNavy, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Achievement celebration banner (if recently unlocked)
            if (appState.recentlyUnlockedAchievement != null)
              _buildAchievementToast(context, appState),

            // HERO REQUIREMENT: Current location event prompt
            _buildCurrentLocationHero(context, inLocationEvent, userLoc),

            // INTERESTS SECTION: Selection based feed
            _buildInterestsSection(context, appState),

            // WRITERS & JOURNALISTS YOU FOLLOW SECTION
            _buildFollowedWritersSection(context, appState, followedWriters),

            // TRENDING TAGS CAROUSEL
            _buildTrendingTagsSection(context, appState, trendingEvents, userLoc),

            const SizedBox(height: 8),

            // FEED FILTER TABS (Interests / Following / Trending / All)
            _buildFeedFilterTabs(context, appState, homePosts.length),

            // Active Writer / Tag specific filter badge
            if (appState.homeWriterFilterId != null || appState.homeTagFilter != null)
              _buildActiveFilterBanner(context, appState),

            const SizedBox(height: 10),

            // POSTS FEED
            if (homePosts.isEmpty)
              _buildEmptyFeedState(context, appState)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: homePosts.length,
                itemBuilder: (context, index) {
                  final post = homePosts[index];
                  final event = appState.getEventForPost(post);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag header badge above each post
                      if (event != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventDetailScreen(eventId: event.id),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD0E1FD),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.tag, size: 12, color: AppColors.primaryNavy),
                                      const SizedBox(width: 3),
                                      Text(
                                        event.tagName,
                                        style: const TextStyle(
                                          color: AppColors.primaryNavy,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '• ${event.city}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 10.5,
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

                      PostCard(
                        post: post,
                        onVote: (direction) {
                          final res = appState.votePost(
                            eventId: post.eventId,
                            postId: post.id,
                            direction: direction,
                            userLocation: userLoc,
                          );

                          if (!res.allowed) {
                            if (event != null) {
                              VerificationRestrictedSheet.show(
                                context,
                                event: event,
                                distanceMeters: res.distanceMeters ?? event.distanceFromUser(userLoc),
                                onOpenComments: () => CommentsSheet.show(context, event, post),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Color(0xFF0D652D),
                                content: Text('News verified on-site! +20 XP awarded.'),
                              ),
                            );
                          }
                        },
                        onPollVote: (optId) {
                          final res = appState.votePoll(
                            eventId: post.eventId,
                            postId: post.id,
                            optionId: optId,
                            userLocation: userLoc,
                          );
                          if (!res.allowed) {
                            if (event != null) {
                              VerificationRestrictedSheet.show(
                                context,
                                event: event,
                                distanceMeters: res.distanceMeters ?? event.distanceFromUser(userLoc),
                                customTitle: 'On-Site Poll Voting Required',
                                customMessage: 'The sole purpose of GroundTruth is to verify ground reality. Only eyewitnesses physically located inside ${event.tagName} (${event.formattedRadius} radius) can participate in polls.',
                                onOpenComments: () => CommentsSheet.show(context, event, post),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.alertRed,
                                  content: Text(res.message ?? 'Only eyewitnesses on-site can vote in polls.'),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Color(0xFF0D652D),
                                content: Text('Eyewitness poll vote recorded! (+15 XP)'),
                              ),
                            );
                          }
                        },
                        onOpenComments: () {
                          if (event != null) {
                            CommentsSheet.show(context, event, post);
                          }
                        },
                      ),
                    ],
                  );
                },
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: eventsUserIsInside.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF006C35),
              elevation: 6,
              icon: const Icon(Icons.rate_review_rounded, color: Colors.white, size: 22),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Write Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      eventsUserIsInside.first.tagName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreatePostScreen(event: eventsUserIsInside.first),
                  ),
                );
              },
            )
          : null,
    );
  }

  /// Interests Selector Chips Section
  Widget _buildInterestsSection(BuildContext context, AppState appState) {
    final availableInterests = [
      (EventCategory.protest, 'Protests & Rights', Icons.campaign_rounded),
      (EventCategory.naturalDisaster, 'Disasters & Floods', Icons.warning_rounded),
      (EventCategory.fire, 'Fires & Hazards', Icons.local_fire_department_rounded),
      (EventCategory.weather, 'Severe Weather', Icons.thunderstorm_rounded),
      (EventCategory.election, 'Elections & Politics', Icons.how_to_vote_rounded),
      (EventCategory.war, 'Conflict & Defense', Icons.shield_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune_rounded, size: 16, color: AppColors.primaryNavy),
                  SizedBox(width: 6),
                  Text(
                    'Your Selected Interests',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  appState.selectAllInterests();
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Select All',
                  style: TextStyle(
                    color: AppColors.primaryNavy,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availableInterests.map((item) {
                final cat = item.$1;
                final label = item.$2;
                final icon = item.$3;
                final isSelected = appState.isInterestSelected(cat);

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    avatar: Icon(
                      icon,
                      size: 13,
                      color: isSelected ? Colors.white : AppColors.primaryNavy,
                    ),
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (val) {
                      appState.toggleInterest(cat);
                    },
                    selectedColor: AppColors.primaryNavy,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryNavy : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Followed Writers & Journalists Section
  Widget _buildFollowedWritersSection(
    BuildContext context,
    AppState appState,
    List<JournalistModel> followedWriters,
  ) {
    final allJournalists = appState.journalists;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF15803D)),
                  SizedBox(width: 6),
                  Text(
                    'Writers You Follow',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Text(
                '${followedWriters.length} Following',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: allJournalists.map((writer) {
                final isFilteringThisWriter = appState.homeWriterFilterId == writer.id;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      if (isFilteringThisWriter) {
                        appState.setHomeWriterFilter(null);
                      } else {
                        appState.setHomeWriterFilter(writer.id);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isFilteringThisWriter ? const Color(0xFFD0E1FD) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isFilteringThisWriter
                              ? AppColors.primaryNavy
                              : (writer.isFollowed ? const Color(0xFF86EFAC) : AppColors.border),
                          width: isFilteringThisWriter ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(writer.avatarUrl),
                            onBackgroundImageError: (exception, stackTrace) {},
                            backgroundColor: const Color(0xFFF1F5F9),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    writer.name.split(' ').first,
                                    style: TextStyle(
                                      color: isFilteringThisWriter
                                          ? AppColors.primaryNavy
                                          : AppColors.textPrimary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (writer.isFollowed)
                                    const Icon(Icons.check_circle, size: 11, color: Color(0xFF15803D)),
                                ],
                              ),
                              Text(
                                '${writer.trustScore}% Trust',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Trending Tags Section
  Widget _buildTrendingTagsSection(
    BuildContext context,
    AppState appState,
    List<EventModel> trendingEvents,
    userLoc,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department_rounded, size: 16, color: Color(0xFFD97706)),
              SizedBox(width: 6),
              Text(
                'Trending Tags',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: appState.events.take(6).map((ev) {
                final isFilterActive = appState.homeTagFilter?.toLowerCase() == ev.tagName.toLowerCase();

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    avatar: Icon(
                      ev.isUserInside(userLoc) ? Icons.my_location : Icons.tag,
                      size: 13,
                      color: isFilterActive
                          ? Colors.white
                          : (ev.isUserInside(userLoc) ? const Color(0xFF15803D) : AppColors.primaryNavy),
                    ),
                    label: Text('${ev.tagName} (${ev.totalPosts})'),
                    labelStyle: TextStyle(
                      color: isFilterActive ? Colors.white : AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: isFilterActive ? FontWeight.w800 : FontWeight.w600,
                    ),
                    backgroundColor: isFilterActive ? AppColors.primaryNavy : Colors.white,
                    side: BorderSide(
                      color: isFilterActive ? AppColors.primaryNavy : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onPressed: () {
                      if (isFilterActive) {
                        appState.setHomeTagFilter(null);
                      } else {
                        appState.setHomeTagFilter(ev.tagName);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Segmented Feed Filter Tabs
  Widget _buildFeedFilterTabs(BuildContext context, AppState appState, int postsCount) {
    final active = appState.homeFeedFilter;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _buildFeedFilterTabItem('My Interests', HomeFeedFilter.interests, active, appState),
            _buildFeedFilterTabItem('Following', HomeFeedFilter.following, active, appState),
            _buildFeedFilterTabItem('Trending', HomeFeedFilter.trending, active, appState),
            _buildFeedFilterTabItem('All Posts', HomeFeedFilter.all, active, appState),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedFilterTabItem(
    String label,
    HomeFeedFilter filter,
    HomeFeedFilter activeFilter,
    AppState appState,
  ) {
    final isSelected = activeFilter == filter && appState.homeWriterFilterId == null && appState.homeTagFilter == null;

    return Expanded(
      child: InkWell(
        onTap: () {
          appState.setHomeFeedFilter(filter);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// Active filter banner
  Widget _buildActiveFilterBanner(BuildContext context, AppState appState) {
    String label = '';
    if (appState.homeWriterFilterId != null) {
      final writer = appState.journalists.where((j) => j.id == appState.homeWriterFilterId).firstOrNull;
      label = 'Filtering posts by ${writer?.name ?? "selected writer"}';
    } else if (appState.homeTagFilter != null) {
      label = 'Filtering posts under ${appState.homeTagFilter}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFD0E1FD),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryNavy,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            InkWell(
              onTap: () {
                appState.setHomeWriterFilter(null);
                appState.setHomeTagFilter(null);
              },
              child: const Icon(Icons.close, size: 16, color: AppColors.primaryNavy),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty Feed State
  Widget _buildEmptyFeedState(BuildContext context, AppState appState) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.feed_outlined, size: 44, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text(
            'No posts match your selected filter',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try selecting more interests or following more journalists to populate your live feed.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              appState.setHomeFeedFilter(HomeFeedFilter.all);
            },
            child: const Text('Show All Posts', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  /// HERO REQUIREMENT: Current location event prompt
  Widget _buildCurrentLocationHero(BuildContext context, EventModel? activeEvent, userLoc) {
    if (activeEvent != null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A192F), Color(0xFF1E3A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE IN YOUR LOCATION',
                        style: TextStyle(
                          color: Color(0xFFFECACA),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    activeEvent.tagName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              activeEvent.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.campaign_rounded, color: Color(0xFFFBBF24), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Eyewitness Verification Needed!',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'There is an event happening in your location (${activeEvent.formattedRadius} radius). Please write something about what is happening around you!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreatePostScreen(event: activeEvent),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 20, color: Colors.black),
                    label: const Text(
                      'Write Post Now',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailScreen(eventId: activeEvent.id),
                        ),
                      );
                    },
                    child: const Text(
                      'View Tag',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildAchievementToast(BuildContext context, AppState appState) {
    final ach = appState.recentlyUnlockedAchievement;
    if (ach == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ach.tier.badgeBackgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: ach.tier.primaryColor),
            ),
            child: Icon(ach.icon, size: 20, color: ach.tier.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'ACHIEVEMENT UNLOCKED!',
                      style: TextStyle(
                        color: Color(0xFFB45309),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+${ach.xpReward} XP',
                      style: const TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Text(
                  ach.title,
                  style: const TextStyle(
                    color: AppColors.primaryNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Color(0xFFB45309)),
            onPressed: () => appState.clearRecentAchievement(),
          ),
        ],
      ),
    );
  }
}
