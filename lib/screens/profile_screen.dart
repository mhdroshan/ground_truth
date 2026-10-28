import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/achievement_model.dart';
import '../models/post_model.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common/glass_card.dart';
import 'settings_screen.dart';
import 'create_tag_screen.dart';
import 'comments_sheet.dart';
import 'event_detail_screen.dart';
import 'login_screen.dart';
import 'edit_personal_info_screen.dart';
import '../widgets/common/safe_image.dart';
import '../providers/location_service.dart';
import '../widgets/post/poll_widget.dart';
import '../widgets/post/verification_restricted_sheet.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final UserModel? initialUser;
  final String? initialAuthorName;
  final String? initialAuthorAvatar;
  final int? initialAuthorTrustScore;
  final bool? isVerifiedJournalist;

  const ProfileScreen({
    super.key,
    this.userId,
    this.initialUser,
    this.initialAuthorName,
    this.initialAuthorAvatar,
    this.initialAuthorTrustScore,
    this.isVerifiedJournalist,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedMainTab = 0; // 0: Posts, 1: Achievements
  int _selectedFilterIndex = 0; // 0: All, 1: Unlocked, 2: In Progress
  final List<String> _filterTabs = ['All', 'Unlocked', 'In Progress'];

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  void _showFollowingModal(BuildContext context, AppState appState, bool isSelf) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final liveFollowed = appState.getFollowedProfiles();
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border(
                      top: BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryNavy.withValues(alpha: 0.08),
                        blurRadius: 28,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryNavy.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.people_alt_rounded, color: AppColors.primaryNavy, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isSelf ? 'People You Follow' : 'Following (${liveFollowed.length})',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${liveFollowed.length} Following',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      if (liveFollowed.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              'Not following any contributors yet.\nTap "+ Follow" on any author\'s post or profile to follow them.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            itemCount: liveFollowed.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final p = liveFollowed[index];
                              final isFollowing = appState.isFollowing(p.id);
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFF1F5F9)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: getUserAvatarProvider(p.avatarUrl),
                                      backgroundColor: const Color(0xFFE2E8F0),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  p.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 13.5,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (p.isJournalist) ...[
                                                const SizedBox(width: 4),
                                                const Icon(Icons.verified, size: 14, color: AppColors.primaryNavy),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${p.handle} • ${p.trustScore}% Trust',
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isFollowing ? const Color(0xFFDCFCE7) : AppColors.primaryNavy,
                                        foregroundColor: isFollowing ? const Color(0xFF15803D) : Colors.white,
                                        elevation: 0,
                                        side: isFollowing ? const BorderSide(color: Color(0xFF86EFAC)) : BorderSide.none,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () async {
                                        await appState.toggleFollowUser(p.id, userName: p.name, userAvatar: p.avatarUrl);
                                        setModalState(() {});
                                      },
                                      child: Text(
                                        isFollowing ? 'Following' : 'Follow',
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ],
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
          },
        );
      },
    );
  }

  void _showFollowersModal(BuildContext context, UserModel user, bool isSelf) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 34),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.15)),
                    ),
                    child: const Icon(Icons.people_alt_rounded, size: 30, color: AppColors.primaryNavy),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${_formatCount(user.followersCount)} Eyewitness Followers',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSelf
                        ? 'Other verified field witnesses, reporters, and observers tracking your real-time ground truth updates.'
                        : '${user.name} is followed by ${_formatCount(user.followersCount)} community observers and eyewitnesses.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAchievementDetails(BuildContext context, AchievementModel ach) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildAchievementModal(context, ach),
    );
  }

  Widget _buildAchievementModal(BuildContext context, AchievementModel ach) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 34),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Badge Icon with 2026 Tier Halo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: ach.tier.badgeBackgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: ach.tier.primaryColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: ach.tier.primaryColor.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(ach.icon, size: 38, color: ach.tier.primaryColor),
              ),
              const SizedBox(height: 16),

              // Title & Tier
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ach.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ach.tier.badgeBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ach.tier.primaryColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      ach.tier.label.toUpperCase(),
                      style: TextStyle(
                        color: ach.tier.primaryColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ach.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // 2026 Bento Progress Module
              BentoCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ach.isUnlocked ? 'STATUS: COMPLETED' : 'CURRENT PROGRESS',
                          style: TextStyle(
                            color: ach.isUnlocked ? const Color(0xFF15803D) : AppColors.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          '${ach.currentProgress} / ${ach.maxProgress} (${ach.progressPercent}%)',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ach.progressFraction,
                        minHeight: 7,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ach.isUnlocked ? const Color(0xFF15803D) : AppColors.primaryNavy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Reward: +${ach.xpReward} XP Points',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // How to Earn Details
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.primaryNavy),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HOW TO EARN',
                            style: TextStyle(
                              color: AppColors.primaryNavy,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            ach.howToEarn,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Close CTA
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final locationService = context.watch<LocationService>();

    final isSelf = widget.userId == null ||
        widget.userId == appState.currentUser.id ||
        (widget.initialAuthorName != null &&
            widget.initialAuthorName == appState.currentUser.name);

    final user = isSelf
        ? appState.currentUser
        : appState.getUserProfile(
            widget.userId!,
            fallbackName: widget.initialAuthorName,
            fallbackAvatar: widget.initialAuthorAvatar,
            fallbackTrustScore: widget.initialAuthorTrustScore,
            isVerifiedJournalist: widget.isVerifiedJournalist,
          );

    final achievements = user.achievements.isNotEmpty
        ? user.achievements
        : appState.currentUser.achievements;
    final posts = isSelf
        ? appState.getMyWrittenPosts()
        : appState.getPostsByAuthor(user.id, authorName: user.name);

    // Filter achievements
    final filteredAchievements = achievements.where((ach) {
      if (_selectedFilterIndex == 1) return ach.isUnlocked;
      if (_selectedFilterIndex == 2) return !ach.isUnlocked;
      return true;
    }).toList();

    final unlockedCount = achievements.where((a) => a.isUnlocked).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: !isSelf
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSelf ? Icons.security_rounded : Icons.person_rounded,
                color: AppColors.primaryNavy,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isSelf ? 'Profile' : user.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (isSelf) ...[
            if (!appState.isLoggedIn)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  icon: const Icon(Icons.login_rounded, size: 16, color: AppColors.primaryNavy),
                  label: const Text('Log In', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w800, fontSize: 13)),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
                tooltip: 'Log Out',
                onPressed: () {
                  appState.logout();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logged out successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppColors.primaryNavy, size: 21),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ] else ...[
            IconButton(
              icon: Icon(
                appState.isFollowing(user.id) ? Icons.check_circle_rounded : Icons.person_add_rounded,
                color: appState.isFollowing(user.id) ? const Color(0xFF15803D) : AppColors.primaryNavy,
                size: 22,
              ),
              tooltip: appState.isFollowing(user.id) ? 'Following' : 'Follow',
              onPressed: () => appState.toggleFollowUser(
                user.id,
                userName: user.name,
                userAvatar: user.avatarUrl,
                userTrustScore: user.trustScore,
                isJournalist: user.isJournalist,
              ),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          children: [
            // Guest Account Banner when unauthenticated
            if (isSelf && !appState.isLoggedIn)
              GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: const Color(0xFFFFFBEB).withValues(alpha: 0.9),
                borderColor: const Color(0xFFFDE68A),
                borderRadius: 18,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFFB45309)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'You are currently browsing as a guest.',
                        style: TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: const Text('Log In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),

            // 2026 Bento User Public Identity Card
            GlassCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 26,
              hasGlow: true,
              glowColor: AppColors.primaryNavy.withValues(alpha: 0.06),
              child: Column(
                children: [
                  // Avatar with Verified Sentinel Check
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: isSelf
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const EditPersonalInfoScreen()),
                                );
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(3.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF10B981)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: const Color(0xFFF1F5F9),
                            backgroundImage: getUserAvatarProvider(user.avatarUrl),
                            onBackgroundImageError: (error, stack) {},
                          ),
                        ),
                      ),
                      if (isSelf)
                        Positioned(
                          bottom: 2,
                          left: 2,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const EditPersonalInfoScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryNavy,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified, size: 13, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Name & Handle
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.handle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // GPS Telemetry Pill
                  if (locationService.hasRealGpsFix) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: Color(0xFF15803D),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              locationService.displayLocationName,
                              style: const TextStyle(
                                color: Color(0xFF15803D),
                                fontSize: 11,
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
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '±${locationService.gpsAccuracyMeters.toStringAsFixed(0)}m',
                              style: const TextStyle(
                                color: Color(0xFF166534),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),

                  // Level & Tier Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.military_tech_rounded, size: 14, color: AppColors.primaryNavy),
                            const SizedBox(width: 4),
                            Text(
                              'Level ${user.level} • ${user.levelTitle}',
                              style: const TextStyle(
                                color: AppColors.primaryNavy,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_rounded, size: 13, color: Color(0xFF15803D)),
                            const SizedBox(width: 4),
                            Text(
                              '${user.trustScore}% Trust Score',
                              style: const TextStyle(
                                color: Color(0xFF15803D),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        user.bio,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // 2026 Bento 3-Column Stats Module
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                          onTap: () => _showFollowersModal(context, user, isSelf),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Column(
                              children: [
                                Text(
                                  _formatCount(user.followersCount),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'FOLLOWERS',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                        InkWell(
                          onTap: () => _showFollowingModal(context, appState, isSelf),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Column(
                              children: [
                                Text(
                                  _formatCount(isSelf ? appState.followedUserIds.length : user.followingCount),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'FOLLOWING',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Column(
                            children: [
                              Text(
                                '${posts.length}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'REPORTS',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Button: Edit Profile (Self) or Follow (Others)
                  if (isSelf) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryNavy,
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EditPersonalInfoScreen()),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text(
                          'Edit Profile & Photo',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final isFollowing = appState.isFollowing(user.id);
                        return SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            icon: Icon(
                              isFollowing ? Icons.check_circle_rounded : Icons.person_add_rounded,
                              size: 18,
                              color: isFollowing ? const Color(0xFF15803D) : Colors.white,
                            ),
                            label: Text(
                              isFollowing ? 'Following' : '+ Follow Contributor',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isFollowing ? const Color(0xFF15803D) : Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing ? const Color(0xFFDCFCE7) : AppColors.primaryNavy,
                              foregroundColor: isFollowing ? const Color(0xFF15803D) : Colors.white,
                              elevation: 0,
                              side: isFollowing ? const BorderSide(color: Color(0xFF86EFAC), width: 1.5) : BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () async {
                              final nowFollowing = await appState.toggleFollowUser(
                                user.id,
                                userName: user.name,
                                userAvatar: user.avatarUrl,
                                userTrustScore: user.trustScore,
                                isJournalist: user.isJournalist,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      nowFollowing
                                          ? 'You are now following ${user.name}. Their posts will appear in your Following feed.'
                                          : 'Unfollowed ${user.name}.',
                                    ),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ],

                  // 2026 Bento XP Progression Bar (Self Profile)
                  if (isSelf) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'RANK EXPERIENCE',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                '${user.xp} / ${user.nextLevelXp} XP',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: user.levelProgress,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2026 Bento 2x2 Activity Matrix
            Row(
              children: [
                Expanded(
                  child: _buildBentoActivityTile(
                    icon: Icons.newspaper_rounded,
                    count: '${user.postsCreated}',
                    label: 'Verified Posts',
                    sublabel: 'Inside Radius',
                    color: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBentoActivityTile(
                    icon: Icons.verified_rounded,
                    count: '${user.verificationsDone}',
                    label: 'Truth Votes',
                    sublabel: 'On-Site Verification',
                    color: const Color(0xFF10B981),
                    bgColor: const Color(0xFFECFDF5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildBentoActivityTile(
                    icon: Icons.forum_rounded,
                    count: '${user.commentsAdded}',
                    label: 'Comments',
                    sublabel: 'Community Discourse',
                    color: const Color(0xFF8B5CF6),
                    bgColor: const Color(0xFFF5F3FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBentoActivityTile(
                    icon: Icons.tag_rounded,
                    count: '${user.tagsCreated}',
                    label: 'Tags Created',
                    sublabel: 'Custom Geofences',
                    color: const Color(0xFFF59E0B),
                    bgColor: const Color(0xFFFFFBEB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2026 Floating Segmented Tabs: "Posts" vs "Achievements"
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedMainTab = 0),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedMainTab == 0 ? AppColors.primaryNavy : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 16,
                              color: _selectedMainTab == 0 ? Colors.white : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isSelf ? 'My Posts (${posts.length})' : 'Verified Posts (${posts.length})',
                              style: TextStyle(
                                color: _selectedMainTab == 0 ? Colors.white : AppColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: _selectedMainTab == 0 ? FontWeight.w900 : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedMainTab = 1),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedMainTab == 1 ? AppColors.primaryNavy : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 16,
                              color: _selectedMainTab == 1 ? Colors.white : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Achievements (${achievements.length})',
                              style: TextStyle(
                                color: _selectedMainTab == 1 ? Colors.white : AppColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: _selectedMainTab == 1 ? FontWeight.w900 : FontWeight.w600,
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
            const SizedBox(height: 16),

            if (_selectedMainTab == 0)
              _buildPostsSection(context, appState, posts, isSelf, user.name)
            else
              _buildAchievementsSection(context, user, achievements, unlockedCount, filteredAchievements),
            const SizedBox(height: 18),

            // 2026 Bento Hero CTA: Create Tag
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notice real news happening?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Create a tag and define its verification radius.',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryNavy,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateTagScreen()),
                      );
                    },
                    child: const Text('New Tag', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoActivityTile({
    required IconData icon,
    required String count,
    required String label,
    required String sublabel,
    required Color color,
    required Color bgColor,
  }) {
    return BentoCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sublabel,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(BuildContext context, AchievementModel ach) {
    return InkWell(
      onTap: () => _showAchievementDetails(context, ach),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ach.isUnlocked ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: ach.isUnlocked ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Badge Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ach.tier.badgeBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: ach.tier.primaryColor, width: 1.5),
              ),
              child: Icon(ach.icon, size: 22, color: ach.tier.primaryColor),
            ),
            const SizedBox(width: 12),

            // Title, Description & Progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          ach.title,
                          style: TextStyle(
                            color: ach.isUnlocked ? const Color(0xFF14532D) : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (ach.isUnlocked)
                        const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF15803D))
                      else
                        Text(
                          '+${ach.xpReward} XP',
                          style: const TextStyle(
                            color: Color(0xFFD97706),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ach.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ach.progressFraction,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ach.isUnlocked ? const Color(0xFF15803D) : AppColors.primaryNavy,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ach.isUnlocked ? 'Unlocked' : '${ach.currentProgress}/${ach.maxProgress}',
                        style: TextStyle(
                          color: ach.isUnlocked ? const Color(0xFF15803D) : AppColors.textMuted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(
    BuildContext context,
    UserModel user,
    List<AchievementModel> achievements,
    int unlockedCount,
    List<AchievementModel> filteredAchievements,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.emoji_events_rounded, color: Color(0xFFD97706), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Achievements & Badges',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  '$unlockedCount of ${achievements.length} Unlocked',
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Earn achievements and level up your credibility by posting verified news, voting on-site, commenting, and scoping tags.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.4),
          ),
          const SizedBox(height: 14),

          // Filter Segmented Bar
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: _filterTabs.asMap().entries.map((entry) {
                final isSelected = entry.key == _selectedFilterIndex;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedFilterIndex = entry.key),
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
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
                        entry.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Achievements List
          if (filteredAchievements.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No achievements match this filter.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredAchievements.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final ach = filteredAchievements[index];
                return _buildAchievementCard(context, ach);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPostsSection(
    BuildContext context,
    AppState appState,
    List<PostModel> posts,
    bool isSelf,
    String userName,
  ) {
    if (posts.isEmpty) {
      return GlassCard(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        borderRadius: 22,
        child: Column(
          children: [
            const Icon(Icons.rate_review_outlined, size: 44, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              isSelf ? 'No posts published yet' : 'No posts published yet by $userName',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isSelf
                  ? 'Visit the Write tab to submit your first on-site verified eyewitness report and start earning truth badges.'
                  : '$userName has not published any verified reports yet.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isSelf ? 'Your Published Eyewitness Reports' : '$userName\'s Verified Reports',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${posts.length} Published',
                style: const TextStyle(
                  color: Color(0xFF15803D),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final post = posts[index];
            final event = appState.getEventForPost(post);
            return _buildMyPostCard(context, appState, post, event);
          },
        ),
      ],
    );
  }

  Widget _buildMyPostCard(BuildContext context, AppState appState, PostModel post, EventModel? event) {
    final timeStr = DateFormat('MMM d, h:mm a').format(post.createdAt);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tag, Post Type, Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (event != null || (post.tagName != null && post.tagName!.isNotEmpty))
                InkWell(
                  onTap: event != null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EventDetailScreen(eventId: event.id)),
                          );
                        }
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tag, size: 12, color: AppColors.primaryNavy),
                        const SizedBox(width: 3),
                        Text(
                          event?.tagName ?? (post.tagName!.startsWith('#') ? post.tagName! : '#${post.tagName!}'),
                          style: const TextStyle(
                            color: AppColors.primaryNavy,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox(),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      post.type.name.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeStr,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Content
          Text(
            post.content,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Image if any
          if (post.mediaUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                post.mediaUrl!,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: const Color(0xFFF1F5F9),
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
          ],

          // Poll Widget if post is a poll
          if (post.type == PostType.poll && post.pollOptions != null) ...[
            const SizedBox(height: 10),
            PollWidget(
              options: post.pollOptions!,
              userVotedOptionId: post.userVotedPollOptionId,
              isInsideGeofence: event != null
                  ? event.isUserInside(context.read<LocationService>().currentLocation)
                  : appState.isUserInsidePostGeofence(post, context.read<LocationService>().currentLocation),
              isOwnPost: true,
              onVote: (optId) {
                final locationService = context.read<LocationService>();
                final userLoc = locationService.currentLocation;
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
            ),
          ],
          const SizedBox(height: 12),

          // Bottom Stats & Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.thumb_up_rounded, size: 12, color: Color(0xFF15803D)),
                        const SizedBox(width: 4),
                        Text(
                          '${post.upvotes}',
                          style: const TextStyle(
                            color: Color(0xFF15803D),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${post.commentsCount}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (event != null)
                TextButton.icon(
                  onPressed: () {
                    CommentsSheet.show(context, event, post);
                  },
                  icon: const Icon(Icons.forum_outlined, size: 14, color: AppColors.primaryNavy),
                  label: const Text(
                    'View Discussion',
                    style: TextStyle(
                      color: AppColors.primaryNavy,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
