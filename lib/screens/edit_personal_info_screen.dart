import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/location_service.dart';
import '../services/file_picker_helper.dart';
import '../theme/app_colors.dart';
import '../widgets/common/safe_image.dart';
import '../widgets/common/glass_card.dart';

class EditPersonalInfoScreen extends StatefulWidget {
  const EditPersonalInfoScreen({super.key});

  @override
  State<EditPersonalInfoScreen> createState() => _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _handleController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  late TextEditingController _organizationController;
  late TextEditingController _bioController;

  String? _avatarUrl;
  bool _isSaving = false;
  bool _hasPhotoChanged = false;

  // Preset avatar choices for reporters & eyewitnesses
  static const List<Map<String, String>> _presetAvatars = [
    {
      'name': 'Eyewitness 1',
      'url': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Eyewitness 2',
      'url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Field Reporter',
      'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Investigative',
      'url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Emergency Lead',
      'url': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Welfare Observer',
      'url': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Urban Witness',
      'url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Tactical Scout',
      'url': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=400&auto=format&fit=crop&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().currentUser;
    _nameController = TextEditingController(text: user.name);
    _handleController = TextEditingController(text: user.handle);
    _emailController = TextEditingController(text: user.email);
    _locationController = TextEditingController(text: user.location ?? '');
    _organizationController = TextEditingController(text: user.organization ?? '');
    _bioController = TextEditingController(text: user.bio);
    _avatarUrl = user.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _organizationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto({required bool fromCamera}) async {
    try {
      final picked = await pickFilePlatform(
        accept: 'image/*',
        fromCamera: fromCamera,
      );
      if (picked != null && picked.dataUrl != null) {
        setState(() {
          _avatarUrl = picked.dataUrl;
          _hasPhotoChanged = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New profile photo selected.'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick photo: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImageUrlDialog() {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.link_rounded, color: AppColors.primaryNavy),
            SizedBox(width: 8),
            Text('Enter Image URL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste a direct public link to your profile photo (JPEG, PNG, or WebP).',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: urlController,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'https://example.com/avatar.jpg',
                prefixIcon: const Icon(Icons.image_outlined, color: AppColors.textSecondary),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'))) {
                setState(() {
                  _avatarUrl = url;
                  _hasPhotoChanged = true;
                });
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid HTTP or HTTPS image URL.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showPresetsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose a Verified Avatar Preset',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select from curated field-attested eyewitness representations.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _presetAvatars.length,
                  itemBuilder: (ctx, index) {
                    final preset = _presetAvatars[index];
                    final isSelected = _avatarUrl == preset['url'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _avatarUrl = preset['url'];
                          _hasPhotoChanged = true;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage: NetworkImage(preset['url']!),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            preset['name']!,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                              color: isSelected ? const Color(0xFF10B981) : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
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
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Profile Picture',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF1D4ED8), size: 20),
                  ),
                  title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  subtitle: const Text('Capture using device camera', style: TextStyle(fontSize: 11.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(fromCamera: true);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFF15803D), size: 20),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  subtitle: const Text('Select photo from local device files', style: TextStyle(fontSize: 11.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(fromCamera: false);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.palette_outlined, color: Color(0xFF9333EA), size: 20),
                  ),
                  title: const Text('Choose Preset Avatar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  subtitle: const Text('Pick from verified eyewitness & reporter icons', style: TextStyle(fontSize: 11.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPresetsSheet();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.link_rounded, color: AppColors.primaryNavy, size: 20),
                  ),
                  title: const Text('Enter Image URL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  subtitle: const Text('Provide direct link to an online image', style: TextStyle(fontSize: 11.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showImageUrlDialog();
                  },
                ),
                if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                    ),
                    title: const Text('Reset to Default Avatar',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFFDC2626))),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _avatarUrl = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop&q=80';
                        _hasPhotoChanged = true;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final appState = context.read<AppState>();
    try {
      await appState.updateCurrentUserProfile(
        name: _nameController.text.trim(),
        handle: _handleController.text.trim(),
        email: _emailController.text.trim(),
        location: _locationController.text.trim(),
        organization: _organizationController.text.trim(),
        bio: _bioController.text.trim(),
        avatarUrl: _avatarUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Personal info & profile picture updated.'),
              ],
            ),
            backgroundColor: Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentUser = appState.currentUser;
    final locationService = context.watch<LocationService>();

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
        title: const Text(
          'Personal Info',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _isSaving ? null : _saveChanges,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNavy),
                    )
                  : const Icon(Icons.check_rounded, size: 18, color: AppColors.primaryNavy),
              label: Text(
                _isSaving ? 'Saving...' : 'Save',
                style: const TextStyle(
                  color: AppColors.primaryNavy,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2026 Bento Photo Editing Hero Card
              GlassCard(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                borderRadius: 26,
                hasGlow: true,
                child: Column(
                  children: [
                    // Avatar with Camera Overlay
                    Stack(
                      children: [
                        Container(
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
                            radius: 48,
                            backgroundColor: const Color(0xFFE2E8F0),
                            backgroundImage: getUserAvatarProvider(_avatarUrl),
                            onBackgroundImageError: (_, __) {},
                            child: _avatarUrl == null || _avatarUrl!.isEmpty
                                ? Text(
                                    currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      color: AppColors.primaryNavy,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: InkWell(
                            onTap: _showChangePhotoOptions,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryNavy,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Change Photo Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryNavy,
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      ),
                      onPressed: _showChangePhotoOptions,
                      icon: const Icon(Icons.photo_camera_outlined, size: 16),
                      label: const Text(
                        'Change Profile Picture',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),

                    if (_hasPhotoChanged) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF15803D)),
                            SizedBox(width: 4),
                            Text(
                              'Photo updated • Click Save to apply',
                              style: TextStyle(
                                color: Color(0xFF15803D),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SECTION 1: PERSONAL INFORMATION
              const Text(
                'PERSONAL DETAILS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name Field
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'e.g. Vikram Malhotra',
                      icon: Icons.person_outline_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Handle Field
                    _buildTextField(
                      controller: _handleController,
                      label: 'Handle / Public Username',
                      hint: '@handle',
                      icon: Icons.alternate_email_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Handle is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'name@groundtruth.org',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Enter a valid email address';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Location Field with "Use GPS" quick action
                    _buildTextField(
                      controller: _locationController,
                      label: 'Coverage Location / Region',
                      hint: 'e.g. New Delhi, India',
                      icon: Icons.location_on_outlined,
                      suffix: InkWell(
                        onTap: () {
                          final resolved = locationService.displayLocationName;
                          if (resolved.isNotEmpty) {
                            setState(() {
                              _locationController.text = resolved;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Set location to $resolved'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.my_location_rounded, size: 13, color: Color(0xFF1D4ED8)),
                              SizedBox(width: 4),
                              Text(
                                'Use GPS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Organization Field
                    _buildTextField(
                      controller: _organizationController,
                      label: 'Organization / Publication',
                      hint: 'e.g. The Ground Wire, Civic Dispatch, or Independent',
                      icon: Icons.business_outlined,
                    ),
                    const SizedBox(height: 16),

                    // Bio Field
                    _buildTextField(
                      controller: _bioController,
                      label: 'Eyewitness Bio / Focus',
                      hint: 'Brief summary of your field verification background, beat, or reporting areas...',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                      maxLength: 240,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SECTION 2: HARDWARE & ATTESTATION IDENTITY (READ-ONLY)
              const Text(
                'CRYPTOGRAPHIC TELEMETRY & ATTESTATION',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAttestationRow(
                      icon: Icons.shield_rounded,
                      title: 'Trust Score',
                      value: '${currentUser.trustScore} / 100',
                      badgeColor: const Color(0xFFF0FDF4),
                      textColor: const Color(0xFF15803D),
                    ),
                    const Divider(height: 18, color: Color(0xFFF1F5F9)),
                    _buildAttestationRow(
                      icon: Icons.verified_rounded,
                      title: 'Credential Tier',
                      value: currentUser.tier,
                      badgeColor: const Color(0xFFEFF6FF),
                      textColor: const Color(0xFF1D4ED8),
                    ),
                    const Divider(height: 18, color: Color(0xFFF1F5F9)),
                    _buildAttestationRow(
                      icon: Icons.devices_rounded,
                      title: 'Hardware Keystore',
                      value: currentUser.deviceModel,
                      badgeColor: const Color(0xFFF8FAFC),
                      textColor: AppColors.textPrimary,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Trust scores and hardware attestations are cryptographically signed on-chain and cannot be manually modified.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1,
                  ),
                  onPressed: _isSaving ? null : _saveChanges,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: Text(
                    _isSaving ? 'Saving Changes...' : 'Save Personal Info',
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // CANCEL BUTTON
              SizedBox(
                width: double.infinity,
                height: 46,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (suffix != null) suffix,
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttestationRow({
    required IconData icon,
    required String title,
    required String value,
    required Color badgeColor,
    required Color textColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
