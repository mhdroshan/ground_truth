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
import 'event_detail_screen.dart';

class ReadScreen extends StatefulWidget {
  const ReadScreen({super.key});

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'trending'; // 'trending', 'mostComments', 'mostLikes'
  int _searchFilterTab = 0; // 0: All, 1: Tags, 2: Journalists

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final locationService = context.watch<LocationService>();
    final userLoc = locationService.currentLocation;

    final events = appState.events;
    final journalists = appState.journalists;
    final trendingPosts = appState.getWorldwideTrendingPosts(sortBy: _sortBy);

    // Search filtering
    final q = _searchQuery.trim().toLowerCase();
    final matchingTags = q.isEmpty
        ? <EventModel>[]
        : events.where((e) =>
            e.tagName.toLowerCase().contains(q) ||
            e.title.toLowerCase().contains(q) ||
            e.city.toLowerCase().contains(q) ||
            e.country.toLowerCase().contains(q) ||
            e.category.label.toLowerCase().contains(q)).toList();

    final matchingJournalists = q.isEmpty
        ? <JournalistModel>[]
        : journalists.where((j) =>
            j.name.toLowerCase().contains(q) ||
            j.handle.toLowerCase().contains(q) ||
            j.organization.toLowerCase().contains(q) ||
            j.bio.toLowerCase().contains(q)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFD0E1FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppColors.primaryNavy,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global Read & Discover',
                  style: TextStyle(
                    color: AppColors.primaryNavy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Worldwide Trending • Forensic Eyewitness Reports',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SEARCH BOX (Moved from Homepage to Read page as requested)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.primaryNavy, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                        },
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Search tags (#FarmersMarch) or journalists (@ananya)...',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                  ],
                ),
              ),
            ),

            // If Search Query is active -> Show Search Results (Tags & Journalists)
            if (_searchQuery.isNotEmpty)
              _buildSearchResults(context, appState, matchingTags, matchingJournalists)
            else ...[
              // WORLDWIDE TRENDING SECTION HEADER & SORT CHIPS
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded, color: Color(0xFFD97706), size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Worldwide Trending Posts',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Ranked by highest global engagement, comments, and on-site eyewitness likes',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Sort Tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSortChip(
                            label: 'Top Trending',
                            icon: Icons.trending_up_rounded,
                            sortKey: 'trending',
                          ),
                          const SizedBox(width: 8),
                          _buildSortChip(
                            label: 'Most Comments',
                            icon: Icons.chat_bubble_outline_rounded,
                            sortKey: 'mostComments',
                          ),
                          const SizedBox(width: 8),
                          _buildSortChip(
                            label: 'Most Likes',
                            icon: Icons.thumb_up_alt_outlined,
                            sortKey: 'mostLikes',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // TRENDING POSTS FEED
              if (trendingPosts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'No trending posts available right now.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trendingPosts.length,
                  itemBuilder: (context, index) {
                    final post = trendingPosts[index];
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
                                        ? 'On-site verification vote recorded! (+20 XP)'
                                        : 'Dispute recorded from on-site position. (+20 XP)'),
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
                    );
                  },
                ),

              const SizedBox(height: 80),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip({
    required String label,
    required IconData icon,
    required String sortKey,
  }) {
    final isSelected = _sortBy == sortKey;
    return InkWell(
      onTap: () => setState(() => _sortBy = sortKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryNavy.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    AppState appState,
    List<EventModel> matchingTags,
    List<JournalistModel> matchingJournalists,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Tabs (All / Tags / Journalists)
          Row(
            children: [
              _buildSearchFilterChip(0, 'All (${matchingTags.length + matchingJournalists.length})'),
              const SizedBox(width: 8),
              _buildSearchFilterChip(1, 'Tags (${matchingTags.length})'),
              const SizedBox(width: 8),
              _buildSearchFilterChip(2, 'Journalists (${matchingJournalists.length})'),
            ],
          ),
          const SizedBox(height: 16),

          // No results
          if (matchingTags.isEmpty && matchingJournalists.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 44, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text(
                    'No tags or journalists found',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Try searching with keywords like #protest, flood, Delhi, @ananya...',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Matching Tags
          if ((_searchFilterTab == 0 || _searchFilterTab == 1) && matchingTags.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.tag, size: 16, color: AppColors.primaryNavy),
                SizedBox(width: 6),
                Text(
                  'Event Tags',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...matchingTags.map((tag) => _buildTagSearchResultCard(context, tag)),
            const SizedBox(height: 16),
          ],

          // Matching Journalists
          if ((_searchFilterTab == 0 || _searchFilterTab == 2) && matchingJournalists.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.person_search_rounded, size: 18, color: AppColors.primaryNavy),
                SizedBox(width: 6),
                Text(
                  'Writers & Verified Journalists',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...matchingJournalists.map((j) => _buildJournalistSearchResultCard(context, appState, j)),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchFilterChip(int index, String label) {
    final isSel = _searchFilterTab == index;
    return InkWell(
      onTap: () => setState(() => _searchFilterTab = index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFD0E1FD) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? AppColors.primaryNavy : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? AppColors.primaryNavy : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTagSearchResultCard(BuildContext context, EventModel tag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFD0E1FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tag_rounded, color: AppColors.primaryNavy, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag.tagName,
                  style: const TextStyle(
                    color: AppColors.primaryNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${tag.title} • ${tag.city}, ${tag.country}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${tag.activeContributors} contributors • ${tag.totalPosts} posts • ${tag.formattedRadius} Radius',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailScreen(eventId: tag.id),
                ),
              );
            },
            child: const Text('Read Tag', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalistSearchResultCard(
    BuildContext context,
    AppState appState,
    JournalistModel journalist,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage(journalist.avatarUrl),
            backgroundColor: const Color(0xFFF1F5F9),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      journalist.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${journalist.trustScore}% TRUST',
                        style: const TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${journalist.handle} • ${journalist.organization}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  journalist.bio,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: journalist.isFollowed ? const Color(0xFFF1F5F9) : AppColors.primaryNavy,
              foregroundColor: journalist.isFollowed ? AppColors.textPrimary : Colors.white,
              side: BorderSide(
                color: journalist.isFollowed ? AppColors.border : AppColors.primaryNavy,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              appState.toggleFollowJournalist(journalist.id);
            },
            child: Text(
              journalist.isFollowed ? 'Following' : 'Follow',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
