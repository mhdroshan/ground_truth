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
import 'profile_screen.dart';

class CommentsSheet extends StatefulWidget {
  final EventModel event;
  final PostModel post;

  const CommentsSheet({
    super.key,
    required this.event,
    required this.post,
  });

  static void show(BuildContext context, EventModel event, PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(event: event, post: post),
    );
  }

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadCommentsForPost(widget.post.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    final appState = context.read<AppState>();
    final locationService = context.read<LocationService>();

    final success = appState.addComment(
      postId: widget.post.id,
      text: text,
      event: widget.event,
      locationService: locationService,
    );

    setState(() => _isSubmitting = false);

    if (success) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final locationService = context.watch<LocationService>();
    final isInside = widget.event.isUserInside(locationService.currentLocation);
    final comments = appState.getCommentsForPost(widget.post.id);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNavy.withValues(alpha: 0.1),
                blurRadius: 28,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Community Discussion',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${comments.length} responses • Open worldwide',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isInside ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isInside ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isInside ? Icons.my_location_rounded : Icons.public_rounded,
                            size: 13,
                            color: isInside ? const Color(0xFF15803D) : AppColors.primaryNavy,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isInside ? 'YOU ARE ON-SITE' : 'REMOTE OBSERVER',
                            style: TextStyle(
                              color: isInside ? const Color(0xFF15803D) : AppColors.primaryNavy,
                              fontSize: 9.5,
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
              const SizedBox(height: 10),

              // Info Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Anyone worldwide can comment and read. Original reports & news verification remain restricted to on-site eyewitnesses.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // Comments List
              Expanded(
                child: comments.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No comments yet.\nBe the first to join the conversation and ask questions.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: comments.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final cmt = comments[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfileScreen(
                                        userId: cmt.authorId,
                                        initialAuthorName: cmt.authorName,
                                        initialAuthorAvatar: cmt.authorAvatar,
                                        initialAuthorTrustScore: cmt.authorTrustScore,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(18),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  backgroundImage: NetworkImage(cmt.authorAvatar),
                                  onBackgroundImageError: (error, stack) {},
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFF1F5F9)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ProfileScreen(
                                                    userId: cmt.authorId,
                                                    initialAuthorName: cmt.authorName,
                                                    initialAuthorAvatar: cmt.authorAvatar,
                                                    initialAuthorTrustScore: cmt.authorTrustScore,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              cmt.authorName,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            DateFormat('h:mm a').format(cmt.createdAt),
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 10.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        cmt.text,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            cmt.isVerifiedOnSite ? Icons.check_circle_rounded : Icons.public_rounded,
                                            size: 12,
                                            color: cmt.isVerifiedOnSite
                                                ? const Color(0xFF15803D)
                                                : const Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            cmt.isVerifiedOnSite
                                                ? 'Verified (${GeofenceMath.formatDistance(cmt.distanceMeters)} from epicenter)'
                                                : 'Remote Observer (${GeofenceMath.formatDistance(cmt.distanceMeters)} away)',
                                            style: TextStyle(
                                              color: cmt.isVerifiedOnSite
                                                  ? const Color(0xFF15803D)
                                                  : const Color(0xFF64748B),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),

              // Universal Comment Input Box
              Container(
                padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: isInside
                              ? 'Add your on-site observation...'
                              : 'Ask an eyewitness or add a comment...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _submitComment(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: _isSubmitting ? null : _submitComment,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryNavy.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: _isSubmitting
                            ? const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                ),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 19),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
