import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'event_detail_screen.dart';
import 'settings_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final events = appState.events;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.primaryNavy, size: 24),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Menu opened')),
            );
          },
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
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.primaryNavy, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: AppColors.primaryNavy, size: 24),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header Row (Exact Figma Screen 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alerts',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Stay updated with real-time field\ndata.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      for (final a in appState.alerts) {
                        appState.markAlertAsRead(a.id);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All alerts marked as read')),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text(
                      'Mark all as\nread',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppColors.primaryNavy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Pills (All, Critical, Updates, Community)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  _buildFilterPill('All'),
                  const SizedBox(width: 8),
                  _buildFilterPill('Critical'),
                  const SizedBox(width: 8),
                  _buildFilterPill('Updates'),
                  const SizedBox(width: 8),
                  _buildFilterPill('Community'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // SECTION 1: CRITICAL ALERTS (Exact Figma Screen 2)
            if (_selectedFilter == 'All' || _selectedFilter == 'Critical') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: const [
                    Icon(Icons.warning, color: Color(0xFF991B1B), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'CRITICAL ALERTS',
                      style: TextStyle(
                        color: Color(0xFF991B1B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Alert Card 1: Emergency Broadcast Flash Flood
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: InkWell(
                  onTap: () {
                    final floodEvent = events.firstWhere(
                      (e) => e.title.contains('Flood') || e.title.contains('Water'),
                      orElse: () => events.first,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailScreen(eventId: floodEvent.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
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
                    clipBehavior: Clip.antiAlias,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 4px Red Left Border
                          Container(
                            width: 4.5,
                            color: const Color(0xFF991B1B),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Pink Icon Square
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.flood_outlined,
                                        color: Color(0xFF991B1B),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'EMERGENCY BROADCAST',
                                              style: TextStyle(
                                                color: Color(0xFF991B1B),
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                const Text(
                                                  '2m ago',
                                                  style: TextStyle(
                                                    color: AppColors.textMuted,
                                                    fontSize: 10.5,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF991B1B),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Flash Flood in Delhi Sector 4',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        const Text(
                                          'Severe water logging reported near Metro Station. All...',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Green Location Verified Pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check_circle, size: 11, color: Color(0xFF15803D)),
                                              SizedBox(width: 4),
                                              Text(
                                                'LOCATION VERIFIED',
                                                style: TextStyle(
                                                  color: Color(0xFF15803D),
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Alert Card 2: Safety Alert Active Protest
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: InkWell(
                  onTap: () {
                    final protestEvent = events.firstWhere(
                      (e) => e.title.contains('Protest'),
                      orElse: () => events.first,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailScreen(eventId: protestEvent.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
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
                    clipBehavior: Clip.antiAlias,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 4px Red Left Border
                          Container(
                            width: 4.5,
                            color: const Color(0xFF991B1B),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Pink Icon Square
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.groups_rounded,
                                        color: Color(0xFF991B1B),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'SAFETY ALERT',
                                              style: TextStyle(
                                                color: Color(0xFF991B1B),
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                            Text(
                                              '14m ago',
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 10.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Active Protest Near Your Location',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'Large gathering reported at Central Square. Road closures in',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // SECTION 2: ACTIVITY & UPDATES (Exact Figma Screen 2)
            if (_selectedFilter == 'All' || _selectedFilter == 'Updates' || _selectedFilter == 'Community') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: const [
                    Icon(Icons.history_toggle_off_rounded, color: Color(0xFF1E3A8A), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'ACTIVITY & UPDATES',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Activity Card 1: Reputation Score +15
              _buildActivityCard(
                icon: Icons.trending_up,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF15803D),
                title: "Reputation Score +15 for your detailed report on 'Urban Heat Islands'.",
                time: "1h ago",
                onTap: () {},
              ),
              const SizedBox(height: 10),

              // Activity Card 2: New Peer Review
              _buildActivityCard(
                icon: Icons.chat_bubble_outline_rounded,
                iconBg: const Color(0xFFDBEAFE),
                iconColor: const Color(0xFF1D4ED8),
                title: "New Peer Review received for your ongoing Air Quality investigation.",
                time: "3h ago",
                onTap: () {},
              ),
              const SizedBox(height: 10),

              // Activity Card 3: Verification Success
              _buildActivityCard(
                icon: Icons.article_outlined,
                iconBg: const Color(0xFFCCFBF1),
                iconColor: const Color(0xFF0D9488),
                title: "Verification Success. Your report on 'Streetlight Outages' has been cross-referenced and confirmed.",
                time: "5h ago",
                onTap: () {},
              ),
              const SizedBox(height: 10),

              // Activity Card 4: Alex Chen followed
              _buildActivityCard(
                icon: Icons.person_add_alt_1_outlined,
                iconBg: const Color(0xFFF1F5F9),
                iconColor: const Color(0xFF475569),
                title: "Alex Chen and 4 others followed your verification thread.",
                time: "Yesterday",
                onTap: () {},
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String title) {
    final isSelected = _selectedFilter == title;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = title),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF334155),
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String time,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 19),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
