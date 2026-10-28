import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../providers/app_state.dart';
import '../providers/location_service.dart';
import '../theme/app_colors.dart';
import '../utils/geofence_math.dart';
import 'create_post_screen.dart';
import 'create_tag_screen.dart';
import 'event_detail_screen.dart';

class WriteScreen extends StatefulWidget {
  const WriteScreen({super.key});

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  EventCategory? _selectedCategory;

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

    // Detect real events user is physically inside (excluding dummy tags)
    final eventsUserIsInside = appState.getEventsUserIsInside(userLoc)
        .where((e) => !AppState.isDummyTag(e.id))
        .toList();

    // Filter real events only (all dummy mock seed tags are removed)
    var tags = List<EventModel>.from(appState.realEvents);
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      tags = tags.where((e) =>
          e.tagName.toLowerCase().contains(q) ||
          e.title.toLowerCase().contains(q) ||
          e.city.toLowerCase().contains(q) ||
          e.country.toLowerCase().contains(q) ||
          e.category.label.toLowerCase().contains(q)).toList();
    }
    if (_selectedCategory != null) {
      tags = tags.where((e) => e.category == _selectedCategory).toList();
    }

    // Sort tags based on geofence boundary:
    // 1. Tags user is physically INSIDE the boundary come first
    // 2. Tags outside the boundary follow
    // 3. Within each group, closest tags (lowest distance) appear first
    tags.sort((a, b) {
      final aInside = a.isUserInside(userLoc);
      final bInside = b.isUserInside(userLoc);
      if (aInside && !bInside) return -1;
      if (!aInside && bInside) return 1;
      final aDist = a.distanceFromUser(userLoc);
      final bDist = b.distanceFromUser(userLoc);
      return aDist.compareTo(bDist);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: AppColors.primaryNavy,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Write Report',
                  style: TextStyle(
                    color: AppColors.primaryNavy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'Select verified tag to submit eyewitness telemetry',
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateTagScreen()),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 15, color: AppColors.primaryNavy),
              label: const Text(
                'New Tag',
                style: TextStyle(
                  color: AppColors.primaryNavy,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryNavy,
        onRefresh: () async {
          await Future.wait([
            appState.loadRemoteDatabaseData(),
            locationService.refreshPhysicalLocation(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PROXIMITY HERO BANNER (When inside an event tag)
              if (eventsUserIsInside.isNotEmpty)
                _buildInsideTagHero(context, eventsUserIsInside.first)
              else
                _buildLocationInfoBanner(context, locationService),

              const SizedBox(height: 16),

              // Tag Search & Quick Filter Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.bentoBorder, width: 0.9),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x060F172A),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.primaryNavy, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                        decoration: const InputDecoration(
                          hintText: 'Search active tags by name, city, or category...',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Category Chips Carousel
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('All Categories', null),
                    const SizedBox(width: 6),
                    _buildCategoryChip('Protests', EventCategory.protest),
                    const SizedBox(width: 6),
                    _buildCategoryChip('Disasters', EventCategory.naturalDisaster),
                    const SizedBox(width: 6),
                    _buildCategoryChip('Fires', EventCategory.fire),
                    const SizedBox(width: 6),
                    _buildCategoryChip('Weather', EventCategory.weather),
                    const SizedBox(width: 6),
                    _buildCategoryChip('Elections', EventCategory.election),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Section Header (Exaggerated Minimalism)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Reporting Zones',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    eventsUserIsInside.isNotEmpty
                        ? '${eventsUserIsInside.length} in zone • ${tags.length} tags'
                        : '${tags.length} Active Tags',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Tag List
              if (appState.isLoadingFromDb && tags.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Loading verified tags from database...',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              else if (tags.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.tag_faces_rounded, size: 44, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty || _selectedCategory != null
                            ? 'No matching event tags found'
                            : 'No active event tags yet',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _searchQuery.isNotEmpty || _selectedCategory != null
                            ? 'Try clearing filters or search terms.'
                            : 'Be the first to create a verified tag with a custom geofence radius.',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreateTagScreen()),
                          );
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Create New Event Tag', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tags.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ev = tags[index];
                    final isInside = ev.isUserInside(userLoc);
                    final distance = ev.distanceFromUser(userLoc);

                    return _buildTagCard(context, ev, isInside, distance, locationService);
                  },
                ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsideTagHero(BuildContext context, EventModel insideEvent) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F5132), Color(0xFF198754), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 18,
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
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified, size: 14, color: Color(0xFF0F5132)),
              ),
              const SizedBox(width: 8),
              const Text(
                'INSIDE VERIFIED GEOFENCE ZONE',
                style: TextStyle(
                  color: Color(0xFFD1E7DD),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insideEvent.tagName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            '${insideEvent.title} (${insideEvent.formattedRadius} Radius)',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F5132),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreatePostScreen(event: insideEvent),
                  ),
                );
              },
              icon: const Icon(Icons.rate_review_rounded, size: 18),
              label: const Text(
                'Draft Eyewitness Report Now',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfoBanner(BuildContext context, LocationService locationService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.radar_rounded, color: Color(0xFF1D4ED8), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Physical Geofence Radar Enforced',
                      style: TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'GroundTruth eliminates bot rumors. Posting is strictly restricted to devices physically inside the verified perimeter.',
                      style: TextStyle(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.8),
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Row(
              children: [
                Icon(
                  locationService.isLocating
                      ? Icons.radar_rounded
                      : (locationService.hasRealGpsFix ? Icons.my_location_rounded : Icons.location_searching_rounded),
                  size: 16,
                  color: const Color(0xFF1D4ED8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    locationService.isLocating
                        ? 'Acquiring high-precision GNSS satellite fix...'
                        : (locationService.hasRealGpsFix
                            ? 'GPS Location: ${locationService.displayLocationName}'
                            : (locationService.locationStatus ?? 'Checking device GPS location...')),
                    style: const TextStyle(
                      color: AppColors.primaryNavy,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => locationService.refreshPhysicalLocation(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (locationService.isLocating)
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF1D4ED8)),
                          )
                        else
                          const Icon(Icons.refresh_rounded, size: 12, color: Color(0xFF1D4ED8)),
                        const SizedBox(width: 4),
                        const Text(
                          'Update GPS',
                          style: TextStyle(
                            color: Color(0xFF1D4ED8),
                            fontSize: 10,
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
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, EventCategory? category) {
    final isSelected = _selectedCategory == category;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = category),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.border,
            width: 0.9,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primaryNavy.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTagCard(
    BuildContext context,
    EventModel ev,
    bool isInside,
    double distance,
    LocationService locationService,
  ) {
    void openTagFeed() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventDetailScreen(eventId: ev.id),
        ),
      );
    }

    final locationStr = ev.cleanLocation;
    final contributorStr = ev.activeContributors == 1
        ? '1 contributor'
        : '${ev.activeContributors} contributors';
    final postsStr = ev.totalPosts == 1 ? '1 post' : '${ev.totalPosts} posts';
    final subtitleText = locationStr.isNotEmpty
        ? '$locationStr • $contributorStr • $postsStr'
        : '$contributorStr • $postsStr';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isInside ? const Color(0xFF86EFAC) : AppColors.bentoBorder,
          width: isInside ? 1.5 : 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: isInside
                ? const Color(0xFF15803D).withValues(alpha: 0.08)
                : const Color(0x060F172A),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tappable Header & Body
            InkWell(
              onTap: openTagFeed,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Tag, Category, Radius
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                          ),
                          child: Text(
                            ev.tagName,
                            style: const TextStyle(
                              color: AppColors.primaryNavy,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            ev.category.label,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Geofence status & radius pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: isInside ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isInside ? const Color(0xFF86EFAC) : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isInside) ...[
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF16A34A),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'In Zone • ${ev.formattedRadius}',
                                  style: const TextStyle(
                                    color: Color(0xFF15803D),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ] else ...[
                                const Icon(
                                  Icons.near_me_outlined,
                                  size: 11,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${GeofenceMath.formatDistance(distance)} away',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Title
                    Text(
                      ev.title,
                      style: const TextStyle(
                        color: AppColors.primaryNavy,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Subtitle
                    Text(
                      subtitleText,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Modern Geofence Boundary Status Strip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isInside ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isInside ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: isInside ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isInside ? Icons.check : Icons.lock_outline_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isInside
                                  ? 'Inside Geofence Boundary'
                                  : 'Outside Boundary (${GeofenceMath.formatDistance(distance)} away)',
                              style: TextStyle(
                                color: isInside ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isInside ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isInside ? 'UNLOCKED' : 'LOCKED',
                              style: TextStyle(
                                color: isInside ? const Color(0xFF166534) : const Color(0xFF64748B),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action CTA Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isInside ? const Color(0xFF006C35) : const Color(0xFFF1F5F9),
                    foregroundColor: isInside ? Colors.white : const Color(0xFF64748B),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isInside ? const Color(0xFF006C35) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  onPressed: isInside
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreatePostScreen(event: ev),
                            ),
                          );
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.alertRed,
                              behavior: SnackBarBehavior.floating,
                              content: Row(
                                children: [
                                  const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Cannot enter: You must be physically inside ${ev.tagName} (${ev.formattedRadius} radius) to create a post. You are ${GeofenceMath.formatDistance(distance)} away.',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                  icon: Icon(
                    isInside ? Icons.edit_note_rounded : Icons.lock_outline_rounded,
                    size: 19,
                    color: isInside ? Colors.white : const Color(0xFF64748B),
                  ),
                  label: Text(
                    isInside ? 'Write Post' : 'Outside Radius • Post Locked',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: isInside ? 13 : 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
