import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          'GroundTruth',
          style: TextStyle(
            color: AppColors.primaryNavy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFE2E8F0),
              backgroundImage: NetworkImage(currentUser.avatarUrl),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header (Exact Figma Screen 3)
            const Text(
              'Settings',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage your account preferences, verification tools, and privacy settings.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 22),

            // SECTION 1: ACCOUNT & PROFILE (Exact Figma Screen 3)
            const Text(
              'ACCOUNT & PROFILE',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.account_circle_outlined,
                    title: 'Account',
                    subtitle: appState.isLoggedIn
                        ? 'Logged in as ${currentUser.name}'
                        : 'Not logged in • Tap to log in',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 52),
                  _buildListTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Personal Info',
                    subtitle: 'Update your name and contact details',
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 52),
                  _buildListTile(
                    icon: Icons.shield_outlined,
                    title: 'Security',
                    subtitle: 'Password, 2FA, and active sessions',
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 52),
                  _buildListTile(
                    icon: Icons.badge_outlined,
                    title: 'Linked Credentials',
                    subtitle: 'Press passes and identity verification',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 2: PRIVACY & VERIFICATION (Exact Figma Screen 3)
            const Text(
              'PRIVACY & VERIFICATION',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
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
                        Icon(Icons.verified_user_outlined, color: Color(0xFF15803D), size: 20),
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
                          title: 'GPS Tagging',
                          value: _gpsTagging,
                          onChanged: (val) => setState(() => _gpsTagging = val),
                        ),
                        _buildSwitchRow(
                          title: 'Device Integrity Check',
                          value: _deviceIntegrity,
                          onChanged: (val) => setState(() => _deviceIntegrity = val),
                        ),
                        _buildSwitchRow(
                          title: 'VPN Detection Warning',
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
                          activeTrackColor: const Color(0xFF1D4ED8),
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
                    title: 'Data Privacy',
                    subtitle: 'Manage your data and retention',
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
                      title: const Text('Log Out'),
                      content: Text('Are you sure you want to log out of ${currentUser.name}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
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
                          child: const Text('Log Out', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Color(0xFFDC2626), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
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
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(12),
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),
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
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
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
              fontWeight: FontWeight.w500,
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF1D4ED8),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCBD5E1),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
