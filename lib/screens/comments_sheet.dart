import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/post_model.dart';
import '../providers/app_state.dart';
import '../providers/location_service.dart';
import '../theme/app_colors.dart';
import '../utils/geofence_math.dart';

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

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -4),
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
          const SizedBox(height: 12),

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
                        color: AppColors.primaryNavy,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${comments.length} responses • Open to all readers',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isInside ? const Color(0xFFDCFCE7) : const Color(0xFFD0E1FD),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isInside ? Icons.my_location : Icons.public,
                        size: 13,
                        color: isInside ? const Color(0xFF15803D) : AppColors.primaryNavy,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isInside ? 'YOU ARE ON-SITE' : 'REMOTE OBSERVER',
                        style: TextStyle(
                          color: isInside ? const Color(0xFF15803D) : AppColors.primaryNavy,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Info Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Anyone worldwide can comment and read. Original reports & news verification remain restricted to on-site eyewitnesses.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // Comments List
          Expanded(
            child: comments.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No comments yet.\nBe the first to join the conversation and ask questions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13.5, height: 1.4),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: comments.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final cmt = comments[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: const Color(0xFFF1F5F9),
                            backgroundImage: NetworkImage(cmt.authorAvatar),
                            onBackgroundImageError: (error, stack) {},
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        cmt.authorName,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD0E1FD),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${cmt.authorTrustScore}',
                                          style: const TextStyle(
                                            color: AppColors.primaryNavy,
                                            fontSize: 9.5,
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
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        cmt.isVerifiedOnSite ? Icons.check_circle : Icons.public,
                                        size: 12,
                                        color: cmt.isVerifiedOnSite
                                            ? const Color(0xFF15803D)
                                            : const Color(0xFF475569),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        cmt.isVerifiedOnSite
                                            ? 'Verified On-Site (${GeofenceMath.formatDistance(cmt.distanceMeters)} from epicenter)'
                                            : 'Remote Observer (${GeofenceMath.formatDistance(cmt.distanceMeters)} away)',
                                        style: TextStyle(
                                          color: cmt.isVerifiedOnSite
                                              ? const Color(0xFF15803D)
                                              : const Color(0xFF64748B),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
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

          // Universal Comment Input Box (OPEN TO EVERY USER FROM ANYWHERE)
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
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
                    decoration: const BoxDecoration(
                      color: AppColors.primaryNavy,
                      shape: BoxShape.circle,
                    ),
                    child: _isSubmitting
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
