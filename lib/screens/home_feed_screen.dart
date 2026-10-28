import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../providers/app_state.dart';
import '../providers/location_service.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/post/post_card.dart';
import '../widgets/post/verification_restricted_sheet.dart';
import '../widgets/common/live_location_tags_slider.dart';
import '../widgets/common/safe_image.dart';
import 'comments_sheet.dart';
import 'create_post_screen.dart';
import 'settings_screen.dart';
import 'alerts_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

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
    if (appState.selectedEventId != null) {
      final selectedIdx = eventsUserIsInside.indexWhere((e) => e.id == appState.selectedEventId);
      if (selectedIdx > 0) {
        final selected = eventsUserIsInside.removeAt(selectedIdx);
        eventsUserIsInside.insert(0, selected);
      }
    }

    // Posts for home feed
    final homePosts = appState.getHomePosts();
    final followedProfiles = appState.getFollowedProfiles();
    final trendingEvents = appState.events.where((e) => e.isTrending || e.isHighActivity).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryNavy.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'GroundTruth',
              style: TextStyle(
                color: AppColors.primaryNavy,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Activity & Alerts Bell with Liquid Indicator
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
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
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
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryNavy,
        onRefresh: () async {
          await appState.loadRemoteDatabaseData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Database syncing progress bar
              if (appState.isLoadingFromDb)
                const LinearProgressIndicator(
                  minHeight: 2.5,
                  backgroundColor: Colors.transparent,
                  color: AppColors.primaryNavy,
                ),

              // Achievement celebration banner (if recently unlocked)
              if (appState.recentlyUnlockedAchievement != null)
                _buildAchievementToast(context, appState),

              // HERO REQUIREMENT: Current location event prompt (Auto-sliding tags matching location)
              LiveLocationTagsSlider(events: eventsUserIsInside),

              // INTERESTS SECTION: Selection based feed (Bento style)
              _buildInterestsSection(context, appState),

              // PROFILES YOU FOLLOW SECTION (Real profiles from followers/following)
              _buildFollowedProfilesSection(context, appState, followedProfiles),

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

                    return PostCard(
                      post: post,
                      isInsideGeofence: appState.isUserInsidePostGeofence(post, userLoc),
                      onVote: (direction) {
                        final res = appState.votePost(
                          eventId: post.eventId,
                          postId: post.id,
                          direction: direction,
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
                                  : (res.userVote == -1
                                      ? const Color(0xFF991B1B)
                                      : const Color(0xFF0D652D)),
                              content: Text(
                                res.isRemoved
                                    ? (direction == 1 ? 'Verification vote removed.' : 'Dispute vote removed.')
                                    : (res.userVote == 1
                                        ? 'News verified! +20 XP awarded.'
                                        : 'Dispute recorded. +20 XP awarded.'),
                              ),
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
                              customMessage: 'The sole purpose of GroundTruth is to verify ground reality. Only eyewitnesses physically located inside ${event.tagName} (${event.formattedRadius} radius) can participate in polls. Others can only view results.',
                              onOpenComments: () => CommentsSheet.show(context, event, post),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.alertRed,
                                content: Text(res.message ?? 'Only eyewitnesses on-site can vote in polls. Others can only view results.'),
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 2),
                              backgroundColor: const Color(0xFF0D652D),
                              content: Text(res.isChanged
                                  ? 'Eyewitness poll vote updated!'
                                  : 'Eyewitness poll vote recorded! (+15 XP)'),
                            ),
                          );
                        }
                      },
                      onOpenComments: () {
                        if (event != null) {
                          CommentsSheet.show(context, event, post);
                        }
                      },
                    );
                  },
                ),

              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
      floatingActionButton: eventsUserIsInside.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF006C35),
              elevation: 8,
              icon: const Icon(Icons.rate_review_rounded, color: Colors.white, size: 21),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Write Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      eventsUserIsInside.first.tagName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
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

  /// Interests Selector Chips Section (Bento Grid Inspired)
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
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                      width: 0.9,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Followed Profiles Section (Modular Bento Horizontal Row)
  Widget _buildFollowedProfilesSection(
    BuildContext context,
    AppState appState,
    List<UserModel> followedProfiles,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.people_alt_rounded, size: 14, color: Color(0xFF15803D)),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Profiles You Follow',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showDiscoverContributorsSheet(context, appState),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        followedProfiles.isNotEmpty
                            ? '${followedProfiles.length} Following'
                            : '+ Follow',
                        style: const TextStyle(
                          color: AppColors.primaryNavy,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primaryNavy),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (followedProfiles.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...followedProfiles.map((profile) {
                    final isFilteringThis = appState.homeWriterFilterId == profile.id;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          if (isFilteringThis) {
                            appState.setHomeWriterFilter(null);
                          } else {
                            appState.setHomeWriterFilter(profile.id);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isFilteringThis ? const Color(0xFFD0E1FD) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isFilteringThis
                                  ? AppColors.primaryNavy
                                  : AppColors.bentoBorder,
                              width: isFilteringThis ? 1.5 : 0.9,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x060F172A),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ProfileScreen(
                                        userId: profile.id,
                                        initialAuthorName: profile.name,
                                        initialAuthorAvatar: profile.avatarUrl,
                                        initialAuthorTrustScore: profile.trustScore,
                                        isVerifiedJournalist: profile.isJournalist,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 15,
                                      backgroundImage: getUserAvatarProvider(profile.avatarUrl),
                                      onBackgroundImageError: (err, stack) {},
                                      backgroundColor: const Color(0xFF0F172A),
                                      child: profile.avatarUrl.isEmpty
                                          ? Text(
                                              profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF15803D),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        profile.name.split(' ').first,
                                        style: TextStyle(
                                          color: isFilteringThis
                                              ? AppColors.primaryNavy
                                              : AppColors.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF15803D)),
                                    ],
                                  ),
                                  Text(
                                    '${profile.trustScore}% Trust',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
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
                  }),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _showDiscoverContributorsSheet(context, appState),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_add_alt_1_outlined, size: 16, color: AppColors.primaryNavy),
                            SizedBox(width: 6),
                            Text(
                              'Discover',
                              style: TextStyle(
                                color: AppColors.primaryNavy,
                                fontSize: 11.5,
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
            )
          else
            InkWell(
              onTap: () => _showDiscoverContributorsSheet(context, appState),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border, width: 0.9),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x060F172A),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_rounded, size: 18, color: AppColors.primaryNavy),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Follow Eyewitness Contributors',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Follow real observers to curate your personalized ground reality feed.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Discover',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
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

  /// Trending Tags Section (Bento Modular Chips)
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
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
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
                      fontWeight: isFilterActive ? FontWeight.w900 : FontWeight.w600,
                    ),
                    backgroundColor: isFilterActive ? AppColors.primaryNavy : Colors.white,
                    side: BorderSide(
                      color: isFilterActive ? AppColors.primaryNavy : AppColors.border,
                      width: 0.9,
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

  /// Segmented Feed Filter Tabs (Liquid Glass Pill)
  Widget _buildFeedFilterTabs(BuildContext context, AppState appState, int postsCount) {
    final active = appState.homeFeedFilter;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.bentoBorder, width: 0.9),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
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
      final profile = appState.getUserProfile(appState.homeWriterFilterId!);
      label = 'Filtering posts by ${profile.name}';
    } else if (appState.homeTagFilter != null) {
      label = 'Filtering posts under ${appState.homeTagFilter}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFD0E1FD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryNavy,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            InkWell(
              onTap: () {
                appState.setHomeWriterFilter(null);
                appState.setHomeTagFilter(null);
              },
              child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primaryNavy),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty Feed State
  Widget _buildEmptyFeedState(BuildContext context, AppState appState) {
    final isFollowingFilter = appState.homeFeedFilter == HomeFeedFilter.following;

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            isFollowingFilter ? Icons.person_add_alt_1_rounded : Icons.feed_outlined,
            size: 44,
            color: isFollowingFilter ? AppColors.primaryNavy : AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            isFollowingFilter
                ? 'No updates from people you follow'
                : 'No posts match your selected filter',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            isFollowingFilter
                ? 'Follow verified journalists and eyewitness contributors to curate your personal ground-truth feed.'
                : 'Try selecting more interests or following more journalists to populate your live feed.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (isFollowingFilter)
            ElevatedButton.icon(
              icon: const Icon(Icons.person_search_rounded, size: 16),
              label: const Text('Discover People to Follow', style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () => _showDiscoverContributorsSheet(context, appState),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                appState.setHomeFeedFilter(HomeFeedFilter.all);
              },
              child: const Text('Show All Posts', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }

  /// Bottom sheet to discover real eyewitnesses and contributors to follow
  void _showDiscoverContributorsSheet(BuildContext context, AppState appState) {
    final currentUserId = appState.currentUser.id;

    // Collect real authors from active posts first
    final Map<String, UserModel> initialMap = {};
    for (final post in appState.allPosts) {
      final aId = post.authorId;
      if (aId.isNotEmpty &&
          aId != currentUserId &&
          !aId.startsWith('auth_') &&
          !aId.startsWith('seed_')) {
        if (!initialMap.containsKey(aId)) {
          initialMap[aId] = appState.getUserProfile(
            aId,
            fallbackName: post.authorName,
            fallbackAvatar: post.authorAvatar,
            fallbackTrustScore: post.authorTrustScore,
            isVerifiedJournalist: post.authorIsVerifiedJournalist,
          );
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return _DiscoverContributorsModal(
          appState: appState,
          initialContributors: initialMap.values.toList(),
          modalContext: modalCtx,
        );
      },
    );
  }

  Widget _buildAchievementToast(BuildContext context, AppState appState) {
    final ach = appState.recentlyUnlockedAchievement;
    if (ach == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+${ach.xpReward} XP',
                      style: const TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
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
            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFB45309)),
            onPressed: () => appState.clearRecentAchievement(),
          ),
        ],
      ),
    );
  }
}

class _DiscoverContributorsModal extends StatefulWidget {
  final AppState appState;
  final List<UserModel> initialContributors;
  final BuildContext modalContext;

  const _DiscoverContributorsModal({
    required this.appState,
    required this.initialContributors,
    required this.modalContext,
  });

  @override
  State<_DiscoverContributorsModal> createState() => _DiscoverContributorsModalState();
}

class _DiscoverContributorsModalState extends State<_DiscoverContributorsModal> {
  late List<UserModel> _contributors;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _contributors = List.from(widget.initialContributors);
    _loadRemoteUsers();
  }

  Future<void> _loadRemoteUsers() async {
    setState(() => _isLoading = true);
    try {
      final remoteUsers = await ApiService.searchUsers(
        '',
        token: widget.appState.authToken,
        followerId: widget.appState.currentUser.id,
      );

      if (mounted && remoteUsers != null) {
        final currentId = widget.appState.currentUser.id;
        final map = <String, UserModel>{};

        for (final u in remoteUsers) {
          if (u.id != currentId && !u.id.startsWith('auth_') && !u.id.startsWith('seed_')) {
            map[u.id] = u;
          }
        }

        for (final u in _contributors) {
          if (u.id != currentId && !u.id.startsWith('auth_') && !u.id.startsWith('seed_')) {
            map.putIfAbsent(u.id, () => u);
          }
        }

        setState(() {
          _contributors = map.values.toList();
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Discover Contributors',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryNavy,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Follow verified eyewitnesses & ground reporters',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(widget.modalContext).pop(),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  color: AppColors.primaryNavy,
                ),
              const Divider(height: 1),
              Expanded(
                child: _contributors.isEmpty && !_isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text(
                                'No other contributors found yet',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'New eyewitnesses registering or posting ground reports will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _contributors.length,
                        separatorBuilder: (context, index) => const Divider(height: 16),
                        itemBuilder: (context, idx) {
                          final contributor = _contributors[idx];
                          final isFollowing = widget.appState.isFollowing(contributor.id);

                          return InkWell(
                            onTap: () {
                              Navigator.of(widget.modalContext).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProfileScreen(
                                    userId: contributor.id,
                                    initialAuthorName: contributor.name,
                                    initialAuthorAvatar: contributor.avatarUrl,
                                    initialAuthorTrustScore: contributor.trustScore,
                                    isVerifiedJournalist: contributor.isJournalist,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundImage: getUserAvatarProvider(contributor.avatarUrl),
                                        onBackgroundImageError: (err, stack) {},
                                        backgroundColor: const Color(0xFF0F172A),
                                        child: contributor.avatarUrl.isEmpty
                                            ? Text(
                                                contributor.name.isNotEmpty
                                                    ? contributor.name[0].toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check_circle,
                                            size: 13,
                                            color: AppColors.verifiedGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          contributor.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          contributor.handle.isNotEmpty
                                              ? '${contributor.handle} • ${contributor.tier}'
                                              : contributor.tier,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFDCFCE7),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${contributor.trustScore}% Trust',
                                                style: const TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF15803D),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${contributor.followersCount} followers',
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () async {
                                      await widget.appState.toggleFollowUser(
                                        contributor.id,
                                        userName: contributor.name,
                                        userAvatar: contributor.avatarUrl,
                                        userTrustScore: contributor.trustScore,
                                        isJournalist: contributor.isJournalist,
                                      );
                                      if (mounted) setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isFollowing
                                          ? const Color(0xFFE2E8F0)
                                          : AppColors.primaryNavy,
                                      foregroundColor: isFollowing
                                          ? AppColors.textPrimary
                                          : Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                          color: isFollowing
                                              ? AppColors.border
                                              : AppColors.primaryNavy,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      isFollowing ? 'Following' : '+ Follow',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
