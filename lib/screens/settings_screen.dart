import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/common/safe_image.dart';
import 'edit_personal_info_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Verification tool switches
  bool _gpsTagging = true;
  bool _deviceIntegrity = true;
  bool _vpnDetection = false;
  bool _anonymousReporting = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentUser = appState.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'GroundTruth Settings',
              style: TextStyle(
                color: AppColors.primaryNavy,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditPersonalInfoScreen()),
                );
              },
              child: Tooltip(
                message: 'Edit Personal Info',
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFFE2E8F0),
                  backgroundImage: getUserAvatarProvider(currentUser.avatarUrl),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header (Exaggerated Minimalism)
            const Text(
              'Settings',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Manage cryptographic identity, geofencing radar, and privacy controls.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),

            // Bento Profile Quick Card with Photo Change Callout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.bentoBorder, width: 0.9),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditPersonalInfoScreen()),
                      );
                    },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFF1F5F9),
                          backgroundImage: getUserAvatarProvider(currentUser.avatarUrl),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryNavy,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${currentUser.handle} • ${currentUser.tier}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryNavy,
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditPersonalInfoScreen()),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 13),
                    label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // SECTION 1: ACCOUNT & PROFILE
            const Text(
              'ACCOUNT & IDENTITY',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),

            Container(
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
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.account_circle_outlined,
                    title: 'Account Identity',
                    subtitle: appState.isLoggedIn
                        ? 'Authenticated as ${currentUser.name}'
                        : 'Guest Observer • Tap to sign in',
                    onTap: () {
                      if (appState.isLoggedIn) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EditPersonalInfoScreen()),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 52),
                  _buildListTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Personal Info',
                    subtitle: 'Update your name, photo, and contact details',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditPersonalInfoScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 52),
                  _buildListTile(
                    icon: Icons.shield_outlined,
                    title: 'Security & Keys',
                    subtitle: 'Password, cryptographic keypairs, sessions',
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 52),
                  _buildListTile(
                    icon: Icons.badge_outlined,
                    title: 'Linked Credentials',
                    subtitle: 'Press credentials and hardware attestation',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 2: PRIVACY & VERIFICATION
            const Text(
              'GEOFENCING & PROTOCOL TOOLS',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),

            Container(
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
              child: Column(
                children: [
                  // Verification Tools Header inside card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: Row(
                      children: const [
                        Icon(Icons.verified_user_outlined, color: AppColors.verifiedGreen, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Verification Tools',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Switches: GPS Tagging, Device Integrity, VPN Warning
                  Padding(
                    padding: const EdgeInsets.only(left: 46, right: 16),
                    child: Column(
                      children: [
                        _buildSwitchRow(
                          title: 'GNSS Radar Tagging',
                          value: _gpsTagging,
                          onChanged: (val) => setState(() => _gpsTagging = val),
                        ),
                        _buildSwitchRow(
                          title: 'Hardware Integrity Attestation',
                          value: _deviceIntegrity,
                          onChanged: (val) => setState(() => _deviceIntegrity = val),
                        ),
                        _buildSwitchRow(
                          title: 'Anti-Spoofing & VPN Warning',
                          value: _vpnDetection,
                          onChanged: (val) => setState(() => _vpnDetection = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // Anonymous Reporting Switch
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility_off_outlined, color: AppColors.textSecondary, size: 22),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Anonymous Reporting',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Hide identity on public submissions',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _anonymousReporting,
                          activeThumbColor: Colors.white,
                          activeTrackColor: AppColors.primaryNavy,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFCBD5E1),
                          onChanged: (val) => setState(() => _anonymousReporting = val),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // Data Privacy Tile
                  _buildListTile(
                    icon: Icons.shield_outlined,
                    title: 'Data Retention & Encryption',
                    subtitle: 'Local cache, encrypted traces, and wipe',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // AUTHENTICATION ACTION BUTTON (Log Out or Sign In)
            if (appState.isLoggedIn)
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w800)),
                      content: Text('Are you sure you want to log out of ${currentUser.name}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            appState.logout();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Logged out successfully.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Text('Log Out', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Log In',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primaryNavy,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCBD5E1),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
