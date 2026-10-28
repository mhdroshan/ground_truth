import 'dart:ui';
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
              'GroundTruth Alerts',
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
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.primaryNavy, size: 21),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header Row (Exaggerated Minimalism)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Signals',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Real-time physical field dispatches & verifications',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      for (final a in appState.alerts) {
                        appState.markAlertAsRead(a.id);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All alerts marked as read')),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.done_all_rounded, size: 14, color: AppColors.primaryNavy),
                    label: const Text(
                      'Mark Read',
                      style: TextStyle(
                        color: AppColors.primaryNavy,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Pills (All, Critical, Updates, Community)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
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
            ),
            const SizedBox(height: 18),

            // SECTION 1: CRITICAL ALERTS
            if (_selectedFilter == 'All' || _selectedFilter == 'Critical') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: const [
                    Icon(Icons.warning_rounded, color: Color(0xFF991B1B), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'CRITICAL ALERTS',
                      style: TextStyle(
                        color: Color(0xFF991B1B),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
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
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.6), width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 5,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.flood_rounded,
                                        color: Color(0xFF991B1B),
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
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
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.6,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                const Text(
                                                  '2m ago',
                                                  style: TextStyle(
                                                    color: AppColors.textMuted,
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
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
                                        const SizedBox(height: 5),
                                        const Text(
                                          'Flash Flood in Delhi Sector 4',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        const Text(
                                          'Severe water logging reported near Metro Station. All observers advise route diversion.',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF15803D)),
                                              SizedBox(width: 4),
                                              Text(
                                                'LOCATION VERIFIED',
                                                style: TextStyle(
                                                  color: Color(0xFF15803D),
                                                  fontSize: 9,
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
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.6), width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 5,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.groups_rounded,
                                        color: Color(0xFF991B1B),
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
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
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.6,
                                              ),
                                            ),
                                            Text(
                                              '14m ago',
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          'Active Protest Near Your Location',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'Large gathering reported at Central Square. Road closures in place.',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                            height: 1.35,
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
              const SizedBox(height: 22),
            ],

            // SECTION 2: ACTIVITY & UPDATES
            if (_selectedFilter == 'All' || _selectedFilter == 'Updates' || _selectedFilter == 'Community') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: const [
                    Icon(Icons.history_toggle_off_rounded, color: AppColors.primaryNavy, size: 17),
                    SizedBox(width: 6),
                    Text(
                      'ACTIVITY & UPDATES',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              _buildActivityCard(
                icon: Icons.trending_up_rounded,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF15803D),
                title: "Reputation Score +15 for your detailed report on 'Urban Heat Islands'.",
                time: "1h ago",
                onTap: () {},
              ),
              const SizedBox(height: 10),

              _buildActivityCard(
                icon: Icons.chat_bubble_outline_rounded,
                iconBg: const Color(0xFFDBEAFE),
                iconColor: const Color(0xFF1D4ED8),
                title: "New Peer Review received for your ongoing Air Quality investigation.",
                time: "3h ago",
                onTap: () {},
              ),
              const SizedBox(height: 10),

              _buildActivityCard(
                icon: Icons.article_outlined,
                iconBg: const Color(0xFFCCFBF1),
                iconColor: const Color(0xFF0D9488),
                title: "Verification Success. Your report on 'Streetlight Outages' has been cross-referenced and confirmed.",
                time: "5h ago",
                onTap: () {},
              ),
              const SizedBox(height: 10),

              _buildActivityCard(
                icon: Icons.person_add_alt_1_outlined,
                iconBg: const Color(0xFFF1F5F9),
                iconColor: const Color(0xFF475569),
                title: "Alex Chen and 4 others followed your verification thread.",
                time: "Yesterday",
                onTap: () {},
              ),
              const SizedBox(height: 28),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                color: AppColors.primaryNavy.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 0.9),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ),
              const SizedBox(width: 14),
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
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
