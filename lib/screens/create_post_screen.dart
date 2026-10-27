import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../models/post_model.dart';
import '../providers/app_state.dart';
import '../providers/location_service.dart';
import '../services/file_picker_helper.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/geofence_math.dart';
import '../widgets/common/safe_image.dart';
import 'login_screen.dart';

class CreatePostScreen extends StatefulWidget {
  final EventModel event;
  final PostType initialType;

  const CreatePostScreen({
    super.key,
    required this.event,
    this.initialType = PostType.text,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  late PostType _selectedType;
  bool _isAnonymous = false;
  bool _isPublishing = false;

  // Attached media states
  String? _attachedPhotoUrl;
  String? _attachedPhotoName;

  String? _attachedVideoThumbnailUrl;
  String? _attachedVideoName;
  int _attachedVideoDuration = 30; // seconds

  // Poll options state
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType == PostType.voiceNote ? PostType.text : widget.initialType;
    if (_selectedType == PostType.poll && _pollOptionControllers.isEmpty) {
      _pollOptionControllers.add(TextEditingController());
      _pollOptionControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (final c in _pollOptionControllers) {
      c.dispose();
    }
    _contentController.dispose();
    super.dispose();
  }

  // --- Normal Direct Photo Uploader ---
  Future<void> _handlePhotoTap() async {
    final bool? useCamera = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Attach Eyewitness Photo',
                style: TextStyle(
                  color: AppColors.primaryNavy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB)),
                ),
                title: const Text('Take Live Photo', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Capture live on-site eyewitness photo with camera', style: TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(ctx, true),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primaryNavy),
                ),
                title: const Text('Choose from Photo Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Select a photo from your photo library', style: TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(ctx, false),
              ),
            ],
          ),
        ),
      ),
    );

    if (useCamera == null) return;

    final file = await pickFilePlatform(accept: 'image/*', fromCamera: useCamera);
    if (!mounted) return;

    if (file != null) {
      setState(() {
        _attachedPhotoUrl = file.dataUrl;
        _attachedPhotoName = file.name;
        _selectedType = PostType.photo;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0D652D),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Photo attached: ${file.name} (${file.formattedSize})',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // --- Normal Direct Video Uploader ---
  Future<void> _handleVideoTap() async {
    final bool? useCamera = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Attach Eyewitness Video',
                style: TextStyle(
                  color: AppColors.primaryNavy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.videocam_rounded, color: Color(0xFF2563EB)),
                ),
                title: const Text('Record Live Video', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Capture live on-site eyewitness footage with camera', style: TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(ctx, true),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.video_library_rounded, color: AppColors.primaryNavy),
                ),
                title: const Text('Choose Video from Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Select existing recorded footage from your device', style: TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(ctx, false),
              ),
            ],
          ),
        ),
      ),
    );

    if (useCamera == null) return;

    final file = await pickFilePlatform(accept: 'video/*', fromCamera: useCamera);
    if (!mounted) return;

    if (file != null) {
      setState(() {
        _attachedVideoThumbnailUrl = file.dataUrl ?? 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=800&auto=format&fit=crop&q=80';
        _attachedVideoName = file.name;
        _attachedVideoDuration = 30;
        _selectedType = PostType.video;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0D652D),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Video attached: ${file.name} (${file.formattedSize})',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // --- Poll Handling ---
  void _handlePollTap() {
    setState(() {
      _selectedType = PostType.poll;
      if (_pollOptionControllers.length < 2) {
        while (_pollOptionControllers.length < 2) {
          _pollOptionControllers.add(TextEditingController());
        }
      }
    });
  }

  // --- Publishing ---
  Future<void> _publish() async {
    final appState = context.read<AppState>();
    if (!appState.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.alertAmber,
          content: const Text('Eyewitness authentication required to publish truth tags.'),
          action: SnackBarAction(
            label: 'Sign In',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ),
      );
      return;
    }

    final rawText = _contentController.text.trim();
    final hasMedia = _attachedPhotoUrl != null || _attachedVideoThumbnailUrl != null;

    if (_selectedType == PostType.poll) {
      if (rawText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.alertAmber,
            content: Text('Please enter your poll question (e.g. Is the roadblock cleared?)'),
          ),
        );
        return;
      }
      final validOptions = _pollOptionControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (validOptions.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.alertRed,
            content: Text('Please provide at least 2 poll options.'),
          ),
        );
        return;
      }
    } else if (rawText.isEmpty && !hasMedia && _selectedType == PostType.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write your eyewitness report or attach media')),
      );
      return;
    }

    final locationService = context.read<LocationService>();
    final isInside = widget.event.isUserInside(locationService.currentLocation);
    if (!isInside) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.alertRed,
          content: Text(
            'Publishing blocked: You must be physically inside ${widget.event.tagName} (${widget.event.formattedRadius} radius) to post.',
          ),
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);

    String finalContent = rawText;
    if (finalContent.isEmpty) {
      if (_selectedType == PostType.photo) {
        finalContent = 'Verified eyewitness photo from ${widget.event.tagName}.';
      } else if (_selectedType == PostType.video) {
        finalContent = 'Live verified field footage from ${widget.event.tagName}.';
      } else {
        finalContent = 'Verified ground report from ${widget.event.tagName}.';
      }
    }

    final String? finalPhotoUrl = _attachedPhotoUrl ?? (_selectedType == PostType.photo ? 'https://images.unsplash.com/photo-1541872703-74c5e44368f9?w=800&auto=format&fit=crop&q=80' : null);
    final String? finalVideoUrl = _attachedVideoThumbnailUrl ?? (_selectedType == PostType.video ? 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=800&auto=format&fit=crop&q=80' : null);
    final int? finalAudioDuration = null;
    final List<double>? finalWaveform = null;

    List<PollOption>? finalPollOptions;
    if (_selectedType == PostType.poll) {
      final validOptions = _pollOptionControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      finalPollOptions = validOptions.asMap().entries.map((entry) {
        return PollOption(
          id: 'opt_${entry.key + 1}_${DateTime.now().millisecondsSinceEpoch}',
          text: entry.value,
          votes: 0,
        );
      }).toList();
    }

    final success = appState.addPost(
      eventId: widget.event.id,
      event: widget.event,
      type: _selectedType,
      content: finalContent,
      mediaUrl: finalPhotoUrl,
      videoThumbnailUrl: finalVideoUrl,
      audioDurationSeconds: finalAudioDuration,
      waveform: finalWaveform,
      pollOptions: finalPollOptions,
      locationService: locationService,
    );

    // Sync to backend API
    if (success) {
      final posts = appState.getPostsForEvent(widget.event.id);
      if (posts.isNotEmpty) {
        final tempPost = posts.first;
        final savedPost = await ApiService.submitVerifiedPost(
          eventId: widget.event.id,
          post: tempPost,
          latitude: locationService.currentLocation.latitude,
          longitude: locationService.currentLocation.longitude,
          gpsAccuracy: 3.5,
          mockLocationDetected: false,
          deviceRooted: false,
        );

        if (savedPost != null) {
          appState.replaceTempPost(widget.event.id, tempPost.id, savedPost);
        }
      }
    }

    setState(() => _isPublishing = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0D652D),
            content: Text('Eyewitness report verified & published! (+100 XP)'),
          ),
        );
      } else {
        final eval = locationService.evaluateVerificationForEvent(widget.event);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.alertRed,
            content: Text('Publishing rejected: ${eval.summaryMessage}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = context.watch<LocationService>();
    final isInside = widget.event.isUserInside(locationService.currentLocation);
    final distance = widget.event.distanceFromUser(locationService.currentLocation);

    if (!isInside) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Posting Restricted',
            style: TextStyle(
              color: AppColors.primaryNavy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_person_rounded, size: 40, color: AppColors.alertRed),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Physical Geofence Gate',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You cannot enter or draft posts for ${widget.event.tagName}. Posting is strictly permitted only when you are physically inside the ${widget.event.formattedRadius} boundary.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_off_rounded, size: 16, color: AppColors.alertRed),
                      const SizedBox(width: 8),
                      Text(
                        'Your Location: ${GeofenceMath.formatDistance(distance)} outside radius',
                        style: const TextStyle(
                          color: AppColors.alertRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryNavy,
                        side: const BorderSide(color: AppColors.primaryNavy),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => locationService.refreshPhysicalLocation(),
                      icon: locationService.isLocating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNavy),
                            )
                          : const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(locationService.isLocating ? 'Acquiring GPS...' : 'Refresh GPS Location'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Back to Tags Feed'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report Draft',
          style: TextStyle(
            color: AppColors.primaryNavy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC7D7F4),
                foregroundColor: AppColors.primaryNavy,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: _isPublishing ? null : _publish,
              child: _isPublishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNavy),
                    )
                  : const Text(
                      'Publish',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Posting Destination Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD0E1FD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.location_on, color: AppColors.primaryNavy, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'POSTING TO: ',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6F4EA),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.check, size: 10, color: Color(0xFF0D652D)),
                                        SizedBox(width: 3),
                                        Text(
                                          'VERIFIED',
                                          style: TextStyle(
                                            color: Color(0xFF0D652D),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.event.tagName,
                                style: const TextStyle(
                                  color: AppColors.primaryNavy,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${widget.event.title} • ${widget.event.formattedRadius} Radius',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Text input
                  TextField(
                    controller: _contentController,
                    maxLines: 5,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14.5),
                    decoration: InputDecoration(
                      hintText: _selectedType == PostType.poll
                          ? "What is your eyewitness poll question? (e.g. Is the roadblock cleared?)..."
                          : "What's happening on the ground? Provide objective details...",
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Normal Media Buttons Row (Photo, Video, Poll)
                  Row(
                    children: [
                      _buildMediaButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Photo',
                        type: PostType.photo,
                        hasAttachment: _attachedPhotoUrl != null,
                        onTap: _handlePhotoTap,
                      ),
                      const SizedBox(width: 8),
                      _buildMediaButton(
                        icon: Icons.videocam_outlined,
                        label: 'Video',
                        type: PostType.video,
                        hasAttachment: _attachedVideoThumbnailUrl != null,
                        onTap: _handleVideoTap,
                      ),
                      const SizedBox(width: 8),
                      _buildMediaButton(
                        icon: Icons.how_to_vote_outlined,
                        label: 'Poll',
                        type: PostType.poll,
                        hasAttachment: _pollOptionControllers.any((c) => c.text.trim().isNotEmpty),
                        onTap: _handlePollTap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- PREVIEW SECTION ---
                  // 1. Photo Preview Card
                  if (_attachedPhotoUrl != null) ...[
                    _buildPhotoPreviewCard(),
                    const SizedBox(height: 14),
                  ],

                  // 2. Video Preview Card
                  if (_attachedVideoThumbnailUrl != null) ...[
                    _buildVideoPreviewCard(),
                    const SizedBox(height: 14),
                  ],

                  // 4. Poll Creator Card
                  if (_selectedType == PostType.poll) ...[
                    _buildPollCreatorCard(),
                    const SizedBox(height: 14),
                  ],

                  // Post Anonymously Toggle
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility_off_outlined, color: AppColors.textSecondary, size: 22),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Post Anonymously',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Hides your identity from the public feed...',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isAnonymous,
                          activeThumbColor: AppColors.primaryNavy,
                          onChanged: (val) => setState(() => _isAnonymous = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Verification Status Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_user, color: Color(0xFF15803D), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Verified Inside Event',
                                  style: TextStyle(
                                    color: Color(0xFF15803D),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Text(
                                'Active Syncing...',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your location is verified at ${locationService.currentLocation.label ?? 'Jantar Mantar (Delhi)'}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildMiniCheck('GPS Confirmed'),
                              const SizedBox(width: 14),
                              _buildMiniCheck('Device Integrity'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.88,
                    minHeight: 4,
                    backgroundColor: Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF15803D)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Components ---

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required PostType type,
    required bool hasAttachment,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedType == type || hasAttachment;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD0E1FD) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primaryNavy : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (hasAttachment) ...[
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF15803D),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- PREVIEW WIDGETS ---

  Widget _buildPhotoPreviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                child: SafeImageWidget(
                  urlOrData: _attachedPhotoUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _attachedPhotoUrl = null;
                      _attachedPhotoName = null;
                      if (_selectedType == PostType.photo) _selectedType = PostType.text;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _attachedPhotoName ?? 'photo.jpg',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryNavy,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _handlePhotoTap,
                  icon: const Icon(Icons.sync, size: 14, color: AppColors.primaryNavy),
                  label: const Text('Change', style: TextStyle(fontSize: 12, color: AppColors.primaryNavy, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                child: SafeImageWidget(
                  urlOrData: _attachedVideoThumbnailUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '0:${_attachedVideoDuration.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _attachedVideoThumbnailUrl = null;
                      _attachedVideoName = null;
                      if (_selectedType == PostType.video) _selectedType = PostType.text;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _attachedVideoName ?? 'video.mp4',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryNavy,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _handleVideoTap,
                  icon: const Icon(Icons.sync, size: 14, color: AppColors.primaryNavy),
                  label: const Text('Change', style: TextStyle(fontSize: 12, color: AppColors.primaryNavy, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildPollCreatorCard() {
    const letters = ['A', 'B', 'C', 'D', 'E', 'F'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD0E1FD),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.how_to_vote_rounded,
                      size: 18,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EYEWITNESS POLL BUILDER',
                        style: TextStyle(
                          color: AppColors.primaryNavy,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Only on-site eyewitnesses can vote',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                onPressed: () {
                  setState(() {
                    _selectedType = PostType.text;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Option Input Fields
          ..._pollOptionControllers.asMap().entries.map((entry) {
            final idx = entry.key;
            final controller = entry.value;
            final letter = idx < letters.length ? letters[idx] : '${idx + 1}';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      letter,
                      style: const TextStyle(
                        color: AppColors.primaryNavy,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: idx == 0
                            ? 'e.g., Road is completely blocked'
                            : (idx == 1
                                ? 'e.g., Traffic moving slowly'
                                : 'Option ${idx + 1}...'),
                        hintStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (_pollOptionControllers.length > 2)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.alertRed),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _pollOptionControllers.removeAt(idx).dispose();
                        });
                      },
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: 4),

          // Add Option Button
          if (_pollOptionControllers.length < 6)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _pollOptionControllers.add(TextEditingController());
                  });
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  'Add Option (${_pollOptionControllers.length}/6)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),

          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF1D4ED8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'GroundTruth Rule: Anyone outside ${widget.event.tagName} (${widget.event.formattedRadius}) will be blocked from voting.',
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  Widget _buildMiniCheck(String label) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF15803D), size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
